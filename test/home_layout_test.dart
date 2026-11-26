import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/security/order_lifecycle.dart';
import 'package:servico_conecta/features/home/home_layout.dart';
import 'package:servico_conecta/shared/services/payment_gateway.dart';

void main() {
  test('tiles da home em 1280x800 não passam de 168px', () {
    const content = 1280 - 248;
    expect(HomeLayout.estimatedTileWidth(content.toDouble()),
        lessThanOrEqualTo(168));
    expect(HomeLayout.tileMainAxisExtent, 112);
  });

  test('banner estreito empilha os botões e esconde o retrato', () {
    expect(HomeLayout.stackedHeroButtons(390), isTrue);
    expect(HomeLayout.showHeroPortrait(390), isFalse);
    expect(HomeLayout.stackedHeroButtons(1100), isFalse);
    expect(HomeLayout.showHeroPortrait(1100), isTrue);
  });

  test('ciclo de vida tem rótulo em português', () {
    expect(OrderLifecycle.label('aguardando_orcamentos'),
        'Aguardando orçamentos');
    expect(OrderLifecycle.label('em_contestacao'), 'Em contestação');
    expect(OrderLifecycle.label(null), isNull);
  });

  test('boleto não aprova pagamento no cliente', () async {
    final result = await PaymentGateway.charge(
      method: PaymentMethod.boleto,
      amount: 10,
      description: 'teste',
      orderId: 'o1',
    );
    expect(result.success, isFalse);
    expect(result.error, contains('aguardando credenciais'));
  });
}
