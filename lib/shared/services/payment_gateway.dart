import '../../core/constants/runtime_config.dart';
import '../../core/utils/platform_info.dart';
import 'firebase_service.dart';

/// Métodos de pagamento suportados pela plataforma.
enum PaymentMethod { pix, creditCard, boleto, googlePay, applePay, wallet }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.pix => 'PIX',
        PaymentMethod.creditCard => 'Cartão de crédito',
        PaymentMethod.boleto => 'Boleto',
        PaymentMethod.googlePay => 'Google Pay',
        PaymentMethod.applePay => 'Apple Pay',
        PaymentMethod.wallet => 'Carteira ServiçoConecta',
      };

  String get icon => switch (this) {
        PaymentMethod.pix => '⚡',
        PaymentMethod.creditCard => '💳',
        PaymentMethod.boleto => '📄',
        PaymentMethod.googlePay => '🟢',
        PaymentMethod.applePay => '',
        PaymentMethod.wallet => '👜',
      };
}

/// Resultado padronizado de uma tentativa de pagamento, independente
/// do gateway usado por baixo.
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? error;
  final bool pending; // ex.: PIX aguardando confirmação

  const PaymentResult(
      {required this.success,
      this.transactionId,
      this.error,
      this.pending = false});

  factory PaymentResult.ok(String id, {bool pending = false}) =>
      PaymentResult(success: true, transactionId: id, pending: pending);
  factory PaymentResult.fail(String error) =>
      PaymentResult(success: false, error: error);
}

/// Camada de abstração sobre os provedores de pagamento.
abstract class PaymentGateway {
  /// Métodos disponíveis na plataforma atual. Apple Pay só em iOS;
  /// Google Pay no restante (inclui Web/Android).
  static List<PaymentMethod> availableMethods({bool? isIOS}) {
    final apple = isIOS ?? PlatformInfo.isIOS;
    return [
      PaymentMethod.pix,
      PaymentMethod.creditCard,
      PaymentMethod.boleto,
      if (apple) PaymentMethod.applePay else PaymentMethod.googlePay,
      PaymentMethod.wallet,
    ];
  }

  /// Ponto único de entrada para cobrar. Roteia para o provedor certo
  /// conforme o método escolhido.
  static Future<PaymentResult> charge({
    required PaymentMethod method,
    required double amount,
    required String description,
    required String orderId,
    String? email,
  }) async {
    switch (method) {
      case PaymentMethod.pix:
        final data = await PaySvc.generatePix(
            amount: amount,
            description: description,
            email: email ?? '',
            orderId: orderId);
        if (data == null)
          return PaymentResult.fail('Não foi possível gerar o PIX.');
        // PIX é assíncrono: a confirmação vem por webhook/polling.
        return PaymentResult.ok(data['id']?.toString() ?? orderId,
            pending: true);

      case PaymentMethod.wallet:
        final ok = await FS.payOrderWithWallet(orderId);
        return ok
            ? PaymentResult.ok(orderId)
            : PaymentResult.fail(
                'Não foi possível pagar com a carteira. Confira o saldo e o preço do pedido.');

      case PaymentMethod.boleto:
      case PaymentMethod.creditCard:
        if (method == PaymentMethod.boleto ||
            RuntimeConfig.hasPlaceholderMercadoPago) {
          return PaymentResult.fail(
              'Gateway aguardando credenciais. Nenhum pagamento foi aprovado.');
        }
        return PaymentResult.fail(
            'Use a tela de cartão para tokenizar antes de cobrar.');

      case PaymentMethod.googlePay:
      case PaymentMethod.applePay:
        // Ponto de integração pronto. A implementação nativa requer o
        // pacote `pay` + credenciais de merchant configuradas. Enquanto
        // não conectado, retorna um erro claro em vez de simular sucesso.
        return PaymentResult.fail(
            '${method.label} ainda não está ativado. Configure as credenciais de merchant para habilitar.');
    }
  }

  /// Indica se o método precisa de uma tela dedicada (cartão) ou pode
  /// ser cobrado inline (carteira, carteiras digitais nativas).
  static bool needsDedicatedScreen(PaymentMethod method) =>
      method == PaymentMethod.creditCard ||
      method == PaymentMethod.boleto ||
      method == PaymentMethod.pix;
}
