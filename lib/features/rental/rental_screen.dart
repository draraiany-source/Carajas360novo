import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/chat_nav.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/micro_interactions.dart';

// ─────────────────────────────────────────────────────────────
// LOCAÇÃO (Vol.13) — vitrine de veículos e máquinas para aluguel.
// Reaproveita chat, avaliações e favoritos já existentes no app.
// ─────────────────────────────────────────────────────────────
class RentalScreen extends StatefulWidget {
  /// Aba inicial: 0 = veículos, 1 = máquinas.
  final int initialTab;
  const RentalScreen({super.key, this.initialTab = 0});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  String _query = '';

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MyRentalsScreen())),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Anunciar'),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
                child: GradHeader(
              gradient: AppGradients.primary,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20)),
                      const SizedBox(width: 12),
                      const Text('🔑 Locação',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 4),
                    const Padding(
                        padding: EdgeInsets.only(left: 32),
                        child: Text(
                            'Veículos e máquinas por hora, dia, semana ou mês',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12))),
                    const SizedBox(height: 14),
                    AppSearchBar(
                        hint: 'Buscar por modelo, marca ou cidade...',
                        onChanged: (v) =>
                            setState(() => _query = v.toLowerCase())),
                  ]),
            )),
            SliverToBoxAdapter(
                child: Container(
              color: AppColors.white,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: '🚗  Veículos'),
                  Tab(text: '🚜  Máquinas')
                ],
              ),
            )),
          ],
          body: TabBarView(controller: _tab, children: [
            _list(RentalKind.vehicle),
            _list(RentalKind.machine),
          ]),
        ),
      );

  Widget _list(RentalKind kind) => StreamBuilder<List<RentalModel>>(
        stream: FS.rentalsStream(kind: kind),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const SkeletonCard());
          }
          var items = snap.data ?? [];
          if (_query.isNotEmpty) {
            items = items
                .where((r) =>
                    r.title.toLowerCase().contains(_query) ||
                    (r.brand ?? '').toLowerCase().contains(_query) ||
                    (r.model ?? '').toLowerCase().contains(_query) ||
                    (r.city ?? '').toLowerCase().contains(_query))
                .toList();
          }
          if (items.isEmpty) {
            return EmptyState(
              emoji: kind == RentalKind.vehicle ? '🚗' : '🚜',
              title: 'Nenhum anúncio ainda',
              subtitle: kind == RentalKind.vehicle
                  ? 'Seja o primeiro a anunciar um veículo para locação'
                  : 'Seja o primeiro a anunciar uma máquina para locação',
              asset: AppAssets.ilListaVazia,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) =>
                FadeSlideIn(index: i, child: _card(items[i])),
          );
        },
      );

  Widget _card(RentalModel r) => TapScale(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RentalDetailScreen(rental: r))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.card(r: 16),
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: r.photos.isEmpty
                    ? Container(
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: Text(r.isVehicle ? '🚗' : '🚜',
                            style: const TextStyle(fontSize: 44)))
                    : CachedNetworkImage(
                        imageUrl: r.photos.first, fit: BoxFit.cover),
              ),
              Positioned(
                  top: 10,
                  left: 10,
                  child: AppTag(
                    r.available ? 'Disponível' : 'Indisponível',
                    bg: r.available ? AppColors.secondary : AppColors.error,
                  )),
            ]),
            Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                          [
                            if (r.brand != null && r.brand!.isNotEmpty) r.brand,
                            if (r.year != null) '${r.year}',
                            if (r.km != null) '${r.km} km',
                            if (r.power != null && r.power!.isNotEmpty) r.power,
                          ].whereType<String>().join(' · '),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(
                                '${r.city ?? '—'}${r.state != null ? '/${r.state}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textLight))),
                        if (r.totalReviews > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.gold),
                          Text(
                              ' ${r.rating.toStringAsFixed(1)} (${r.totalReviews})',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      if (r.fromPrice != null)
                        Text.rich(TextSpan(children: [
                          const TextSpan(
                              text: 'a partir de ',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textLight)),
                          TextSpan(
                              text: PaySvc.fmt(r.fromPrice!),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                          TextSpan(
                              text: r.fromPeriod,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight)),
                        ])),
                    ])),
          ]),
        ),
      );
}

// ── Detalhe do anúncio ───────────────────────────────────────
class RentalDetailScreen extends StatelessWidget {
  final RentalModel rental;
  const RentalDetailScreen({super.key, required this.rental});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(color: AppColors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ]),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text('a partir de',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textLight)),
                  Text(
                      '${rental.fromPrice != null ? PaySvc.fmt(rental.fromPrice!) : 'Sob consulta'}${rental.fromPeriod}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                ])),
            IconButton(
              tooltip: 'Conversar',
              onPressed: () => ChatNav.open(context,
                  otherUserId: rental.ownerId,
                  otherName: rental.ownerName),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: rental.available ? () => _openBooking(context) : null,
              icon: const Icon(Icons.event_available_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              label: Text(rental.available ? 'Reservar' : 'Indisponível',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Compartilhar',
                icon: const Icon(Icons.share_rounded),
                onPressed: () => snack(context, 'Link do anúncio copiado!',
                    bg: AppColors.secondary),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: rental.photos.isEmpty
                  ? Container(
                      decoration:
                          const BoxDecoration(gradient: AppGradients.primary),
                      alignment: Alignment.center,
                      child: Text(rental.isVehicle ? '🚗' : '🚜',
                          style: const TextStyle(fontSize: 70)))
                  : PageView.builder(
                      itemCount: rental.photos.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: rental.photos[i], fit: BoxFit.cover),
                    ),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(rental.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900))),
                AppTag(rental.available ? 'Disponível' : 'Indisponível',
                    bg: rental.available
                        ? AppColors.secondary
                        : AppColors.error),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                    '${rental.city ?? '—'}${rental.state != null ? '/${rental.state}' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textLight)),
              ]),
              const SizedBox(height: 18),
              const SecHeader(title: 'Valores'),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                if (rental.pricePerHour != null)
                  _price('Hora', rental.pricePerHour!),
                if (rental.pricePerDay != null)
                  _price('Diária', rental.pricePerDay!),
                if (rental.pricePerWeek != null)
                  _price('Semana', rental.pricePerWeek!),
                if (rental.pricePerMonth != null)
                  _price('Mês', rental.pricePerMonth!),
              ]),
              const SizedBox(height: 20),
              const SecHeader(title: 'Ficha técnica'),
              const SizedBox(height: 8),
              Container(
                decoration: AppDecorations.card(r: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(children: [
                  if (rental.brand != null && rental.brand!.isNotEmpty)
                    _row('Marca', rental.brand!),
                  if (rental.model != null && rental.model!.isNotEmpty)
                    _row('Modelo', rental.model!),
                  if (rental.year != null) _row('Ano', '${rental.year}'),
                  if (rental.km != null)
                    _row('Quilometragem', '${rental.km} km'),
                  if (rental.power != null && rental.power!.isNotEmpty)
                    _row('Potência', rental.power!),
                  if (rental.specs != null && rental.specs!.isNotEmpty)
                    _row('Especificações', rental.specs!),
                  _row(
                      'Categoria',
                      Categories.byId(rental.category)?.name ??
                          rental.category),
                ]),
              ),
              if (rental.description != null &&
                  rental.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SecHeader(title: 'Descrição'),
                const SizedBox(height: 8),
                Text(rental.description!,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textMedium)),
              ],
              const SizedBox(height: 30),
            ]),
          )),
        ]),
      );

  void _openBooking(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _BookingSheet(rental: rental),
      );

  Widget _price(String label, double v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          Text(PaySvc.fmt(v),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
        ]),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.textLight)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700))),
        ]),
      );
}

// ── Meus anúncios ────────────────────────────────────────────
class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Meus anúncios'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _form(context),
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<RentalModel>>(
          stream: FS.myRentalsStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const EmptyState(
                  emoji: '🔑',
                  title: 'Nenhum anúncio',
                  subtitle: 'Toque no + para anunciar um veículo ou máquina');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppDecorations.card(r: 14),
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: r.photos.isEmpty
                            ? Text(r.isVehicle ? '🚗' : '🚜',
                                style: const TextStyle(fontSize: 22))
                            : CachedNetworkImage(
                                imageUrl: r.photos.first,
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                              r.fromPrice != null
                                  ? '${PaySvc.fmt(r.fromPrice!)}${r.fromPeriod}'
                                  : 'Sob consulta',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ])),
                    Switch(
                      value: r.available,
                      activeColor: AppColors.secondary,
                      onChanged: (v) => FS.setRentalAvailability(r.id, v),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.primary),
                      onPressed: () => _form(context, edit: r),
                    ),
                    IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      onPressed: () => FS.removeRental(r.id),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      );

  void _form(BuildContext context, {RentalModel? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RentalForm(edit: edit),
    );
  }
}

// ── Formulário de anúncio ────────────────────────────────────
class _RentalForm extends StatefulWidget {
  final RentalModel? edit;
  const _RentalForm({this.edit});

  @override
  State<_RentalForm> createState() => _RentalFormState();
}

class _RentalFormState extends State<_RentalForm> {
  late final _title = TextEditingController(text: widget.edit?.title ?? '');
  late final _brand = TextEditingController(text: widget.edit?.brand ?? '');
  late final _model = TextEditingController(text: widget.edit?.model ?? '');
  late final _year =
      TextEditingController(text: widget.edit?.year?.toString() ?? '');
  late final _km =
      TextEditingController(text: widget.edit?.km?.toString() ?? '');
  late final _power = TextEditingController(text: widget.edit?.power ?? '');
  late final _specs = TextEditingController(text: widget.edit?.specs ?? '');
  late final _city = TextEditingController(text: widget.edit?.city ?? '');
  late final _state = TextEditingController(text: widget.edit?.state ?? '');
  late final _desc =
      TextEditingController(text: widget.edit?.description ?? '');
  late final _hour = TextEditingController(
      text: widget.edit?.pricePerHour?.toStringAsFixed(2) ?? '');
  late final _day = TextEditingController(
      text: widget.edit?.pricePerDay?.toStringAsFixed(2) ?? '');
  late final _week = TextEditingController(
      text: widget.edit?.pricePerWeek?.toStringAsFixed(2) ?? '');
  late final _month = TextEditingController(
      text: widget.edit?.pricePerMonth?.toStringAsFixed(2) ?? '');

  late RentalKind _kind = widget.edit?.kind ?? RentalKind.vehicle;
  late String _cat = widget.edit?.category ?? 'aluguel_carro';
  late List<String> _photos = [...?widget.edit?.photos];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _brand,
      _model,
      _year,
      _km,
      _power,
      _specs,
      _city,
      _state,
      _desc,
      _hour,
      _day,
      _week,
      _month
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final v = double.tryParse(c.text.replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  /// Categorias disponíveis conforme o tipo escolhido.
  List<ServiceCategory> get _cats => Categories.all
      .where((c) =>
          c.group == (_kind == RentalKind.vehicle ? 'Veículos' : 'Máquinas'))
      .toList();

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1400);
    if (picked == null) return;
    final id =
        widget.edit?.id ?? 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    if (mounted) snack(context, 'Enviando foto...', bg: AppColors.primary);
    final url = await FS.uploadRentalPhoto(
        id, await picked.readAsBytes(), picked.name);
    if (!mounted) return;
    if (url == null) {
      snack(context, 'Falha ao enviar a foto.', bg: AppColors.error);
      return;
    }
    setState(() => _photos = [..._photos, url]);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      snack(context, 'Informe o título do anúncio', bg: AppColors.error);
      return;
    }
    if (_num(_hour) == null &&
        _num(_day) == null &&
        _num(_week) == null &&
        _num(_month) == null) {
      snack(context, 'Informe ao menos um valor de locação',
          bg: AppColors.error);
      return;
    }
    setState(() => _saving = true);
    final id = await FS.saveRental(RentalModel(
      id: widget.edit?.id ?? '',
      ownerId: '',
      ownerName: 'Anunciante',
      title: _title.text.trim(),
      category: _cat,
      kind: _kind,
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      description: _desc.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().toUpperCase(),
      power: _power.text.trim(),
      specs: _specs.text.trim(),
      year: int.tryParse(_year.text),
      km: int.tryParse(_km.text),
      photos: _photos,
      pricePerHour: _num(_hour),
      pricePerDay: _num(_day),
      pricePerWeek: _num(_week),
      pricePerMonth: _num(_month),
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    snack(context, id != null ? '✅ Anúncio publicado!' : 'Falha ao publicar.',
        bg: id != null ? AppColors.secondary : AppColors.error);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          const SizedBox(height: 14),
          Text(widget.edit == null ? 'Novo anúncio' : 'Editar anúncio',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SegmentedButton<RentalKind>(
            segments: const [
              ButtonSegment(
                  value: RentalKind.vehicle,
                  label: Text('Veículo'),
                  icon: Icon(Icons.directions_car_rounded)),
              ButtonSegment(
                  value: RentalKind.machine,
                  label: Text('Máquina'),
                  icon: Icon(Icons.agriculture_rounded)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _cat = _cats.isNotEmpty ? _cats.first.id : _cat;
            }),
          ),
          const SizedBox(height: 14),
          // Fotos
          SizedBox(
              height: 78,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                GestureDetector(
                    onTap: _addPhoto,
                    child: Container(
                      width: 78,
                      height: 78,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border)),
                      child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.textLight),
                            SizedBox(height: 2),
                            Text('Foto',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textLight)),
                          ]),
                    )),
                ..._photos.map((p) => Container(
                      width: 78,
                      height: 78,
                      margin: const EdgeInsets.only(right: 8),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12)),
                      child: CachedNetworkImage(imageUrl: p, fit: BoxFit.cover),
                    )),
              ])),
          const SizedBox(height: 14),
          TextField(
              controller: _title,
              decoration:
                  const InputDecoration(labelText: 'Título do anúncio *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _cats.any((c) => c.id == _cat)
                ? _cat
                : (_cats.isNotEmpty ? _cats.first.id : null),
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: _cats
                .map((c) => DropdownMenuItem(
                    value: c.id, child: Text('${c.emoji}  ${c.name}')))
                .toList(),
            onChanged: (v) => setState(() => _cat = v ?? _cat),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Marca'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Modelo'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ano'))),
            const SizedBox(width: 10),
            Expanded(
                child: _kind == RentalKind.vehicle
                    ? TextField(
                        controller: _km,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Quilometragem'))
                    : TextField(
                        controller: _power,
                        decoration:
                            const InputDecoration(labelText: 'Potência'))),
          ]),
          if (_kind == RentalKind.machine) ...[
            const SizedBox(height: 12),
            TextField(
                controller: _specs,
                decoration: const InputDecoration(labelText: 'Especificações')),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                flex: 3,
                child: TextField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'Cidade'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _state,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'UF'))),
          ]),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 16),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Valores de locação *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _hour,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Por hora', prefixText: 'R\$ '))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _day,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Diária', prefixText: 'R\$ '))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _week,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Semana', prefixText: 'R\$ '))),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
                    controller: _month,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Mês', prefixText: 'R\$ '))),
          ]),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.edit == null
                            ? 'Publicar anúncio'
                            : 'Salvar alterações',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
              )),
        ])),
      );
}

// ── Reserva ──────────────────────────────────────────────────
class _BookingSheet extends StatefulWidget {
  final RentalModel rental;
  const _BookingSheet({required this.rental});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late final Map<String, double?> _prices = {
    'hora': widget.rental.pricePerHour,
    'diária': widget.rental.pricePerDay,
    'semana': widget.rental.pricePerWeek,
    'mês': widget.rental.pricePerMonth,
  };
  late String _period = _prices.entries
      .firstWhere((e) => e.value != null,
          orElse: () => const MapEntry('diária', null))
      .key;
  int _qty = 1;
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double get _unit => _prices[_period] ?? 0;
  double get _total => _unit * _qty;

  /// Data final calculada a partir do período e da quantidade.
  DateTime get _end => switch (_period) {
        'hora' => _start.add(Duration(hours: _qty)),
        'semana' => _start.add(Duration(days: 7 * _qty)),
        'mês' => DateTime(_start.year, _start.month + _qty, _start.day),
        _ => _start.add(Duration(days: _qty)),
      };

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _confirm() async {
    if (_unit <= 0) {
      snack(context, 'Este período não tem valor definido.',
          bg: AppColors.error);
      return;
    }
    setState(() => _saving = true);
    final id = await FS.createBooking(BookingModel(
      id: '',
      rentalId: widget.rental.id,
      rentalTitle: widget.rental.title,
      ownerId: widget.rental.ownerId,
      clientId: '',
      clientName: 'Cliente',
      start: _start,
      end: _end,
      period: _period,
      quantity: _qty,
      total: _total,
      note: _note.text.trim(),
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    snack(
        context,
        id != null
            ? '✅ Reserva solicitada! O anunciante vai confirmar.'
            : 'Falha ao solicitar a reserva.',
        bg: id != null ? AppColors.secondary : AppColors.error);
  }

  @override
  Widget build(BuildContext context) {
    final avail = _prices.entries.where((e) => e.value != null).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        Text('Reservar ${widget.rental.title}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Período',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            children: avail
                .map((e) => ChoiceChip(
                      label: Text('${e.key} · ${PaySvc.fmt(e.value!)}'),
                      selected: _period == e.key,
                      onSelected: (_) => setState(() => _period = e.key),
                    ))
                .toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_fmtDate(_start),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          )),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null),
              Text('$_qty',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: () => setState(() => _qty++)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'De ${_fmtDate(_start)} até ${_fmtDate(_end)}',
              style:
                  const TextStyle(fontSize: 11.5, color: AppColors.textLight),
            )),
        const SizedBox(height: 14),
        TextField(
            controller: _note,
            maxLines: 2,
            decoration:
                const InputDecoration(labelText: 'Observação (opcional)')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$_qty × ${PaySvc.fmt(_unit)}/$_period',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textLight)),
            Text(PaySvc.fmt(_total),
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _confirm,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Solicitar reserva',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            )),
      ])),
    );
  }
}

// ── Minhas reservas ──────────────────────────────────────────
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Reservas'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [Tab(text: 'Fiz'), Tab(text: 'Recebi')],
            ),
          ),
          body: TabBarView(children: [
            _list(FS.myBookingsStream(), owner: false),
            _list(FS.receivedBookingsStream(), owner: true),
          ]),
        ),
      );

  Widget _list(Stream<List<BookingModel>> stream, {required bool owner}) =>
      StreamBuilder<List<BookingModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyState(
              emoji: '🔑',
              title: owner ? 'Nenhuma reserva recebida' : 'Nenhuma reserva',
              subtitle: owner
                  ? 'As solicitações nos seus anúncios aparecerão aqui'
                  : 'Suas reservas de veículos e máquinas aparecerão aqui',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final b = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppDecorations.card(r: 16),
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(b.rentalTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14))),
                        AppTag(b.statusLabel,
                            bg: switch (b.status) {
                              BookingStatus.confirmed => AppColors.secondary,
                              BookingStatus.active => AppColors.primary,
                              BookingStatus.cancelled => AppColors.error,
                              BookingStatus.completed => AppColors.textLight,
                              _ => AppColors.warning,
                            }),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                          '${b.quantity} ${b.period}(s) · ${PaySvc.fmt(b.total)}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textLight)),
                      if (owner)
                        Text('Cliente: ${b.clientName}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                      if (owner && b.status == BookingStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                              onPressed: () => FS.updateBookingStatus(
                                  b.id, BookingStatus.cancelled),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side:
                                      const BorderSide(color: AppColors.error)),
                              child: const Text('Recusar'),
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: ElevatedButton(
                              onPressed: () => FS.updateBookingStatus(
                                  b.id, BookingStatus.confirmed),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary),
                              child: const Text('Confirmar'),
                            )),
                          ]),
                        ),
                      if (!owner && b.status == BookingStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => FS.updateBookingStatus(
                                    b.id, BookingStatus.cancelled),
                                child: const Text('Cancelar',
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                              )),
                        ),
                    ]),
              );
            },
          );
        },
      );
}
