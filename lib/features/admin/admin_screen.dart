import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../core/catalog/service_catalog.dart';
import '../../shared/widgets/official_icon.dart';
import '../../shared/widgets/widgets.dart';
import '../tia/admin_ai_panel.dart';

// ─────────────────────────────────────────────────────────────
// PAINEL ADMINISTRATIVO (Vol.6 – Painel Administrativo)
// Dashboard · Usuários · Validação · Categorias ·
// Financeiro · Marketing · Atendimento · Auditoria
// ─────────────────────────────────────────────────────────────
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = [
    'Usuários',
    'Validação',
    'Categorias',
    'Financeiro',
    'Marketing',
    'Atendimento',
    'Denúncias',
    'Auditoria',
    'Tia Carajás IA',
    'Configurações'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
                child: GradHeader(
                    gradient: AppGradients.dark,
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('⚙️ Painel Admin',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22)),
                            GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(11)),
                                    child: const Icon(Icons.close_rounded,
                                        color: Colors.white, size: 20))),
                          ]),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: FS.fetchDashboardKpis(),
                        builder: (_, snap) {
                          final k = snap.data;
                          final loading =
                              snap.connectionState == ConnectionState.waiting;
                          return Row(children: [
                            _kpi(loading ? '…' : '${k?['totalUsers'] ?? 0}',
                                'Usuários'),
                            const SizedBox(width: 8),
                            _kpi(loading ? '…' : '${k?['totalProviders'] ?? 0}',
                                'Prestadores'),
                            const SizedBox(width: 8),
                            _kpi(
                                loading
                                    ? '…'
                                    : PaySvc.fmt(
                                        (k?['revenue'] as double?) ?? 0),
                                'Faturamento'),
                          ]);
                        },
                      ),
                      const SizedBox(height: 14),
                      TabBar(
                        controller: _tab,
                        isScrollable: true,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        tabs: _tabs.map((t) => Tab(text: t)).toList(),
                      ),
                    ])))
          ],
          body: TabBarView(controller: _tab, children: [
            _UsersTab(),
            _ValidationTab(),
            _CategoriesTab(),
            _FinancialTab(),
            _MarketingTab(),
            _SupportTab(),
            _ReportsTab(),
            _AuditTab(),
            const AdminAiPanel(),
            _SettingsTab(),
          ]),
        ),
      );

  Widget _kpi(String val, String lbl) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 2),
            Text(lbl,
                style: const TextStyle(color: Colors.white70, fontSize: 10))
          ])));
}

// ═══════════════════════════════════════════════════════════════
// 1. GESTÃO DE USUÁRIOS (Clientes, Profissionais, Empresas, Bloqueios)
// ═══════════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 44,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  for (final f in [
                    ['all', 'Todos'],
                    ['client', 'Clientes'],
                    ['provider', 'Prestadores'],
                    ['company', 'Empresas'],
                    ['deliverer', 'Entregadores']
                  ])
                    Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                            onTap: () => setState(() => _filter = f[0]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: _filter == f[0]
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _filter == f[0]
                                          ? AppColors.primary
                                          : AppColors.border)),
                              child: Text(f[1],
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _filter == f[0]
                                          ? Colors.white
                                          : AppColors.textDark)),
                            ))),
                ])),
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
          stream: FS.adminUsersStream(limit: 50),
          builder: (_, s) {
            var docs = s.data?.docs ?? [];
            if (_filter != 'all')
              docs = docs
                  .where((d) => (d.data() as Map)['type'] == _filter)
                  .toList();
            if (docs.isEmpty)
              return const EmptyState(
                  emoji: '👥',
                  title: 'Sem usuários',
                  subtitle: 'Aguardando cadastros');
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final isActive = d['status'] != 'suspended';
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDecorations.card(r: 14),
                      child: ListTile(
                        leading: AppAvatar(
                            name: d['name'] ?? '?',
                            size: 40,
                            bg: _typeColor(d['type']),
                            r: 12),
                        title: Text(
                            d['name']?.toString().isNotEmpty == true
                                ? d['name']
                                : '—',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(
                            '${_typeLabel(d['type'])} · ${d['city'] ?? 'sem cidade'}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.secondary.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(isActive ? 'ativo' : 'suspenso',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? AppColors.secondary
                                        : AppColors.error))),
                        onTap: () => _userActions(
                            context, docs[i].id, d['name'] ?? '', isActive),
                      ));
                });
          },
        )),
      ]);

  String _typeLabel(String? t) {
    switch (t) {
      case 'provider':
        return '🔧 Prestador';
      case 'company':
        return '🏢 Empresa';
      case 'deliverer':
        return '🛵 Entregador';
      case 'admin':
        return '⚙️ Admin';
      default:
        return '👤 Cliente';
    }
  }

  Color _typeColor(String? t) {
    switch (t) {
      case 'provider':
        return AppColors.primary;
      case 'company':
        return AppColors.purple;
      case 'deliverer':
        return AppColors.delivery;
      default:
        return AppColors.secondary;
    }
  }

  void _userActions(
          BuildContext context, String uid, String name, bool isActive) =>
      showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SheetHandle(),
                  const SizedBox(height: 12),
                  Text('Ações: $name',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (isActive)
                    ListTile(
                        leading: const Icon(Icons.block_rounded,
                            color: AppColors.error),
                        title: const Text('Suspender conta'),
                        onTap: () async {
                          await FS.suspendUser(uid);
                          if (context.mounted) {
                            Navigator.pop(context);
                            snack(context, 'Conta suspensa',
                                bg: AppColors.error);
                          }
                        })
                  else
                    ListTile(
                        leading: const Icon(Icons.refresh_rounded,
                            color: AppColors.secondary),
                        title: const Text('Reativar conta'),
                        onTap: () async {
                          await FS.reactivateUser(uid);
                          if (context.mounted) {
                            Navigator.pop(context);
                            snack(context, 'Conta reativada',
                                bg: AppColors.secondary);
                          }
                        }),
                  ListTile(
                      leading: const Icon(Icons.history_rounded,
                          color: AppColors.primary),
                      title: const Text('Ver histórico'),
                      onTap: () => Navigator.pop(context)),
                ]),
              ));
}

// ═══════════════════════════════════════════════════════════════
// 2. VALIDAÇÃO DE PROFISSIONAIS E EMPRESAS
// ═══════════════════════════════════════════════════════════════
class _ValidationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Column(children: [
        Container(
            color: Colors.white,
            child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                tabs: [Tab(text: '🔧 Prestadores'), Tab(text: '🏢 Empresas')])),
        Expanded(
            child: TabBarView(children: [
          _pendingProviders(context),
          _pendingCompanies(context)
        ])),
      ]));

  Widget _pendingProviders(BuildContext context) =>
      StreamBuilder<QuerySnapshot>(
        stream: FS.pendingProvidersStream(),
        builder: (_, s) {
          final docs = s.data?.docs ?? [];
          if (docs.isEmpty)
            return const EmptyState(
                emoji: '✅',
                title: 'Sem pendências',
                subtitle: 'Todos os prestadores aprovados');
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AppDecorations.card(r: 14),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            AppAvatar(
                                name: d['name'] ?? '?',
                                size: 44,
                                bg: AppColors.orange,
                                r: 12),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(d['name'] ?? '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  const Text(
                                      '⏳ Aguardando aprovação · Documentos enviados',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600)),
                                ])),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () => _viewDocuments(context, d),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10)),
                                    child: const Text('Ver documentos',
                                        style: TextStyle(fontSize: 12)))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: () async {
                                      await FS.approveProvider(docs[i].id);
                                      if (context.mounted)
                                        snack(context, '✅ Prestador aprovado!',
                                            bg: AppColors.secondary);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10)),
                                    child: const Text('Aprovar',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)))),
                          ]),
                        ]));
              });
        },
      );

  Widget _pendingCompanies(BuildContext context) =>
      StreamBuilder<QuerySnapshot>(
        stream: FS.pendingCompaniesStream(),
        builder: (_, s) {
          final docs = s.data?.docs ?? [];
          if (docs.isEmpty)
            return const EmptyState(
                emoji: '✅',
                title: 'Sem pendências',
                subtitle: 'Todas as empresas aprovadas');
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AppDecorations.card(r: 14),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      AppAvatar(
                          name: d['name'] ?? '?',
                          size: 44,
                          bg: AppColors.purple,
                          r: 12),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(d['name'] ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('CNPJ: ${d['cnpj'] ?? '—'}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight)),
                          ])),
                      ElevatedButton(
                          onPressed: () async {
                            await FS.approveCompany(docs[i].id);
                            if (context.mounted)
                              snack(context, '✅ Empresa aprovada!',
                                  bg: AppColors.secondary);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8)),
                          child: const Text('Aprovar',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700))),
                    ]));
              });
        },
      );

  void _viewDocuments(BuildContext context, Map<String, dynamic> providerData) {
    final docs = List<String>.from(providerData['documents'] ?? []);
    showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                Text('Documentos: ${providerData['name'] ?? '—'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: EmptyState(
                          emoji: '📄',
                          title: 'Nenhum documento',
                          subtitle: 'O prestador ainda não enviou documentos'))
                else
                  for (final url in docs)
                    ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined,
                          color: AppColors.primary),
                      title: Text(url.split('/').last,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.open_in_new_rounded,
                          size: 18, color: AppColors.textLight),
                      onTap: () => snack(context, 'Abrindo documento...',
                          bg: AppColors.primary),
                    ),
                const SizedBox(height: 12),
                for (final doc in [
                  'CPF',
                  'Comprovante de endereço',
                  'Certificação/Registro profissional'
                ])
                  ListTile(
                    leading: const Icon(Icons.description_outlined,
                        color: AppColors.textLight),
                    title: Text(doc, style: const TextStyle(fontSize: 13)),
                    trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('pendente',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700))),
                  ),
              ]),
            ));
  }
}

// ═══════════════════════════════════════════════════════════════
// 3. CATEGORIAS E SERVIÇOS (criar/editar/excluir/ordenação)
// ═══════════════════════════════════════════════════════════════
class _CategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
            onPressed: () => _editCategory(context),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white)),
        body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: Categories.all.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Catálogo oficial do aplicativo. O Firestore continua gravando o id da profissão. Máquinas e Equipamentos e Ver Todas aguardam arte oficial.',
                    style: TextStyle(color: AppColors.textMedium, height: 1.35),
                  ),
                );
              }
              final c = Categories.all[i - 1];
              final profession = ServiceCatalog.professionById(c.id);
              final parent = profession == null
                  ? null
                  : ServiceCatalog.categoryById(profession.categoryId);
              return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: AppDecorations.card(r: 14),
                  child: ListTile(
                    leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: OfficialIcon(
                        label: c.name,
                        assetPath: profession?.asset256,
                        pendingArt: profession?.asset == null,
                      ),
                    ),
                    title: profession?.asset != null
                        ? Text(profession!.id,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13))
                        : Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(
                        '${parent?.name ?? c.group}'
                        '${parent?.pendingArt == true ? ' · aguardando arte oficial' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primary),
                          onPressed: () =>
                              _editCategory(context, name: c.name)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          onPressed: () => _confirmDelete(context, c.name)),
                    ]),
                  ));
            }),
      );

  void _editCategory(BuildContext context, {String? name}) {
    final ctrl = TextEditingController(text: name);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const SheetHandle(),
                const SizedBox(height: 16),
                Text(name == null ? 'Nova categoria' : 'Editar categoria',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                    controller: ctrl,
                    decoration:
                        const InputDecoration(hintText: 'Nome da categoria')),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          snack(context, '✅ Categoria salva!',
                              bg: AppColors.secondary);
                        },
                        child: const Text('Salvar'))),
              ]),
            ));
  }

  void _confirmDelete(BuildContext context, String name) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: const Text('Excluir categoria'),
            content: Text(
                'Deseja realmente excluir "$name"? Serviços vinculados poderão ficar sem categoria.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    snack(context, 'Categoria excluída', bg: AppColors.error);
                  },
                  child: const Text('Excluir',
                      style: TextStyle(color: AppColors.error))),
            ],
          ));
}

// ═══════════════════════════════════════════════════════════════
// 4. FINANCEIRO (comissões, repasses, saques, estornos, assinaturas)
// ═══════════════════════════════════════════════════════════════
class _FinancialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: FS.fetchFinancialReport(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data ?? {};
          final rows = [
            [
              '💰',
              'Receita bruta (serviços concluídos)',
              PaySvc.fmt((r['grossRevenue'] as double?) ?? 0),
              AppColors.secondary
            ],
            [
              '📊',
              'Comissão plataforma (15%)',
              PaySvc.fmt((r['commission'] as double?) ?? 0),
              AppColors.primary
            ],
            [
              '🏦',
              'Repasses a prestadores',
              PaySvc.fmt((r['netToProviders'] as double?) ?? 0),
              AppColors.secondary
            ],
            [
              '💳',
              'Total processado (créditos)',
              PaySvc.fmt((r['pixProcessed'] as double?) ?? 0),
              AppColors.pix
            ],
            [
              '❌',
              'Estornos',
              PaySvc.fmt((r['refunds'] as double?) ?? 0),
              AppColors.error
            ],
            [
              '✅',
              'Serviços concluídos',
              '${r['completedCount'] ?? 0}',
              AppColors.gold
            ],
          ];
          return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Visão geral',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 10),
                    for (final row in rows)
                      Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppDecorations.card(r: 14),
                          child: ListTile(
                            leading: Text(row[0] as String,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(row[1] as String,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            trailing: Text(row[2] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: row[3] as Color)),
                          )),
                    const SizedBox(height: 16),
                    const Text('Ações rápidas',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () =>
                                  _exportReport(context, rows, csv: true),
                              icon: const Icon(Icons.receipt_long_outlined,
                                  size: 18),
                              label: const Text('Exportar CSV',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12)))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () =>
                                  _exportReport(context, rows, csv: false),
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  size: 18),
                              label: const Text('Exportar PDF',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textDark,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12)))),
                    ]),
                  ]));
        },
      );

  Future<void> _exportReport(BuildContext context, List<List<Object>> rows,
      {required bool csv}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (csv) {
        final buffer = StringBuffer('Relatório,Valor\n');
        for (final row in rows) {
          buffer.writeln('"${row[1]}","${row[2]}"');
        }
        final bytes = utf8.encode(buffer.toString());
        final name = 'relatorio_financeiro_$timestamp.csv';
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(Uint8List.fromList(bytes),
                name: name, mimeType: 'text/csv'),
          ],
          text: 'Relatório financeiro — ServiçoConecta',
        ));
      } else {
        final doc = pw.Document();
        doc.addPage(pw.Page(
          build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório Financeiro',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'ServiçoConecta — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2)
                  },
                  children: [
                    pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.blue800),
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Descrição',
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Valor',
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold))),
                        ]),
                    for (final row in rows)
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${row[0]} ${row[1]}')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${row[2]}')),
                      ]),
                  ],
                ),
              ]),
        ));
        final pdfBytes = await doc.save();
        final name = 'relatorio_financeiro_$timestamp.pdf';
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(pdfBytes, name: name, mimeType: 'application/pdf'),
          ],
          text: 'Relatório financeiro — ServiçoConecta',
        ));
      }
    } catch (e) {
      if (context.mounted)
        snack(context, 'Erro ao gerar relatório: $e', bg: AppColors.error);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 5. MARKETING (banners, cupons, campanhas, push)
// ═══════════════════════════════════════════════════════════════
class _MarketingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 2,
      child: Column(children: [
        Container(
            color: Colors.white,
            child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary,
                tabs: [Tab(text: '🖼️ Banners'), Tab(text: '🎟️ Cupons')])),
        Expanded(
            child:
                TabBarView(children: [_banners(context), _coupons(context)])),
      ]));

  Widget _banners(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
            onPressed: () => _newBanner(context),
            backgroundColor: AppColors.primary,
            mini: true,
            child: const Icon(Icons.add, color: Colors.white)),
        body: StreamBuilder<QuerySnapshot>(
            stream: FS.adminBannersStream(),
            builder: (_, s) {
              final docs = s.data?.docs ?? [];
              if (docs.isEmpty)
                return const EmptyState(
                    emoji: '🖼️',
                    title: 'Sem banners',
                    subtitle: 'Adicione banners promocionais para a home');
              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: AppDecorations.card(r: 14),
                        child: ListTile(
                          leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.primary)),
                          title: Text(d['title'] ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          subtitle: Text(
                              d['active'] == true ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: d['active'] == true
                                      ? AppColors.secondary
                                      : AppColors.textLight)),
                          trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              onPressed: () => FS.deleteBanner(docs[i].id)),
                        ));
                  });
            }),
      );

  Widget _coupons(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
            onPressed: () => _newCoupon(context),
            backgroundColor: AppColors.primary,
            mini: true,
            child: const Icon(Icons.add, color: Colors.white)),
        body: StreamBuilder<QuerySnapshot>(
            stream: FS.adminCouponsStream(),
            builder: (_, s) {
              final docs = s.data?.docs ?? [];
              if (docs.isEmpty)
                return const EmptyState(
                    emoji: '🎟️',
                    title: 'Sem cupons',
                    subtitle: 'Crie cupons promocionais');
              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: AppDecorations.card(r: 14),
                        child: ListTile(
                          leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              alignment: Alignment.center,
                              child: const Icon(Icons.local_offer_outlined,
                                  color: AppColors.gold)),
                          title: Text(d['code'] ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13)),
                          subtitle: Text(d['description'] ?? '',
                              style: const TextStyle(fontSize: 11)),
                        ));
                  });
            }),
      );

  void _newBanner(BuildContext context) {
    final title = TextEditingController();
    final url = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const SheetHandle(),
                const SizedBox(height: 16),
                const Text('Novo banner',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                    controller: title,
                    decoration:
                        const InputDecoration(hintText: 'Título do banner')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: url,
                    decoration:
                        const InputDecoration(hintText: 'URL da imagem')),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          await FS.saveBanner({
                            'title': title.text,
                            'imageUrl': url.text,
                            'active': true,
                            'order': 0
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            snack(context, '✅ Banner criado!',
                                bg: AppColors.secondary);
                          }
                        },
                        child: const Text('Criar banner'))),
              ]),
            ));
  }

  void _newCoupon(BuildContext context) {
    final code = TextEditingController();
    final desc = TextEditingController();
    final discount = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const SheetHandle(),
                const SizedBox(height: 16),
                const Text('Novo cupom',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'CÓDIGO')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: desc,
                    decoration: const InputDecoration(hintText: 'Descrição')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: discount,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Desconto (%)')),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          await FS.createCoupon({
                            'code': code.text.toUpperCase(),
                            'description': desc.text,
                            'discount': double.tryParse(discount.text) ?? 0,
                            'isPercentage': true,
                            'expiresAt': Timestamp.fromDate(
                                DateTime.now().add(const Duration(days: 30)))
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            snack(context, '✅ Cupom criado!',
                                bg: AppColors.secondary);
                          }
                        },
                        child: const Text('Criar cupom'))),
              ]),
            ));
  }
}

// ═══════════════════════════════════════════════════════════════
// 6. ATENDIMENTO (chamados, FAQ, relatórios de suporte)
// ═══════════════════════════════════════════════════════════════
class _SupportTab extends StatefulWidget {
  @override
  State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
            height: 44,
            child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  for (final f in [
                    [null, 'Todos'],
                    ['open', 'Abertos'],
                    ['inProgress', 'Em atendimento'],
                    ['resolved', 'Resolvidos']
                  ])
                    Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                            onTap: () => setState(() => _statusFilter = f[0]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: _statusFilter == f[0]
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _statusFilter == f[0]
                                          ? AppColors.primary
                                          : AppColors.border)),
                              child: Text(f[1]!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _statusFilter == f[0]
                                          ? Colors.white
                                          : AppColors.textDark)),
                            ))),
                ])),
        Expanded(
            child: StreamBuilder<List<TicketModel>>(
          stream: FS.adminTicketsStream(status: _statusFilter),
          builder: (_, s) {
            final tickets = s.data ?? [];
            if (tickets.isEmpty)
              return const EmptyState(
                  emoji: '🎧',
                  title: 'Sem chamados',
                  subtitle: 'Nenhum chamado nesta categoria');
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                itemBuilder: (_, i) {
                  final t = tickets[i];
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDecorations.card(r: 14),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(t.subject,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14))),
                              Text(t.statusLabel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(height: 4),
                            Text(t.message,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMedium),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 10),
                            Row(children: [
                              if (t.status != TicketStatus.inProgress)
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: () => FS.updateTicketStatus(
                                            t.id, 'inProgress'),
                                        style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8)),
                                        child: const Text('Atender',
                                            style: TextStyle(fontSize: 11)))),
                              if (t.status != TicketStatus.inProgress)
                                const SizedBox(width: 8),
                              Expanded(
                                  child: ElevatedButton(
                                      onPressed: () => FS.updateTicketStatus(
                                          t.id, 'resolved'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8)),
                                      child: const Text('Resolver',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)))),
                            ]),
                          ]));
                });
          },
        )),
      ]);
}

// ═══════════════════════════════════════════════════════════════
// 7. AUDITORIA (todas as ações críticas registradas — Vol.6)
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// DENÚNCIAS (Vol.20: Administração — moderação de conteúdo/usuários)
// ═══════════════════════════════════════════════════════════════
class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<List<ReportModel>>(
        stream: FS.reportsStream(),
        builder: (_, snap) {
          final reports = snap.data ?? [];
          if (reports.isEmpty)
            return const EmptyState(
                emoji: '🚩',
                title: 'Sem denúncias',
                subtitle: 'Denúncias de usuários aparecerão aqui');
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final r = reports[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppDecorations.card(r: 16),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(r.reason,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14))),
                          AppTag(r.statusLabel,
                              bg: AppColors.background, fg: AppColors.textDark),
                        ]),
                        const SizedBox(height: 6),
                        Text('Denunciado: ${r.targetName}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textDark)),
                        Text('Por: ${r.reporterName} · ${fmtDate(r.createdAt)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight)),
                        if (r.details.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(r.details,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium))),
                        if (r.status == ReportStatus.pending ||
                            r.status == ReportStatus.reviewing)
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(children: [
                                if (r.status == ReportStatus.pending)
                                  Expanded(
                                      child: OutlinedButton(
                                          onPressed: () =>
                                              FS.updateReportStatus(
                                                  r.id, ReportStatus.reviewing),
                                          style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8)),
                                          child: const Text('Analisar',
                                              style: TextStyle(fontSize: 12)))),
                                if (r.status == ReportStatus.reviewing) ...[
                                  Expanded(
                                      child: OutlinedButton(
                                          onPressed: () =>
                                              FS.updateReportStatus(
                                                  r.id, ReportStatus.dismissed),
                                          style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8)),
                                          child: const Text('Arquivar',
                                              style: TextStyle(fontSize: 12)))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: ElevatedButton(
                                          onPressed: () =>
                                              FS.updateReportStatus(
                                                  r.id, ReportStatus.resolved),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.secondary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8)),
                                          child: const Text('Resolver',
                                              style: TextStyle(fontSize: 12)))),
                                ],
                              ])),
                      ]),
                );
              });
        },
      );
}

class _AuditTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<List<AuditLogModel>>(
        stream: FS.auditLogStream(),
        builder: (_, s) {
          final logs = s.data ?? [];
          if (logs.isEmpty)
            return const EmptyState(
                emoji: '📜',
                title: 'Sem registros',
                subtitle: 'As ações administrativas aparecerão aqui');
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final l = logs[i];
                return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AppDecorations.card(r: 14),
                    child: ListTile(
                      leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: AppColors.textDark.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.history_rounded,
                              color: AppColors.textDark, size: 18)),
                      title: Text(l.action,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('${l.adminName} · alvo: ${l.target}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                      trailing: Text(fmtDate(l.timestamp),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight)),
                    ));
              });
        },
      );
}

// ═══════════════════════════════════════════════════════════════
// CONFIGURAÇÕES GERAIS DA PLATAFORMA (Vol.20: Administração)
// ═══════════════════════════════════════════════════════════════
class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _commissionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _maintenanceMode = false;
  bool _loaded = false, _saving = false;

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _loadOnce(Map<String, dynamic> config) {
    if (_loaded) return;
    _loaded = true;
    _commissionCtrl.text =
        (((config['commissionRate'] as num?) ?? AppConst.commission) * 100)
            .toStringAsFixed(0);
    _emailCtrl.text = config['supportEmail'] ?? '';
    _phoneCtrl.text = config['supportPhone'] ?? '';
    _maintenanceMode = config['maintenanceMode'] ?? false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final rate =
        (double.tryParse(_commissionCtrl.text.replaceAll(',', '.')) ?? 15) /
            100;
    await FS.updatePlatformConfig({
      'commissionRate': rate,
      'supportEmail': _emailCtrl.text.trim(),
      'supportPhone': _phoneCtrl.text.trim(),
      'maintenanceMode': _maintenanceMode,
    });
    if (mounted) {
      setState(() => _saving = false);
      snack(context, '✅ Configurações salvas!', bg: AppColors.secondary);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
        stream: FS.platformConfigStream(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          _loadOnce(snap.data!);
          return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comissão da plataforma',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Percentual retido em cada serviço concluído',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _commissionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            suffixText: '%', hintText: '15')),
                    const SizedBox(height: 20),
                    const Text('Contato de suporte',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'suporte@servicoconecta.com.br')),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '(11) 4000-0000')),
                    const SizedBox(height: 20),
                    Container(
                        decoration: AppDecorations.card(r: 14),
                        child: SwitchListTile(
                          title: const Text('Modo manutenção',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: const Text(
                              'Bloqueia o acesso de clientes e prestadores temporariamente',
                              style: TextStyle(fontSize: 11)),
                          value: _maintenanceMode,
                          activeColor: AppColors.error,
                          onChanged: (v) =>
                              setState(() => _maintenanceMode = v),
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Salvar configurações',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                        )),
                  ]));
        },
      );
}
