import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/chat_nav.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../core/security/order_policy.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';
import '../tia/tia_screen.dart';

// ─────────────────────────────────────────────────────────────
// PROVIDER HOME SCREEN (Vol.3: Perfil do Profissional — Serviços,
// Agenda). Painel onde o prestador vê e responde aos pedidos
// recebidos, fechando o ciclo Cliente → Pedido → Prestador → GPS.
// ─────────────────────────────────────────────────────────────
class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});
  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHomeScreen> {
  StreamSubscription<List<OrderModel>>? _newOrdersSub;
  int _lastPendingCount = -1; // -1 = primeira carga (não alertar)
  final _ratingsKey = GlobalKey();
  static final _demoPending = [
    OrderModel(
        id: 'p1',
        clientId: 'c1',
        category: 'eletricista',
        title: 'Instalação de chuveiro',
        description: 'Preciso trocar o chuveiro elétrico do banheiro.',
        address: 'Rua Augusta, 500',
        price: 90,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12))),
  ];

  @override
  void initState() {
    super.initState();
    // Alerta estilo iFood: quando chega pedido novo, vibra e avisa.
    _newOrdersSub = c360Stream(() => FS.providerOrdersStream(
        statuses: const [OrderStatus.pending])).listen((orders) {
      if (!mounted) return;
      if (_lastPendingCount >= 0 && orders.length > _lastPendingCount) {
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        snack(context, 'Novo pedido recebido!', bg: AppColors.secondary);
      }
      _lastPendingCount = orders.length;
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _newOrdersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const C360PageBanner(
              icon: Icons.work_rounded,
              title: 'Meus Serviços',
              subtitle:
                  'Gerencie seus serviços, agenda, pedidos e recebimentos.',
            ),
            const SizedBox(height: 14),
            StreamBuilder<ProviderModel?>(
              stream: c360Stream(FS.myProviderStream),
              builder: (_, snap) {
                final prov = snap.data;
                final online = prov?.active ?? false;
                return C360Card(
                  child: prov == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Você ainda não é prestador',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'Cadastre seu serviço para aparecer nas buscas da região.',
                              style: TextStyle(color: AppColors.textMedium),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, Routes.providerOnboarding),
                              child: const Text('Configurar meus serviços'),
                            ),
                          ],
                        )
                      : Row(children: [
                          C360Avatar(
                              name: prov.name,
                              url: prov.photoUrl,
                              size: 64,
                              verified: prov.verified),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prov.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                Text(
                                  prov.categories.isEmpty
                                      ? 'Profissional'
                                      : prov.categories
                                          .map((id) =>
                                              Categories.byId(id)?.name ?? id)
                                          .join(', '),
                                  style: const TextStyle(
                                      color: AppColors.textLight, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                C360Rating(
                                    rating: prov.rating,
                                    reviews: prov.totalReviews),
                              ],
                            ),
                          ),
                          Column(children: [
                            Text(online ? 'Online' : 'Offline',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: online
                                        ? AppColors.primary
                                        : AppColors.textLight)),
                            Switch(
                              value: online,
                              onChanged: (v) async {
                                await FS.setProviderOnline(prov.id, v);
                                if (context.mounted) {
                                  snack(
                                      context,
                                      v
                                          ? 'Online. Você aparece nas buscas.'
                                          : 'Offline. Você saiu das buscas.');
                                }
                              },
                            ),
                          ]),
                        ]),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: AppColors.primarySoft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              title: const Text('Tia Carajás IA para o seu perfil',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Ajuda a descrever serviços e responder pedidos. Nada é publicado sem a sua confirmação.'),
              onTap: () => c360Open(
                context,
                route: Routes.aiAssistant,
                page: const TiaCentralScreen(audience: 'provider'),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<OrderModel>>(
              stream: c360Stream(FS.providerOrdersStream),
              builder: (_, snap) {
                final orders = snap.data ?? const <OrderModel>[];
                final now = DateTime.now();
                final pending =
                    orders.where((o) => o.status == OrderStatus.pending).length;
                final running = orders
                    .where((o) =>
                        o.status == OrderStatus.inProgress ||
                        o.status == OrderStatus.accepted)
                    .length;
                final done = orders
                    .where((o) => o.status == OrderStatus.completed)
                    .length;
                final month = orders.where((o) =>
                    o.status == OrderStatus.completed &&
                    o.createdAt.year == now.year &&
                    o.createdAt.month == now.month);
                final revenue = month.fold<double>(
                    0, (s, o) => s + (o.price ?? 0) * (1 - AppConst.commission));
                final days = List<double>.generate(14, (i) {
                  final d = DateTime(now.year, now.month, now.day - 13 + i);
                  return orders
                      .where((o) =>
                          o.status == OrderStatus.completed &&
                          o.createdAt.year == d.year &&
                          o.createdAt.month == d.month &&
                          o.createdAt.day == d.day)
                      .fold<double>(
                          0,
                          (s, o) =>
                              s + (o.price ?? 0) * (1 - AppConst.commission));
                });
                return Column(children: [
                  LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth > 900 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: cols == 4 ? 2.5 : 2.1,
                      children: [
                        C360KpiCard(
                          icon: Icons.inbox_rounded,
                          tint: AppColors.primary,
                          label: 'Solicitações',
                          value: '$pending',
                        ),
                        C360KpiCard(
                          icon: Icons.handyman_rounded,
                          tint: AppColors.warning,
                          label: 'Em Andamento',
                          value: '$running',
                        ),
                        C360KpiCard(
                          icon: Icons.check_circle_outline_rounded,
                          tint: AppColors.success,
                          label: 'Concluídos',
                          value: '$done',
                        ),
                        C360KpiCard(
                          icon: Icons.payments_rounded,
                          tint: AppColors.primary,
                          label: 'Faturamento (mês)',
                          value: PaySvc.fmt(revenue),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  _actions(),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 980;
                    final left = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const C360SectionHeader(title: 'Próximos Atendimentos'),
                        const SizedBox(height: 8),
                        _OrderList(
                          shrinkWrap: true,
                          statuses: const [
                            OrderStatus.accepted,
                            OrderStatus.inProgress
                          ],
                          demo: const [],
                          emptyEmoji: '📅',
                          emptyTitle: 'Nenhum atendimento marcado',
                          emptySub: 'Pedidos aceitos aparecem aqui',
                        ),
                        const SizedBox(height: 16),
                        const C360SectionHeader(title: 'Solicitações Recentes'),
                        const SizedBox(height: 8),
                        _OrderList(
                          shrinkWrap: true,
                          statuses: const [OrderStatus.pending],
                          demo: _demoPending,
                          emptyEmoji: '📭',
                          emptyTitle: 'Sem pedidos novos',
                          emptySub: 'Novas solicitações aparecerão aqui',
                        ),
                      ],
                    );
                    final right = Column(children: [
                      C360Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meu Desempenho',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Últimos 14 dias · ${PaySvc.fmt(revenue)} no mês',
                                style: const TextStyle(
                                    color: AppColors.textLight, fontSize: 12)),
                            const SizedBox(height: 8),
                            C360Sparkline(
                              values: days,
                              caption:
                                  'Valores líquidos, já descontada a comissão da plataforma.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      C360Card(
                        key: _ratingsKey,
                        child: _ratings(),
                      ),
                    ]);
                    if (!wide) {
                      return Column(children: [
                        left,
                        const SizedBox(height: 12),
                        right,
                      ]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  }),
                ]);
              },
            ),
          ],
        ),
      );

  Widget _actions() {
    final items = <(IconData, String, VoidCallback)>[
      (
        Icons.tune_rounded,
        'Configurar\nMeus Serviços',
        () => Navigator.pushNamed(context, Routes.providerOnboarding)
      ),
      (
        Icons.calendar_month_rounded,
        'Gerenciar\nAgenda',
        () => Navigator.pushNamed(context, Routes.bookings)
      ),
      (
        Icons.request_quote_rounded,
        'Orçamentos\ne Propostas',
        () => Navigator.pushNamed(context, Routes.resolveOpportunities)
      ),
      (
        Icons.star_outline_rounded,
        'Clientes\ne Avaliações',
        () {
          final ctx = _ratingsKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx,
                duration: const Duration(milliseconds: 300));
          }
        }
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Financeiro\ne Recebimentos',
        () => Navigator.pushNamed(context, Routes.wallet)
      ),
      (
        Icons.campaign_outlined,
        'Divulgar\nMeu Perfil',
        () => SharePlus.instance.share(ShareParams(
            text:
                'Meu perfil no Carajás 360. Encontre serviços locais em Canaã dos Carajás.'))
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 800 ? 6 : 3;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
        children: [
          for (final item in items)
            Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: item.$3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$1, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(item.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _ratings() {
    return StreamBuilder<ProviderModel?>(
      stream: c360Stream(FS.myProviderStream),
      builder: (_, snap) {
        final prov = snap.data;
        if (prov == null) {
          return const Text(
            'As avaliações dos clientes aparecem depois que o perfil de prestador estiver ativo.',
            style: TextStyle(color: AppColors.textLight, height: 1.35),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avaliação dos Clientes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(prov.rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            Text('${prov.totalReviews} avaliações',
                style: const TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 8),
            const Text(
              'A distribuição por estrelas usa as avaliações já registradas no perfil.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: StreamBuilder<List<ReviewModel>>(
                stream: c360Stream(() => FS.reviewsForProvider(prov.id)),
                builder: (_, reviewSnap) {
                  final list = reviewSnap.data ?? const <ReviewModel>[];
                  if (list.isEmpty) {
                    return const Text('Nenhuma avaliação detalhada ainda.',
                        style: TextStyle(color: AppColors.textMedium));
                  }
                  final counts = List<int>.filled(5, 0);
                  for (final r in list) {
                    counts[(r.stars.clamp(1, 5)) - 1]++;
                  }
                  return Column(children: [
                    for (var stars = 5; stars >= 1; stars--)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Text('$stars'),
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.yellowDeep),
                          const SizedBox(width: 6),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: counts[stars - 1] / list.length,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.primary,
                              backgroundColor: AppColors.surfaceMuted,
                            ),
                          ),
                        ]),
                      ),
                  ]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderStatus> statuses;
  final List<OrderModel> demo;
  final String emptyEmoji, emptyTitle, emptySub;
  final bool shrinkWrap;
  const _OrderList(
      {required this.statuses,
      required this.demo,
      required this.emptyEmoji,
      required this.emptyTitle,
      required this.emptySub,
      this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<OrderModel>>(
        stream: c360Stream(() => FS.providerOrdersStream(statuses: statuses)),
        builder: (_, snap) {
          final orders = DemoData.orEmpty(
              snap.data,
              statuses.contains(OrderStatus.pending) ? demo : <OrderModel>[]);
          if (orders.isEmpty)
            return EmptyState(
                emoji: emptyEmoji, title: emptyTitle, subtitle: emptySub);
          return ListView.builder(
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
            padding: EdgeInsets.all(shrinkWrap ? 0 : 16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              final cat = Categories.byId(o.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppDecorations.card(r: 16),
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: (cat?.color ?? AppColors.primary)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text(cat?.emoji ?? '🔧',
                                style: const TextStyle(fontSize: 20))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Text(o.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14))),
                                if (o.urgent)
                                  const AppTag('🚨 Urgente',
                                      bg: Color(0xFFFFEBEE),
                                      fg: AppColors.error),
                              ]),
                              Text(fmtDate(o.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight)),
                            ])),
                        if (o.price != null)
                          Text(PaySvc.fmt(o.price!),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.secondary)),
                      ]),
                      const SizedBox(height: 8),
                      Text(o.description,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium,
                              height: 1.4)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(o.address,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textLight),
                                overflow: TextOverflow.ellipsis))
                      ]),
                      if (o.status == OrderStatus.accepted ||
                          o.status == OrderStatus.inProgress) ...[
                        const SizedBox(height: 6),
                        AppTag(o.statusLabel,
                            bg: o.status == OrderStatus.inProgress
                                ? const Color(0xFFE1F5FE)
                                : const Color(0xFFE3F0FF),
                            fg: o.status == OrderStatus.inProgress
                                ? AppColors.info
                                : AppColors.primary),
                      ],
                      const SizedBox(height: 12),
                      if (o.status == OrderStatus.pending)
                        _PendingActions(order: o),
                      if (o.status == OrderStatus.accepted)
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await FS.startOrder(o.id);
                                if (context.mounted)
                                  Navigator.pushNamed(context, Routes.gps,
                                      arguments: {
                                        'ctx': 'servico',
                                        'orderId': o.id
                                      });
                              },
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 18),
                              label: const Text('Iniciar atendimento',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10)),
                            )),
                      if (o.status == OrderStatus.inProgress)
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed: () => ChatNav.open(context,
                                      otherUserId: o.clientId,
                                      otherName: 'Cliente'),
                                  icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16),
                                  label: const Text('Chat',
                                      style: TextStyle(fontSize: 12)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await FS.completeOrder(o.id);
                                      if (context.mounted) {
                                        snack(context, '✅ Serviço concluído!',
                                            bg: AppColors.secondary);
                                      }
                                    } on CloudCallException catch (e) {
                                      if (context.mounted) {
                                        snack(context, e.message,
                                            bg: AppColors.error);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10)),
                                  child: const Text('Concluir',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)))),
                        ]),
                    ]),
              );
            },
          );
        },
      );
}

// ─────────────────────────────────────────────────────────────
// PROVIDER ONBOARDING SCREEN (Vol.3: Cadastro de Profissionais —
// foto, documento, selfie, certificados, áreas atendidas).
// Aberta logo após o cadastro básico, quando o tipo é provider.
// Todos os arquivos são opcionais aqui para não travar o fluxo,
// mas o admin só aprova (FS.approveProvider) quem enviou os
// documentos — a UI deixa isso claro para o prestador.
// ─────────────────────────────────────────────────────────────
class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});
  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingState();
}

class _ProviderOnboardingState extends State<ProviderOnboardingScreen> {
  XFile? _photo, _document, _selfie;
  Uint8List? _photoBytes, _documentBytes, _selfieBytes;
  final _certCtrl = TextEditingController();
  final _areasCtrl = TextEditingController();
  final _certificates = <String>[];
  bool _loading = false;

  @override
  void dispose() {
    _certCtrl.dispose();
    _areasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(void Function(XFile, Uint8List) onPicked,
      {required ImageSource source}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1600);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => onPicked(picked, bytes));
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      String? photoUrl, documentUrl, selfieUrl;
      if (_photo != null && _photoBytes != null) {
        photoUrl = await FS.uploadProviderFile(
            _photoBytes!, _photo!.name, 'photo');
      }
      if (_document != null && _documentBytes != null) {
        documentUrl = await FS.uploadProviderFile(
            _documentBytes!, _document!.name, 'document');
      }
      if (_selfie != null && _selfieBytes != null) {
        selfieUrl = await FS.uploadProviderFile(
            _selfieBytes!, _selfie!.name, 'selfie');
      }

      final areas = _areasCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await FS.updateProviderDocuments(
        photoUrl: photoUrl,
        documentUrl: documentUrl,
        selfieUrl: selfieUrl,
        certificates: _certificates,
        serviceAreas: areas,
      );

      if (mounted) {
        snack(context,
            '✅ Documentos enviados! Aguarde a aprovação do administrador.',
            bg: AppColors.secondary);
        Navigator.pushReplacementNamed(context, Routes.main);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Complete seu cadastro'),
            automaticallyImplyLeading: false),
        body: LoadingOverlay(
            loading: _loading,
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(
                      decoration:
                          AppDecorations.gradient(AppGradients.primary, r: 18),
                      padding: const EdgeInsets.all(18),
                      child: const Row(children: [
                        Icon(Icons.verified_user_outlined,
                            color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'Envie seus documentos para ativar seu perfil de prestador e começar a receber pedidos.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.4))),
                      ])),
                  const SizedBox(height: 20),
                  _uploadTile(
                      '📷',
                      'Foto de perfil',
                      'Aparece para os clientes na busca',
                      _photoBytes,
                      () => _pickImage((f, b) {
                            _photo = f;
                            _photoBytes = b;
                          }, source: ImageSource.gallery)),
                  _uploadTile(
                      '🪪',
                      'Documento de identidade',
                      'RG, CNH ou CPF (foto legível)',
                      _documentBytes,
                      () => _pickImage((f, b) {
                            _document = f;
                            _documentBytes = b;
                          }, source: ImageSource.camera)),
                  _uploadTile(
                      '🤳',
                      'Selfie de validação',
                      'Segurando o documento ao lado do rosto',
                      _selfieBytes,
                      () => _pickImage((f, b) {
                            _selfie = f;
                            _selfieBytes = b;
                          }, source: ImageSource.camera)),
                  const SizedBox(height: 8),
                  Container(
                      decoration: AppDecorations.card(r: 16),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎓 Certificados (opcional)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                  child: TextFormField(
                                      controller: _certCtrl,
                                      decoration: const InputDecoration(
                                          hintText:
                                              'Ex: Curso técnico em elétrica'))),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                  onPressed: () {
                                    if (_certCtrl.text.trim().isNotEmpty)
                                      setState(() {
                                        _certificates
                                            .add(_certCtrl.text.trim());
                                        _certCtrl.clear();
                                      });
                                  },
                                  child: const Icon(Icons.add, size: 18)),
                            ]),
                            if (_certificates.isNotEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _certificates
                                          .map((c) => Chip(
                                              label: Text(c,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              onDeleted: () => setState(() =>
                                                  _certificates.remove(c))))
                                          .toList())),
                          ])),
                  const SizedBox(height: 12),
                  Container(
                      decoration: AppDecorations.card(r: 16),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📍 Áreas atendidas',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text(
                                'Bairros ou cidades, separados por vírgula',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textLight)),
                            const SizedBox(height: 8),
                            TextFormField(
                                controller: _areasCtrl,
                                decoration: const InputDecoration(
                                    hintText:
                                        'Ex: Centro, Zona Sul, Vila Mariana')),
                          ])),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: const Text('Enviar para aprovação',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      )),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, Routes.main),
                      child: const Text('Completar depois',
                          style: TextStyle(color: AppColors.textLight))),
                  const SizedBox(height: 30),
                ]))),
      );

  Widget _uploadTile(String icon, String title, String subtitle,
          Uint8List? bytes, VoidCallback onTap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.card(r: 16),
        child: ListTile(
          leading: bytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(bytes,
                      width: 44, height: 44, fit: BoxFit.cover))
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 20))),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(bytes != null ? '✅ Selecionado' : subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: bytes != null
                      ? AppColors.secondary
                      : AppColors.textLight)),
          trailing: TextButton(
              onPressed: onTap,
              child: Text(bytes != null ? 'Trocar' : 'Enviar')),
        ),
      );
}

// ── Ações do pedido pendente com timer de expiração (estilo iFood) ──
class _PendingActions extends StatefulWidget {
  final OrderModel order;
  const _PendingActions({required this.order});

  @override
  State<_PendingActions> createState() => _PendingActionsState();
}

class _PendingActionsState extends State<_PendingActions> {
  static const _window = Duration(minutes: 15);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Duration get _left {
    final elapsed = DateTime.now().difference(widget.order.createdAt);
    final left = _window - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final expired = left == Duration.zero;
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = left.inMinutes < 3;
    return Column(children: [
      // Barra de tempo restante para responder
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: expired
              ? const Color(0xFFF5F5F5)
              : (urgent ? const Color(0xFFFFEBEE) : const Color(0xFFE3F0FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 15,
              color: expired
                  ? AppColors.textLight
                  : (urgent ? AppColors.error : AppColors.primary)),
          const SizedBox(width: 6),
          Text(expired ? 'Tempo esgotado' : 'Responda em $mm:$ss',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: expired
                      ? AppColors.textLight
                      : (urgent ? AppColors.error : AppColors.primary))),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
            child: OutlinedButton(
                onPressed: expired
                    ? null
                    : () async {
                        await FS.declineOrder(widget.order.id);
                      },
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                        color: expired ? AppColors.border : AppColors.error)),
                child: Text('Recusar',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            expired ? AppColors.textLight : AppColors.error)))),
        const SizedBox(width: 8),
        Expanded(
            child: ElevatedButton(
                onPressed: expired
                    ? null
                    : () async {
                        await FS.acceptOrder(widget.order.id);
                        if (context.mounted)
                          snack(context, '✅ Pedido aceito!',
                              bg: AppColors.secondary);
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Text('Aceitar',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))),
      ]),
    ]);
  }
}

// ── Resumo semanal de ganhos com gráfico de barras (Flutter puro) ──
class WeeklyEarnings extends StatelessWidget {
  const WeeklyEarnings({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<OrderModel>>(
        stream:
            FS.providerOrdersStream(statuses: const [OrderStatus.completed]),
        builder: (_, snap) {
          final now = DateTime.now();
          final days = List.generate(
              7, (i) => DateTime(now.year, now.month, now.day - 6 + i));
          final totals = days
              .map((d) => (snap.data ?? const <OrderModel>[])
                  .where((o) =>
                      o.createdAt.year == d.year &&
                      o.createdAt.month == d.month &&
                      o.createdAt.day == d.day)
                  .fold<double>(0,
                      (s, o) => s + (o.price ?? 0) * (1 - AppConst.commission)))
              .toList();
          final max = totals.fold<double>(0, (a, b) => a > b ? a : b);
          final week = totals.fold<double>(0, (a, b) => a + b);
          const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
          String lbl(DateTime d) => labels[(d.weekday - 1) % 7];
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.card(r: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Ganhos da semana',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(PaySvc.fmt(week),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.secondary)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                  height: 68,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == 6;
                      final h = max <= 0
                          ? 4.0
                          : (totals[i] / max * 48).clamp(4.0, 48.0);
                      return Expanded(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? AppColors.secondary
                                        : AppColors.primary.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(4),
                                  )),
                              const SizedBox(height: 5),
                              Text(lbl(days[i]),
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isToday
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isToday
                                          ? AppColors.secondary
                                          : AppColors.textLight)),
                            ]),
                      ));
                    }),
                  )),
            ]),
          );
        },
      );
}
