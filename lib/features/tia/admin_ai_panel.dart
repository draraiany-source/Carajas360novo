import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'tia_service.dart';

class AdminAiPanel extends StatefulWidget {
  const AdminAiPanel({super.key});

  @override
  State<AdminAiPanel> createState() => _AdminAiPanelState();
}

class _AdminAiPanelState extends State<AdminAiPanel> {
  bool _loading = true;
  String? _error;
  bool _enabled = true;
  bool _kill = false;
  String _provider = 'auto';
  final _tokenCap = TextEditingController();
  final _usd = TextEditingController();
  final _greeting = TextEditingController();
  final _knowledgeTitle = TextEditingController();
  final _knowledgeBody = TextEditingController();
  final _deleteUid = TextEditingController();
  Map<String, dynamic> _usage = {};
  Map<String, dynamic> _counts = {};
  Map<String, dynamic> _keys = {};
  List _errors = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCap.dispose();
    _usd.dispose();
    _greeting.dispose();
    _knowledgeTitle.dispose();
    _knowledgeBody.dispose();
    _deleteUid.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await TiaService.adminGet();
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Não foi possível ler a configuração. É preciso estar autenticado como admin e com as funções publicadas.';
      });
      return;
    }
    final config = Map<String, dynamic>.from((data['config'] as Map?) ?? {});
    setState(() {
      _loading = false;
      _enabled = config['enabled'] != false;
      _kill = config['killSwitch'] == true;
      _provider = (config['provider'] as String?)?.isNotEmpty == true ? config['provider'] as String : 'auto';
      _tokenCap.text = '${config['monthlyTokenCap'] ?? 2000000}';
      _usd.text = config['monthlyUsdBudget'] == null ? '' : '${config['monthlyUsdBudget']}';
      _greeting.text = config['greeting'] as String? ?? '';
      _usage = Map<String, dynamic>.from((data['usage'] as Map?) ?? {});
      _counts = Map<String, dynamic>.from((data['counts'] as Map?) ?? {});
      _keys = Map<String, dynamic>.from((data['keys'] as Map?) ?? {});
      _errors = (data['recentErrors'] as List?) ?? const [];
    });
  }

  Future<void> _save() async {
    final err = await TiaService.adminUpdate({
      'config': {
        'enabled': _enabled,
        'killSwitch': _kill,
        'provider': _provider == 'auto' ? '' : _provider,
        'monthlyTokenCap': int.tryParse(_tokenCap.text),
        'monthlyUsdBudget': _usd.text.trim().isEmpty ? null : num.tryParse(_usd.text),
        'greeting': _greeting.text.trim(),
      },
      if (_knowledgeTitle.text.trim().isNotEmpty && _knowledgeBody.text.trim().isNotEmpty)
        'knowledge': {
          'title': _knowledgeTitle.text.trim(),
          'body': _knowledgeBody.text.trim(),
        },
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Configuração da Tia Carajás IA salva.')));
    if (err == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(padding: const EdgeInsets.all(16), child: Text(_error!));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tia Carajás IA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Chaves presentes no servidor (sem revelar o valor): Gemini ${_keys['gemini'] == true ? 'sim' : 'não'}, '
            'OpenAI ${_keys['openai'] == true ? 'sim' : 'não'}, Anthropic ${_keys['anthropic'] == true ? 'sim' : 'não'}.'),
        Text('Mês ${_usage['month'] ?? '—'} · tokens ${_usage['tokens'] ?? 0} · estimativa USD ${_usage['estimatedUsd'] ?? 0}'),
        Text('Erros ${_counts['errors'] ?? 0} · encaminhamentos ${_counts['handoffs'] ?? 0} · pedidos originados na IA ${_counts['ordersFromAi'] ?? 0}'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('IA ativa'),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kill switch de custo'),
          value: _kill,
          onChanged: (v) => setState(() => _kill = v),
        ),
        DropdownButtonFormField<String>(
          initialValue: _provider,
          decoration: const InputDecoration(labelText: 'Provedor'),
          items: const [
            DropdownMenuItem(value: 'auto', child: Text('Automático')),
            DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
            DropdownMenuItem(value: 'openai', child: Text('OpenAI compatível')),
            DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
          ],
          onChanged: (v) => setState(() => _provider = v ?? 'auto'),
        ),
        TextField(
          controller: _tokenCap,
          decoration: const InputDecoration(labelText: 'Teto global de tokens no mês'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _usd,
          decoration: const InputDecoration(labelText: 'Orçamento global USD (vazio = só o teto de tokens)'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _greeting,
          decoration: const InputDecoration(labelText: 'Saudação (vazio usa o texto padrão)'),
        ),
        const SizedBox(height: 12),
        const Text('Base de conhecimento', style: TextStyle(fontWeight: FontWeight.w800)),
        TextField(controller: _knowledgeTitle, decoration: const InputDecoration(labelText: 'Título do artigo')),
        TextField(
          controller: _knowledgeBody,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Texto'),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
        const Divider(),
        const Text('Exclusão de dados (LGPD)', style: TextStyle(fontWeight: FontWeight.w800)),
        TextField(controller: _deleteUid, decoration: const InputDecoration(labelText: 'UID do usuário')),
        OutlinedButton(
          onPressed: () async {
            final uid = _deleteUid.text.trim();
            if (uid.isEmpty) return;
            final message = await TiaService.deleteUser(uid);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'Pronto.')));
          },
          child: const Text('Apagar conversas desse usuário'),
        ),
        const SizedBox(height: 12),
        const Text('Erros recentes', style: TextStyle(fontWeight: FontWeight.w800)),
        if (_errors.isEmpty) const Text('Nenhum erro registrado.'),
        for (final item in _errors)
          if (item is Map)
            ListTile(
              dense: true,
              title: Text('${item['message'] ?? ''}'),
              subtitle: Text('${item['at'] ?? ''}'),
            ),
        const SizedBox(height: 8),
        const Text(
          'Preços dos planos continuam vazios até você gravá-los. Os tetos técnicos iniciais estão no código e podem ser substituídos em config/aiPlans.',
          style: TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }
}
