import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';
import '../catalog/profession_picker.dart';

// ─────────────────────────────────────────────────────────────
// MINHA LOJA (Vol.12: Marketplace — lojas de empresas)
// Cadastro da loja, catálogo, estoque e promoções. Carrinho,
// pedidos, cupons, favoritos e avaliações são os já existentes.
// ─────────────────────────────────────────────────────────────
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Minha loja'),
            backgroundColor: AppColors.delivery,
            foregroundColor: Colors.white),
        body: StreamBuilder<StoreModel?>(
          stream: FS.myStoreStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final store = snap.data;
            return store == null ? _StoreForm() : _StoreDashboard(store: store);
          },
        ),
      );
}

// ── Cadastro da loja ─────────────────────────────────────────
class _StoreForm extends StatefulWidget {
  @override
  State<_StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends State<_StoreForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnpj = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _selectedCats = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _cnpj, _desc, _phone, _city, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedCats.isEmpty) {
      snack(context, 'Selecione ao menos uma categoria', bg: AppColors.error);
      return;
    }
    setState(() => _saving = true);
    final id = await FS.saveStore(StoreModel(
      id: '',
      ownerId: '',
      name: _name.text.trim(),
      cnpj: _cnpj.text.trim(),
      description: _desc.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().toUpperCase(),
      categories: _selectedCats.toList(),
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    snack(context, id != null ? '✅ Loja criada!' : 'Falha ao criar a loja.',
        bg: id != null ? AppColors.secondary : AppColors.error);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration:
                    AppDecorations.gradient(AppGradients.delivery, r: 18),
                padding: const EdgeInsets.all(18),
                width: double.infinity,
                child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏪 Abra sua loja',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text(
                          'Anuncie seus produtos e venda para todo o marketplace.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: 'Nome da loja *'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Informe o nome'
                      : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _cnpj,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CNPJ')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    flex: 3,
                    child: TextFormField(
                        controller: _city,
                        decoration:
                            const InputDecoration(labelText: 'Cidade'))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                        controller: _state,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'UF'))),
              ]),
              const SizedBox(height: 18),
              const Text('Categorias da loja *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: ProfessionPicker(
                    selected: _selectedCats,
                    onToggle: (id) => setState(() {
                      if (_selectedCats.contains(id)) {
                        _selectedCats.remove(id);
                      } else {
                        _selectedCats.add(id);
                      }
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.delivery,
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Criar loja',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                  )),
              const SizedBox(height: 30),
            ])),
      );
}

// ── Painel da loja ───────────────────────────────────────────
class _StoreDashboard extends StatelessWidget {
  final StoreModel store;
  const _StoreDashboard({required this.store});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        // Banner da loja — toque para enviar/trocar a imagem.
        SliverToBoxAdapter(
            child: GestureDetector(
          onTap: () => _pickImage(context, 'banner'),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: store.bannerUrl == null ? AppGradients.delivery : null,
              image: store.bannerUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(store.bannerUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: store.bannerUrl == null
                ? const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('Adicionar banner da loja',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])
                : null,
          ),
        )),
        SliverToBoxAdapter(
            child: Container(
          decoration: AppDecorations.gradient(AppGradients.delivery, r: 0),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => _pickImage(context, 'logo'),
                child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      image: store.logoUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(store.logoUrl!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: store.logoUrl == null
                        ? const Text('🏪', style: TextStyle(fontSize: 26))
                        : null),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Flexible(
                          child: Text(store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800))),
                      if (store.verified)
                        const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.verified_rounded,
                                color: Colors.white, size: 18)),
                    ]),
                    Text('${store.city ?? ''} ${store.state ?? ''}'.trim(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _stat('${store.totalProducts}', 'Produtos'),
              _stat(store.rating.toStringAsFixed(1), 'Avaliação'),
              _stat('${store.totalReviews}', 'Avaliações'),
            ]),
          ]),
        )),
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _menu(
                context,
                '📦',
                'Catálogo e estoque',
                'Adicionar e editar produtos',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _CatalogScreen(store: store)))),
            _menu(
                context,
                '🏷️',
                'Promoções',
                'Defina preço promocional nos produtos',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => _CatalogScreen(store: store)))),
            _menu(context, '🎟️', 'Cupons', 'Gerencie cupons de desconto',
                () => Navigator.pushNamed(context, Routes.coupons)),
            _menu(context, '📋', 'Pedidos', 'Acompanhe as vendas',
                () => Navigator.pushNamed(context, Routes.myOrders)),
          ]),
        )),
      ]);

  /// Seleciona uma imagem da galeria e a envia como logo ou banner.
  Future<void> _pickImage(BuildContext context, String kind) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: kind == 'banner' ? 1600 : 600,
    );
    if (picked == null) return;
    if (context.mounted)
      snack(context, 'Enviando imagem...', bg: AppColors.primary);
    final url = await FS.uploadStoreImage(
        store.id, await picked.readAsBytes(), picked.name, kind);
    if (!context.mounted) return;
    snack(context,
        url != null ? '✅ Imagem atualizada!' : 'Falha ao enviar a imagem.',
        bg: url != null ? AppColors.secondary : AppColors.error);
  }

  Widget _stat(String v, String l) => Expanded(
          child: Column(children: [
        Text(v,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]));

  Widget _menu(BuildContext c, String icon, String title, String sub,
          VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppDecorations.card(r: 16),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ]),
        ),
      );
}

// ── Catálogo / estoque ───────────────────────────────────────
class _CatalogScreen extends StatelessWidget {
  final StoreModel store;
  const _CatalogScreen({required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Catálogo'),
            backgroundColor: AppColors.delivery,
            foregroundColor: Colors.white),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _productSheet(context),
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<ProductModel>>(
          stream: FS.productsStream(storeId: store.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const EmptyState(
                  emoji: '📦',
                  title: 'Nenhum produto',
                  subtitle: 'Toque no + para anunciar seu primeiro produto');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppDecorations.card(r: 16),
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text(p.emoji ?? '📦',
                            style: const TextStyle(fontSize: 22))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Row(children: [
                            if (p.onSale) ...[
                              Text(PaySvc.fmt(p.price),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                      decoration: TextDecoration.lineThrough)),
                              const SizedBox(width: 6),
                            ],
                            Text(PaySvc.fmt(p.finalPrice),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.delivery)),
                            if (p.onSale)
                              Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: AppTag('-${p.discountPercent}%',
                                      bg: const Color(0xFFFFEBEE),
                                      fg: AppColors.error)),
                          ]),
                          Text(
                              p.inStock ? 'Estoque: ${p.stock}' : 'Sem estoque',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: p.inStock
                                      ? AppColors.textLight
                                      : AppColors.error)),
                        ])),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.primary),
                      onPressed: () => _productSheet(context, edit: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.error),
                      onPressed: () => FS.removeProduct(p.id, store.id),
                    ),
                  ]),
                );
              },
            );
          },
        ),
      );

  void _productSheet(BuildContext context, {ProductModel? edit}) {
    final name = TextEditingController(text: edit?.name ?? '');
    final price =
        TextEditingController(text: edit?.price.toStringAsFixed(2) ?? '');
    final promo =
        TextEditingController(text: edit?.promoPrice?.toStringAsFixed(2) ?? '');
    final stock = TextEditingController(text: '${edit?.stock ?? 0}');
    final emoji = TextEditingController(text: edit?.emoji ?? '📦');
    final desc = TextEditingController(text: edit?.description ?? '');
    String cat = edit?.category ??
        (store.categories.isNotEmpty ? store.categories.first : 'materials');

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SheetHandle(),
                const SizedBox(height: 14),
                Text(edit == null ? 'Novo produto' : 'Editar produto',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(children: [
                  SizedBox(
                      width: 70,
                      child: TextField(
                          controller: emoji,
                          textAlign: TextAlign.center,
                          decoration:
                              const InputDecoration(labelText: 'Ícone'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: name,
                          decoration: const InputDecoration(
                              labelText: 'Nome do produto *'))),
                ]),
                const SizedBox(height: 12),
                TextField(
                    controller: desc,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Preço *', prefixText: 'R\$ '))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: promo,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Promoção', prefixText: 'R\$ '))),
                ]),
                const SizedBox(height: 12),
                TextField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Estoque')),
                const SizedBox(height: 18),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final v =
                            double.tryParse(price.text.replaceAll(',', '.')) ??
                                0;
                        if (name.text.trim().isEmpty || v <= 0) {
                          snack(ctx, 'Informe nome e preço válidos',
                              bg: AppColors.error);
                          return;
                        }
                        final pr =
                            double.tryParse(promo.text.replaceAll(',', '.'));
                        await FS.saveProduct(ProductModel(
                          id: edit?.id ?? '',
                          storeId: store.id,
                          storeName: store.name,
                          name: name.text.trim(),
                          category: cat,
                          description: desc.text.trim(),
                          emoji: emoji.text.trim().isEmpty
                              ? '📦'
                              : emoji.text.trim(),
                          price: v,
                          promoPrice:
                              (pr != null && pr > 0 && pr < v) ? pr : null,
                          stock: int.tryParse(stock.text) ?? 0,
                          createdAt: DateTime.now(),
                        ));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.delivery,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: Text(
                          edit == null
                              ? 'Publicar produto'
                              : 'Salvar alterações',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    )),
              ])),
            ));
  }
}

// ─────────────────────────────────────────────────────────────
// VITRINE DE LOJAS — lista pública das lojas do marketplace
// ─────────────────────────────────────────────────────────────
class StoresListScreen extends StatelessWidget {
  const StoresListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Lojas'),
            backgroundColor: AppColors.delivery,
            foregroundColor: Colors.white),
        body: StreamBuilder<List<StoreModel>>(
          stream: FS.storesStream(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final stores = snap.data ?? [];
            if (stores.isEmpty) {
              return const EmptyState(
                  emoji: '🏪',
                  title: 'Nenhuma loja ainda',
                  subtitle: 'As lojas cadastradas aparecerão aqui');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stores.length,
              itemBuilder: (_, i) {
                final s = stores[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StoreProfileScreen(store: s))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: AppDecorations.card(r: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: [
                      SizedBox(
                          height: 88,
                          width: double.infinity,
                          child: s.bannerUrl == null
                              ? Container(
                                  decoration: const BoxDecoration(
                                      gradient: AppGradients.delivery))
                              : CachedNetworkImage(
                                  imageUrl: s.bannerUrl!, fit: BoxFit.cover)),
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12)),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: s.logoUrl == null
                                    ? const Text('🏪',
                                        style: TextStyle(fontSize: 20))
                                    : CachedNetworkImage(
                                        imageUrl: s.logoUrl!,
                                        fit: BoxFit.cover,
                                        width: 44,
                                        height: 44)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Flexible(
                                        child: Text(s.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14))),
                                    if (s.verified)
                                      const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.verified_rounded,
                                              size: 15,
                                              color: AppColors.primary)),
                                  ]),
                                  Text(
                                      '${s.totalProducts} produtos · ${s.city ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textLight)),
                                ])),
                            if (s.totalReviews > 0)
                              Row(children: [
                                const Icon(Icons.star_rounded,
                                    size: 15, color: AppColors.gold),
                                Text(' ${s.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ]),
                          ])),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// PERFIL PÚBLICO DA LOJA — vitrine de produtos para o comprador
// ─────────────────────────────────────────────────────────────
class StoreProfileScreen extends StatelessWidget {
  final StoreModel store;
  const StoreProfileScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: AppColors.delivery,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: store.bannerUrl == null
                  ? Container(
                      decoration:
                          const BoxDecoration(gradient: AppGradients.delivery))
                  : CachedNetworkImage(
                      imageUrl: store.bannerUrl!, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8)
                      ]),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: store.logoUrl == null
                      ? const Text('🏪', style: TextStyle(fontSize: 26))
                      : CachedNetworkImage(
                          imageUrl: store.logoUrl!,
                          fit: BoxFit.cover,
                          width: 58,
                          height: 58)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Flexible(
                          child: Text(store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900))),
                      if (store.verified)
                        const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(Icons.verified_rounded,
                                size: 17, color: AppColors.primary)),
                    ]),
                    Text('${store.city ?? ''} ${store.state ?? ''}'.trim(),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                    if (store.totalReviews > 0)
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.gold),
                        Text(
                            ' ${store.rating.toStringAsFixed(1)} (${store.totalReviews} avaliações)',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                  ])),
            ]),
          )),
          if (store.description != null && store.description!.isNotEmpty)
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(store.description!,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: AppColors.textMedium)),
            )),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SecHeader(title: 'Produtos (${store.totalProducts})'),
          )),
          StreamBuilder<List<ProductModel>>(
            stream: FS.productsStream(storeId: store.id),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator())));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                    child: Padding(
                  padding: EdgeInsets.all(30),
                  child: EmptyState(
                      emoji: '📦',
                      title: 'Sem produtos',
                      subtitle: 'Esta loja ainda não publicou produtos'),
                ));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .78),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final p = items[i];
                    return Container(
                      decoration: AppDecorations.card(r: 14),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: Text(p.emoji ?? '📦',
                                  style: const TextStyle(fontSize: 34)),
                            )),
                            const SizedBox(height: 8),
                            Text(p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Row(children: [
                              Text(PaySvc.fmt(p.finalPrice),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.delivery)),
                              if (p.onSale)
                                Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: AppTag('-${p.discountPercent}%',
                                        bg: const Color(0xFFFFEBEE),
                                        fg: AppColors.error)),
                            ]),
                          ]),
                    );
                  }, childCount: items.length),
                ),
              );
            },
          ),
        ]),
      );
}
