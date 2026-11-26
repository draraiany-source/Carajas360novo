import 'package:flutter/material.dart';
import '../../core/auth/access_control.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/catalog/service_catalog.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/official_icon.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/chat_nav.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../tia/order_detail_panel.dart';
import '../../shared/widgets/widgets.dart';
import '../resolve/resolve_screen.dart';

// ─────────────────────────────────────────────────────────────
// FAVORITES SCREEN (Vol.3/Vol.5: coleção favorites)
// ─────────────────────────────────────────────────────────────
class FavoritesScreen extends StatelessWidget {
  final bool embedded;
  const FavoritesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      if (embedded)
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: C360PageBanner(
            icon: Icons.favorite_rounded,
            title: 'Favoritos',
            subtitle: 'Profissionais e serviços que você salvou.',
          ),
        ),
      Expanded(child: _body(context)),
    ]);
    if (embedded) {
      return ColoredBox(color: AppColors.background, child: body);
    }
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textDark,
          title: const Text('Favoritos'),
        ),
        body: body);
  }

  Widget _body(BuildContext context) => StreamBuilder<List<ProviderModel>>(
          stream: c360Stream(FS.favoritesStream),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (_, __) => const ShimCard());
            }
            final favs = snap.data ?? [];
            if (favs.isEmpty) {
              return const EmptyState(
                  emoji: '⭐',
                  title: 'Nenhum favorito ainda',
                  subtitle:
                      'Toque no ícone de estrela em um profissional para salvá-lo aqui',
                  asset: AppAssets.ilListaVazia);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              itemBuilder: (_, i) {
                final p = favs[i];
                final profession = p.categories.isNotEmpty
                    ? ServiceCatalog.professionById(p.categories.first)
                    : null;
                final catName = profession?.name ??
                    (p.categories.isNotEmpty
                        ? p.categories.first
                        : 'Profissional');
                return Dismissible(
                  key: Key(p.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16)),
                    child:
                        const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (_) => FS.toggleFavorite(p.id),
                  child: ProvCard(
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
                    emblem: profession == null
                        ? null
                        : OfficialIcon(
                            label: profession.name,
                            assetPath: profession.asset256,
                            pendingArt: profession.asset == null,
                          ),
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
                  ),
                );
              },
            );
          },
        );
}

// Nota: o botão de favoritar já está embutido no ProvCard (via parâmetro providerId).

// ─────────────────────────────────────────────────────────────
// MY ORDERS / HISTORY SCREEN (Vol.3: Perfil do Cliente – Pedidos)
// ─────────────────────────────────────────────────────────────
class MyOrdersScreen extends StatefulWidget {
  final bool embedded;
  const MyOrdersScreen({super.key, this.embedded = false});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrdersScreen> {
  OrderStatus? _filter;
  int _segment = 0;
  int? _periodDays;

  static final _demo = [
    OrderModel(
        id: 'd1',
        clientId: 'me',
        category: 'eletricista',
        title: 'Instalação de tomadas',
        description: 'Instalar 4 tomadas na sala',
        address: 'Rua das Flores, 123',
        price: 180,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 2))),
    OrderModel(
        id: 'd2',
        clientId: 'me',
        category: 'diarista',
        title: 'Limpeza semanal',
        description: 'Limpeza completa do apartamento',
        address: 'Av. Paulista, 1000',
        price: 150,
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(hours: 3))),
    OrderModel(
        id: 'd3',
        clientId: 'me',
        category: 'medico',
        title: 'Consulta clínico geral',
        description: 'Consulta de rotina',
        address: 'Online',
        price: 120,
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
  ];

  @override
  Widget build(BuildContext context) {
    final content = Column(children: [
      Expanded(
        child: StreamBuilder<List<OrderModel>>(
          stream: c360Stream(FS.orderHistoryStream),
          builder: (_, snap) {
            final all = DemoData.orEmpty(snap.data, _demo);
            final now = DateTime.now();
            final ranged = _periodDays == null
                ? all
                : all
                    .where((o) => now.difference(o.createdAt).inDays <= _periodDays!)
                    .toList();
            final visible = ranged.where((o) {
              if (_filter == null) return true;
              if (_filter == OrderStatus.inProgress) {
                return o.status == OrderStatus.inProgress ||
                    o.status == OrderStatus.accepted;
              }
              return o.status == _filter;
            }).toList();
            final running = ranged
                .where((o) =>
                    o.status == OrderStatus.inProgress ||
                    o.status == OrderStatus.accepted)
                .length;
            final done =
                ranged.where((o) => o.status == OrderStatus.completed).length;
            final cancelled =
                ranged.where((o) => o.status == OrderStatus.cancelled).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const C360PageBanner(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Meus Pedidos',
                  subtitle: 'Acompanhe, gerencie e avalie todos os seus serviços.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : 2;
                  final cards = [
                    C360KpiCard(
                      icon: Icons.shopping_bag_outlined,
                      tint: AppColors.primary,
                      label: 'Pedidos Totais',
                      value: '${ranged.length}',
                    ),
                    C360KpiCard(
                      icon: Icons.timelapse_rounded,
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
                      icon: Icons.cancel_outlined,
                      tint: AppColors.error,
                      label: 'Cancelados',
                      value: '$cancelled',
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: cols == 4 ? 2.6 : 2.2,
                    children: cards,
                  );
                }),
                const SizedBox(height: 14),
                Row(children: [
                  C360FilterChip(
                    label: 'Meus Pedidos',
                    icon: Icons.list_alt_rounded,
                    selected: _segment == 0,
                    onTap: () => setState(() => _segment = 0),
                  ),
                  C360FilterChip(
                    label: 'Minhas Solicitações',
                    icon: Icons.bolt_rounded,
                    selected: _segment == 1,
                    onTap: () => setState(() => _segment = 1),
                  ),
                ]),
                const SizedBox(height: 8),
                if (_segment == 1)
                  const SizedBox(
                    height: 460,
                    child: MyResolveScreen(embedded: true),
                  )
                else ...[
                  Row(children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          C360FilterChip(
                            label: 'Todos (${ranged.length})',
                            selected: _filter == null,
                            onTap: () => setState(() => _filter = null),
                          ),
                          C360FilterChip(
                            label: 'Em Andamento ($running)',
                            icon: Icons.timelapse_rounded,
                            selected: _filter == OrderStatus.inProgress,
                            onTap: () => setState(
                                () => _filter = OrderStatus.inProgress),
                          ),
                          C360FilterChip(
                            label: 'Concluídos ($done)',
                            icon: Icons.check_circle_outline_rounded,
                            selected: _filter == OrderStatus.completed,
                            onTap: () =>
                                setState(() => _filter = OrderStatus.completed),
                          ),
                          C360FilterChip(
                            label: 'Cancelados ($cancelled)',
                            icon: Icons.cancel_outlined,
                            selected: _filter == OrderStatus.cancelled,
                            onTap: () =>
                                setState(() => _filter = OrderStatus.cancelled),
                          ),
                        ]),
                      ),
                    ),
                    PopupMenuButton<int?>(
                      tooltip: 'Período',
                      onSelected: (v) => setState(() => _periodDays = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: null, child: Text('Todo o período')),
                        PopupMenuItem(value: 7, child: Text('Últimos 7 dias')),
                        PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
                        PopupMenuItem(value: 90, child: Text('Últimos 90 dias')),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(children: [
                          Icon(Icons.calendar_month_rounded, size: 18),
                          SizedBox(width: 4),
                          Text('Período',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    const EmptyState(
                        emoji: '📋',
                        title: 'Nenhum pedido',
                        subtitle: 'Seus pedidos aparecerão aqui',
                        asset: AppAssets.ilListaVazia)
                  else
                    for (final order in visible) _orderRow(context, order),
                ],
              ],
            );
          },
        ),
      ),
    ]);

    if (widget.embedded) {
      return ColoredBox(color: AppColors.background, child: content);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        title: const Text('Meus Pedidos'),
      ),
      body: content,
    );
  }

  Widget _orderRow(BuildContext context, OrderModel order) {
    final cat = Categories.byId(order.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: C360Card(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 760;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
              Text(order.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(cat?.name ?? order.category,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
            ],
          );
          final thumb = Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(cat?.emoji ?? '🔧',
                style: const TextStyle(fontSize: 20)),
          );
          final chip = C360StatusChip(labelForOrder(order.status),
              tone: toneForOrder(order.status),
              icon: iconForOrder(order.status));
          final price = Text(order.price == null ? '—' : PaySvc.fmt(order.price!),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary));
          if (!wide) {
            return Row(children: [
              thumb,
              const SizedBox(width: 10),
              Expanded(child: info),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                price,
                const SizedBox(height: 6),
                chip,
              ]),
              _actions(context, order),
            ]);
          }
          return Row(children: [
            thumb,
            const SizedBox(width: 10),
            Expanded(flex: 3, child: info),
            Expanded(
                child: Text(fmtDate(order.createdAt),
                    style: const TextStyle(fontSize: 12))),
            Expanded(child: price),
            chip,
            _actions(context, order),
          ]);
        }),
      ),
    );
  }

  Widget _actions(BuildContext context, OrderModel order) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (v) {
        if (v == 'cancel') _confirmCancel(context, order.id);
        if (v == 'track') {
          Navigator.pushNamed(context, Routes.gps,
              arguments: {'ctx': 'servico', 'orderId': order.id});
        }
        if (v == 'review') {
          Navigator.pushNamed(context, Routes.reviews,
              arguments: {'orderId': order.id});
        }
        if (v == 'detail') openOrderDetail(context, order);
      },
      itemBuilder: (_) => [
        if (order.status == OrderStatus.pending ||
            order.status == OrderStatus.accepted)
          const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
        if (order.status == OrderStatus.inProgress)
          const PopupMenuItem(value: 'track', child: Text('Rastrear')),
        if (order.status == OrderStatus.completed && !order.reviewed)
          const PopupMenuItem(value: 'review', child: Text('Avaliar')),
        const PopupMenuItem(value: 'detail', child: Text('Acompanhar')),
      ],
    );
  }

  void _confirmCancel(BuildContext context, String orderId) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: const Text('Cancelar pedido'),
            content: const Text(
                'Tem certeza que deseja cancelar esta solicitação? Essa ação não pode ser desfeita.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Voltar')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await FS.cancelOrder(orderId);
                      if (context.mounted) {
                        snack(context, 'Pedido cancelado', bg: AppColors.error);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        snack(context, 'Não foi possível cancelar.',
                            bg: AppColors.error);
                      }
                    }
                  },
                  child: const Text('Cancelar pedido',
                      style: TextStyle(color: AppColors.error))),
            ],
          ));
}

// ─────────────────────────────────────────────────────────────
// REQUEST SERVICE SCREEN (Vol.3: Detalhes do Serviço — Solicitar
// orçamento). Cria o OrderModel real antes de abrir o chat com o
// profissional, fechando o fluxo Cliente → Pedido → Negociação.
// ─────────────────────────────────────────────────────────────
class RequestServiceScreen extends StatefulWidget {
  final String providerId, providerName, category;
  final Color providerColor;
  final String? initialDescription;
  const RequestServiceScreen(
      {super.key,
      required this.providerId,
      required this.providerName,
      required this.category,
      this.providerColor = AppColors.primary,
      this.initialDescription});
  @override
  State<RequestServiceScreen> createState() => _RequestServiceState();
}

class _RequestServiceState extends State<RequestServiceScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  bool _urgent = false,
      _loading = false,
      _improvingDescription = false,
      _loadingBudget = false;
  String? _budgetSuggestion;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDescription?.trim();
    if (seed != null && seed.isNotEmpty) _description.text = seed;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _improveDescription() async {
    if (_description.text.trim().isEmpty) {
      snack(context, 'Escreva algumas palavras primeiro');
      return;
    }
    setState(() => _improvingDescription = true);
    final catName = Categories.byId(widget.category)?.name ?? widget.category;
    final suggestion = await AiSvc.suggestDescription(
        category: catName, draft: _description.text.trim());
    if (!mounted) return;
    setState(() => _improvingDescription = false);
    if (suggestion != null && suggestion.isNotEmpty) {
      setState(() => _description.text = suggestion);
    } else {
      snack(context,
          'Não foi possível gerar uma sugestão agora. Tente novamente.',
          bg: AppColors.error);
    }
  }

  Future<void> _estimateBudget() async {
    if (_description.text.trim().isEmpty) {
      snack(context, 'Descreva o serviço primeiro');
      return;
    }
    setState(() => _loadingBudget = true);
    final catName = Categories.byId(widget.category)?.name ?? widget.category;
    final suggestion = await AiSvc.suggestBudget(
        category: catName, description: _description.text.trim());
    if (!mounted) return;
    setState(() {
      _loadingBudget = false;
      _budgetSuggestion = suggestion;
    });
  }

  Future<void> _submit() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted || !_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final orderId = await FS.createOrder({
      'providerId': widget.providerId,
      'category': widget.category,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'address': _address.text.trim(),
      'urgent': _urgent,
    });

    final roomId = await FS.getOrCreateRoom(widget.providerId);
    await FS.sendMessage(
        roomId: roomId,
        senderName: 'Você',
        text:
            '📋 Nova solicitação: ${_title.text.trim()}\n${_description.text.trim()}');
    await FS.pushNotif(widget.providerId, '📋 Nova solicitação de serviço',
        _title.text.trim(), 'order');

    if (!mounted) return;
    setState(() => _loading = false);
    snack(context, '✅ Solicitação enviada! Acompanhe pelo chat.',
        bg: AppColors.secondary);
    Navigator.pop(context);
    Navigator.pushNamed(context, Routes.chat, arguments: {
      'roomId': roomId,
      'id': widget.providerId,
      'name': widget.providerName,
      'orderId': orderId
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Solicitar orçamento')),
        body: LoadingOverlay(
            loading: _loading,
            child: Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Container(
                      decoration: AppDecorations.card(),
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        AppAvatar(
                            name: widget.providerName,
                            size: 48,
                            bg: widget.providerColor,
                            r: 14),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(widget.providerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15))),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: OfficialIcon(
                            label: ServiceCatalog.labelOf(widget.category),
                            assetPath: ServiceCatalog.professionById(
                                        widget.category)
                                    ?.asset256 ??
                                ServiceCatalog.categoryById(widget.category)
                                    ?.asset256,
                            pendingArt: (ServiceCatalog.professionById(
                                        widget.category)
                                    ?.asset ??
                                ServiceCatalog.categoryById(widget.category)
                                    ?.asset) ==
                                null,
                          ),
                        ),
                      ])),
                  const SizedBox(height: 20),
                  TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          hintText: 'Título do serviço *',
                          prefixIcon: Icon(Icons.title_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _description,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          hintText: 'Descreva o que você precisa *',
                          alignLabelWithHint: true),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton.icon(
                      onPressed:
                          _improvingDescription ? null : _improveDescription,
                      icon: _improvingDescription
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Melhorar com IA',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: OutlinedButton.icon(
                      onPressed: _loadingBudget ? null : _estimateBudget,
                      icon: _loadingBudget
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Estimar preço',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10)),
                    )),
                  ]),
                  if (_budgetSuggestion != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.secondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Estimativa da IA: $_budgetSuggestion',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _address,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          hintText: 'Endereço *',
                          prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Campo obrigatório' : null),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Serviço urgente',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                        'Prioriza sua solicitação na fila do profissional',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                    value: _urgent,
                    onChanged: (v) => setState(() => _urgent = v),
                    activeThumbColor: AppColors.error,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        child: const Text('Enviar solicitação',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      )),
                  const SizedBox(height: 40),
                ]))),
      );
}
