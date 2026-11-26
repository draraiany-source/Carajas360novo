import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/c360_nav.dart';
import '../home/provider_profile_screen.dart';
import '../../core/catalog/service_catalog.dart';
import 'tia_catalog_card.dart';
import 'tia_models.dart';
import 'tia_request_screen.dart';
import 'tia_schedule_screen.dart';
import 'tia_service.dart';
import 'tia_voice.dart';
import 'tia_widgets.dart';

class _Msg {
  final String text;
  final bool mine;
  final bool alert;
  final List<TiaProviderRef> providers;
  final List<TiaProposedAction> actions;
  final CatalogMatch? match;
  const _Msg({
    required this.text,
    this.mine = false,
    this.alert = false,
    this.providers = const [],
    this.actions = const [],
    this.match,
  });
}

class TiaCentralScreen extends StatefulWidget {
  final String audience;
  final String? seed;
  const TiaCentralScreen({super.key, this.audience = 'client', this.seed});

  @override
  State<TiaCentralScreen> createState() => _TiaCentralScreenState();
}

class _TiaCentralScreenState extends State<TiaCentralScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = TiaVoice();
  final _msgs = <_Msg>[];
  bool _busy = false;
  String? _conversationId;
  String? _quotaLine;
  String _pose = 'recepcionando';

  @override
  void initState() {
    super.initState();
    _restore();
    final seed = widget.seed?.trim();
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(seed));
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final history = await TiaService.history();
    final status = await TiaService.status();
    if (!mounted) return;
    final usage = status?['usage'];
    String? line;
    if (usage is Map) {
      line =
          'Uso neste mês: ${usage['messages'] ?? 0}/${usage['messageLimit'] ?? '—'} mensagens · '
          '${usage['tokens'] ?? 0}/${usage['tokenLimit'] ?? '—'} tokens';
    }
    setState(() {
      _quotaLine = line;
      if (history != null && _msgs.isEmpty) {
        _conversationId = history.conversationId ?? _conversationId;
        for (final message in history.messages) {
          _msgs.add(_Msg(text: message.text, mine: message.mine));
        }
      }
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _busy = true;
      _pose = 'processando';
      _msgs.add(_Msg(text: text, mine: true));
    });
    _jump();
    final history = _msgs
        .where((m) => !m.alert)
        .map((m) => {'text': m.text, 'isAi': !m.mine})
        .toList();
    final reply = await TiaService.send(
      message: text,
      conversationId: _conversationId,
      history: history.length > 1 ? history.sublist(0, history.length - 1) : const [],
      audience: widget.audience,
    );
    if (!mounted) return;
    final identified = _matchFromReply(text, reply);
    setState(() {
      _busy = false;
      _conversationId = reply.conversationId ?? _conversationId;
      if (!reply.available || (reply.text == null || reply.text!.trim().isEmpty)) {
        _pose = 'suporte';
        _msgs.add(_Msg(
          text: reply.reason ?? 'IA indisponível.',
          alert: true,
          match: identified,
        ));
      } else {
        _pose = reply.providers.isNotEmpty ? 'apresentando' : 'orientando';
        _msgs.add(_Msg(
          text: reply.text!,
          providers: reply.providers,
          actions: reply.actions,
          match: identified,
        ));
        if (reply.disclaimer != null) {
          _msgs.add(_Msg(text: reply.disclaimer!, alert: true));
        }
      }
    });
    _jump();
    if (reply.available && reply.text != null && _voice.audioEnabled) {
      await _voice.speak(reply.text!);
      if (mounted) setState(() {});
    }
  }

  CatalogMatch? _matchFromReply(String text, TiaReply reply) {
    for (final action in reply.actions) {
      final raw = action.payload['category'];
      if (raw is String && raw.isNotEmpty) {
        final profession = ServiceCatalog.professionById(raw);
        if (profession != null) {
          return CatalogMatch(
            kind: 'profissao',
            id: profession.id,
            name: profession.name,
            categoryId: profession.categoryId,
            profession: profession,
            category: ServiceCatalog.categoryById(profession.categoryId),
          );
        }
        final category = ServiceCatalog.categoryById(raw);
        if (category != null) {
          return CatalogMatch(
            kind: 'categoria',
            id: category.id,
            name: category.name,
            categoryId: category.id,
            category: category,
          );
        }
      }
    }
    return ServiceCatalog.matchText(text);
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _mic() async {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usar o microfone'),
        content: const Text(
            'A Tia Carajás IA transcreve o que você falar neste aparelho. O áudio não é enviado para um servidor de voz. Você pode interromper a fala a qualquer momento.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Agora não')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Permitir')),
        ],
      ),
    );
    if (allow != true || !mounted) return;
    setState(() => _pose = 'escutando_voz');
    final ok = await _voice.startListening((text, isFinal) {
      if (!mounted) return;
      _input.text = text;
      _input.selection = TextSelection.collapsed(offset: text.length);
      if (isFinal && text.trim().isNotEmpty) {
        _voice.stopListening();
        _send(text);
      }
      setState(() {});
    });
    if (!mounted) return;
    if (!ok) {
      setState(() => _pose = 'suporte');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_voice.limitation ?? 'Microfone indisponível.')));
    } else {
      setState(() {});
    }
  }

  Future<void> _attach() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _busy = true;
      _pose = 'analisando_fotos';
      _msgs.add(const _Msg(text: 'Enviei uma foto para análise.', mine: true));
    });
    final insight = await TiaService.analyzePhoto(bytes: bytes, note: _input.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pose = 'apresentando';
      if (!insight.available) {
        _msgs.add(_Msg(text: insight.reason ?? 'Análise indisponível.', alert: true));
      } else {
        final lines = <String>[
          if (insight.elements.isNotEmpty) 'Elementos: ${insight.elements.join(', ')}',
          if (insight.suggestedCategoryId != null)
            'Categoria sugerida: ${insight.suggestedCategoryId}',
          if (insight.organizedDescription.isNotEmpty) insight.organizedDescription,
          if (insight.questions.isNotEmpty)
            'Perguntas: ${insight.questions.join(' ')}',
          insight.disclaimer ?? tiaPhotoDisclaimer,
        ];
        _msgs.add(_Msg(text: lines.join('\n\n')));
      }
    });
    _jump();
  }

  Future<void> _confirm(TiaProposedAction action) async {
    setState(() => _busy = true);
    final result = await TiaService.confirm(action);
    if (!mounted) return;
    final ok = result['ok'] == true;
    setState(() {
      _busy = false;
      _pose = ok ? 'confirmando' : 'suporte';
      _msgs.add(_Msg(
        text: ok
            ? (result['message'] as String? ?? 'Ação registrada.')
            : (result['error'] as String? ?? 'A confirmação não foi concluída.'),
        alert: !ok,
      ));
    });
    _jump();
  }

  void _openProvider(TiaProviderRef provider) {
    c360Open(
      context,
      route: Routes.providerProfile,
      arguments: {
        'providerId': provider.id,
        'providerName': provider.name,
        'category': provider.categories.isEmpty ? '' : provider.categories.first,
      },
      page: ProviderProfileScreen(
        providerId: provider.id,
        providerName: provider.name,
        category: provider.categories.isEmpty ? '' : provider.categories.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final chat = _chat(wide);
        if (!wide) return chat;
        return Row(children: [
          Expanded(child: chat),
          SizedBox(width: 320, child: _rail()),
        ]);
      }),
    );
  }

  Widget _chat(bool wide) {
    return Column(children: [
      Expanded(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          children: [
            if (c360Uid() == null)
              const TiaBubble(
                text:
                    'Você pode explorar a plataforma sem entrar. Para conversar com a Tia, enviar fotos e gravar pedidos, faça login. Nenhuma resposta é simulada.',
                alert: true,
              ),
            if (!wide) _mobileHeader(),
            if (wide) _desktopIntro(),
            for (final msg in _msgs) ...[
              TiaBubble(text: msg.text, mine: msg.mine, alert: msg.alert),
              if (msg.providers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TiaProviderStrip(providers: msg.providers, onOpen: _openProvider),
                ),
              for (final action in msg.actions)
                TiaActionCard(action: action, onConfirm: () => _confirm(action)),
              if (msg.match != null) TiaCatalogCard(match: msg.match!),
            ],
            if (_busy)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
      _composer(),
    ]);
  }

  Widget _desktopIntro() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        TiaPortrait(pose: _pose, height: 92, animate: _voice.speaking || _voice.listening),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(tiaIntro,
              style: TextStyle(color: Colors.white, height: 1.35, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _mobileHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        TiaPortrait(pose: _pose, height: 120, animate: _voice.speaking || _voice.listening),
        const SizedBox(width: 8),
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(tiaIntro, style: TextStyle(height: 1.35)),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
        children: [
          _quick(Icons.person_search_rounded, 'Encontrar um profissional', () {
            c360Go(context, C360Dest.professionals, Routes.search);
          }),
          _quick(Icons.request_quote_rounded, 'Solicitar um orçamento', () {
            c360Open(context, route: Routes.tiaRequest, page: const TiaRequestScreen());
          }),
          _quick(Icons.event_rounded, 'Agendar um atendimento', () {
            c360Open(context, route: Routes.tiaSchedule, page: const TiaScheduleScreen());
          }),
          _quick(Icons.help_outline_rounded, 'Tirar dúvidas', () => _send('Como funciona o Carajás 360?')),
          _quick(Icons.place_rounded, 'Serviços na minha região', () {
            c360Go(context, C360Dest.explore, Routes.search);
          }),
          _quick(Icons.mic_rounded, 'Falar por voz', _mic),
        ],
      ),
      const SizedBox(height: 8),
    ]);
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.yellow, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _composer() {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(children: [
            if (_quotaLine != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_quotaLine!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ),
            if (_voice.listening || _voice.speaking)
              Row(children: [
                TiaVoiceWaves(active: _voice.listening || _voice.speaking),
                const SizedBox(width: 8),
                Text(_voice.listening ? 'Ouvindo…' : 'Falando…',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await _voice.stopListening();
                    await _voice.stopSpeaking();
                    if (mounted) setState(() => _pose = 'recepcionando');
                  },
                  child: const Text('Interromper'),
                ),
              ]),
            Row(children: [
              IconButton(
                tooltip: 'Anexar foto',
                onPressed: _busy ? null : _attach,
                icon: const Icon(Icons.attach_file_rounded),
              ),
              Expanded(
                child: TextField(
                  key: const Key('tia-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem para a Tia Carajás IA...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: _voice.audioEnabled ? 'Desligar áudio' : 'Ligar áudio',
                onPressed: () => setState(() => _voice.setAudioEnabled(!_voice.audioEnabled)),
                icon: Icon(_voice.audioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              ),
              IconButton(
                tooltip: 'Falar',
                onPressed: _busy ? null : _mic,
                icon: Icon(Icons.mic_rounded, color: _voice.listening ? AppColors.error : AppColors.primary),
              ),
              IconButton(
                key: const Key('tia-send'),
                tooltip: 'Enviar',
                onPressed: _busy ? null : () => _send(_input.text),
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _rail() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      children: [
        const Text('O que você pode fazer com a Tia Carajás IA',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final item in tiaCapabilities)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(item.icon, color: AppColors.primary),
            title: Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            onTap: () {
              if (item.label == 'Solicitar orçamento') {
                c360Open(context, route: Routes.tiaRequest, page: const TiaRequestScreen());
              } else if (item.label == 'Agendar atendimento') {
                c360Open(context, route: Routes.tiaSchedule, page: const TiaScheduleScreen());
              } else if (item.label == 'Enviar fotos') {
                _attach();
              } else {
                _send(item.prompt);
              }
            },
          ),
        const Divider(),
        const Text('Comando por voz', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('O microfone e a voz feminina em português ficam neste aparelho.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _mic, icon: const Icon(Icons.mic_rounded), label: const Text('Falar agora')),
        const SizedBox(height: 12),
        const Text('Sugestões', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final tip in const [
            'Revisão elétrica da residência',
            'Instalação de chuveiro',
            'Manutenção preventiva',
          ])
            ActionChip(label: Text(tip), onPressed: () => _send(tip)),
        ]),
        TextButton(
          onPressed: () async {
            final err = await TiaService.deleteMine();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err ?? 'Conversas com a Tia Carajás IA apagadas.')));
          },
          child: const Text('Apagar minhas conversas'),
        ),
      ],
    );
  }
}

class TiaFloatingHelp extends StatelessWidget {
  final String? contextNote;
  const TiaFloatingHelp({super.key, this.contextNote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Material(
        color: const Color(0xFF145C32),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => c360Open(
            context,
            route: Routes.aiAssistant,
            page: TiaCentralScreen(
              seed: contextNote ??
                  'Preciso de ajuda para contratar ou solicitar um orçamento.',
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              const TiaPortrait(pose: 'orientando', height: 64),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Precisa de ajuda para contratar ou solicitar um orçamento?',
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.25)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class TiaTalkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool compact;
  const TiaTalkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.sidebar,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        minimumSize: compact ? const Size(0, 36) : null,
        padding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.mic_rounded, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
