import '../constants/runtime_config.dart';
import '../../shared/models/models.dart';

/// Listas de exemplo só no bypass local, com Firebase desligado.
/// Fora disso, ausência de dados continua vazia — nunca vira cadastro falso.
abstract final class DemoData {
  static bool get allow => RuntimeConfig.showLabeledDemo;

  static List<T> orEmpty<T>(List<T>? data, List<T> demo) {
    if (data != null) return data;
    return allow ? demo : <T>[];
  }
}

abstract final class DemoCatalog {
  static final providers = <ProviderModel>[
    ProviderModel(
      id: 'demo-pedreiro',
      userId: 'demo-pedreiro',
      name: 'Exemplo · reforma (demonstração)',
      city: 'Canaã dos Carajás',
      categories: const ['pedreiro'],
      bio: 'Cartão de demonstração. Não é um profissional cadastrado.',
      rating: 0,
      totalReviews: 0,
      active: false,
      verified: false,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    ProviderModel(
      id: 'demo-eletrica',
      userId: 'demo-eletrica',
      name: 'Exemplo · elétrica (demonstração)',
      city: 'Canaã dos Carajás',
      categories: const ['eletricista'],
      bio: 'Cartão de demonstração. Não é um profissional cadastrado.',
      rating: 0,
      totalReviews: 0,
      active: false,
      verified: false,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  ];
}
