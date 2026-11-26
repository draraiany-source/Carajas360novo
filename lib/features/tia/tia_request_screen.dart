import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/constants/app_constants.dart';
import '../../features/home/home_layout.dart';
import '../../shared/widgets/official_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import 'tia_models.dart';
import 'tia_service.dart';
import 'tia_widgets.dart';

class TiaRequestScreen extends StatefulWidget {
  final String? providerId;
  final String? providerName;
  final String? category;
  const TiaRequestScreen({super.key, this.providerId, this.providerName, this.category});

  @override
  State<TiaRequestScreen> createState() => _TiaRequestScreenState();
}

class _TiaRequestScreenState extends State<TiaRequestScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  int _step = 0;
  String? _category;
  String _urgency = 'normal';
  bool _whatsapp = false;
  bool _busy = false;
  DateTime? _date;
  TimeOfDay? _time;
  final List<_Photo> _photos = [];
  TiaPhotoInsight? _insight;
  TiaEstimate? _estimate;
  String? _orderId;
  String? _requestId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = widget.category?.isNotEmpty == true ? widget.category : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photos.add(_Photo(Uint8List.fromList(bytes), file.name)));
  }

  Future<void> _analyze() async {
    if (_photos.isEmpty) {
      setState(() => _error = 'Anexe uma foto antes da análise.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final insight = await TiaService.analyzePhoto(
      bytes: _photos.first.bytes,
      note: _description.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _insight = insight;
      if (!insight.available) {
        _error = insight.reason;
      } else if ((insight.organizedDescription).isNotEmpty) {
        _description.text = insight.organizedDescription;
        _category = insight.suggestedCategoryId ?? _category;
      }
    });
  }

  Future<void> _price() async {
    final cat = _category;
    if (cat == null) return;
    setState(() => _busy = true);
    final estimate = await TiaService.estimate(cat);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _estimate = estimate;
    });
  }

  Future<void> _submit() async {
    if ((_category ?? '').isEmpty || _title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = 'Informe categoria, título e descrição antes de confirmar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await TiaService.confirm(TiaProposedAction(
      type: 'request_quote',
      label: 'Solicitar orçamento',
      payload: {
        'category': _category,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'providerId': widget.providerId,
        'urgent': _urgency == 'urgente',
        'whatsappOptIn': _whatsapp,
        'preferredDate': _date == null
            ? null
            : '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
        'preferredTime': _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      },
    ));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result['ok'] == true) {
        _orderId = result['id'] as String?;
        _requestId = result['requestId'] as String?;
        _step = 3;
      } else {
        _error = result['error'] as String? ?? 'A solicitação não foi registrada.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final form = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const C360PageBanner(
              icon: Icons.assignment_rounded,
              title: 'Solicitar serviço',
              subtitle: 'Descreva a necessidade, envie fotos e receba orçamentos de profissionais da região.',
            ),
            const SizedBox(height: 12),
            _steps(),
            const SizedBox(height: 12),
            if (_error != null)
              TiaBubble(text: _error!, alert: true),
            if (_step == 0) _describe(),
            if (_step == 1) _photosStep(),
            if (_step == 2) _review(),
            if (_step == 3) _done(),
            const SizedBox(height: 12),
            Row(children: [
              if (_step > 0 && _step < 3)
                OutlinedButton(onPressed: () => setState(() => _step -= 1), child: const Text('Voltar')),
              const Spacer(),
              if (_step == 0)
                FilledButton(onPressed: () => setState(() => _step = 1), child: const Text('Enviar fotos')),
              if (_step == 1)
                FilledButton(onPressed: () => setState(() => _step = 2), child: const Text('Revisar')),
              if (_step == 2)
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Enviando...' : 'Solicitar orçamento com a Tia Carajás IA'),
                ),
            ]),
          ],
        );
        if (!wide) return form;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: form),
          SizedBox(width: 320, child: _side()),
        ]);
      }),
    );
  }

  Widget _steps() {
    const labels = ['Descreva o serviço', 'Envie fotos', 'Receba orçamentos', 'Escolha'];
    return Row(children: [
      for (var i = 0; i < labels.length; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= _step ? AppColors.primary : AppColors.divider,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(labels[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
    ]);
  }

  Widget _describe() {
    final profession = ServiceCatalog.professionById(_category ?? '');
    final category = ServiceCatalog.categoryById(_category ?? '');
    final asset = profession?.asset512 ?? category?.asset512;
    final label = profession?.name ?? category?.name;
    return Column(children: [
      if (label != null)
        Align(
          alignment: Alignment.centerLeft,
          child: OfficialIcon(
            label: label,
            assetPath: asset,
            pendingArt: asset == null,
            tier: IconTier.subcategory,
          ),
        ),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: const InputDecoration(labelText: 'Categoria do serviço'),
        items: [
          for (final cat in Categories.all)
            DropdownMenuItem(value: cat.id, child: Text(cat.name)),
        ],
        onChanged: (v) => setState(() => _category = v),
      ),
      const SizedBox(height: 8),
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Título')),
      const SizedBox(height: 8),
      TextField(
        controller: _description,
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(labelText: 'Descreva o que você precisa'),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: _urgency,
        decoration: const InputDecoration(labelText: 'Urgência'),
        items: const [
          DropdownMenuItem(value: 'normal', child: Text('Normal')),
          DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
        ],
        onChanged: (v) => setState(() => _urgency = v ?? 'normal'),
      ),
      const SizedBox(height: 8),
      TextField(controller: _address, decoration: const InputDecoration(labelText: 'Endereço do serviço')),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_date == null ? 'Data desejada' : '${_date!.day}/${_date!.month}/${_date!.year}'),
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
        title: Text(_time == null
            ? 'Horário desejado'
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
        subtitle: const Text('Preferência sua. Não é horário livre do profissional.'),
        trailing: const Icon(Icons.schedule_rounded),
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
          if (picked != null) setState(() => _time = picked);
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _whatsapp,
        title: const Text('Quero alerta no WhatsApp'),
        subtitle: const Text(
            'A preferência fica gravada no pedido. O envio por WhatsApp ainda depende de integração; o aviso no app usa as notificações já existentes.'),
        onChanged: (v) => setState(() => _whatsapp = v),
      ),
    ]);
  }

  Widget _photosStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Fotos do local (opcional)', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _addPhoto,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Adicionar fotos'),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final photo in _photos)
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: MemoryImage(photo.bytes), fit: BoxFit.cover),
            ),
          ),
      ]),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _busy ? null : _analyze,
        child: Text(_busy ? 'Analisando...' : 'Analisar fotos com a Tia Carajás IA'),
      ),
      if (_insight != null && _insight!.available) ...[
        const SizedBox(height: 8),
        Text('Elementos: ${_insight!.elements.join(', ')}'),
        if (_insight!.questions.isNotEmpty)
          Text('Perguntas: ${_insight!.questions.join(' ')}'),
        Text(_insight!.disclaimer ?? tiaPhotoDisclaimer,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
      ],
    ]);
  }

  Widget _review() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_title.text.isEmpty ? 'Sem título' : _title.text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      Text(_description.text),
      const SizedBox(height: 8),
      Text('Categoria: ${_category ?? 'não escolhida'}'),
      Text('Endereço: ${_address.text.isEmpty ? 'não informado' : _address.text}'),
      if (widget.providerName != null) Text('Profissional: ${widget.providerName}'),
      const SizedBox(height: 8),
      const Text(
          'Ao confirmar, o pedido é gravado como pendente. Nenhum valor é cobrado nesta etapa.',
          style: TextStyle(fontSize: 12, color: AppColors.textLight)),
    ]);
  }

  Widget _done() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Solicitação registrada', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      Text('Pedido ${_orderId ?? ''}. Você será avisado quando houver proposta.'),
      const SizedBox(height: 8),
      if (_requestId == null)
        const Text('Sem propostas ainda.')
      else
        StreamBuilder<List<ResolveProposal>>(
          stream: c360Stream(() => FS.resolveProposalsStream(_requestId!)),
          builder: (context, snap) {
            final list = snap.data ?? const <ResolveProposal>[];
            if (list.isEmpty) {
              return const Text('Nenhuma proposta chegou. Esta lista mostra só o que estiver no cadastro.');
            }
            return Column(children: [
              for (final item in list)
                ListTile(
                  title: Text(item.providerName.isEmpty ? 'Profissional' : item.providerName),
                  subtitle: Text(
                      '${item.message ?? ''}\n${item.price > 0 ? 'R\$ ${item.price.toStringAsFixed(2)}' : 'Preço não informado'}'),
                  trailing: FilledButton(
                    onPressed: () async {
                      await FS.acceptResolveProposal(
                        requestId: _requestId!,
                        proposalId: item.id,
                        providerId: item.providerId,
                        providerName: item.providerName,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proposta marcada. Nenhum pagamento foi criado.')));
                      }
                    },
                    child: const Text('Escolher'),
                  ),
                ),
            ]);
          },
        ),
    ]);
  }

  Widget _side() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      children: [
        const TiaPortrait(pose: 'suporte', height: 140),
        const SizedBox(height: 8),
        const Text('Tia Carajás IA', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _sideTile(Icons.photo_outlined, 'Análise das fotos', _insight == null
            ? 'Ainda não há análise.'
            : (_insight!.available
                ? (_insight!.elements.isEmpty ? 'Sem elementos identificados.' : _insight!.elements.join(', '))
                : _insight!.reason!)),
        _sideTile(Icons.payments_outlined, 'Estimativa de preço', _estimate?.message ?? 'Sem estimativa.'),
        TextButton(onPressed: _busy ? null : _price, child: const Text('Calcular com pedidos concluídos')),
        _sideTile(
          Icons.groups_rounded,
          'Profissionais da categoria',
          'A lista abaixo usa cadastros ativos. Não é um ranking inventado.',
        ),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<ProviderModel>>(
            stream: _category == null
                ? const Stream.empty()
                : c360Stream(() => FS.providersStream(category: _category, limit: 5)),
            builder: (context, snap) {
              final list = snap.data ?? const <ProviderModel>[];
              if (list.isEmpty) return const Text('Nenhum profissional verificado nessa categoria.');
              return ListView(
                children: [
                  for (final p in list)
                    ListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: Text(p.city ?? 'Cidade não informada'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sideTile(IconData icon, String title, String text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      subtitle: Text(text),
    );
  }
}

class _Photo {
  final Uint8List bytes;
  final String name;
  _Photo(this.bytes, this.name);
}
