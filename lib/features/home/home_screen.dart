import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/catalog/service_catalog.dart';
import '../../core/constants/runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../catalog/category_browse.dart';
import '../catalog/provider_filters.dart';
import '../../shared/widgets/official_icon.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/chat_nav.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/micro_interactions.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../tia/tia_screen.dart';
import '../tia/tia_widgets.dart';
import '../orders/orders_screen.dart';
import 'provider_profile_screen.dart';

/// Hub do módulo Serviços (núcleo original do Serviço Conecta).
/// A Home da plataforma Carajás 360 fica em [HomeScreen] (carajas_home_screen.dart).
class ServicesHubScreen extends StatefulWidget {
  const ServicesHubScreen({super.key});
  @override
  State<ServicesHubScreen> createState() => _ServicesHubState();
}

class _ServicesHubState extends State<ServicesHubScreen> {
  String _selGroup = 'Todos';
  // Grupos vindos da fonte única de categorias — assim novos segmentos
  // (Agro, Drones, Máquinas, Veículos, Lojas...) aparecem automaticamente.
  final _groups = ['Todos', ...Categories.groups];

  static const _modules = [
    {'id': 'services', 'icon': '🔧', 'label': 'Serviços'},
    {'id': 'health', 'icon': '🏥', 'label': 'Saúde'},
    {'id': 'delivery', 'icon': '📦', 'label': 'Entregas'},
    {'id': 'marketplace', 'icon': '🛒', 'label': 'Mercado'},
    {'id': 'rental', 'icon': '🔑', 'label': 'Aluguel'},
    {'id': 'machines', 'icon': '🚜', 'label': 'Máquinas'},
    {'id': 'vehicles', 'icon': '🚗', 'label': 'Veículos'},
    {'id': 'labor', 'icon': '👷', 'label': 'Mão de Obra'},
    {'id': 'drones', 'icon': '🚁', 'label': 'Drones'},
    {'id': 'pets', 'icon': '🐾', 'label': 'Pets'},
    {'id': 'beauty', 'icon': '💅', 'label': 'Beleza'},
    {'id': 'education', 'icon': '📚', 'label': 'Educação'},
    {'id': 'agro', 'icon': '🌾', 'label': 'Agro'},
    {'id': 'ai', 'icon': '🤖', 'label': 'IA'},
  ];

  static final _demoProviders = [
    ProviderModel(
        id: 'd1',
        userId: 'u1',
        name: 'Carlos Silva',
        categories: ['eletricista'],
        rating: 4.9,
        totalReviews: 312,
        modalities: ['presential'],
        createdAt: DateTime.now()),
    ProviderModel(
        id: 'd2',
        userId: 'u2',
        name: 'Ana Oliveira',
        categories: ['diarista'],
        rating: 4.8,
        totalReviews: 524,
        modalities: ['presential'],
        createdAt: DateTime.now()),
    ProviderModel(
        id: 'd3',
        userId: 'u3',
        name: 'Dr. Marcos',
        categories: ['medico'],
        rating: 5.0,
        totalReviews: 480,
        modalities: ['online', 'presential'],
        createdAt: DateTime.now()),
    ProviderModel(
        id: 'd4',
        userId: 'u4',
        name: 'Julia Santos',
        categories: ['cabeleireiro'],
        rating: 4.7,
        totalReviews: 198,
        modalities: ['presential'],
        createdAt: DateTime.now()),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.uid;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: StreamBuilder<UserModel?>(
            stream: uid != null ? FS.userStream(uid) : const Stream.empty(),
            builder: (_, snap) {
              final user = snap.data;
              return GradHeader(
                  gradient: AppGradients.primary,
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Olá, ${user?.firstName.isNotEmpty == true ? user!.firstName : 'Bem-vindo'}',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.82),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: SvgPicture.asset(
                                        AppAssets.wordmarkWhite,
                                        height: 22)),
                              ]),
                          Row(children: [
                            StreamBuilder<List<NotifModel>>(
                              stream: FS.notifStream(),
                              builder: (_, notifSnap) {
                                final unread = (notifSnap.data ?? [])
                                    .where((n) => !n.read)
                                    .length;
                                return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context, Routes.notifications),
                                          icon: const Icon(
                                              Icons.notifications_none_rounded,
                                              color: Colors.white,
                                              size: 26)),
                                      if (unread > 0)
                                        Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: AppColors.primary,
                                                      width: 1.5)),
                                              constraints: const BoxConstraints(
                                                  minWidth: 16),
                                              child: Text(
                                                  unread > 9 ? '9+' : '$unread',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            )),
                                    ]);
                              },
                            ),
                            GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.profile),
                                child: AppAvatar(
                                    url: user?.photoUrl,
                                    name: user?.name ?? '?',
                                    size: 40,
                                    bg: AppColors.warning,
                                    r: 12)),
                          ]),
                        ]),
                    const SizedBox(height: 14),
                    AppSearchBar(
                        hint: 'Buscar serviços, profissionais...',
                        readOnly: true,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.search)),
                  ]));
            },
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SecHeader(title: 'O que você precisa hoje?'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
                children: _modules
                    .map((m) => GestureDetector(
                        onTap: () => _navigate(m['id']!),
                        child: Container(
                            decoration: AppDecorations.card(r: 14),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 2),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m['icon']!,
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 5),
                                  Text(m['label']!,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark),
                                      textAlign: TextAlign.center),
                                ]))))
                    .toList(),
              ),
            ]),
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(children: [
              Expanded(
                  child: _banner(
                      '🏥',
                      'SaúdeConecta',
                      'Médico · Psicólogo · Fisio',
                      AppGradients.health,
                      Routes.health)),
              const SizedBox(width: 10),
              Expanded(
                  child: _banner('📦', 'EntregaConecta', 'GPS em tempo real',
                      AppGradients.delivery, Routes.delivery)),
            ]),
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _promoBanner('promocoes', Routes.coupons),
                    _promoBanner('marketplace', Routes.marketplace),
                    _promoBanner('cashback', Routes.wallet),
                    _promoBanner('cupons', Routes.coupons),
                    _promoBanner('home_care', Routes.health),
                    _promoBanner('empresas', Routes.companyProfile),
                  ],
                )),
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SecHeader(title: 'Categorias de Serviços'),
                  const SizedBox(height: 12),
                  OfficialIconGrid(
                    items: ServiceCatalog.homeCategories
                        .map(OfficialIconData.category)
                        .toList(),
                    keyPrefix: 'hub-categoria-',
                    onTap: (item) {
                      final category = ServiceCatalog.categoryById(item.id);
                      if (category != null) {
                        openCatalogCategory(context, category);
                      }
                    },
                  ),
                ]),
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SecHeader(title: 'Categorias')),
              const SizedBox(height: 10),
              SizedBox(
                  height: 40,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _groups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sel = _selGroup == _groups[i];
                        return GestureDetector(
                            onTap: () => setState(() => _selGroup = _groups[i]),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.border)),
                                child: Text(_groups[i],
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: sel
                                            ? AppColors.white
                                            : AppColors.textDark))));
                      })),
              // Categorias do grupo selecionado — dá acesso direto aos
              // segmentos (Agro, Drones, Máquinas, Veículos, Lojas...).
              if (_selGroup != 'Todos')
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: Categories.all
                            .where((c) => c.group == _selGroup)
                            .length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = Categories.all
                              .where((c) => c.group == _selGroup)
                              .elementAt(i);
                          return CatChip(
                              emoji: c.emoji,
                              name: c.name,
                              categoryId: c.id,
                              color: c.color,
                              selected: false,
                              onTap: () => Navigator.pushNamed(
                                  context, Routes.search,
                                  arguments: {'category': c.id}));
                        },
                      )),
                ),
            ]),
          )),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: SecHeader(
                      title: 'Em destaque',
                      action: 'Ver todos →',
                      onAction: () =>
                          Navigator.pushNamed(context, Routes.search)))),
          SliverToBoxAdapter(
              child: StreamBuilder<List<ProviderModel>>(
            stream: FS.providersStream(limit: 5),
            builder: (_, snap) {
              final provs = DemoData.orEmpty(snap.data, _demoProviders);
              return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                      children: provs.map((p) {
                    final catName = p.categories.isNotEmpty
                        ? (Categories.byId(p.categories.first)?.name ??
                            p.categories.first)
                        : 'Profissional';
                    return ProvCard(
                      name: p.name,
                      role: catName,
                      badge: p.badge,
                      price: p.minPrice != null
                          ? 'A partir de R\$ ${p.minPrice!.toStringAsFixed(0)}'
                          : 'Consultar',
                      rating: p.rating,
                      reviews: p.totalReviews,
                      isOnline: p.modalities.contains('online'),
                      photo: p.photoUrl,
                      providerId: p.id,
                      onTap: () => Navigator.pushNamed(
                          context, Routes.requestService,
                          arguments: {
                            'providerId': p.id,
                            'providerName': p.name,
                            'category': p.categories.isNotEmpty
                                ? p.categories.first
                                : ''
                          }),
                      onChat: () => ChatNav.open(context,
                          otherUserId: p.userId.isNotEmpty ? p.userId : p.id,
                          otherName: p.name,
                          otherPhoto: p.photoUrl),
                    );
                  }).toList()));
            },
          )),
          SliverToBoxAdapter(
              child: uid != null
                  ? StreamBuilder<UserModel?>(
                      stream: FS.userStream(uid),
                      builder: (_, snap) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: XpCard(xp: snap.data?.xp ?? 0)),
                    )
                  : const SizedBox.shrink()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  Widget _promoBanner(String slug, String route) {
    final path = AppAssets.banners[slug];
    if (path == null) return const SizedBox.shrink();
    // Largura responsiva: ~80% da tela, limitada entre 260 e 320, para
    // ficar bem tanto em celulares pequenos quanto em tablets.
    final w = (MediaQuery.of(context).size.width * 0.8).clamp(260.0, 320.0);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: w,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ]),
        child: SvgPicture.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  Widget _banner(
          String icon, String title, String sub, Gradient g, String route) =>
      GestureDetector(
          onTap: () => Navigator.pushNamed(context, route),
          child: Container(
            decoration: AppDecorations.gradient(g, r: 18),
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
            ]),
          ));

  void _navigate(String id) {
    switch (id) {
      case 'health':
        Navigator.pushNamed(context, Routes.health);
        break;
      case 'delivery':
        Navigator.pushNamed(context, Routes.delivery);
        break;
      case 'marketplace':
        Navigator.pushNamed(context, Routes.marketplace);
        break;
      case 'ai':
        Navigator.pushNamed(context, Routes.aiAssistant);
        break;
      // Locação: abre a vitrine já na aba certa.
      case 'rental':
        Navigator.pushNamed(context, Routes.rental);
        break;
      case 'vehicles':
        Navigator.pushNamed(context, Routes.rental, arguments: {'tab': 0});
        break;
      case 'machines':
        Navigator.pushNamed(context, Routes.rental, arguments: {'tab': 1});
        break;
      // Segmentos de serviço: abrem a busca filtrada pelo grupo.
      case 'agro':
        setState(() => _selGroup = 'Agro');
        break;
      case 'drones':
        setState(() => _selGroup = 'Drones');
        break;
      case 'labor':
        setState(() => _selGroup = 'Mão de Obra');
        break;
      case 'pets':
        setState(() => _selGroup = 'Pets');
        break;
      case 'beauty':
        setState(() => _selGroup = 'Beleza');
        break;
      case 'education':
        setState(() => _selGroup = 'Educação');
        break;
      default:
        Navigator.pushNamed(context, Routes.search);
    }
  }
}

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  final bool embedded;
  final SearchMode mode;

  /// Lista injetada em teste. Em produção fica nula e a tela lê o Firestore.
  final List<ProviderModel>? seedProviders;
  const SearchScreen({
    super.key,
    this.initialCategory,
    this.embedded = false,
    this.mode = SearchMode.explore,
    this.seedProviders,
  });
  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';
  String? _cat;
  bool _onlineOnly = false;
  bool _verifiedOnly = false;
  bool _cityOnly = false;
  bool _availableToday = false;
  String _sort = 'rating';
  bool _grid = true;
  int _page = 0;
  static const _pageSize = 8;

  bool get _explore => widget.mode == SearchMode.explore;

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCategory;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _smartSearch() async {
    if (_q.trim().isEmpty) {
      snack(context, 'Digite o que você precisa primeiro');
      return;
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    final catNames = Categories.all.map((c) => c.name).toList();
    final result = await AiSvc.smartSearchCategory(_q, catNames);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (result != null && result.isNotEmpty) {
      final matched = Categories.all.firstWhere((c) => c.name == result,
          orElse: () => Categories.all.first);
      setState(() {
        _cat = matched.id;
        _page = 0;
      });
      snack(context, 'Categoria sugerida: ${matched.name}',
          bg: AppColors.secondary);
    } else {
      snack(context,
          'Não consegui identificar uma categoria. Tente ser mais específico.',
          bg: AppColors.error);
    }
  }

  void _openProfile(ProviderModel provider, {ProviderDetailStyle style = ProviderDetailStyle.profile}) {
    c360Open(
      context,
      route: Routes.providerProfile,
      arguments: {
        'providerId': provider.id,
        'providerName': provider.name,
        'category': provider.categories.isNotEmpty
            ? provider.categories.first
            : (_cat ?? ''),
        'style': style == ProviderDetailStyle.service ? 'service' : 'profile',
      },
      page: ProviderProfileScreen(
        providerId: provider.id,
        providerName: provider.name,
        category: provider.categories.isNotEmpty
            ? provider.categories.first
            : (_cat ?? ''),
        style: style,
      ),
    );
  }

  void _request(ProviderModel provider) {
    c360Open(
      context,
      route: Routes.requestService,
      arguments: {
        'providerId': provider.id,
        'providerName': provider.name,
        'category': provider.categories.isNotEmpty
            ? provider.categories.first
            : (_cat ?? ''),
      },
      page: RequestServiceScreen(
        providerId: provider.id,
        providerName: provider.name,
        category: provider.categories.isNotEmpty
            ? provider.categories.first
            : (_cat ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: C360PageBanner(
          icon: _explore ? Icons.travel_explore_rounded : Icons.groups_rounded,
          title: _explore ? 'Explorar Serviços' : 'Profissionais',
          subtitle: _explore
              ? 'Encontre rapidamente o serviço ideal na sua região.'
              : 'Encontre, avalie e contrate os melhores profissionais da região.',
        ),
      ),
      if (_explore)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.hero,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const TiaPortrait(pose: 'apresentando', height: 72),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Vamos encontrar o serviço ideal. Fale com a Tia Carajás IA.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              TiaTalkButton(
                label: 'Fale com a IA',
                onPressed: () => c360Open(
                  context,
                  route: Routes.aiAssistant,
                  page: const TiaCentralScreen(),
                ),
              ),
            ]),
          ),
        ),
      if (!_explore)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final field = TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() {
                _q = v;
                _page = 0;
              }),
              decoration: const InputDecoration(
                hintText: 'Buscar profissional, serviço ou empresa...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            );
            final mapButton = IconButton(
              tooltip: 'Ver no Mapa',
              onPressed: () => Navigator.pushNamed(context, Routes.gps,
                  arguments: {'ctx': 'servico'}),
              icon: const Icon(Icons.map_outlined),
            );
            final filterButton = IconButton(
              tooltip: 'Filtros',
              onPressed: _filters,
              icon: const Icon(Icons.tune_rounded),
            );
            final micButton = IconButton(
              tooltip: 'Falar a busca',
              onPressed: () => c360Open(
                context,
                route: Routes.aiAssistant,
                page: TiaCentralScreen(seed: _q.isEmpty ? null : _q),
              ),
              icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
            );
            if (narrow) {
              return Column(children: [
                field,
                Row(children: [mapButton, filterButton, micButton]),
              ]);
            }
            return Row(children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.gps,
                    arguments: {'ctx': 'servico'}),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Ver no Mapa'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _filters,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filtros'),
              ),
              micButton,
            ]);
          }),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() {
                  _q = v;
                  _page = 0;
                }),
                decoration: const InputDecoration(
                  hintText: 'Buscar serviço ou profissional...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Busca inteligente',
              onPressed: _smartSearch,
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary),
            ),
            IconButton(
              tooltip: 'Falar a busca',
              onPressed: () => c360Open(
                context,
                route: Routes.aiAssistant,
                page: const TiaCentralScreen(),
              ),
              icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
            ),
          ]),
        ),
      if (_cat != null) _selectedIcon(),
      if (_explore)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: OfficialIconGrid(
            items: ServiceCatalog.homeCategories
                .map(OfficialIconData.category)
                .toList(),
            keyPrefix: 'explorar-',
            maxVisibleRows: MediaQuery.sizeOf(context).width >= 900 ? null : 2,
            onTap: (item) {
              final category = ServiceCatalog.categoryById(item.id);
              if (category != null) openCatalogCategory(context, category);
            },
          ),
        ),
      const SizedBox(height: 10),
      SizedBox(
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: _explore ? _exploreChips() : _proChips(),
        ),
      ),
      if (_explore)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _menuChip('Distância', Icons.place_outlined, () {
              setState(() {
                _cityOnly = !_cityOnly;
                _page = 0;
              });
              snack(
                  context,
                  _cityOnly
                      ? 'Mostrando profissionais da cidade selecionada.'
                      : 'Filtro de cidade removido.');
            }, selected: _cityOnly),
            _menuChip('Avaliação', Icons.star_outline_rounded, () {
              setState(() {
                _sort = 'rating';
                _page = 0;
              });
            }, selected: _sort == 'rating'),
            _menuChip('Preço', Icons.payments_outlined, () {
              setState(() {
                _sort = 'price_asc';
                _page = 0;
              });
            }, selected: _sort == 'price_asc'),
            _menuChip('Tipo de serviço', Icons.category_outlined, _filters),
            _menuChip('Atendimento', Icons.support_agent_rounded, () {
              setState(() {
                _onlineOnly = !_onlineOnly;
                _page = 0;
              });
            }, selected: _onlineOnly),
          ]),
        ),
      Expanded(
        child: widget.seedProviders != null
            ? _resultList(widget.seedProviders!, demo: false)
            : StreamBuilder<List<ProviderModel>>(
          stream: c360Stream(() => FS.providersStream(
                category: ServiceCatalog.professionById(_cat ?? '') != null
                    ? _cat
                    : null,
                limit: 40,
              )),
          builder: (context, snap) {
            final waiting = snap.connectionState == ConnectionState.waiting &&
                !snap.hasData;
            if (waiting) {
              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (_, __) => const SkeletonCard());
            }
            if (snap.hasError) {
              return const EmptyState(
                  emoji: '🔍',
                  title: 'Não foi possível carregar',
                  subtitle: 'Verifique a conexão e tente de novo.');
            }
            final loaded = snap.data ?? <ProviderModel>[];
            final demo = loaded.isEmpty && RuntimeConfig.showLabeledDemo;
            final source = demo
                ? DemoCatalog.providers
                    .where((p) => providerMatchesCategory(p, _cat))
                    .toList()
                : loaded;
            return _resultList(source, demo: demo);
          },
        ),
      ),
    ]);

    if (widget.embedded) {
      return ColoredBox(
        key: Key('lista-${_cat ?? 'todos'}'),
        color: AppColors.background,
        child: body,
      );
    }
    return Scaffold(
      key: Key('lista-${_cat ?? 'todos'}'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        leading: BackButton(onPressed: () => c360Pop(context)),
        title: Text(_explore ? 'Explorar Serviços' : 'Profissionais'),
      ),
      body: body,
    );
  }

  Widget _selectedIcon() {
    final profession = ServiceCatalog.professionById(_cat ?? '');
    final category = ServiceCatalog.categoryById(_cat ?? '');
    final asset = profession?.asset512 ?? category?.asset512;
    final label = profession?.name ?? category?.name ?? _cat!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 160,
          height: 160,
          child: OfficialIcon(
            label: label,
            assetPath: asset,
            pendingArt: asset == null,
          ),
        ),
      ),
    );
  }

  Widget _resultList(List<ProviderModel> source, {required bool demo}) {
    final city = RegionController.instance.city.value;
    final list = applyProviderFilters(
      source: source,
      query: _q,
      categoryId: _cat,
      onlineOnly: _onlineOnly,
      verifiedOnly: _verifiedOnly,
      cityOnly: _cityOnly,
      availableToday: _availableToday,
      city: city,
      sort: _sort,
    );
    if (list.isEmpty) {
      final bare = _q.isEmpty &&
          !_onlineOnly &&
          !_verifiedOnly &&
          !_cityOnly &&
          !_availableToday;
      if (_cat != null && bare) {
        return const EmptyState(
          emoji: '📭',
          title: 'Ainda não há profissionais cadastrados nesta categoria',
          subtitle:
              'Quando alguém se cadastrar nesta profissão, a lista aparece aqui.',
        );
      }
      return const EmptyState(
          emoji: '🔍',
          title: 'Nenhum resultado',
          subtitle: 'Tente outros filtros ou palavras-chave',
          asset: AppAssets.estadoNenhumResultado);
    }
    final pages = (list.length / _pageSize).ceil();
    final safePage = _page.clamp(0, pages - 1).toInt();
    final slice = list.skip(safePage * _pageSize).take(_pageSize).toList();
    return Column(children: [
      if (demo)
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Demonstração · estes cartões não são profissionais cadastrados.',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF7A5B00)),
          ),
        ),
      Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      '${list.length} profissionais e serviços encontrados',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium),
                    ),
                  ),
                  if (_explore) ...[
                    DropdownButton<String>(
                      value: _sort,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                            value: 'rating', child: Text('Mais relevantes')),
                        DropdownMenuItem(
                            value: 'reviews', child: Text('Mais avaliações')),
                        DropdownMenuItem(
                            value: 'price_asc', child: Text('Menor preço')),
                      ],
                      onChanged: (v) => setState(() {
                        _sort = v ?? 'rating';
                        _page = 0;
                      }),
                    ),
                    IconButton(
                      tooltip: 'Grade',
                      onPressed: () => setState(() => _grid = true),
                      icon: Icon(Icons.grid_view_rounded,
                          color: _grid ? AppColors.primary : AppColors.textHint),
                    ),
                    IconButton(
                      tooltip: 'Lista',
                      onPressed: () => setState(() => _grid = false),
                      icon: Icon(Icons.view_list_rounded,
                          color: !_grid ? AppColors.primary : AppColors.textHint),
                    ),
                  ],
                ]),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  itemCount: slice.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _grid
                        ? (MediaQuery.sizeOf(context).width > 1400
                            ? 4
                            : MediaQuery.sizeOf(context).width > 900
                                ? 3
                                : 2)
                        : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: _explore
                        ? (_grid ? 0.62 : 1.8)
                        : (_grid ? 0.72 : 2.1),
                  ),
                  itemBuilder: (_, i) {
                    final p = slice[i];
                    final catName = _cat != null
                        ? (Categories.byId(_cat!)?.name ?? _cat!)
                        : (p.categories.isNotEmpty
                            ? (Categories.byId(p.categories.first)?.name ??
                                p.categories.first)
                            : 'Profissional');
                    final place = c360Place(p, city);
                    if (_explore) {
                      return C360ServiceCard(
                        title: catName,
                        subtitle: p.bio?.isNotEmpty == true ? p.bio! : p.name,
                        rating: p.rating,
                        reviews: p.totalReviews,
                        photoUrl: p.photoUrl,
                        verified: p.verified,
                        place: place,
                        onProfile: () => _openProfile(p,
                            style: ProviderDetailStyle.service),
                        onRequest: () => _request(p),
                      );
                    }
                    return C360PersonCard(
                      name: p.name,
                      role: catName,
                      bio: p.bio,
                      rating: p.rating,
                      reviews: p.totalReviews,
                      photoUrl: p.photoUrl,
                      verified: p.verified,
                      place: place,
                      onChat: () => ChatNav.open(context,
                          otherUserId: p.userId.isNotEmpty ? p.userId : p.id,
                          otherName: p.name,
                          otherPhoto: p.photoUrl),
                      onRequest: () => _request(p),
                    );
                  },
                ),
              ),
              if (pages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: safePage == 0
                            ? null
                            : () => setState(() => _page = safePage - 1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      for (var i = 0; i < pages && i < 6; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: TextButton(
                            onPressed: () => setState(() => _page = i),
                            style: TextButton.styleFrom(
                              backgroundColor: i == safePage
                                  ? AppColors.primary
                                  : Colors.transparent,
                              foregroundColor: i == safePage
                                  ? Colors.white
                                  : AppColors.textDark,
                              minimumSize: const Size(36, 36),
                            ),
                            child: Text('${i + 1}'),
                          ),
                        ),
                      IconButton(
                        onPressed: safePage >= pages - 1
                            ? null
                            : () => setState(() => _page = safePage + 1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
    ]);
  }

  List<Widget> _exploreChips() {
    return [
      C360FilterChip(
        label: 'Todos',
        icon: Icons.apps_rounded,
        selected: _cat == null,
        onTap: () => setState(() {
          _cat = null;
          _page = 0;
        }),
      ),
      for (final profession
          in ServiceCatalog.professions.where((p) => p.asset != null))
        C360FilterChip(
          label: profession.name,
          selected: _cat == profession.id,
          onTap: () => setState(() {
            _cat = _cat == profession.id ? null : profession.id;
            _page = 0;
          }),
        ),
    ];
  }

  List<Widget> _proChips() {
    return [
      C360FilterChip(
        label: 'Todos',
        icon: Icons.grid_view_rounded,
        selected: !_verifiedOnly &&
            !_cityOnly &&
            _sort == 'rating' &&
            !_onlineOnly &&
            !_availableToday,
        onTap: () => setState(() {
          _verifiedOnly = false;
          _cityOnly = false;
          _onlineOnly = false;
          _availableToday = false;
          _sort = 'rating';
          _cat = null;
          _page = 0;
        }),
      ),
      C360FilterChip(
        label: 'Verificados',
        icon: Icons.verified_outlined,
        selected: _verifiedOnly,
        onTap: () => setState(() {
          _verifiedOnly = !_verifiedOnly;
          _page = 0;
        }),
      ),
      C360FilterChip(
        label: 'Mais Bem Avaliados',
        icon: Icons.star_rounded,
        selected: _sort == 'reviews',
        onTap: () => setState(() {
          _sort = 'reviews';
          _page = 0;
        }),
      ),
      C360FilterChip(
        label: 'Disponíveis Hoje',
        icon: Icons.event_available_rounded,
        selected: _availableToday,
        onTap: () => setState(() {
          _availableToday = !_availableToday;
          _page = 0;
        }),
      ),
      C360FilterChip(
        label: 'Próximos de Você',
        icon: Icons.near_me_outlined,
        selected: _cityOnly,
        onTap: () => setState(() {
          _cityOnly = !_cityOnly;
          _page = 0;
        }),
      ),
    ];
  }

  Widget _menuChip(String label, IconData icon, VoidCallback onTap,
      {bool selected = false}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.textDark,
        backgroundColor: selected ? AppColors.primarySoft : AppColors.white,
        side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _filters() => showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const SheetHandle(),
                    const SizedBox(height: 16),
                    const Text('Filtros',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    SwitchListTile(
                        title: const Text('Somente atendimento online'),
                        value: _onlineOnly,
                        onChanged: (v) {
                          setS(() => _onlineOnly = v);
                          setState(() => _page = 0);
                        }),
                    SwitchListTile(
                        title: const Text('Somente verificados'),
                        value: _verifiedOnly,
                        onChanged: (v) {
                          setS(() => _verifiedOnly = v);
                          setState(() => _page = 0);
                        }),
                    SwitchListTile(
                        title: const Text('Somente na cidade selecionada'),
                        subtitle: const Text(
                            'A distância em km depende de coordenadas que ainda não estão no cadastro.'),
                        value: _cityOnly,
                        onChanged: (v) {
                          setS(() => _cityOnly = v);
                          setState(() => _page = 0);
                        }),
                    const Divider(),
                    const Text('Ordenar por',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    for (final e in {
                      'rating': 'Melhor avaliação',
                      'reviews': 'Mais avaliações',
                      'price_asc': 'Menor preço'
                    }.entries)
                      RadioListTile<String>(
                          title: Text(e.value),
                          value: e.key,
                          groupValue: _sort,
                          onChanged: (v) {
                            setS(() => _sort = v!);
                            setState(() => _page = 0);
                          }),
                    const SizedBox(height: 8),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Aplicar'))),
                  ]))));
}
