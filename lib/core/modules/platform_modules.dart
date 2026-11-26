import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Status de disponibilidade de um módulo da plataforma.
enum ModuleStatus { available, comingSoon }

/// Descritor de módulo Carajás 360 (Home / busca global).
class PlatformModule {
  final String id;
  final String emoji;
  final String label;
  final String subtitle;
  final ModuleStatus status;
  final String? route;
  final Color accent;

  const PlatformModule({
    required this.id,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.status,
    this.route,
    required this.accent,
  });

  bool get isAvailable => status == ModuleStatus.available;
}

/// Catálogo de módulos da plataforma. Novos módulos entram aqui
/// antes de ganhar telas próprias — cards "Em desenvolvimento"
/// nunca navegam para rotas vazias.
abstract class PlatformModules {
  static const all = <PlatformModule>[
    PlatformModule(
      id: 'services',
      emoji: '🔧',
      label: 'Serviços',
      subtitle: 'Profissionais da região',
      status: ModuleStatus.available,
      route: Routes.servicesHub,
      accent: Color(0xFF0B3D91),
    ),
    PlatformModule(
      id: 'jobs',
      emoji: '💼',
      label: 'Vagas',
      subtitle: 'Emprego e oportunidades',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFF1565C0),
    ),
    PlatformModule(
      id: 'freight',
      emoji: '🚚',
      label: 'Fretes',
      subtitle: 'Cargas e mudanças',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFFD4550A),
    ),
    PlatformModule(
      id: 'realty',
      emoji: '🏠',
      label: 'Imóveis',
      subtitle: 'Aluguel e venda',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFF5D4037),
    ),
    PlatformModule(
      id: 'health',
      emoji: '🩺',
      label: 'Saúde',
      subtitle: 'Clínicas e profissionais',
      status: ModuleStatus.available,
      route: Routes.health,
      accent: Color(0xFF0F6B5C),
    ),
    PlatformModule(
      id: 'construction',
      emoji: '🏗️',
      label: 'Obras',
      subtitle: 'Materiais e equipamentos',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFF6D4C41),
    ),
    PlatformModule(
      id: 'auto',
      emoji: '🚗',
      label: 'Auto',
      subtitle: 'Oficinas e socorro',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFF37474F),
    ),
    PlatformModule(
      id: 'kids',
      emoji: '👶',
      label: 'Kids',
      subtitle: 'Família e infância',
      status: ModuleStatus.comingSoon,
      accent: Color(0xFFAD1457),
    ),
  ];

  static PlatformModule? byId(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Cidades prioritárias da região (expansível — sem hard-limit técnico).
abstract class RegionCities {
  static const priority = <String>[
    'Canaã dos Carajás',
    'Parauapebas',
    'Marabá',
  ];

  static const nearby = <String>[
    'Ourilândia do Norte',
    'Água Azul do Norte',
    'Curionópolis',
    'Eldorado dos Carajás',
  ];

  static const defaultCity = 'Canaã dos Carajás';
}
