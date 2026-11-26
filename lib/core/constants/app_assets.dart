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

  // Ícones de categoria e profissão: ServiceCatalog e assets/icons/**/*.webp.
  // Os SVG Feather/Lucide de categoria foram removidos depois que a UI
  // passou a usar só a arte oficial.

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
