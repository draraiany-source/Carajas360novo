import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';
import '../wallet/wallet_screen.dart';

// ─────────────────────────────────────────────────────────────
// COMPANY PROFILE SCREEN (Vol.5: coleção companies /
// Vol.2 perfil Empresa / Vol.7: planos corporativos)
// ─────────────────────────────────────────────────────────────
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});
  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileState();
}

class _CompanyProfileState extends State<CompanyProfileScreen> {
  final String _ownerId = AuthService.uid ?? '';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: _ownerId.isEmpty
            ? const EmptyState(
                emoji: '🏢',
                title: 'Não autenticado',
                subtitle: 'Faça login para gerenciar sua empresa')
            : FutureBuilder<CompanyModel?>(
                future: FS.getCompanyByOwner(_ownerId),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final company = snap.data;
                  return company == null
                      ? _RegisterCompanyForm(ownerId: _ownerId)
                      : _CompanyDashboard(company: company);
                },
              ),
      );
}

// ── Cadastro de empresa (quando ainda não existe) ──────────────
class _RegisterCompanyForm extends StatefulWidget {
  final String ownerId;
  const _RegisterCompanyForm({required this.ownerId});
  @override
  State<_RegisterCompanyForm> createState() => _RegisterCompanyFormState();
}

class _RegisterCompanyFormState extends State<_RegisterCompanyForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnpj = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _selectedCats = <String>{};
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _cnpj.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedCats.isEmpty) {
      snack(context, 'Selecione ao menos uma categoria de atuação');
      return;
    }
    setState(() => _loading = true);

    final company = CompanyModel(
      id: widget.ownerId,
      ownerId: widget.ownerId,
      name: _name.text.trim(),
      cnpj: _cnpj.text.replaceAll(RegExp(r'\D'), ''),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim().toUpperCase(),
      categories: _selectedCats.toList(),
      plan: PlanTier.free,
      verified: false,
      active: true,
      createdAt: DateTime.now(),
    );
    await FS.saveCompany(company);
    await FS.switchProfileType('company');
    if (mounted) {
      setState(() => _loading = false);
      snack(context, '✅ Empresa cadastrada! Aguarde aprovação.',
          bg: AppColors.secondary);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
      loading: _loading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  decoration:
                      AppDecorations.gradient(AppGradients.primary, r: 20),
                  padding: const EdgeInsets.all(20),
                  child: const Column(children: [
                    Text('🏢', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('Cadastre sua empresa',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                        textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text('Gerencie equipe, categorias e leads em um só lugar',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center),
                  ])),
              const SizedBox(height: 20),
              _field(_name, 'Nome da empresa *', Icons.business_outlined,
                  caps: true),
              _field(_cnpj, 'CNPJ *', Icons.badge_outlined,
                  kt: TextInputType.number,
                  fmt: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14)
                  ],
                  val: (v) =>
                      (v?.replaceAll(RegExp(r'\D'), '').length ?? 0) < 14
                          ? 'CNPJ inválido'
                          : null),
              _field(_email, 'E-mail comercial *', Icons.email_outlined,
                  kt: TextInputType.emailAddress),
              _field(_phone, 'Telefone *', Icons.phone_outlined,
                  kt: TextInputType.phone),
              Row(children: [
                Expanded(
                    child: _field(
                        _city, 'Cidade *', Icons.location_city_outlined,
                        caps: true)),
                const SizedBox(width: 10),
                SizedBox(
                    width: 80,
                    child: _field(_state, 'UF *', Icons.map_outlined, fmt: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(2)
                    ])),
              ]),
              const SizedBox(height: 8),
              const Text('Categorias de atuação *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              // Todas as categorias, agrupadas por segmento e com rolagem.
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      for (final g in Categories.groups) ...[
                        Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 8),
                            child: Text(g.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textLight,
                                    letterSpacing: .6))),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: Categories.all
                                .where((c) => c.group == g)
                                .map((c) {
                              final sel = _selectedCats.contains(c.id);
                              return CatChip(
                                  emoji: c.emoji,
                                  name: c.name,
                                  categoryId: c.id,
                                  color: c.color,
                                  selected: sel,
                                  onTap: () => setState(() => sel
                                      ? _selectedCats.remove(c.id)
                                      : _selectedCats.add(c.id)));
                            }).toList()),
                      ],
                    ])),
              ),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: const Text('Cadastrar empresa',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  )),
              const SizedBox(height: 40),
            ])),
      ));

  Widget _field(TextEditingController c, String hint, IconData icon,
          {TextInputType? kt,
          List<TextInputFormatter>? fmt,
          String? Function(String?)? val,
          bool caps = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: c,
            keyboardType: kt,
            inputFormatters: fmt,
            textCapitalization:
                caps ? TextCapitalization.words : TextCapitalization.none,
            validator:
                val ?? (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null,
            decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
          ));
}

// ── Dashboard da empresa (quando já existe) ─────────────────────
class _CompanyDashboard extends StatelessWidget {
  final CompanyModel company;
  const _CompanyDashboard({required this.company});

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: GradHeader(
                gradient: AppGradients.primary,
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          AppAvatar(
                              url: company.logoUrl,
                              name: company.name,
                              size: 52,
                              bg: AppColors.warning,
                              r: 14),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(company.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17)),
                                Text(
                                    company.verified
                                        ? '✅ Verificada'
                                        : '⏳ Aguardando aprovação',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11)),
                              ]),
                        ]),
                      ]),
                  const SizedBox(height: 14),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Plano ${company.planLabel}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            if (company.plan == PlanTier.free)
                              ElevatedButton(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const PixScreen(
                                              amount: 149.90,
                                              desc:
                                                  'Upgrade Plano Profissional - Empresa'))),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.textDark,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6)),
                                  child: const Text('Upgrade',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800))),
                          ])),
                ]))),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  StatCard(
                      value: '${company.teamSize}',
                      label: 'Equipe',
                      color: AppColors.primary),
                  const StatCard(
                      value: '0',
                      label: 'Leads no mês',
                      color: AppColors.secondary),
                  StatCard(
                      value: '${company.categories.length}',
                      label: 'Categorias',
                      color: AppColors.warning),
                ]))),
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _menuCard(
                      '👥',
                      'Gerenciar equipe',
                      'Adicionar e remover profissionais',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  _EmployeesScreen(companyId: company.id)))),
                  _menuCard(
                      '🏢',
                      'Filiais',
                      'Gerenciar endereços e unidades',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  _BranchesScreen(companyId: company.id)))),
                  _menuCard(
                      '📄',
                      'Contratos',
                      'Acordos com clientes corporativos',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  _ContractsScreen(companyId: company.id)))),
                  _menuCard(
                      '🏪',
                      'Minha loja',
                      'Anuncie produtos no marketplace',
                      () => Navigator.pushNamed(context, Routes.store)),
                  _menuCard(
                      '🏷️',
                      'Categorias de atuação',
                      '${company.categories.length} categorias ativas',
                      () => snack(context,
                          'Para alterar suas categorias, fale com o suporte pela Central de Ajuda.',
                          bg: AppColors.primary)),
                  _menuCard(
                      '💳',
                      'Assinatura',
                      'Plano ${company.planLabel}',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WalletScreen()))),
                  _menuCard(
                      '⚙️',
                      'Dados da empresa',
                      company.cnpj,
                      () => snack(context,
                          'Para alterar CNPJ ou razão social, fale com o suporte pela Central de Ajuda.',
                          bg: AppColors.primary)),
                ]))),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]);

  Widget _menuCard(String icon, String title, String sub, VoidCallback onTap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppDecorations.card(r: 14),
        child: ListTile(
            leading: Text(icon, style: const TextStyle(fontSize: 22)),
            title: Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(sub,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textLight)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight),
            onTap: onTap),
      );
}

// ─────────────────────────────────────────────────────────────
// EQUIPE (Vol.15: Empresas — Funcionários)
// ─────────────────────────────────────────────────────────────
class _EmployeesScreen extends StatelessWidget {
  final String companyId;
  const _EmployeesScreen({required this.companyId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Equipe'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _addEmployee(context),
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.add)),
        body: StreamBuilder<List<EmployeeModel>>(
          stream: FS.employeesStream(companyId),
          builder: (_, snap) {
            final employees = snap.data ?? [];
            if (employees.isEmpty)
              return const EmptyState(
                  emoji: '👥',
                  title: 'Sem funcionários ainda',
                  subtitle: 'Toque no + para adicionar sua equipe');
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: employees.length,
                itemBuilder: (_, i) {
                  final e = employees[i];
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDecorations.card(r: 14),
                      child: ListTile(
                        leading: AppAvatar(
                            url: e.photoUrl,
                            name: e.name,
                            size: 42,
                            bg: AppColors.primary,
                            r: 12),
                        title: Text(e.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(e.role,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error),
                            onPressed: () =>
                                FS.removeEmployee(e.id, companyId)),
                      ));
                });
          },
        ),
      );

  void _addEmployee(BuildContext context) {
    final name = TextEditingController(),
        role = TextEditingController(),
        email = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Adicionar funcionário',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(hintText: 'Nome completo')),
                const SizedBox(height: 10),
                TextField(
                    controller: role,
                    decoration: const InputDecoration(
                        hintText: 'Cargo (ex: Eletricista, Recepcionista)')),
                const SizedBox(height: 10),
                TextField(
                    controller: email,
                    decoration:
                        const InputDecoration(hintText: 'E-mail (opcional)')),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          if (name.text.trim().isEmpty ||
                              role.text.trim().isEmpty) return;
                          await FS.addEmployee(
                              companyId: companyId,
                              name: name.text.trim(),
                              role: role.text.trim(),
                              email: email.text.trim().isEmpty
                                  ? null
                                  : email.text.trim());
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Adicionar'))),
              ]),
            ));
  }
}

// ─────────────────────────────────────────────────────────────
// FILIAIS (Vol.15: Empresas — Filiais)
// ─────────────────────────────────────────────────────────────
class _BranchesScreen extends StatelessWidget {
  final String companyId;
  const _BranchesScreen({required this.companyId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Filiais'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _addBranch(context),
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.add)),
        body: StreamBuilder<List<BranchModel>>(
          stream: FS.branchesStream(companyId),
          builder: (_, snap) {
            final branches = snap.data ?? [];
            if (branches.isEmpty)
              return const EmptyState(
                  emoji: '🏢',
                  title: 'Sem filiais cadastradas',
                  subtitle: 'Toque no + para adicionar uma unidade');
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: branches.length,
                itemBuilder: (_, i) {
                  final b = branches[i];
                  return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppDecorations.card(r: 14),
                      child: ListTile(
                        leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.store_outlined,
                                color: AppColors.primary)),
                        title: Text(b.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text('${b.address}, ${b.city}-${b.state}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error),
                            onPressed: () => FS.removeBranch(b.id)),
                      ));
                });
          },
        ),
      );

  void _addBranch(BuildContext context) {
    final name = TextEditingController(),
        address = TextEditingController(),
        city = TextEditingController(),
        state = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Adicionar filial',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(hintText: 'Nome da unidade')),
                const SizedBox(height: 10),
                TextField(
                    controller: address,
                    decoration: const InputDecoration(hintText: 'Endereço')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: city,
                          decoration:
                              const InputDecoration(hintText: 'Cidade'))),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 70,
                      child: TextField(
                          controller: state,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          decoration: const InputDecoration(
                              hintText: 'UF', counterText: ''))),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          if (name.text.trim().isEmpty ||
                              address.text.trim().isEmpty) return;
                          await FS.addBranch(
                              companyId: companyId,
                              name: name.text.trim(),
                              address: address.text.trim(),
                              city: city.text.trim(),
                              state: state.text.trim().toUpperCase());
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Adicionar'))),
              ]),
            ));
  }
}

// ─────────────────────────────────────────────────────────────
// CONTRATOS (Vol.15: Empresas — Contratos)
// ─────────────────────────────────────────────────────────────
class _ContractsScreen extends StatelessWidget {
  final String companyId;
  const _ContractsScreen({required this.companyId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Contratos'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _addContract(context),
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.add)),
        body: StreamBuilder<List<ContractModel>>(
          stream: FS.contractsStream(companyId),
          builder: (_, snap) {
            final contracts = snap.data ?? [];
            if (contracts.isEmpty)
              return const EmptyState(
                  emoji: '📄',
                  title: 'Sem contratos ainda',
                  subtitle: 'Toque no + para criar um contrato');
            return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contracts.length,
                itemBuilder: (_, i) {
                  final c = contracts[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: AppDecorations.card(r: 16),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(c.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14))),
                            AppTag(c.statusLabel,
                                bg: AppColors.background,
                                fg: AppColors.textDark),
                          ]),
                          const SizedBox(height: 4),
                          Text('Cliente: ${c.clientName}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textDark)),
                          Text(
                              '${fmtDate(c.startDate)} até ${fmtDate(c.endDate)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight)),
                          const SizedBox(height: 6),
                          Text(PaySvc.fmt(c.value),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.secondary)),
                          if (c.status == ContractStatus.draft)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                        onPressed: () =>
                                            FS.updateContractStatus(
                                                c.id, ContractStatus.active),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.secondary,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10)),
                                        child: const Text('Ativar contrato',
                                            style: TextStyle(fontSize: 13))))),
                        ]),
                  );
                });
          },
        ),
      );

  void _addContract(BuildContext context) {
    final client = TextEditingController(),
        title = TextEditingController(),
        value = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Novo contrato',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                    controller: client,
                    decoration:
                        const InputDecoration(hintText: 'Nome do cliente')),
                const SizedBox(height: 10),
                TextField(
                    controller: title,
                    decoration:
                        const InputDecoration(hintText: 'Título do contrato')),
                const SizedBox(height: 10),
                TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Valor total (R\$)')),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          if (client.text.trim().isEmpty ||
                              title.text.trim().isEmpty) return;
                          final v = double.tryParse(
                                  value.text.replaceAll(',', '.')) ??
                              0;
                          final now = DateTime.now();
                          await FS.createContract(
                              companyId: companyId,
                              clientName: client.text.trim(),
                              title: title.text.trim(),
                              value: v,
                              startDate: now,
                              endDate: now.add(const Duration(days: 365)));
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Criar contrato'))),
              ]),
            ));
  }
}
