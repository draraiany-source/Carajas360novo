import 'package:flutter/material.dart';
import '../../core/catalog/service_catalog.dart';
import '../../core/constants/runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../catalog/category_browse.dart';
import '../../shared/widgets/official_icon.dart';
import '../../core/utils/demo_data.dart';
import 'home_layout.dart';
import '../../core/modules/platform_modules.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../profile/plans_screen.dart';
import '../provider/provider_home_screen.dart';
import '../tia/tia_screen.dart';
import '../tia/tia_widgets.dart';
import 'provider_profile_screen.dart';

/// Home da plataforma Carajás 360 (mockups Início v1 e v2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _banner = PageController();
  int _bannerPage = 0;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheHomeIcons(context);
  }

  @override
  void dispose() {
    _banner.dispose();
    super.dispose();
  }

  void _openCategory(CatalogCategory category) {
    openCatalogCategory(context, category);
  }

  void _openProfile(ProviderModel provider) {
    c360Open(
      context,
      route: Routes.providerProfile,
      arguments: {
        'providerId': provider.id,
        'providerName': provider.name,
        'category':
            provider.categories.isNotEmpty ? provider.categories.first : '',
        'style': 'profile',
      },
      page: ProviderProfileScreen(
        providerId: provider.id,
        providerName: provider.name,
        category:
            provider.categories.isNotEmpty ? provider.categories.first : '',
        style: ProviderDetailStyle.profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<List<ProviderModel>>(
        stream: c360Stream(() => FS.providersStream(limit: 12)),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting &&
              !snap.hasData;
          final failed = snap.hasError;
          final loaded = snap.data ?? <ProviderModel>[];
          final showDemo = !loading &&
              !failed &&
              loaded.isEmpty &&
              RuntimeConfig.showLabeledDemo;
          final providers = showDemo ? DemoCatalog.providers : loaded;
          return LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 400));
                if (mounted) setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _Hero(
                    controller: _banner,
                    page: _bannerPage,
                    onPage: (i) => setState(() => _bannerPage = i),
                    onSearch: () =>
                        c360Go(context, C360Dest.explore, Routes.search),
                    onTia: () => c360Open(
                      context,
                      route: Routes.aiAssistant,
                      page: const TiaCentralScreen(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _categoryGrid(),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            flex: 7,
                            child: _mainColumn(providers,
                                loading: loading,
                                failed: failed,
                                demo: showDemo)),
                        const SizedBox(width: 16),
                        SizedBox(width: 300, child: _rail()),
                      ],
                    )
                  else ...[
                    _mainColumn(providers,
                        loading: loading, failed: failed, demo: showDemo),
                    const SizedBox(height: 16),
                    _rail(),
                  ],
                  const SizedBox(height: 18),
                  C360TrustStrip(activeProviders: providers.length),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _categoryGrid() {
    final items = ServiceCatalog.homeCategories;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      C360SectionHeader(
        title: 'Categorias de Serviços',
        action: 'Ver todas',
        onAction: () {
          final todas = ServiceCatalog.categoryById('ver-todas');
          if (todas != null) openCatalogCategory(context, todas);
        },
      ),
      const SizedBox(height: 12),
      OfficialIconGrid(
        items: items.map(OfficialIconData.category).toList(),
        keyPrefix: 'categoria-',
        onTap: (item) {
          final category = ServiceCatalog.categoryById(item.id);
          if (category != null) _openCategory(category);
        },
      ),
    ]);
  }

  Widget _mainColumn(List<ProviderModel> providers,
      {required bool loading, required bool failed, required bool demo}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      C360SectionHeader(
        title: 'Profissionais em Destaque',
        icon: Icons.star_rounded,
        action: 'Ver todas',
        onAction: () =>
            c360Go(context, C360Dest.professionals, Routes.search),
      ),
      const SizedBox(height: 12),
      if (loading)
        const _LoadingRow()
      else if (failed)
        const C360Card(
          child: Text(
            'Não foi possível carregar os profissionais. Verifique a conexão e puxe a tela para tentar de novo.',
            style: TextStyle(color: AppColors.textMedium, height: 1.4),
          ),
        )
      else if (providers.isEmpty)
        C360Card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Nenhum profissional verificado nesta cidade ainda.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'A lista fica vazia de propósito: não completamos com nomes fictícios.',
              style: TextStyle(color: AppColors.textMedium, height: 1.4),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => c360Open(
                context,
                route: Routes.aiAssistant,
                page: const TiaCentralScreen(),
              ),
              child: const Text('Pedir ajuda à Tia Carajás'),
            ),
          ]),
        )
      else
        SizedBox(
          height: 210,
          child: ValueListenableBuilder<String>(
            valueListenable: RegionController.instance.city,
            builder: (_, city, __) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: providers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final provider = providers[i];
                final profession = provider.categories.isNotEmpty
                    ? ServiceCatalog.professionById(provider.categories.first)
                    : null;
                final role = profession?.name ??
                    (provider.categories.isNotEmpty
                        ? provider.categories.first
                        : 'Profissional');
                return C360HighlightCard(
                  name: provider.name,
                  role: role,
                  emblem: profession == null
                      ? null
                      : OfficialIcon(
                          label: profession.name,
                          assetPath: profession.asset256,
                          pendingArt: profession.asset == null,
                          tier: IconTier.list,
                          caption: true,
                        ),
                  rating: provider.rating,
                  reviews: provider.totalReviews,
                  photoUrl: provider.photoUrl,
                  verified: provider.verified,
                  place: c360Place(provider, city),
                  providerId: provider.id,
                  demoLabel: demo ? 'Demonstração · sem avaliação real' : null,
                  onProfile: () => _openProfile(provider),
                );
              },
            ),
          ),
        ),
      const SizedBox(height: 8),
      _modules(),
    ]);
  }

  Widget _modules() {
    final soon =
        PlatformModules.all.where((m) => !m.isAvailable).take(4).toList();
    if (soon.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 18),
      const C360SectionHeader(title: 'Em breve na região'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final module in soon)
            Chip(
              avatar: Text(module.emoji),
              label: Text(module.label),
              backgroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.border),
            ),
        ],
      ),
    ]);
  }

  Widget _rail() {
    return Column(children: [
      _promo(
        title: 'Cadastre seu serviço',
        text: 'Divulgue seu trabalho e conquiste mais clientes.',
        button: 'Anunciar agora',
        yellow: true,
        onTap: () => c360Open(
          context,
          route: Routes.providerHome,
          page: const ProviderHomeScreen(),
        ),
      ),
      const SizedBox(height: 12),
      C360Card(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: [
          _shortcut(Icons.receipt_long_rounded, 'Acompanhe seus pedidos',
              'Veja o status dos seus serviços.', () {
            c360Go(context, C360Dest.orders, Routes.myOrders);
          }),
          const Divider(height: 1),
          _shortcut(Icons.chat_bubble_outline_rounded, 'Mensagens',
              'Converse com clientes e profissionais.', () {
            c360Go(context, C360Dest.messages, Routes.chatInbox);
          }),
          const Divider(height: 1),
          _shortcut(Icons.favorite_border_rounded, 'Meus Favoritos',
              'Seus profissionais e serviços salvos.', () {
            c360Go(context, C360Dest.favorites, Routes.favorites);
          }),
        ]),
      ),
      const SizedBox(height: 12),
      _promo(
        title: 'Carajás360 para Empresas',
        text: 'Soluções em manutenção, mão de obra, máquinas e contratos contínuos.',
        button: 'Conheça os planos',
        yellow: false,
        onTap: () => c360Open(
          context,
          route: Routes.companyProfile,
          page: const PlansScreen(),
        ),
      ),
    ]);
  }

  Widget _shortcut(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _promo({
    required String title,
    required String text,
    required String button,
    required bool yellow,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: yellow ? null : AppGradients.hero,
        color: yellow ? AppColors.primary : null,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        Text(text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow ? AppColors.yellow : AppColors.white,
            foregroundColor: AppColors.sidebar,
          ),
          child: Text(button),
        ),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  final PageController controller;
  final int page;
  final ValueChanged<int> onPage;
  final VoidCallback onSearch;
  final VoidCallback onTia;
  const _Hero({
    required this.controller,
    required this.page,
    required this.onPage,
    required this.onSearch,
    required this.onTia,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = HomeLayout.stackedHeroButtons(constraints.maxWidth);
      final portrait = HomeLayout.tiaHeroHeight(constraints.maxWidth);
      return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: HomeLayout.heroHeight(constraints.maxWidth),
        child: Stack(children: [
          PageView(
            controller: controller,
            onPageChanged: onPage,
            children: [
              _HeroSlide(
                title: 'Encontre o profissional ideal para o seu dia a dia',
                subtitle:
                    'Serviços, mão de obra, máquinas e muito mais em Canaã dos Carajás.',
                compact: narrow,
              ),
              _HeroSlide(
                title: 'Serviços confiáveis, perto de você',
                subtitle:
                    'Profissionais verificados, pagamento seguro e suporte na região.',
                compact: narrow,
              ),
            ],
          ),
          if (HomeLayout.showHeroPortrait(constraints.maxWidth))
            Positioned(
              right: 6,
              top: 6,
              child: TiaPortrait(pose: 'apresentando', height: portrait),
            ),
          Positioned(
            left: 16,
            right: narrow ? 78 : 130,
            bottom: 10,
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _searchButton(onSearch, compact: true),
                      const SizedBox(height: 6),
                      TiaTalkButton(
                        label: 'Falar com a Tia',
                        compact: true,
                        onPressed: onTia,
                      ),
                    ],
                  )
                : Row(children: [
                    _searchButton(onSearch),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TiaTalkButton(
                        label: 'Conversar com a Tia Carajás IA',
                        onPressed: onTia,
                      ),
                    ),
                  ]),
          ),
          Positioned(
            left: 16,
            top: 12,
            child: Row(children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: i == page ? 16 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: i == page
                        ? AppColors.yellow
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
    });
  }

  Widget _searchButton(VoidCallback onSearch, {bool compact = false}) {
    return ElevatedButton.icon(
      onPressed: onSearch,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.sidebar,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        minimumSize: compact ? const Size(0, 36) : null,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      ),
      icon: const Icon(Icons.search_rounded, size: 18),
      label: const Text('Buscar serviços'),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;
  const _HeroSlide({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.hero),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: C360LandscapePainter())),
        Padding(
          padding: EdgeInsets.fromLTRB(18, compact ? 12 : 16, compact ? 78 : 120, compact ? 84 : 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('CANAÃ DOS CARAJÁS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 18 : 26,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: compact ? 12 : 14,
                      height: 1.25)),
            ],
          ),
        ),
      ]),
    );
  }
}
