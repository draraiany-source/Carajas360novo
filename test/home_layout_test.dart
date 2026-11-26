import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/security/order_lifecycle.dart';
import 'package:servico_conecta/features/home/home_layout.dart';
import 'package:servico_conecta/shared/services/payment_gateway.dart';

void main() {
  test('grade e ícones respeitam breakpoint', () {
    expect(HomeLayout.columnsFor(320), 2);
    expect(HomeLayout.columnsFor(390), 3);
    expect(HomeLayout.columnsFor(768), 4);
    expect(HomeLayout.columnsFor(1100), 5);
    expect(HomeLayout.columnsFor(1400), 6);
    expect(HomeLayout.iconInRange(IconTier.category, 1400, HomeLayout.iconSize(IconTier.category, 1400)), isTrue);
    expect(HomeLayout.iconSize(IconTier.category, 1400), inInclusiveRange(88, 100));
    expect(HomeLayout.iconSize(IconTier.category, 768), inInclusiveRange(76, 88));
    expect(HomeLayout.iconSize(IconTier.category, 390), inInclusiveRange(64, 76));
    expect(HomeLayout.iconSize(IconTier.subcategory, 1400), inInclusiveRange(64, 80));
    expect(HomeLayout.iconSize(IconTier.list, 390), inInclusiveRange(36, 44));
    expect(HomeLayout.heroHeight(390), lessThanOrEqualTo(200));
    expect(HomeLayout.tiaHeroHeight(390), lessThanOrEqualTo(64));
  });

  test('banner estreito empilha os botões e reduz o retrato', () {
    expect(HomeLayout.stackedHeroButtons(390), isTrue);
    expect(HomeLayout.showHeroPortrait(390), isTrue);
    expect(HomeLayout.tiaHeroHeight(390), lessThan(HomeLayout.heroHeight(390)));
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
