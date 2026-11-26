import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/widgets.dart';
import '../provider/provider_home_screen.dart';
import '../support/support_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = c360Uid();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: uid == null
          ? EmptyState(
              emoji: '👤',
              title: 'Não autenticado',
              subtitle: 'Faça login para ver seu perfil',
              actionLabel: 'Entrar',
              onAction: () => Navigator.pushNamed(context, Routes.login),
            )
          : StreamBuilder<UserModel?>(
              stream: FS.userStream(uid),
              builder: (_, snap) {
                final user = snap.data;
                final xp = user?.xp ?? 0;
                return CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: GradHeader(
                          gradient: AppGradients.primary,
                          br: 32,
                          child: Center(
                              child: Column(children: [
                            Stack(children: [
                              AppAvatar(
                                  url: user?.photoUrl,
                                  name: user?.name ?? '?',
                                  size: 80,
                                  bg: AppColors.warning,
                                  r: 24),
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _pickAndUploadPhoto(context),
                                    child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle),
                                        child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: Colors.white)),
                                  )),
                            ]),
                            const SizedBox(height: 12),
                            Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name
                                    : 'Usuário',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                    '${user?.levelName ?? '⭐ Iniciante'} · $xp XP',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12))),
                          ])))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(children: [
                            const StatCard(
                                value: '—',
                                label: 'Serviços',
                                color: AppColors.primary),
                            const StatCard(
                                value: '—',
                                label: 'Economia',
                                color: AppColors.secondary),
                            StatCard(
                                value: xp > 0 ? '$xp XP' : '—',
                                label: 'Experiência',
                                color: AppColors.warning),
                          ]))),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(children: [
                            _section('Conta', [
                              _item(
                                  context,
                                  '👤',
                                  'Dados pessoais',
                                  'Nome, CPF, telefone',
                                  () => _editProfile(context, user)),
                              _item(
                                  context,
                                  '📍',
                                  'Endereços',
                                  'Gerenciar endereços',
                                  () => _editProfile(context, user)),
                              _item(
                                  context,
                                  '🔔',
                                  'Notificações',
                                  '3 não lidas',
                                  () => Navigator.pushNamed(
                                      context, Routes.notifications)),
                              _item(context, '🔐', 'Segurança', 'Alterar senha',
                                  () => _changePassword(context, user)),
                            ]),
                            _section('Financeiro', [
                              _item(
                                  context,
                                  '👜',
                                  'Minha carteira',
                                  'Ver saldo disponível',
                                  () => Navigator.pushNamed(
                                      context, Routes.wallet)),
                              _item(
                                  context,
                                  '🔑',
                                  'Minhas reservas',
                                  'Locações de veículos e máquinas',
                                  () => Navigator.pushNamed(
                                      context, Routes.bookings)),
                              _item(
                                  context,
                                  '📋',
                                  'Meu histórico',
                                  'Pedidos e serviços',
                                  () => Navigator.pushNamed(
                                      context, Routes.myOrders)),
                              _item(
                                  context,
                                  '⭐',
                                  'Favoritos',
                                  'Profissionais salvos',
                                  () => Navigator.pushNamed(
                                      context, Routes.favorites)),
                              _item(
                                  context,
                                  '🎟️',
                                  'Cupons',
                                  'PROMO30 disponível',
                                  () => Navigator.pushNamed(
                                      context, Routes.coupons)),
                            ]),
                            _section('Serviços', [
                              _item(
                                  context,
                                  '⚡',
                                  'Resolve Carajás',
                                  'Pedir orçamento e ver propostas',
                                  () => Navigator.pushNamed(
                                      context, Routes.resolve)),
                              _item(
                                  context,
                                  '📋',
                                  'Meus Resolve',
                                  'Solicitações abertas',
                                  () => Navigator.pushNamed(
                                      context, Routes.myResolve)),
                              _item(
                                  context,
                                  '🏥',
                                  'Saúde',
                                  '1 consulta agendada',
                                  () => Navigator.pushNamed(
                                      context, Routes.health)),
                              _item(
                                  context,
                                  '📦',
                                  'Entregas',
                                  'Rastrear pedidos',
                                  () => Navigator.pushNamed(
                                      context, Routes.delivery)),
                              _item(context, '🏆', 'Conquistas', '8 medalhas',
                                  () => _showBadges(context)),
                              _item(
                                  context,
                                  '❓',
                                  'Suporte',
                                  'Central de ajuda',
                                  () => Navigator.pushNamed(
                                      context, Routes.support)),
                            ]),
                            if (user?.type == UserType.provider)
                              _section('Área do Prestador', [
                                _item(
                                    context,
                                    '🔧',
                                    'Meus Atendimentos',
                                    'Pedidos recebidos e agenda',
                                    () => c360Open(
                                          context,
                                          route: Routes.providerHome,
                                          page: const ProviderHomeScreen(),
                                        )),
                                _item(
                                    context,
                                    '⚡',
                                    'Oportunidades Resolve',
                                    'Enviar propostas a pedidos abertos',
                                    () => Navigator.pushNamed(context,
                                        Routes.resolveOpportunities)),
                              ]),
                            if (user?.type == UserType.company)
                              _section('Empresa', [
                                _item(
                                    context,
                                    '🏢',
                                    'Painel da Empresa',
                                    'Equipe, leads e plano',
                                    () => Navigator.pushNamed(
                                        context, Routes.companyProfile)),
                              ])
                            else if (user?.type != UserType.admin)
                              _section('Para empresas', [
                                _item(
                                    context,
                                    '🏢',
                                    'Cadastrar minha empresa',
                                    'Gerencie equipe e leads',
                                    () => Navigator.pushNamed(
                                        context, Routes.companyProfile)),
                              ]),
                            if (user?.type == UserType.admin ||
                                user?.adminRole != null)
                              _section('Administração', [
                                _item(
                                    context,
                                    '⚙️',
                                    'Painel Admin',
                                    'Usuários, validação, financeiro',
                                    () => Navigator.pushNamed(
                                        context, Routes.admin)),
                              ]),
                            _section('App', [
                              _item(
                                  context,
                                  '🎁',
                                  'Indique e ganhe',
                                  'Convide amigos e ganhe cashback',
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ReferralScreen()))),
                              _item(context, '🌗', 'Tema', _themeLabel(),
                                  () => _showThemePicker(context)),
                              _item(context, 'ℹ️', 'Sobre o app',
                                  AppInfo.version, () => _showAbout(context)),
                              _item(
                                  context,
                                  '📄',
                                  'Termos de Uso',
                                  '',
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LegalScreen(
                                              isPrivacy: false)))),
                              _item(
                                  context,
                                  '🔏',
                                  'Privacidade',
                                  '',
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LegalScreen(
                                              isPrivacy: true)))),
                              _item(context, '📦', 'Exportar meus dados',
                                  'LGPD · portabilidade', () {
                                _exportMyData(context);
                              }),
                              _item(context, '🗑️', 'Excluir minha conta',
                                  'LGPD · irreversível', () {
                                _deleteMyAccount(context);
                              }),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await AuthService.signOut();
                                    if (context.mounted)
                                      Navigator.pushReplacementNamed(
                                          context, Routes.login);
                                  },
                                  icon: const Icon(Icons.logout_rounded,
                                      color: AppColors.error),
                                  label: const Text('Sair da conta',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      side: const BorderSide(
                                          color: AppColors.error, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14))),
                                )),
                            const SizedBox(height: 100),
                          ]))),
                ]);
              },
            ),
    );
  }

  static Future<void> _exportMyData(BuildContext context) async {
    try {
      snack(context, 'Preparando exportação…');
      final data = await FS.exportMyData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await Share.share(json, subject: 'Meus dados — ${AppInfo.name}');
      if (context.mounted) {
        snack(context, 'Dados exportados. Escolha onde salvar/compartilhar.',
            bg: AppColors.secondary);
      }
    } catch (e) {
      if (context.mounted) {
        snack(context, 'Não foi possível exportar: $e', bg: AppColors.error);
      }
    }
  }

  static Future<void> _deleteMyAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
            'Isso apaga seu perfil e remove o acesso ao app. '
            'Ação irreversível. Pedidos antigos podem permanecer anonimizados no histórico operacional.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FS.deleteMyAccountData();
      await AuthService.deleteAccount();
      if (context.mounted) {
        snack(context, 'Conta excluída.', bg: AppColors.secondary);
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } on AuthFailure catch (e) {
      if (context.mounted) snack(context, e.message, bg: AppColors.error);
    } catch (e) {
      if (context.mounted) {
        snack(context, 'Erro ao excluir: $e', bg: AppColors.error);
      }
    }
  }

  Widget _section(String title, List<Widget> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight))),
        Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: AppDecorations.card(r: 16),
            child: Column(children: items)),
      ]);

  Widget _item(BuildContext ctx, String icon, String title, String sub,
          VoidCallback onTap) =>
      ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 20)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textDark)),
        subtitle: sub.isNotEmpty
            ? Text(sub,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textLight))
            : null,
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        onTap: onTap,
      );

  void _editProfile(BuildContext ctx, UserModel? user) {
    final nameCtrl = TextEditingController(text: user?.name);
    final cityCtrl = TextEditingController(text: user?.city);
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const SheetHandle(),
                const SizedBox(height: 16),
                const Text('Editar perfil',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 10),
                TextFormField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Cidade',
                        prefixIcon: Icon(Icons.location_city_outlined))),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          await FS.updateUser(
                              {'name': nameCtrl.text, 'city': cityCtrl.text});
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            snack(ctx, '✅ Perfil atualizado!',
                                bg: AppColors.secondary);
                          }
                        },
                        child: const Text('Salvar alterações'))),
              ]),
            ));
  }

  void _showBadges(BuildContext ctx) => showModalBottomSheet(
      context: ctx,
      builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              const Text('🏆 Suas Conquistas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final b in [
                  ['⭐', 'Iniciante', '0 XP'],
                  ['🥉', 'Bronze', '500 XP'],
                  ['🥈', 'Prata', '1000 XP'],
                  ['🥇', 'Ouro', '2000 XP'],
                  ['💎', 'Diamante', '4000 XP']
                ])
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppDecorations.card(r: 16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(b[0], style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(b[1],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                        Text(b[2],
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textLight))
                      ])),
              ]),
            ]),
          ));

  void _showAbout(BuildContext ctx) => showAboutDialog(
        context: ctx,
        applicationName: AppInfo.name,
        applicationVersion: AppInfo.version,
        applicationIcon:
            SvgPicture.asset(AppAssets.logoMark, width: 48, height: 48),
        children: [
          const SizedBox(height: 12),
          const Text(AppInfo.slogan,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMedium, height: 1.5)),
          const SizedBox(height: 12),
          const Text(
              'Um marketplace completo de serviços, saúde, entregas e mercado, tudo em um só app.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      );

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    if (context.mounted)
      snack(context, 'Enviando foto...', bg: AppColors.primary);
    final url = await FS.uploadUserPhoto(await picked.readAsBytes(), picked.name);
    if (context.mounted) {
      snack(
          context,
          url != null
              ? '✅ Foto atualizada!'
              : 'Falha ao enviar foto. Tente novamente.',
          bg: url != null ? AppColors.secondary : AppColors.error);
    }
  }

  void _changePassword(BuildContext context, UserModel? user) {
    if (user == null || user.email.isEmpty) {
      snack(context, 'E-mail não disponível para redefinição.');
      return;
    }
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Alterar senha'),
              content: Text(
                  'Enviaremos um link de redefinição de senha para ${user.email}. Deseja continuar?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await AuthService.resetPassword(user.email);
                      if (context.mounted)
                        snack(context, '✅ Link enviado para seu e-mail!',
                            bg: AppColors.secondary);
                    },
                    child: const Text('Enviar')),
              ],
            ));
  }

  String _themeLabel() => switch (ThemeController.instance.mode.value) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Escuro',
        ThemeMode.system => 'Automático (sistema)',
      };

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              const SheetHandle(),
              const SizedBox(height: 8),
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Escolha o tema',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800))),
              _themeOption(context, ThemeMode.light, '☀️', 'Claro'),
              _themeOption(context, ThemeMode.dark, '🌙', 'Escuro'),
              _themeOption(
                  context, ThemeMode.system, '⚙️', 'Automático (sistema)'),
              const SizedBox(height: 16),
            ])));
  }

  Widget _themeOption(
      BuildContext context, ThemeMode m, String icon, String label) {
    final selected = ThemeController.instance.mode.value == m;
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary)
          : null,
      onTap: () async {
        await ThemeController.instance.set(m);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final _demo = [
    NotifModel(
        id: '1',
        userId: 'u',
        title: '🔧 Profissional confirmado!',
        body: 'Carlos Silva aceitou seu pedido de serviço.',
        type: 'order',
        read: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
    NotifModel(
        id: '2',
        userId: 'u',
        title: '💳 Pagamento confirmado',
        body: 'PIX de R\$ 120,00 recebido com sucesso.',
        type: 'payment',
        read: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    NotifModel(
        id: '3',
        userId: 'u',
        title: '💬 Nova mensagem',
        body: 'Carlos: "Estarei aí em 30 minutos!"',
        type: 'chat',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    NotifModel(
        id: '4',
        userId: 'u',
        title: '⭐ Avalie seu serviço',
        body: 'Como foi o serviço de Ana Souza?',
        type: 'review',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: StreamBuilder<List<NotifModel>>(
        stream: uid != null ? FS.notifStream() : const Stream.empty(),
        builder: (_, snap) {
          final notifs = DemoData.orEmpty(snap.data, _demo);
          if (notifs.isEmpty)
            return const EmptyState(
                emoji: '🔔',
                title: 'Sem notificações',
                subtitle: 'Você está em dia!');
          return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = notifs[i];
                return GestureDetector(
                    onTap: () {
                      if (!n.read && uid != null) FS.markNotifRead(n.id);
                    },
                    child: Container(
                      decoration: AppDecorations.card(
                          r: 14,
                          color: n.read
                              ? null
                              : AppColors.primary.withValues(alpha: 0.05)),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: _nColor(n.type).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12)),
                                alignment: Alignment.center,
                                child: Text(n.icon,
                                    style: const TextStyle(fontSize: 22))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(n.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.textDark))),
                                    if (!n.read)
                                      Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle))
                                  ]),
                                  const SizedBox(height: 3),
                                  Text(n.body,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMedium,
                                          height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(fmtDate(n.createdAt),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textLight)),
                                ])),
                          ]),
                    ));
              });
        },
      ),
    );
  }

  Color _nColor(String type) {
    switch (type) {
      case 'payment':
        return AppColors.secondary;
      case 'chat':
        return AppColors.primary;
      case 'review':
        return AppColors.warning;
      case 'promo':
        return AppColors.purple;
      default:
        return AppColors.primary;
    }
  }
}

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final String? providerId, providerName;
  const ReviewScreen(
      {super.key, required this.orderId, this.providerId, this.providerName});
  @override
  State<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewScreen> {
  int _stars = 5;
  final _ctrl = TextEditingController();
  final _tags = <String>{};
  bool _loading = false;
  static const _tagOptions = [
    'Pontual',
    'Profissional',
    'Ótimo serviço',
    'Comunicativo',
    'Cuidadoso',
    'Organizado',
    'Eficiente',
    'Recomendo!'
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Avaliar serviço')),
        body: LoadingOverlay(
            loading: _loading,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text('Como foi o serviço?',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                      textAlign: TextAlign.center),
                  if (widget.providerName != null) ...[
                    const SizedBox(height: 8),
                    Text('Profissional: ${widget.providerName}',
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 14))
                  ],
                  const SizedBox(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          5,
                          (i) => GestureDetector(
                              onTap: () => setState(() => _stars = i + 1),
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                      i < _stars
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 44,
                                      color: i < _stars
                                          ? AppColors.warning
                                          : AppColors.border))))),
                  const SizedBox(height: 8),
                  Text(_starsLabel(_stars),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('O que você mais gostou?',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14))),
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagOptions.map((t) {
                        final sel = _tags.contains(t);
                        return GestureDetector(
                            onTap: () => setState(
                                () => sel ? _tags.remove(t) : _tags.add(t)),
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.border)),
                                child: Text(t,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? Colors.white
                                            : AppColors.textDark))));
                      }).toList()),
                  const SizedBox(height: 20),
                  TextFormField(
                      controller: _ctrl,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: const InputDecoration(
                          hintText: 'Conte sobre sua experiência...',
                          alignLabelWithHint: true)),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('Enviar avaliação ⭐',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)))),
                ]))),
      );

  Future<void> _submit() async {
    setState(() => _loading = true);
    final user = await FS.getUser();
    final review = ReviewModel(
        id: '',
        orderId: widget.orderId,
        clientId: AuthService.uid ?? '',
        clientName: user?.name ?? 'Anônimo',
        clientPhoto: user?.photoUrl,
        providerId: widget.providerId,
        stars: _stars,
        comment: _ctrl.text,
        tags: _tags.toList(),
        createdAt: DateTime.now());
    await FS.saveReview(review);
    if (mounted) {
      Navigator.pop(context);
      snack(context, '✅ Avaliação enviada! Obrigado!', bg: AppColors.secondary);
    }
  }

  String _starsLabel(int s) {
    switch (s) {
      case 1:
        return '😞 Muito ruim';
      case 2:
        return '😐 Ruim';
      case 3:
        return '😊 Regular';
      case 4:
        return '😄 Bom';
      default:
        return '🤩 Excelente!';
    }
  }
}

// AdminScreen foi movida para features/admin/admin_screen.dart (painel completo)
