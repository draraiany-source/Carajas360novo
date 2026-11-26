import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/access_control.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/chat_nav.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';
import '../orders/orders_screen.dart';
import '../tia/tia_request_screen.dart';

enum ProviderDetailStyle { service, profile }

/// Detalhe do serviço (mockup 8) e perfil do profissional (mockup 9).
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String category;
  final ProviderDetailStyle style;
  const ProviderProfileScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.category,
    this.style = ProviderDetailStyle.profile,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _quote = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String? _estimate;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: widget.style == ProviderDetailStyle.service ? 5 : 5,
        vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _quote.dispose();
    super.dispose();
  }

  String _catName(String id) =>
      Categories.byId(id)?.name ?? (id.isEmpty ? 'Serviço' : id);

  Future<void> _runEstimate() async {
    if (_quote.text.trim().isEmpty) {
      snack(context, 'Descreva o que você precisa');
      return;
    }
    setState(() => _estimating = true);
    final suggestion = await AiSvc.suggestBudget(
        category: _catName(widget.category), description: _quote.text.trim());
    if (!mounted) return;
    setState(() {
      _estimating = false;
      _estimate = suggestion;
    });
    if (suggestion == null || suggestion.isEmpty) {
      snack(context, 'Não foi possível estimar agora.', bg: AppColors.error);
    }
  }

  Future<void> _request(ProviderModel? provider, {String? extra}) async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final parts = <String>[
      if (extra != null && extra.trim().isNotEmpty) extra.trim(),
      if (_date != null)
        'Data preferida: ${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
      if (_time != null)
        'Horário preferido: ${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
    ];
    c360Open(
      context,
      route: Routes.requestService,
      arguments: {
        'providerId': widget.providerId,
        'providerName': provider?.name ?? widget.providerName,
        'category': provider?.categories.isNotEmpty == true
            ? provider!.categories.first
            : widget.category,
      },
      page: RequestServiceScreen(
        providerId: widget.providerId,
        providerName: provider?.name ?? widget.providerName,
        category: provider?.categories.isNotEmpty == true
            ? provider!.categories.first
            : widget.category,
        initialDescription: parts.isEmpty ? null : parts.join('\n'),
      ),
    );
  }

  Future<void> _whatsapp(ProviderModel? provider) async {
    String? phone;
    final id = provider?.userId.isNotEmpty == true
        ? provider!.userId
        : widget.providerId;
    try {
      phone = (await FS.getUser(id))?.phone;
    } catch (_) {}
    if (!mounted) return;
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      snack(context,
          'Telefone não informado. A conversa segue pelo chat do app.');
      await ChatNav.open(context,
          otherUserId: provider?.userId.isNotEmpty == true
              ? provider!.userId
              : widget.providerId,
          otherName: provider?.name ?? widget.providerName,
          otherPhoto: provider?.photoUrl);
      return;
    }
    final uri = Uri.parse('https://wa.me/55$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      snack(context, 'Não foi possível abrir o WhatsApp.', bg: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.style == ProviderDetailStyle.service;
    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<ProviderModel?>(
        stream: c360Stream(() => FS.providerStream(widget.providerId)),
        builder: (context, snap) {
          final provider = snap.data;
          final name = provider?.name.isNotEmpty == true
              ? provider!.name
              : widget.providerName;
          final category = provider?.categories.isNotEmpty == true
              ? provider!.categories.first
              : widget.category;
          return Column(children: [
                if (service)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(children: [
                      IconButton(
                        onPressed: () => c360Pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Explorar Serviços  ›  ${_catName(category)}  ›  Detalhes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMedium),
                        ),
                      ),
                    ]),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      if (!service)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Profissionais  ›  Perfil',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMedium)),
                        ),
                      LayoutBuilder(builder: (context, c) {
                        final side = c.maxWidth >= 980;
                        final main =
                          _header(name, category, provider, service);
                        final aside = service
                            ? _quoteBox(provider)
                            : _scheduleBox(provider);
                        if (!side) {
                          return Column(children: [
                            main,
                            const SizedBox(height: 12),
                            aside,
                          ]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: main),
                            const SizedBox(width: 16),
                            SizedBox(width: 320, child: aside),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ]);
        },
      ),
    );
  }

  Widget _header(String name, String category, ProviderModel? provider,
      bool service) {
    final verified = provider?.verified ?? false;
    return C360Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          C360Avatar(
              name: name,
              url: provider?.photoUrl,
              size: 92,
              verified: verified),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      service ? '$name · ${_catName(category)}' : name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ]),
                Text(_catName(category),
                    style: const TextStyle(color: AppColors.textLight)),
                const SizedBox(height: 6),
                C360Rating(
                  rating: provider?.rating ?? 0,
                  reviews: provider?.totalReviews ?? 0,
                  trailing: provider?.city == null ? null : '· ${provider!.city}',
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (verified)
                    const C360StatusChip('Profissional Verificado',
                        tone: C360Tone.success,
                        icon: Icons.verified_user_outlined),
                  if (provider?.modalities.contains('online') == true)
                    const C360StatusChip('Atendimento online',
                        icon: Icons.bolt_rounded),
                  if (provider?.active == true)
                    const C360StatusChip('Disponível hoje',
                        tone: C360Tone.success,
                        icon: Icons.circle),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton.icon(
            onPressed: () => _request(provider, extra: _quote.text),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Solicitar Serviço'),
          ),
          OutlinedButton.icon(
            onPressed: () => ChatNav.open(context,
                otherUserId: provider?.userId.isNotEmpty == true
                    ? provider!.userId
                    : widget.providerId,
                otherName: name,
                otherPhoto: provider?.photoUrl),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Conversar no Chat'),
          ),
          if (widget.providerId.isNotEmpty)
            _FavoriteButton(providerId: widget.providerId),
        ]),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sobre'),
            Tab(text: 'Serviços'),
            Tab(text: 'Avaliações'),
            Tab(text: 'Portfólio'),
            Tab(text: 'Localização'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: TabBarView(controller: _tabs, children: [
            _about(provider),
            _services(provider),
            _reviews(),
            _portfolio(),
            _location(provider),
          ]),
        ),
      ]),
    );
  }

  Widget _about(ProviderModel? provider) {
    final bio = provider?.bio?.trim();
    final since = provider?.createdAt;
    return ListView(children: [
      Text(
        bio != null && bio.isNotEmpty
            ? bio
            : 'O profissional ainda não publicou uma apresentação.',
        style: const TextStyle(height: 1.4, color: AppColors.textMedium),
      ),
      const SizedBox(height: 12),
      if (since != null)
        Text('No Carajás 360 desde ${since.year}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      if ((provider?.totalReviews ?? 0) > 0)
        Text('${provider!.totalReviews} avaliações registradas',
            style: const TextStyle(color: AppColors.textLight)),
    ]);
  }

  Widget _services(ProviderModel? provider) {
    final cats = provider?.categories ??
        (widget.category.isEmpty ? <String>[] : [widget.category]);
    if (cats.isEmpty) {
      return const Text('Nenhum serviço listado ainda.',
          style: TextStyle(color: AppColors.textLight));
    }
    return ListView(
      children: [
        for (final id in cats)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_rounded,
                color: AppColors.primary),
            title: Text(_catName(id)),
          ),
      ],
    );
  }

  Widget _reviews() {
    if (widget.providerId.isEmpty) {
      return const Text('Sem avaliações publicadas.',
          style: TextStyle(color: AppColors.textLight));
    }
    return StreamBuilder<List<ReviewModel>>(
      stream: c360Stream(() => FS.reviewsForProvider(widget.providerId)),
      builder: (_, snap) {
        final list = snap.data ?? [];
        if (snap.hasError || list.isEmpty) {
          return const Text(
            'As avaliações aparecem aqui quando os clientes concluem um serviço.',
            style: TextStyle(color: AppColors.textLight, height: 1.4),
          );
        }
        final counts = List<int>.filled(5, 0);
        for (final r in list) {
          final i = (r.stars.clamp(1, 5)) - 1;
          counts[i]++;
        }
        return ListView(children: [
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
                    value: list.isEmpty ? 0 : counts[stars - 1] / list.length,
                    backgroundColor: AppColors.surfaceMuted,
                    color: AppColors.primary,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${counts[stars - 1]}',
                    style: const TextStyle(fontSize: 12)),
              ]),
            ),
          const SizedBox(height: 8),
          for (final r in list.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: C360Avatar(name: r.clientName, url: r.clientPhoto, size: 36),
              title: Text(r.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(r.comment.isEmpty
                  ? '${r.stars} estrelas'
                  : r.comment),
            ),
        ]);
      },
    );
  }

  Widget _portfolio() {
    return const Text(
      'Portfólio ainda não publicado pelo profissional.',
      style: TextStyle(color: AppColors.textLight, height: 1.4),
    );
  }

  Widget _location(ProviderModel? provider) {
    final city = provider?.city ?? RegionController.instance.city.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.place_rounded, color: AppColors.primary, size: 32),
          const SizedBox(height: 6),
          Text(city, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Text('Mapa ilustrativo — abra o rastreamento para o mapa.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        ]),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: () => Navigator.pushNamed(context, Routes.gps,
            arguments: {'ctx': 'servico'}),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Ver no Mapa'),
      ),
    ]);
  }

  Widget _quoteBox(ProviderModel? provider) {
    return C360Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Orçamento Rápido',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Descreva o que você precisa:',
            style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        TextField(
          controller: _quote,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex.: instalação de chuveiro, troca de tomada...',
          ),
        ),
        if (_estimate != null) ...[
          const SizedBox(height: 8),
          Text('Estimativa: $_estimate',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _request(provider, extra: _quote.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.sidebar,
            ),
            child: const Text('Solicitar Orçamento'),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _estimating ? null : _runEstimate,
            child: Text(_estimating ? 'Estimando...' : 'Estimar com IA'),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          OutlinedButton.icon(
            onPressed: () => c360Open(
              context,
              route: Routes.tiaRequest,
              arguments: {
                'providerId': provider?.id ?? widget.providerId,
                'providerName': provider?.name ?? widget.providerName,
                'category': widget.category,
              },
              page: TiaRequestScreen(
                providerId: provider?.id ?? widget.providerId,
                providerName: provider?.name ?? widget.providerName,
                category: widget.category,
              ),
            ),
            icon: const Icon(Icons.attach_file_rounded, size: 18),
            label: const Text('Anexar fotos'),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('Contato e Horário',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Horário de atendimento não informado no cadastro.',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ]),
    );
  }

  Widget _scheduleBox(ProviderModel? provider) {
    final price = provider?.minPrice;
    return Column(children: [
      C360Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Solicitar Serviço',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data do atendimento'),
            subtitle: Text(_date == null
                ? 'Selecione a data'
                : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}'),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 120)),
                initialDate: _date ?? DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Horário preferido'),
            subtitle: Text(_time == null
                ? 'Selecione o horário'
                : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.schedule_rounded),
            onTap: () async {
              final picked =
                  await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
              if (picked != null) setState(() => _time = picked);
            },
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('Valor estimado',
                style: TextStyle(color: AppColors.textLight)),
            const Spacer(),
            Text(c360Money(price),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _request(provider),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: const Text('Agendar Agora'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _whatsapp(provider),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Conversar no WhatsApp'),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      C360Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Avaliações Recentes',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(height: 160, child: _reviews()),
        ]),
      ),
    ]);
  }
}

class _FavoriteButton extends StatelessWidget {
  final String providerId;
  const _FavoriteButton({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: c360Stream(() => FS.isFavoriteStream(providerId)),
      builder: (_, snap) {
        final on = snap.data ?? false;
        return OutlinedButton.icon(
          onPressed: () => FS.toggleFavorite(providerId),
          icon: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18, color: on ? AppColors.error : null),
          label: Text(on ? 'Favorito' : 'Favoritar'),
        );
      },
    );
  }
}
