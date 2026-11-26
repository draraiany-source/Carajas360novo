/// Política oficial de pedidos / repasse.
/// Espelhada em `functions/orderPolicy.js` — testes cobrem os dois lados.
abstract final class OrderPolicy {
  static const commissionRate = 0.15;

  /// Campos que o client SDK NUNCA pode alterar após a criação.
  static const sensitiveFields = <String>{
    'price',
    'total',
    'providerId',
    'clientId',
    'status',
    'paymentStatus',
    'payoutStatus',
    'payoutProcessed',
    'commission',
    'platformFee',
    'providerAmount',
    'transactionId',
    'cashbackGranted',
    'paidAt',
    'payoutAt',
  };

  /// Campos administrativos do perfil bloqueados no client.
  static const protectedUserFields = <String>{
    'type',
    'role',
    'roles',
    'adminRole',
    'verified',
    'active',
    'plan',
    'walletId',
    'financialStatus',
    'permissions',
    'createdAt',
    'xp',
    'status',
  };

  static const protectedProviderFields = <String>{
    'verified',
    'plan',
    'status',
    'rating',
    'totalReviews',
    'userId',
  };

  /// Máquina de estados (nomes já usados no app Flutter).
  /// pending ≈ created; inProgress ≈ in_progress.
  static const transitions = <String, Set<String>>{
    'pending': {'accepted', 'cancelled'},
    'accepted': {'inProgress', 'cancelled'},
    'inProgress': {'completed', 'cancelled', 'disputed'},
    'completed': {},
    'cancelled': {},
    'disputed': {'cancelled'},
  };

  static const actions = <String, String>{
    'accept': 'accepted',
    'start': 'inProgress',
    'complete': 'completed',
    'cancel': 'cancelled',
    'decline': 'cancelled',
    'dispute': 'disputed',
  };

  static bool isAllowedTransition(String from, String to) =>
      (transitions[from] ?? const <String>{}).contains(to);

  static String? targetStatus(String action) => actions[action];

  static bool actorMayPerform({
    required String action,
    required String uid,
    required String clientId,
    required String? providerId,
  }) {
    final isClient = uid == clientId;
    final isProvider =
        providerId != null && providerId.isNotEmpty && uid == providerId;
    switch (action) {
      case 'accept':
        return providerId == null ||
            providerId.isEmpty ||
            uid == providerId;
      case 'start':
      case 'decline':
        return isProvider;
      case 'complete':
      case 'dispute':
        return isClient || isProvider;
      case 'cancel':
        return isClient || isProvider;
      default:
        return false;
    }
  }

  static PayoutDecision canPayout({
    required String status,
    required String paymentStatus,
    required bool payoutProcessed,
    required String? providerId,
    required num? price,
    required String orderId,
    String? paymentOrderId,
    String? gatewayStatus,
    num? paidAmount,
  }) {
    if (payoutProcessed) {
      return const PayoutDecision.deny('already_processed');
    }
    if (status != 'completed') {
      return const PayoutDecision.deny('order_not_completed');
    }
    final paid = paymentStatus == 'paid' || gatewayStatus == 'approved';
    if (!paid) {
      return const PayoutDecision.deny('payment_not_confirmed');
    }
    if (providerId == null || providerId.isEmpty) {
      return const PayoutDecision.deny('missing_provider');
    }
    if (price == null || price <= 0) {
      return const PayoutDecision.deny('invalid_price');
    }
    if (paymentOrderId != null && paymentOrderId != orderId) {
      return const PayoutDecision.deny('payment_order_mismatch');
    }
    if (paidAmount != null && (paidAmount - price).abs() > 0.009) {
      return const PayoutDecision.deny('amount_mismatch');
    }
    final gross = price.toDouble();
    final commission = double.parse((gross * commissionRate).toStringAsFixed(2));
    final providerAmount =
        double.parse((gross - commission).toStringAsFixed(2));
    return PayoutDecision.allow(
      gross: gross,
      commission: commission,
      providerAmount: providerAmount,
    );
  }

  static String? completeBlockReason({
    required String currentStatus,
    required String paymentStatus,
  }) {
    if (currentStatus != 'inProgress') return 'invalid_transition';
    if (paymentStatus != 'paid') return 'payment_not_confirmed';
    return null;
  }
}

class PayoutDecision {
  final bool ok;
  final String? reason;
  final double gross;
  final double commission;
  final double providerAmount;

  const PayoutDecision._({
    required this.ok,
    this.reason,
    this.gross = 0,
    this.commission = 0,
    this.providerAmount = 0,
  });

  const PayoutDecision.deny(String reason)
      : this._(ok: false, reason: reason);

  const PayoutDecision.allow({
    required double gross,
    required double commission,
    required double providerAmount,
  }) : this._(
          ok: true,
          gross: gross,
          commission: commission,
          providerAmount: providerAmount,
        );
}

class CloudCallException implements Exception {
  final String message;
  final String code;
  const CloudCallException(this.message, {this.code = 'internal'});
  @override
  String toString() => message;
}
