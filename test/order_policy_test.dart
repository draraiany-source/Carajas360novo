import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/security/order_policy.dart';

void main() {
  group('máquina de estados do pedido', () {
    test('transições explícitas permitidas', () {
      expect(OrderPolicy.isAllowedTransition('pending', 'accepted'), isTrue);
      expect(OrderPolicy.isAllowedTransition('accepted', 'inProgress'), isTrue);
      expect(OrderPolicy.isAllowedTransition('inProgress', 'completed'), isTrue);
      expect(OrderPolicy.isAllowedTransition('pending', 'cancelled'), isTrue);
    });

    test('completar pedido duas vezes / pular estados falha', () {
      expect(OrderPolicy.isAllowedTransition('pending', 'completed'), isFalse);
      expect(OrderPolicy.isAllowedTransition('accepted', 'completed'), isFalse);
      expect(OrderPolicy.isAllowedTransition('completed', 'completed'), isFalse);
      expect(OrderPolicy.isAllowedTransition('completed', 'inProgress'), isFalse);
    });

    test('cliente não troca providerId (campo sensível)', () {
      expect(OrderPolicy.sensitiveFields.contains('providerId'), isTrue);
      expect(OrderPolicy.sensitiveFields.contains('price'), isTrue);
      expect(OrderPolicy.sensitiveFields.contains('clientId'), isTrue);
    });
  });

  group('complete sem pagamento', () {
    test('deve falhar se unpaid/pending', () {
      expect(
        OrderPolicy.completeBlockReason(
            currentStatus: 'inProgress', paymentStatus: 'unpaid'),
        'payment_not_confirmed',
      );
      expect(
        OrderPolicy.completeBlockReason(
            currentStatus: 'inProgress', paymentStatus: 'pending'),
        'payment_not_confirmed',
      );
    });

    test('só de inProgress + paid', () {
      expect(
        OrderPolicy.completeBlockReason(
            currentStatus: 'inProgress', paymentStatus: 'paid'),
        isNull,
      );
      expect(
        OrderPolicy.completeBlockReason(
            currentStatus: 'pending', paymentStatus: 'paid'),
        'invalid_transition',
      );
    });
  });

  group('payout', () {
    PayoutDecision payout({
      bool processed = false,
      String status = 'completed',
      String payment = 'paid',
      String? provider = 'p1',
      num price = 100,
      String payOrder = 'o1',
      num paid = 100,
    }) =>
        OrderPolicy.canPayout(
          status: status,
          paymentStatus: payment,
          payoutProcessed: processed,
          providerId: provider,
          price: price,
          orderId: 'o1',
          paymentOrderId: payOrder,
          gatewayStatus: payment == 'paid' ? 'approved' : 'pending',
          paidAmount: paid,
        );

    test('repasse único calcula 15% de comissão', () {
      final r = payout();
      expect(r.ok, isTrue);
      expect(r.commission, 15);
      expect(r.providerAmount, 85);
    });

    test('executar payout duas vezes falha com already_processed', () {
      final r = payout(processed: true);
      expect(r.ok, isFalse);
      expect(r.reason, 'already_processed');
    });

    test('alterar price (valor pago ≠ price) falha', () {
      final r = payout(paid: 1);
      expect(r.ok, isFalse);
      expect(r.reason, 'amount_mismatch');
    });

    test('pedido de outro orderId no pagamento falha', () {
      final r = payout(payOrder: 'outro');
      expect(r.ok, isFalse);
      expect(r.reason, 'payment_order_mismatch');
    });

    test('concluir sem pagamento falha', () {
      final r = payout(payment: 'unpaid', paid: 0);
      expect(r.ok, isFalse);
      expect(r.reason, 'payment_not_confirmed');
    });

    test('providerId ausente falha', () {
      final r = payout(provider: '');
      expect(r.ok, isFalse);
      expect(r.reason, 'missing_provider');
    });
  });

  group('quem pode agir', () {
    test('terceiro não aceita pedido de outro prestador', () {
      expect(
        OrderPolicy.actorMayPerform(
            action: 'accept', uid: 'p2', clientId: 'c1', providerId: 'p1'),
        isFalse,
      );
    });

    test('cliente não inicia atendimento', () {
      expect(
        OrderPolicy.actorMayPerform(
            action: 'start', uid: 'c1', clientId: 'c1', providerId: 'p1'),
        isFalse,
      );
    });
  });
}
