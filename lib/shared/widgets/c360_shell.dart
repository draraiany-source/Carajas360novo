import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/runtime_config.dart';
import 'demo_banner.dart';
import '../../core/theme/app_colors.dart';
import '../../features/chat/chat_inbox_screen.dart';
import '../../features/home/carajas_home_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/plans_screen.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/provider/provider_home_screen.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import 'c360_nav.dart';
import '../../features/tia/tia_schedule_screen.dart';
import '../../features/tia/tia_screen.dart';
import 'c360_ui.dart';
import 'widgets.dart';

/// Lembra o destino ao trocar um shell avulso pelo app principal.
abstract class C360Memory {
  static C360Dest next = C360Dest.home;
}

/// Moldura desktop (sidebar) e mobile (gaveta + barra inferior).
class C360Shell extends StatefulWidget {
  /// Quando informado, a área principal começa nessa tela (rotas avulsas).
  final Widget? singlePage;
  const C360Shell({super.key, this.singlePage});

  @override
  State<C360Shell> createState() => _C360ShellState();
}

class _C360ShellState extends State<C360Shell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  late C360Dest _dest;
  final List<Widget> _stack = [];
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _dest = C360Memory.next;
    C360Memory.next = C360Dest.home;
    if (widget.singlePage != null) _stack.add(widget.singlePage!);
    _pages = [
      const HomeScreen(),
      const SearchScreen(embedded: true, mode: SearchMode.explore),
      const SearchScreen(embedded: true, mode: SearchMode.professionals),
      const MyOrdersScreen(embedded: true),
      const ChatInboxScreen(embedded: true),
      const FavoritesScreen(embedded: true),
      const ProfileScreen(),
      const TiaCentralScreen(),
      const AgendaScreen(),
    ];
    RegionController.instance.ensureLoaded();
  }

  bool get _innerPop =>
      widget.singlePage == null ? _stack.isNotEmpty : _stack.length > 1;

  void _go(C360Dest dest) {
    if (widget.singlePage != null) {
      C360Memory.next = dest;
      Navigator.pushNamedAndRemoveUntil(context, Routes.main, (_) => false);
      return;
    }
    setState(() {
      _dest = dest;
      _stack.clear();
    });
    _scaffold.currentState?.closeDrawer();
  }

  void _push(Widget page) {
    setState(() => _stack.add(page));
    _scaffold.currentState?.closeDrawer();
  }

  void _pop() {
    if (_innerPop) {
      setState(() => _stack.removeLast());
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return C360Nav(
      current: _dest,
      go: _go,
      push: _push,
      pop: _pop,
      canPop: _innerPop,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        final page = _stack.isNotEmpty
            ? _stack.last
            : IndexedStack(index: _dest.index, children: _pages);
        return Scaffold(
          key: _scaffold,
          backgroundColor: AppColors.background,
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: AppColors.sidebar,
                  child: _Sidebar(
                    dest: _dest,
                    onDest: _go,
                    inDrawer: true,
                    highlight: widget.singlePage == null,
                  ),
                ),
          body: Row(children: [
            if (wide)
              SizedBox(
                width: 248,
                child: _Sidebar(
                  dest: _dest,
                  onDest: _go,
                  highlight: widget.singlePage == null,
                ),
              ),
            Expanded(
              child: Column(children: [
                if (RuntimeConfig.showLabeledDemo) const DemoBanner(),
                _TopBar(
                  showMenu: !wide,
                  showBack: _innerPop ||
                      (widget.singlePage != null && Navigator.canPop(context)),
                  onMenu: () => _scaffold.currentState?.openDrawer(),
                  onBack: _pop,
                  onMessages: () => _go(C360Dest.messages),
                  onAccount: () => _go(C360Dest.account),
                  onSearch: () => _go(C360Dest.explore),
                ),
                Expanded(child: page),
              ]),
            ),
          ]),
          bottomNavigationBar: wide
              ? null
              : _BottomBar(
                  dest: _dest,
                  onDest: _go,
                ),
        );
      }),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final C360Dest dest;
  final ValueChanged<C360Dest> onDest;
  final bool inDrawer;
  final bool highlight;
  const _Sidebar({
    required this.dest,
    required this.onDest,
    this.inDrawer = false,
    this.highlight = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarDeep, AppColors.sidebar, Color(0xFF145C30)],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 16),
          const _Logo(),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              _item(context, C360Dest.home, Icons.home_rounded, 'Início'),
              _item(context, C360Dest.tia, Icons.auto_awesome_rounded,
                  'Tia Carajás IA'),
              _item(context, C360Dest.explore, Icons.grid_view_rounded,
                  'Explorar Serviços'),
              _item(context, C360Dest.professionals, Icons.groups_rounded,
                  'Profissionais'),
              _item(context, C360Dest.orders, Icons.assignment_rounded,
                  'Pedidos / Solicitações'),
              _item(context, C360Dest.messages, Icons.chat_bubble_rounded,
                  'Mensagens'),
              _item(context, C360Dest.favorites, Icons.favorite_rounded,
                  'Favoritos'),
              _item(context, C360Dest.account, Icons.person_rounded,
                  'Minha Conta'),
              const SizedBox(height: 8),
              _link(context, Icons.workspace_premium_rounded,
                  'Planos e Assinaturas', const PlansScreen()),
              _link(
                  context,
                  Icons.campaign_rounded,
                  'Divulgue seu Serviço',
                  const ProviderHomeScreen()),
              _routeLink(context, Icons.help_outline_rounded, 'Ajuda e Suporte',
                  Routes.support),
            ]),
          ),
          _location(context),
          const TiaFloatingHelp(),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _item(
      BuildContext context, C360Dest value, IconData icon, String label) {
    final on = highlight && dest == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: on ? AppColors.yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            onDest(value);
            if (inDrawer) Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(icon, size: 20, color: on ? AppColors.sidebar : Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      color: on ? AppColors.sidebar : Colors.white,
                      fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    )),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          C360Nav.maybeOf(context)?.push(page);
          if (inDrawer && context.mounted) Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.92)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _routeLink(
      BuildContext context, IconData icon, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (inDrawer) Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.92)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _location(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showCityPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ValueListenableBuilder<String>(
              valueListenable: RegionController.instance.city,
              builder: (_, city, __) => Row(children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.yellow, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$city - PA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: Colors.white70, size: 18),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const CustomPaint(
          size: Size(36, 28),
          painter: _Mountains(),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Carajás360',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.3)),
              Text('SERVIÇOS LOCAIS',
                  style: TextStyle(
                      color: AppColors.yellow,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.8)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Mountains extends CustomPainter {
  const _Mountains();

  @override
  void paint(Canvas canvas, Size size) {
    final back = Paint()..color = const Color(0xFF8FBF6A);
    final front = Paint()..color = AppColors.yellow;
    final b = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.28, size.height * 0.28)
      ..lineTo(size.width * 0.48, size.height * 0.62)
      ..lineTo(size.width * 0.7, size.height * 0.05)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(b, back);
    final f = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..lineTo(size.width * 0.42, size.height * 0.42)
      ..lineTo(size.width * 0.62, size.height)
      ..close();
    canvas.drawPath(f, front);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopBar extends StatelessWidget {
  final bool showMenu;
  final bool showBack;
  final VoidCallback onMenu;
  final VoidCallback onBack;
  final VoidCallback onMessages;
  final VoidCallback onAccount;
  final VoidCallback onSearch;
  const _TopBar({
    required this.showMenu,
    required this.showBack,
    required this.onMenu,
    required this.onBack,
    required this.onMessages,
    required this.onAccount,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final uid = c360Uid();
    return Material(
      color: AppColors.white,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            if (showBack)
              IconButton(
                tooltip: 'Voltar',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else if (showMenu)
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.menu_rounded, color: AppColors.textHint),
              ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onSearch,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.textLight, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O que você precisa? (ex.: eletricista, limpeza, pedreiro...)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => showCityPicker(context),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: ValueListenableBuilder<String>(
                  valueListenable: RegionController.instance.city,
                  builder: (_, city, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text('$city - PA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _NotifButton(),
            IconButton(
              tooltip: 'Mensagens',
              onPressed: onMessages,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            const SizedBox(width: 4),
            _AccountChip(uid: uid, onTap: onAccount),
          ]),
        ),
      ),
    );
  }
}

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = c360Uid();
    if (uid == null) {
      return IconButton(
        onPressed: () => Navigator.pushNamed(context, Routes.notifications),
        icon: const Icon(Icons.notifications_none_rounded),
      );
    }
    return StreamBuilder<List<NotifModel>>(
      stream: c360Stream(FS.notifStream),
      builder: (_, snap) {
        final unread =
            (snap.data ?? []).where((n) => !n.read).length;
        return Stack(clipBehavior: Clip.none, children: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          if (unread > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ]);
      },
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String? uid;
  final VoidCallback onTap;
  const _AccountChip({required this.uid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return TextButton(
        onPressed: () => Navigator.pushNamed(context, Routes.login),
        child: const Text('Entrar'),
      );
    }
    return StreamBuilder<UserModel?>(
      stream: c360Stream(() => FS.userStream(uid)),
      builder: (_, snap) {
        final user = snap.data;
        final name = user?.firstName.isNotEmpty == true
            ? user!.firstName
            : 'visitante';
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(children: [
              AppAvatar(
                  url: user?.photoUrl, name: name, size: 36, r: 18),
              const SizedBox(width: 8),
              Text('Olá, $name',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Icon(Icons.expand_more_rounded, size: 18),
            ]),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final C360Dest dest;
  final ValueChanged<C360Dest> onDest;
  const _BottomBar({required this.dest, required this.onDest});

  @override
  Widget build(BuildContext context) {
    const items = <(C360Dest, IconData, String)>[
      (C360Dest.home, Icons.home_rounded, 'Início'),
      (C360Dest.tia, Icons.auto_awesome_rounded, 'Tia Carajás IA'),
      (C360Dest.agenda, Icons.calendar_month_rounded, 'Agenda'),
      (C360Dest.orders, Icons.assignment_rounded, 'Pedidos'),
      (C360Dest.account, Icons.person_outline_rounded, 'Perfil'),
    ];
    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final item in items)
                _cell(item.$1, item.$2, item.$3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(C360Dest value, IconData icon, String label) {
    final on = dest == value;
    return InkWell(
      onTap: () => onDest(value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? AppColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 22, color: on ? AppColors.sidebar : AppColors.textLight),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                  color: on ? AppColors.sidebar : AppColors.textLight)),
        ]),
      ),
    );
  }
}
