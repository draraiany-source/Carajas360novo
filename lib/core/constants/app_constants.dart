import 'package:flutter/material.dart';

abstract class AppInfo {
  static const name = 'Carajás 360';
  static const slogan = 'Tudo que você precisa na região, em um só lugar.';
  static const version = '1.0.0';
  /// Nome legado do núcleo de serviços (módulo Serviços).
  static const servicesModuleName = 'Serviços';
  static const servicesModuleLegacy = 'Serviço Conecta';
}

abstract class AppConst {
  static const double commission = 0.15;
  static const int otpTimeoutSeconds = 60;
  static const int xpPerReview = 30;
}

abstract class Col {
  static const users = 'users';
  static const providers = 'providers';
  static const companies = 'companies';
  static const orders = 'orders';
  static const wallets = 'wallets';
  static const transactions = 'transactions';
  static const reviews = 'reviews';
  static const chatRooms = 'chatRooms';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const coupons = 'coupons';
  static const deliveries = 'deliveries';
  static const appointments = 'appointments';
  static const contracts = 'contracts';
  static const support = 'support';
  static const auditLogs = 'auditLogs';
  static const banners = 'banners';
  static const categories = 'categories';
  static const favorites = 'favorites';
  static const reports = 'reports';
  static const employees = 'employees';
  static const branches = 'branches';
  static const stores = 'stores';
  static const products = 'products';
  static const rentals = 'rentals';
  static const bookings = 'bookings';
  /// Resolve Carajás — solicitações abertas e propostas.
  static const resolveRequests = 'resolveRequests';
  static const resolveProposals = 'resolveProposals';
  static const financialAudits = 'financialAudits';
  static const rateLimits = 'rateLimits';
}

abstract class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const search = '/search';
  static const chat = '/chat';
  static const wallet = '/wallet';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const reviews = '/reviews';
  static const health = '/health';
  static const delivery = '/delivery';
  static const marketplace = '/marketplace';
  static const store = '/store';
  static const rental = '/rental';
  static const bookings = '/bookings';
  static const stores = '/stores';
  static const admin = '/admin';
  static const gps = '/gps';
  static const support = '/support';
  static const coupons = '/coupons';
  static const aiAssistant = '/ai';
  static const tiaRequest = '/tia-request';
  static const tiaSchedule = '/tia-schedule';
  static const companyProfile = '/company';
  static const favorites = '/favorites';
  static const myOrders = '/my-orders';
  static const requestService = '/request-service';
  static const providerHome = '/provider-home';
  static const providerOnboarding = '/provider-onboarding';
  static const servicesHub = '/services-hub';
  static const resolve = '/resolve';
  static const resolveDetail = '/resolve-detail';
  static const resolveOpportunities = '/resolve-opportunities';
  static const chatInbox = '/chat-inbox';
  static const myResolve = '/my-resolve';
  static const providerProfile = '/provider-profile';
}

class ServiceCategory {
  final String id, name, emoji, group;
  final Color color;
  const ServiceCategory(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.group,
      required this.color});
}

abstract class Categories {
  static const all = <ServiceCategory>[
    ServiceCategory(
        id: 'eletricista',
        name: 'Eletricista',
        emoji: '⚡',
        group: 'Casa',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'encanador',
        name: 'Encanador',
        emoji: '🔧',
        group: 'Casa',
        color: Color(0xFF0277BD)),
    ServiceCategory(
        id: 'pedreiro',
        name: 'Pedreiro',
        emoji: '🧱',
        group: 'Casa',
        color: Color(0xFF5D4037)),
    ServiceCategory(
        id: 'pintor',
        name: 'Pintor',
        emoji: '🎨',
        group: 'Casa',
        color: Color(0xFFE65100)),
    ServiceCategory(
        id: 'marceneiro',
        name: 'Marceneiro',
        emoji: '🪚',
        group: 'Casa',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'diarista',
        name: 'Diarista',
        emoji: '🧹',
        group: 'Limpeza',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'faxineira',
        name: 'Faxineira',
        emoji: '🧽',
        group: 'Limpeza',
        color: Color(0xFF388E3C)),
    ServiceCategory(
        id: 'jardineiro',
        name: 'Jardineiro',
        emoji: '🌿',
        group: 'Jardim',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'medico',
        name: 'Médico',
        emoji: '🩺',
        group: 'Saúde',
        color: Color(0xFF006064)),
    ServiceCategory(
        id: 'enfermeiro',
        name: 'Enfermeiro',
        emoji: '💉',
        group: 'Saúde',
        color: Color(0xFF00838F)),
    ServiceCategory(
        id: 'fisioterapeuta',
        name: 'Fisioterapeuta',
        emoji: '🦴',
        group: 'Saúde',
        color: Color(0xFF00695C)),
    ServiceCategory(
        id: 'psicologo',
        name: 'Psicólogo',
        emoji: '🧠',
        group: 'Saúde',
        color: Color(0xFF6A1B9A)),
    ServiceCategory(
        id: 'nutricionista',
        name: 'Nutricionista',
        emoji: '🥗',
        group: 'Saúde',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'home_care',
        name: 'Home Care',
        emoji: '🏠',
        group: 'Saúde',
        color: Color(0xFF00838F)),
    ServiceCategory(
        id: 'cabeleireiro',
        name: 'Cabeleireiro',
        emoji: '✂️',
        group: 'Beleza',
        color: Color(0xFFAD1457)),
    ServiceCategory(
        id: 'manicure',
        name: 'Manicure/Pedicure',
        emoji: '💅',
        group: 'Beleza',
        color: Color(0xFFE91E63)),
    ServiceCategory(
        id: 'esteticista',
        name: 'Esteticista',
        emoji: '🌸',
        group: 'Beleza',
        color: Color(0xFFAD1457)),
    ServiceCategory(
        id: 'massagem',
        name: 'Massagem',
        emoji: '💆',
        group: 'Beleza',
        color: Color(0xFF4A148C)),
    ServiceCategory(
        id: 'professor',
        name: 'Professor Particular',
        emoji: '📚',
        group: 'Educação',
        color: Color(0xFF1A237E)),
    ServiceCategory(
        id: 'ingles',
        name: 'Inglês',
        emoji: '🇬🇧',
        group: 'Educação',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'personal_trainer',
        name: 'Personal Trainer',
        emoji: '🏋️',
        group: 'Educação',
        color: Color(0xFF1B5E20)),
    ServiceCategory(
        id: 'informatica',
        name: 'Informática',
        emoji: '💻',
        group: 'Tech',
        color: Color(0xFF4527A0)),
    ServiceCategory(
        id: 'tecnico_celular',
        name: 'Técnico Celular',
        emoji: '📱',
        group: 'Tech',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'desenvolvedor',
        name: 'Desenvolvedor',
        emoji: '👨‍💻',
        group: 'Tech',
        color: Color(0xFF311B92)),
    ServiceCategory(
        id: 'mecanico',
        name: 'Mecânico',
        emoji: '🔧',
        group: 'Veículos',
        color: Color(0xFF37474F)),
    ServiceCategory(
        id: 'motorista',
        name: 'Motorista Particular',
        emoji: '🧑‍✈️',
        group: 'Veículos',
        color: Color(0xFF0D47A1)),
    ServiceCategory(
        id: 'veterinario',
        name: 'Veterinário',
        emoji: '🐾',
        group: 'Pets',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'banho_tosa',
        name: 'Banho e Tosa',
        emoji: '🛁',
        group: 'Pets',
        color: Color(0xFF00695C)),
    ServiceCategory(
        id: 'advogado',
        name: 'Advogado',
        emoji: '⚖️',
        group: 'Jurídico',
        color: Color(0xFF1A237E)),
    ServiceCategory(
        id: 'contador',
        name: 'Contador',
        emoji: '📊',
        group: 'Jurídico',
        color: Color(0xFF0D47A1)),
    ServiceCategory(
        id: 'fotografo',
        name: 'Fotógrafo',
        emoji: '📷',
        group: 'Eventos',
        color: Color(0xFF4A148C)),
    ServiceCategory(
        id: 'dj',
        name: 'DJ',
        emoji: '🎧',
        group: 'Eventos',
        color: Color(0xFF1A237E)),
    ServiceCategory(
        id: 'mudanca',
        name: 'Mudança',
        emoji: '📦',
        group: 'Transporte',
        color: Color(0xFFE65100)),
    ServiceCategory(
        id: 'ar_condicionado',
        name: 'Ar-Condicionado',
        emoji: '❄️',
        group: 'Equipamentos',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'agronomo',
        name: 'Agrônomo',
        emoji: '🌾',
        group: 'Agro',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'baba',
        name: 'Babá',
        emoji: '👶',
        group: 'Cuidados',
        color: Color(0xFFE91E63)),
    ServiceCategory(
        id: 'entregador_moto',
        name: 'Motoboy',
        emoji: '🛵',
        group: 'Delivery',
        color: Color(0xFFE65100)),
    // ── Categorias adicionadas: Agro, Drones, Máquinas, Veículos e Mão de Obra ──
    // Agrônomo, Veterinário, Pedreiro, Pintor, Encanador, Eletricista, Jardineiro,
    // Diarista, Faxineira, Babá e Motorista já existem acima e são reaproveitados.
    ServiceCategory(
        id: 'tratorista',
        name: 'Tratorista',
        emoji: '🚜',
        group: 'Agro',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'op_colheitadeira',
        name: 'Operador de Colheitadeira',
        emoji: '🌾',
        group: 'Agro',
        color: Color(0xFF388E3C)),
    ServiceCategory(
        id: 'op_escavadeira',
        name: 'Operador de Escavadeira',
        emoji: '🏗️',
        group: 'Agro',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'op_pa_carregadeira',
        name: 'Operador de Pá Carregadeira',
        emoji: '🚧',
        group: 'Agro',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'op_motoniveladora',
        name: 'Operador de Motoniveladora',
        emoji: '🛣️',
        group: 'Agro',
        color: Color(0xFFEF6C00)),
    ServiceCategory(
        id: 'op_retroescavadeira',
        name: 'Operador de Retroescavadeira',
        emoji: '⛏️',
        group: 'Agro',
        color: Color(0xFFEF6C00)),
    ServiceCategory(
        id: 'pulverizacao_terrestre',
        name: 'Pulverização Terrestre',
        emoji: '💨',
        group: 'Agro',
        color: Color(0xFF43A047)),
    ServiceCategory(
        id: 'aplicacao_defensivos',
        name: 'Aplicação de Defensivos',
        emoji: '🧪',
        group: 'Agro',
        color: Color(0xFF558B2F)),
    ServiceCategory(
        id: 'irrigacao',
        name: 'Irrigação',
        emoji: '💧',
        group: 'Agro',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'plantio',
        name: 'Plantio',
        emoji: '🌱',
        group: 'Agro',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'colheita',
        name: 'Colheita',
        emoji: '🌾',
        group: 'Agro',
        color: Color(0xFF689F38)),
    ServiceCategory(
        id: 'silagem',
        name: 'Silagem',
        emoji: '🌽',
        group: 'Agro',
        color: Color(0xFF827717)),
    ServiceCategory(
        id: 'topografia',
        name: 'Topografia',
        emoji: '📐',
        group: 'Agro',
        color: Color(0xFF00695C)),
    ServiceCategory(
        id: 'georreferenciamento',
        name: 'Georreferenciamento',
        emoji: '🛰️',
        group: 'Agro',
        color: Color(0xFF00838F)),
    ServiceCategory(
        id: 'poco_artesiano',
        name: 'Poço Artesiano',
        emoji: '🕳️',
        group: 'Agro',
        color: Color(0xFF0277BD)),
    ServiceCategory(
        id: 'energia_solar_rural',
        name: 'Energia Solar Rural',
        emoji: '☀️',
        group: 'Agro',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'construcao_cercas',
        name: 'Construção de Cercas',
        emoji: '🚧',
        group: 'Agro',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'soldador_rural',
        name: 'Soldador Rural',
        emoji: '🔥',
        group: 'Agro',
        color: Color(0xFFD84315)),
    ServiceCategory(
        id: 'mecanico_agricola',
        name: 'Mecânico Agrícola',
        emoji: '🔩',
        group: 'Agro',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'transporte_gado',
        name: 'Transporte de Gado',
        emoji: '🐄',
        group: 'Agro',
        color: Color(0xFF795548)),
    ServiceCategory(
        id: 'transporte_maquinas',
        name: 'Transporte de Máquinas',
        emoji: '🚛',
        group: 'Agro',
        color: Color(0xFF5D4037)),
    ServiceCategory(
        id: 'frete_agricola',
        name: 'Frete Agrícola',
        emoji: '🚚',
        group: 'Agro',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'drone_pulverizacao',
        name: 'Pulverização com Drone',
        emoji: '🚁',
        group: 'Drones',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'drone_pulverizacao_urbana',
        name: 'Pulverização Urbana',
        emoji: '🚁',
        group: 'Drones',
        color: Color(0xFF1976D2)),
    ServiceCategory(
        id: 'drone_filmagem',
        name: 'Filmagem Aérea',
        emoji: '🎥',
        group: 'Drones',
        color: Color(0xFF283593)),
    ServiceCategory(
        id: 'drone_fotografia',
        name: 'Fotografia Aérea',
        emoji: '📸',
        group: 'Drones',
        color: Color(0xFF3949AB)),
    ServiceCategory(
        id: 'drone_mapeamento',
        name: 'Mapeamento de Fazendas',
        emoji: '🗺️',
        group: 'Drones',
        color: Color(0xFF00695C)),
    ServiceCategory(
        id: 'drone_inspecao_telhados',
        name: 'Inspeção de Telhados',
        emoji: '🏠',
        group: 'Drones',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'drone_inspecao_industrial',
        name: 'Inspeção Industrial',
        emoji: '🏭',
        group: 'Drones',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'drone_topografia',
        name: 'Levantamento Topográfico',
        emoji: '📐',
        group: 'Drones',
        color: Color(0xFF00838F)),
    ServiceCategory(
        id: 'aluguel_trator',
        name: 'Aluguel de Trator',
        emoji: '🚜',
        group: 'Máquinas',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'aluguel_escavadeira',
        name: 'Aluguel de Escavadeira',
        emoji: '🏗️',
        group: 'Máquinas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'aluguel_retroescavadeira',
        name: 'Aluguel de Retroescavadeira',
        emoji: '⛏️',
        group: 'Máquinas',
        color: Color(0xFFEF6C00)),
    ServiceCategory(
        id: 'aluguel_pa_carregadeira',
        name: 'Aluguel de Pá Carregadeira',
        emoji: '🚧',
        group: 'Máquinas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'aluguel_motoniveladora',
        name: 'Aluguel de Motoniveladora',
        emoji: '🛣️',
        group: 'Máquinas',
        color: Color(0xFFEF6C00)),
    ServiceCategory(
        id: 'aluguel_basculante',
        name: 'Caminhão Basculante',
        emoji: '🚛',
        group: 'Máquinas',
        color: Color(0xFF5D4037)),
    ServiceCategory(
        id: 'aluguel_caminhao_pipa',
        name: 'Caminhão Pipa',
        emoji: '🚰',
        group: 'Máquinas',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'aluguel_guindaste',
        name: 'Guindaste',
        emoji: '🏗️',
        group: 'Máquinas',
        color: Color(0xFFC62828)),
    ServiceCategory(
        id: 'aluguel_plataforma',
        name: 'Plataforma Elevatória',
        emoji: '🛗',
        group: 'Máquinas',
        color: Color(0xFF6A1B9A)),
    ServiceCategory(
        id: 'aluguel_compactador',
        name: 'Compactador',
        emoji: '🧱',
        group: 'Máquinas',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'aluguel_betoneira',
        name: 'Betoneira',
        emoji: '🛞',
        group: 'Máquinas',
        color: Color(0xFF757575)),
    ServiceCategory(
        id: 'aluguel_rocadeira',
        name: 'Roçadeira',
        emoji: '🌿',
        group: 'Máquinas',
        color: Color(0xFF558B2F)),
    ServiceCategory(
        id: 'aluguel_gerador',
        name: 'Gerador',
        emoji: '🔌',
        group: 'Máquinas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'aluguel_compressor',
        name: 'Compressor',
        emoji: '💨',
        group: 'Máquinas',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'aluguel_carro',
        name: 'Aluguel de Carro',
        emoji: '🚗',
        group: 'Veículos',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'aluguel_caminhonete',
        name: 'Aluguel de Caminhonete',
        emoji: '🛻',
        group: 'Veículos',
        color: Color(0xFF0277BD)),
    ServiceCategory(
        id: 'aluguel_van',
        name: 'Aluguel de Van',
        emoji: '🚐',
        group: 'Veículos',
        color: Color(0xFF00695C)),
    ServiceCategory(
        id: 'aluguel_caminhao',
        name: 'Aluguel de Caminhão',
        emoji: '🚛',
        group: 'Veículos',
        color: Color(0xFF5D4037)),
    ServiceCategory(
        id: 'aluguel_moto',
        name: 'Aluguel de Moto',
        emoji: '🏍️',
        group: 'Veículos',
        color: Color(0xFFE65100)),
    ServiceCategory(
        id: 'aluguel_onibus',
        name: 'Aluguel de Ônibus',
        emoji: '🚌',
        group: 'Veículos',
        color: Color(0xFF283593)),
    ServiceCategory(
        id: 'aluguel_maquinas_agricolas',
        name: 'Máquinas Agrícolas',
        emoji: '🚜',
        group: 'Veículos',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'aluguel_reboque',
        name: 'Reboque',
        emoji: '🚙',
        group: 'Veículos',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'aluguel_carretinha',
        name: 'Carretinha',
        emoji: '🛒',
        group: 'Veículos',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'servente',
        name: 'Servente de Obra',
        emoji: '👷',
        group: 'Mão de Obra',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'carpinteiro',
        name: 'Carpinteiro',
        emoji: '🪵',
        group: 'Mão de Obra',
        color: Color(0xFF795548)),
    ServiceCategory(
        id: 'armador',
        name: 'Armador',
        emoji: '🔗',
        group: 'Mão de Obra',
        color: Color(0xFF546E7A)),
    ServiceCategory(
        id: 'soldador',
        name: 'Soldador',
        emoji: '🔥',
        group: 'Mão de Obra',
        color: Color(0xFFD84315)),
    ServiceCategory(
        id: 'gesseiro',
        name: 'Gesseiro',
        emoji: '🧱',
        group: 'Mão de Obra',
        color: Color(0xFF8D6E63)),
    ServiceCategory(
        id: 'cuidador_idosos',
        name: 'Cuidador de Idosos',
        emoji: '🧓',
        group: 'Mão de Obra',
        color: Color(0xFFAD1457)),
    ServiceCategory(
        id: 'vigilante',
        name: 'Vigilante',
        emoji: '🛡️',
        group: 'Mão de Obra',
        color: Color(0xFF37474F)),
    ServiceCategory(
        id: 'porteiro',
        name: 'Porteiro',
        emoji: '🚪',
        group: 'Mão de Obra',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'aux_servicos_gerais',
        name: 'Auxiliar de Serviços Gerais',
        emoji: '🧰',
        group: 'Mão de Obra',
        color: Color(0xFF607D8B)),
    ServiceCategory(
        id: 'trabalhador_rural',
        name: 'Trabalhador Rural',
        emoji: '👨‍🌾',
        group: 'Mão de Obra',
        color: Color(0xFF558B2F)),
    ServiceCategory(
        id: 'caseiro',
        name: 'Caseiro',
        emoji: '🏡',
        group: 'Mão de Obra',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'operador_maquinas',
        name: 'Operador de Máquinas',
        emoji: '⚙️',
        group: 'Mão de Obra',
        color: Color(0xFF455A64)),
    // -- v1.2: complementos de Agro/Drones/Veiculos/Maquinas + grupo Lojas --
    ServiceCategory(
        id: 'zootecnista',
        name: 'Zootecnista',
        emoji: '🐂',
        group: 'Agro',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'tecnico_agricola',
        name: 'Técnico Agrícola',
        emoji: '🌾',
        group: 'Agro',
        color: Color(0xFF558B2F)),
    ServiceCategory(
        id: 'capataz',
        name: 'Capataz',
        emoji: '🤠',
        group: 'Agro',
        color: Color(0xFF795548)),
    ServiceCategory(
        id: 'vaqueiro',
        name: 'Vaqueiro',
        emoji: '🐎',
        group: 'Agro',
        color: Color(0xFF8D6E63)),
    ServiceCategory(
        id: 'ordenhador',
        name: 'Ordenhador',
        emoji: '🥛',
        group: 'Agro',
        color: Color(0xFF90A4AE)),
    ServiceCategory(
        id: 'drone_monitoramento_obras',
        name: 'Monitoramento de Obras',
        emoji: '🏗️',
        group: 'Drones',
        color: Color(0xFF37474F)),
    ServiceCategory(
        id: 'aluguel_suv',
        name: 'Aluguel de SUV',
        emoji: '🚙',
        group: 'Veículos',
        color: Color(0xFF1565C0)),
    ServiceCategory(
        id: 'aluguel_rolo_compactador',
        name: 'Rolo Compactador',
        emoji: '🛞',
        group: 'Máquinas',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'loja_material_construcao',
        name: 'Material de Construção',
        emoji: '🧱',
        group: 'Lojas',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'loja_autopecas',
        name: 'Autopeças',
        emoji: '🔧',
        group: 'Lojas',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'loja_agropecuaria',
        name: 'Loja Agropecuária',
        emoji: '🌾',
        group: 'Lojas',
        color: Color(0xFF2E7D32)),
    ServiceCategory(
        id: 'loja_ferragens',
        name: 'Ferragens',
        emoji: '🔩',
        group: 'Lojas',
        color: Color(0xFF546E7A)),
    ServiceCategory(
        id: 'loja_moveis',
        name: 'Móveis',
        emoji: '🛋️',
        group: 'Lojas',
        color: Color(0xFF795548)),
    ServiceCategory(
        id: 'loja_celulares',
        name: 'Celulares',
        emoji: '📱',
        group: 'Lojas',
        color: Color(0xFF1976D2)),
    ServiceCategory(
        id: 'loja_eletrodomesticos',
        name: 'Eletrodomésticos',
        emoji: '🔌',
        group: 'Lojas',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'loja_ferramentas',
        name: 'Ferramentas',
        emoji: '🧰',
        group: 'Lojas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'loja_piscinas',
        name: 'Piscinas',
        emoji: '🏊',
        group: 'Lojas',
        color: Color(0xFF00ACC1)),
    ServiceCategory(
        id: 'loja_energia_solar',
        name: 'Energia Solar',
        emoji: '☀️',
        group: 'Lojas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'loja_seguranca_eletronica',
        name: 'Segurança Eletrônica',
        emoji: '📹',
        group: 'Lojas',
        color: Color(0xFF37474F)),
    // -- v1.3: lojas especializadas --
    ServiceCategory(
        id: 'loja_jardinagem',
        name: 'Jardinagem',
        emoji: '🪴',
        group: 'Lojas',
        color: Color(0xFF558B2F)),
    ServiceCategory(
        id: 'loja_epis',
        name: 'EPIs e Segurança',
        emoji: '🦺',
        group: 'Lojas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'loja_racoes',
        name: 'Rações',
        emoji: '🐕',
        group: 'Lojas',
        color: Color(0xFF795548)),
    ServiceCategory(
        id: 'loja_veterinarios',
        name: 'Produtos Veterinários',
        emoji: '💉',
        group: 'Lojas',
        color: Color(0xFF00695C)),
    // -- v1.4: complementos Agro/Drones/Maquinas/Lojas --
    ServiceCategory(
        id: 'op_rolo_compactador',
        name: 'Operador de Rolo Compactador',
        emoji: '🛞',
        group: 'Agro',
        color: Color(0xFF6D4C41)),
    ServiceCategory(
        id: 'op_caminhao_pipa',
        name: 'Operador de Caminhão Pipa',
        emoji: '🚰',
        group: 'Agro',
        color: Color(0xFF0288D1)),
    ServiceCategory(
        id: 'op_caminhao_basculante',
        name: 'Operador de Caminhão Basculante',
        emoji: '🚛',
        group: 'Agro',
        color: Color(0xFF5D4037)),
    ServiceCategory(
        id: 'drone_agricultura_precisao',
        name: 'Agricultura de Precisão',
        emoji: '🎯',
        group: 'Drones',
        color: Color(0xFF00838F)),
    ServiceCategory(
        id: 'aluguel_perfuratriz',
        name: 'Perfuratriz',
        emoji: '🕳️',
        group: 'Máquinas',
        color: Color(0xFF455A64)),
    ServiceCategory(
        id: 'aluguel_mini_escavadeira',
        name: 'Mini Escavadeira',
        emoji: '🚧',
        group: 'Máquinas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'loja_eletrica',
        name: 'Elétrica',
        emoji: '💡',
        group: 'Lojas',
        color: Color(0xFFF9A825)),
    ServiceCategory(
        id: 'loja_hidraulica',
        name: 'Hidráulica',
        emoji: '🚿',
        group: 'Lojas',
        color: Color(0xFF0277BD)),
  ];

  static List<String> get groups => all.map((c) => c.group).toSet().toList();
  static ServiceCategory? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

String xpLevel(int xp) {
  if (xp >= 4000) return '💎 Diamante';
  if (xp >= 2000) return '🥇 Ouro';
  if (xp >= 1000) return '🥈 Prata';
  if (xp >= 500) return '🥉 Bronze';
  return '⭐ Iniciante';
}

int nextLevelXp(int xp) {
  if (xp < 500) return 500 - xp;
  if (xp < 1000) return 1000 - xp;
  if (xp < 2000) return 2000 - xp;
  if (xp < 4000) return 4000 - xp;
  return 0;
}

double xpProgress(int xp) {
  if (xp < 500) return xp / 500;
  if (xp < 1000) return (xp - 500) / 500;
  if (xp < 2000) return (xp - 1000) / 1000;
  if (xp < 4000) return (xp - 2000) / 2000;
  return 1.0;
}
