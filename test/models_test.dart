import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/constants/app_constants.dart';
import 'package:servico_conecta/shared/models/models.dart';
import 'package:servico_conecta/shared/services/firebase_service.dart';

void main() {
  group('XP / Gamificação', () {
    test('xpLevel retorna o nível correto para cada faixa', () {
      expect(xpLevel(0), '⭐ Iniciante');
      expect(xpLevel(499), '⭐ Iniciante');
      expect(xpLevel(500), '🥉 Bronze');
      expect(xpLevel(999), '🥉 Bronze');
      expect(xpLevel(1000), '🥈 Prata');
      expect(xpLevel(1999), '🥈 Prata');
      expect(xpLevel(2000), '🥇 Ouro');
      expect(xpLevel(3999), '🥇 Ouro');
      expect(xpLevel(4000), '💎 Diamante');
      expect(xpLevel(10000), '💎 Diamante');
    });

    test('nextLevelXp calcula corretamente o XP restante', () {
      expect(nextLevelXp(0), 500);
      expect(nextLevelXp(250), 250);
      expect(nextLevelXp(500), 500);
      expect(nextLevelXp(750), 250);
      expect(nextLevelXp(1000), 1000);
      expect(nextLevelXp(4000), 0);
      expect(nextLevelXp(9999), 0);
    });

    test('xpProgress retorna valor entre 0.0 e 1.0', () {
      expect(xpProgress(0), 0.0);
      expect(xpProgress(250), 0.5);
      expect(xpProgress(500), 0.0);
      expect(xpProgress(4000), 1.0);
      expect(xpProgress(9999), 1.0);
    });
  });

  group('Pagamentos (PaySvc)', () {
    test('fmt formata valores em reais corretamente', () {
      expect(PaySvc.fmt(0), 'R\$ 0,00');
      expect(PaySvc.fmt(9.9), 'R\$ 9,90');
      expect(PaySvc.fmt(150), 'R\$ 150,00');
      expect(PaySvc.fmt(1234.5), 'R\$ 1234,50');
    });

    test('fee calcula 15% de comissão sobre o valor', () {
      expect(PaySvc.fee(100), 15.0);
      expect(PaySvc.fee(0), 0.0);
      expect(PaySvc.fee(200), 30.0);
    });
  });

  group('Categorias de Serviço', () {
    test('Categories.all não está vazia e tem categorias esperadas', () {
      expect(Categories.all, isNotEmpty);
      expect(Categories.byId('eletricista'), isNotNull);
      expect(Categories.byId('medico'), isNotNull);
      expect(Categories.byId('categoria_inexistente_xyz'), isNull);
    });

    test('todas as categorias têm id, name e emoji não vazios', () {
      for (final c in Categories.all) {
        expect(c.id, isNotEmpty, reason: 'categoria com id vazio');
        expect(c.name, isNotEmpty, reason: 'categoria ${c.id} sem nome');
        expect(c.emoji, isNotEmpty, reason: 'categoria ${c.id} sem emoji');
      }
    });

    test('não há ids de categoria duplicados', () {
      final ids = Categories.all.map((c) => c.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length, reason: 'existem categorias com id duplicado');
    });
  });

  group('UserModel', () {
    test('fromMap/toMap preservam os dados essenciais', () {
      final map = {
        'name': 'João Silva', 'email': 'joao@teste.com', 'phone': '11999999999',
        'type': 'provider', 'xp': 750, 'verified': true, 'status': 'active',
      };
      final user = UserModel.fromMap('uid123', map);

      expect(user.id, 'uid123');
      expect(user.name, 'João Silva');
      expect(user.type, UserType.provider);
      expect(user.xp, 750);
      expect(user.verified, true);
      expect(user.levelName, '🥉 Bronze');
      expect(user.firstName, 'João');
    });

    test('fromMap usa valores padrão quando campos estão ausentes', () {
      final user = UserModel.fromMap('uid456', {});
      expect(user.name, '');
      expect(user.type, UserType.client);
      expect(user.xp, 0);
      expect(user.verified, false);
      expect(user.status, 'active');
    });

    test('type company é reconhecido corretamente', () {
      final user = UserModel.fromMap('uid789', {'type': 'company', 'name': 'Empresa X'});
      expect(user.type, UserType.company);
    });
  });

  group('OrderModel', () {
    test('statusLabel retorna o texto correto para cada status', () {
      DateTime now = DateTime.now();
      OrderModel makeOrder(OrderStatus s) => OrderModel(
        id: '1', clientId: 'c1', category: 'eletricista', title: 'Teste',
        description: '', address: '', status: s, createdAt: now,
      );

      expect(makeOrder(OrderStatus.pending).statusLabel, contains('Aguardando'));
      expect(makeOrder(OrderStatus.completed).statusLabel, contains('Concluído'));
      expect(makeOrder(OrderStatus.cancelled).statusLabel, contains('Cancelado'));
    });

    test('reviewed é false por padrão e true quando definido', () {
      final order1 = OrderModel.fromMap('o1', {'clientId': 'c1', 'category': 'medico', 'title': 'T', 'description': '', 'address': ''});
      expect(order1.reviewed, false);

      final order2 = OrderModel.fromMap('o2', {'clientId': 'c1', 'category': 'medico', 'title': 'T', 'description': '', 'address': '', 'reviewed': true});
      expect(order2.reviewed, true);
    });

    test('fromMap preserva providerId quando presente (fluxo Solicitar Orçamento)', () {
      final order = OrderModel.fromMap('o3', {
        'clientId': 'c1', 'providerId': 'prov1', 'category': 'eletricista',
        'title': 'Instalação', 'description': 'Trocar tomadas', 'address': 'Rua X, 100',
      });
      expect(order.providerId, 'prov1');
      expect(order.status, OrderStatus.pending);
    });

    test('todos os status de OrderStatus têm um statusLabel não vazio', () {
      DateTime now = DateTime.now();
      for (final s in OrderStatus.values) {
        final order = OrderModel(id: '1', clientId: 'c1', category: 'x', title: 'T', description: '', address: '', status: s, createdAt: now);
        expect(order.statusLabel, isNotEmpty, reason: 'status $s sem label');
      }
    });
  });

  group('CompanyModel', () {
    test('planLabel retorna o texto correto para cada plano', () {
      DateTime now = DateTime.now();
      CompanyModel makeCompany(PlanTier p) => CompanyModel(
        id: '1', ownerId: 'u1', name: 'Empresa', cnpj: '12345678000100', plan: p, createdAt: now,
      );

      expect(makeCompany(PlanTier.free).planLabel, 'Grátis');
      expect(makeCompany(PlanTier.professional).planLabel, 'Profissional');
      expect(makeCompany(PlanTier.premium).planLabel, 'Premium');
      expect(makeCompany(PlanTier.corporate).planLabel, 'Corporativo');
    });
  });

  group('CouponModel', () {
    test('label formata desconto percentual e fixo corretamente', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final percentCoupon = CouponModel(id: '1', code: 'PROMO10', description: '', discount: 10, isPercentage: true, expiresAt: future);
      final fixedCoupon = CouponModel(id: '2', code: 'DESC20', description: '', discount: 20, isPercentage: false, expiresAt: future);

      expect(percentCoupon.label, '10% OFF');
      expect(fixedCoupon.label, contains('20.00'));
    });

    test('isValid retorna false para cupom expirado', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final expired = CouponModel(id: '1', code: 'OLD', description: '', discount: 10, expiresAt: past);
      expect(expired.isValid, false);
    });

    test('isValid retorna false para cupom inativo mesmo não expirado', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final inactive = CouponModel(id: '1', code: 'X', description: '', discount: 10, active: false, expiresAt: future);
      expect(inactive.isValid, false);
    });

    test('isValid retorna true para cupom ativo e não expirado', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final valid = CouponModel(id: '1', code: 'VALID', description: '', discount: 10, active: true, expiresAt: future);
      expect(valid.isValid, true);
    });
  });

  group('ProviderModel', () {
    test('badge retorna o nível correto conforme total de avaliações', () {
      DateTime now = DateTime.now();
      ProviderModel makeProvider(int reviews) => ProviderModel(
        id: '1', userId: 'u1', name: 'Prof', totalReviews: reviews, createdAt: now,
      );

      expect(makeProvider(0).badge, contains('Bronze'));
      expect(makeProvider(50).badge, contains('Prata'));
      expect(makeProvider(200).badge, contains('Ouro'));
      expect(makeProvider(500).badge, contains('Diamante'));
    });
  });

  group('TicketModel', () {
    test('statusLabel mapeia todos os status corretamente', () {
      DateTime now = DateTime.now();
      TicketModel makeTicket(TicketStatus s) => TicketModel(
        id: '1', userId: 'u1', userName: 'User', subject: 'S', message: 'M', status: s, createdAt: now,
      );

      expect(makeTicket(TicketStatus.open).statusLabel, contains('Aberto'));
      expect(makeTicket(TicketStatus.inProgress).statusLabel, contains('atendimento'));
      expect(makeTicket(TicketStatus.resolved).statusLabel, contains('Resolvido'));
      expect(makeTicket(TicketStatus.closed).statusLabel, contains('Fechado'));
    });
  });
}
