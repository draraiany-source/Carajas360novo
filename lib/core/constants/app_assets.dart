// ─────────────────────────────────────────────────────────────
// APP ASSETS — caminhos centralizados dos assets oficiais.
// Mantém as strings de asset num único lugar (evita caminhos
// mágicos espalhados) e faz o mapa entre os IDs de categoria do
// código e os slugs dos arquivos oficiais, com fallback seguro.
// ─────────────────────────────────────────────────────────────
abstract class AppAssets {
  static const _logos = 'assets/logos';
  static const _onboarding = 'assets/onboarding';
  static const _splash = 'assets/splash';
  static const _banners = 'assets/banners';
  static const _categories = 'assets/categories';
  static const _empty = 'assets/empty_states';
  static const _illustrations = 'assets/illustrations';
  static const _marketplace = 'assets/marketplace';
  static const _wallet = 'assets/wallet';
  static const _chat = 'assets/chat';
  static const _gps = 'assets/gps';
  static const _lottie = 'assets/lottie';

  // ── Logos ──────────────────────────────────────────────────
  static const logoHorizontalLight = '$_logos/logo_horizontal_light.svg';
  static const logoHorizontalDark = '$_logos/logo_horizontal_dark.svg';
  static const logoMark = '$_logos/logo_mark.svg';
  static const logoMarkWhite = '$_logos/logo_mark_mono_white.svg';
  static const logoVerticalLight = '$_logos/logo_vertical_light.svg';
  static const wordmarkLight = '$_logos/wordmark_light.svg';
  static const wordmarkWhite = '$_logos/wordmark_mono_white.svg';

  // ── Splash ─────────────────────────────────────────────────
  static const splashLight = '$_splash/splash_light.svg';
  static const splashDark = '$_splash/splash_dark.svg';

  // ── Onboarding (5 telas na ordem oficial) ──────────────────
  static const onboarding = <String>[
    '$_onboarding/onboarding_1_encontre_profissionais.svg',
    '$_onboarding/onboarding_2_solicite_servicos.svg',
    '$_onboarding/onboarding_3_acompanhe_tempo_real.svg',
    '$_onboarding/onboarding_4_pague_com_seguranca.svg',
    '$_onboarding/onboarding_5_avalie_atendimento.svg',
  ];

  // ── Ilustrações genéricas ──────────────────────────────────
  static const ilBoasVindas = '$_illustrations/ilustracao_boas_vindas.svg';
  static const ilConvideAmigos =
      '$_illustrations/ilustracao_convide_amigos.svg';
  static const ilListaVazia =
      '$_illustrations/ilustracao_lista_generica_vazia.svg';

  // ── Empty states ───────────────────────────────────────────
  static const estadoErro = '$_empty/estado_erro.svg';
  static const estadoSemInternet = '$_empty/estado_sem_internet.svg';
  static const estadoNenhumResultado = '$_empty/estado_nenhum_resultado.svg';
  static const estado404 = '$_empty/estado_pagina_nao_encontrada.svg';
  static const estadoManutencao = '$_empty/estado_manutencao.svg';
  static const estadoSucesso = '$_empty/estado_sucesso.svg';
  static const estadoCarregando = '$_empty/estado_carregando.svg';
  static const estadoAtualizando = '$_empty/estado_atualizando.svg';

  // ── Mascote (cadastro / onboarding) ────────────────────────
  static const registerMascot = 'assets/mascot/register_mascot.png';

  // ── Marketplace ────────────────────────────────────────────
  static const mktCarrinhoVazio =
      '$_marketplace/marketplace_carrinho_vazio.svg';
  static const mktSemProdutos = '$_marketplace/marketplace_sem_produtos.svg';
  static const mktPedidoRealizado =
      '$_marketplace/marketplace_pedido_realizado.svg';
  static const mktPagamentoAprovado =
      '$_marketplace/marketplace_pagamento_aprovado.svg';
  static const mktPagamentoRecusado =
      '$_marketplace/marketplace_pagamento_recusado.svg';

  // ── Carteira ───────────────────────────────────────────────
  static const walletSaldo = '$_wallet/wallet_saldo.svg';
  static const walletExtrato = '$_wallet/wallet_extrato.svg';
  static const walletPix = '$_wallet/wallet_pix.svg';
  static const walletSaque = '$_wallet/wallet_saque.svg';
  static const walletComissao = '$_wallet/wallet_comissao.svg';

  // ── Chat ───────────────────────────────────────────────────
  static const chatSemMensagens = '$_chat/chat_sem_mensagens.svg';
  static const chatNovaConversa = '$_chat/chat_nova_conversa.svg';
  static const chatAudio = '$_chat/chat_audio.svg';
  static const chatLocalizacao = '$_chat/chat_localizacao.svg';
  static const chatEnvioArquivos = '$_chat/chat_envio_arquivos.svg';

  // ── GPS ────────────────────────────────────────────────────
  static const gpsLocalizacaoAtual = '$_gps/gps_localizacao_atual.svg';
  static const gpsProfissionalChegando = '$_gps/gps_profissional_chegando.svg';
  static const gpsVeiculoCarro = '$_gps/gps_veiculo_carro.svg';
  static const gpsVeiculoMoto = '$_gps/gps_veiculo_moto.svg';
  static const gpsVeiculoBicicleta = '$_gps/gps_veiculo_bicicleta.svg';

  // ── Lottie (animações) ─────────────────────────────────────
  static const lottieSucesso = '$_lottie/sucesso.json';
  static const lottieErro = '$_lottie/erro.json';
  static const lottieLoading = '$_lottie/loading.json';
  static const lottiePagamentoAprovado = '$_lottie/pagamento_aprovado.json';
  static const lottiePedidoEnviado = '$_lottie/pedido_enviado.json';
  static const lottieServicoConcluido = '$_lottie/servico_concluido.json';
  static const lottieUploadConcluido = '$_lottie/upload_concluido.json';

  // ── Banners da Home ────────────────────────────────────────
  // Mapa slug -> caminho. A Home referencia pelo slug.
  static const banners = <String, String>{
    'servicos_destaque': '$_banners/banner_servicos_destaque.svg',
    'profissionais_proximos': '$_banners/banner_profissionais_proximos.svg',
    'marketplace': '$_banners/banner_marketplace.svg',
    'saude': '$_banners/banner_saude.svg',
    'home_care': '$_banners/banner_home_care.svg',
    'entregas': '$_banners/banner_entregas.svg',
    'empresas': '$_banners/banner_empresas.svg',
    'cashback': '$_banners/banner_cashback.svg',
    'cupons': '$_banners/banner_cupons.svg',
    'promocoes': '$_banners/banner_promocoes.svg',
  };

  // ── Categorias ─────────────────────────────────────────────
  // Alguns IDs de categoria no código diferem do slug do arquivo
  // oficial. Este mapa cobre essas diferenças; qualquer ID não
  // listado usa o próprio ID como slug. Se o arquivo não existir,
  // `categoryIcon` retorna null e a UI usa o emoji como fallback.
  static const _categoryAliases = <String, String>{
    'jardineiro': 'jardinagem',
    'massagem': 'massagista',
    'professor': 'professor_particular',
    'banho_tosa': 'banho_e_tosa',
    'mudanca': 'mudancas',
    'motorista': 'motoboy',
    'entregador_moto': 'motoboy',
    'tecnico_celular': 'informatica',
    'baba': 'enfermeiro',
  };

  // IDs que possuem arquivo de categoria oficial (slugs disponíveis).
  static const _categorySlugs = <String>{
    'advogado',
    'agua',
    'ar_condicionado',
    'aula_reforco',
    'banho_e_tosa',
    'barbeiro',
    'buffet',
    'busca_animais',
    'cabeleireiro',
    'chaveiro',
    'contador',
    'costureira',
    'decoracao',
    'desenvolvedor',
    'designer',
    'diarista',
    'eletricista',
    'encanador',
    'enfermeiro',
    'entregas',
    'eventos',
    'farmacia',
    'faxineira',
    'fisioterapeuta',
    'fotografo',
    'fretes',
    'gas',
    'guincho',
    'home_care',
    'informatica',
    'jardinagem',
    'lava_jato',
    'manicure',
    'marceneiro',
    'massagista',
    'mecanico',
    'medico',
    'mercado',
    'motoboy',
    'mudancas',
    'nutricionista',
    'passeador_caes',
    'pedreiro',
    'pintor',
    'piscina',
    'professor_particular',
    'psicologo',
    'seguranca',
    'veterinario',
  };

  /// Caminho do ícone SVG oficial da categoria, ou null se não houver
  /// asset correspondente (nesse caso a UI usa o emoji como fallback).

  // Categorias novas (Agro, Drones, Máquinas, Veículos, Mão de Obra) que
  // não têm arte própria em assets/categories/ reaproveitam um ícone da
  // biblioteca em assets/icons/svg/.
  static const _categoryIconLibrary = <String, String>{
    // v1.4
    'op_rolo_compactador': 'truck',
    'op_caminhao_pipa': 'droplet',
    'op_caminhao_basculante': 'truck',
    'drone_agricultura_precisao': 'target',
    'aluguel_perfuratriz': 'tool',
    'aluguel_mini_escavadeira': 'hammer',
    'loja_eletrica': 'zap',
    'loja_hidraulica': 'droplet',
    // v1.3
    'loja_jardinagem': 'broom',
    'loja_epis': 'shield',
    'loja_racoes': 'paw',
    'loja_veterinarios': 'heart_pulse',
    // v1.2
    'zootecnista': 'paw',
    'tecnico_agricola': 'sun',
    'capataz': 'user_check',
    'vaqueiro': 'paw',
    'ordenhador': 'droplet',
    'drone_monitoramento_obras': 'video',
    'aluguel_suv': 'car',
    'aluguel_rolo_compactador': 'truck',
    'loja_material_construcao': 'hammer',
    'loja_autopecas': 'wrench',
    'loja_agropecuaria': 'store',
    'loja_ferragens': 'tool',
    'loja_moveis': 'home',
    'loja_celulares': 'smile',
    'loja_eletrodomesticos': 'plug',
    'loja_ferramentas': 'tool',
    'loja_piscinas': 'droplet',
    'loja_energia_solar': 'sun',
    'loja_seguranca_eletronica': 'shield',
    // Categorias antigas que não tinham arte própria
    'esteticista': 'sparkles',
    'ingles': 'graduation',
    'personal_trainer': 'dumbbell',
    'dj': 'headphones',
    'agronomo': 'sun',
    'tratorista': 'truck',
    'op_colheitadeira': 'truck',
    'op_escavadeira': 'hammer',
    'op_pa_carregadeira': 'hammer',
    'op_motoniveladora': 'truck',
    'op_retroescavadeira': 'hammer',
    'pulverizacao_terrestre': 'droplet',
    'aplicacao_defensivos': 'droplet',
    'irrigacao': 'droplet',
    'plantio': 'sun',
    'colheita': 'sun',
    'silagem': 'package',
    'topografia': 'map',
    'georreferenciamento': 'map_pin',
    'poco_artesiano': 'droplet',
    'energia_solar_rural': 'sun',
    'construcao_cercas': 'hammer',
    'soldador_rural': 'tool',
    'mecanico_agricola': 'wrench',
    'transporte_gado': 'truck',
    'transporte_maquinas': 'truck',
    'frete_agricola': 'truck',
    'drone_pulverizacao': 'rocket',
    'drone_pulverizacao_urbana': 'rocket',
    'drone_filmagem': 'video',
    'drone_fotografia': 'camera',
    'drone_mapeamento': 'map',
    'drone_inspecao_telhados': 'home',
    'drone_inspecao_industrial': 'shield',
    'drone_topografia': 'map_pin',
    'aluguel_trator': 'truck',
    'aluguel_escavadeira': 'hammer',
    'aluguel_retroescavadeira': 'hammer',
    'aluguel_pa_carregadeira': 'hammer',
    'aluguel_motoniveladora': 'truck',
    'aluguel_basculante': 'truck',
    'aluguel_caminhao_pipa': 'droplet',
    'aluguel_guindaste': 'hammer',
    'aluguel_plataforma': 'package',
    'aluguel_compactador': 'hammer',
    'aluguel_betoneira': 'tool',
    'aluguel_rocadeira': 'broom',
    'aluguel_gerador': 'plug',
    'aluguel_compressor': 'tool',
    'aluguel_carro': 'car',
    'aluguel_caminhonete': 'car',
    'aluguel_van': 'car',
    'aluguel_caminhao': 'truck',
    'aluguel_moto': 'bike',
    'aluguel_onibus': 'truck',
    'aluguel_maquinas_agricolas': 'truck',
    'aluguel_reboque': 'truck',
    'aluguel_carretinha': 'package',
    'servente': 'user',
    'carpinteiro': 'hammer',
    'armador': 'tool',
    'soldador': 'tool',
    'gesseiro': 'hammer',
    'cuidador_idosos': 'heart',
    'vigilante': 'shield',
    'porteiro': 'key',
    'aux_servicos_gerais': 'tool',
    'trabalhador_rural': 'user',
    'caseiro': 'home',
    'operador_maquinas': 'wrench',
  };

  static String? categoryIcon(String categoryId) {
    final slug = _categoryAliases[categoryId] ?? categoryId;
    if (_categorySlugs.contains(slug)) return '$_categories/$slug.svg';
    final lib = _categoryIconLibrary[categoryId];
    if (lib != null) return '$_iconsSvg/$lib.svg';
    return null;
  }

  // ── Biblioteca de ícones SVG próprios ──────────────────────
  // Uso: SvgPicture.asset(AppAssets.icon('search'), ...)
  static const _iconsSvg = 'assets/icons/svg';
  static String icon(String name) => '$_iconsSvg/$name.svg';

  // ── Backgrounds SVG exclusivos ─────────────────────────────
  static const _backgrounds = 'assets/backgrounds';
  static const bgSplash = '$_backgrounds/bg_splash.svg';
  static const bgLogin = '$_backgrounds/bg_login.svg';
  static const bgHome = '$_backgrounds/bg_home.svg';
  static const bgPremium = '$_backgrounds/bg_premium.svg';
  static const bgProfile = '$_backgrounds/bg_profile.svg';
  static const bgSettings = '$_backgrounds/bg_settings.svg';
  static const bgOnboarding = '$_backgrounds/bg_onboarding.svg';
  static const bgMarketplace = '$_backgrounds/bg_marketplace.svg';
}
