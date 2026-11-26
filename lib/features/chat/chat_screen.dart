import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';
import 'chat_voice.dart';

class ChatScreen extends StatefulWidget {
  final String roomId, otherName;
  final String? otherPhoto;
  final Color avatarColor;
  final bool embedded;
  final VoidCallback? onClose;
  const ChatScreen(
      {super.key,
      required this.roomId,
      required this.otherName,
      this.otherPhoto,
      this.avatarColor = AppColors.primary,
      this.embedded = false,
      this.onClose});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  final String _uid = AuthService.uid ?? 'me';
  MessageModel? _replyTo; // mensagem sendo respondida
  String _searchQuery = ''; // filtro de busca na conversa
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    FS.markMessagesRead(widget.roomId);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? override]) async {
    final text = override ?? _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    final reply = _replyTo;
    setState(() => _replyTo = null);
    await FS.sendMessage(
      roomId: widget.roomId,
      senderName: 'Você',
      text: text,
      replyToText: reply?.text,
      replyToSender: reply == null
          ? null
          : (reply.senderId == _uid ? 'Você' : widget.otherName),
    );
    _scrollBottom();
  }

  void _onMessageLongPress(MessageModel msg) {
    if (msg.deleted) return;
    final isMe = msg.senderId == _uid;
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              const SheetHandle(),
              const SizedBox(height: 8),
              ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: const Text('Responder'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _replyTo = msg);
                  }),
              if (msg.text.isNotEmpty)
                ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Copiar'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.text));
                      Navigator.pop(context);
                      snack(context, 'Copiado');
                    }),
              if (isMe)
                ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    title: const Text('Apagar para todos',
                        style: TextStyle(color: AppColors.error)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FS.deleteMessageForAll(widget.roomId, msg.id);
                    }),
              const SizedBox(height: 12),
            ])));
  }

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 120), () {
        if (_scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
      });

  void _showAttachMenu() => showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              const Text('Anexar arquivo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ListTile(
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.primary),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.camera);
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.gallery);
                  }),
              ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: AppColors.primary),
                  title: const Text('Documento'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendDocument();
                  }),
              ListTile(
                  leading: const Icon(Icons.mic_none_rounded,
                      color: AppColors.primary),
                  title: const Text('Mensagem de voz'),
                  onTap: () {
                    Navigator.pop(context);
                    _startVoiceRecording();
                  }),
              ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  title: const Text('Localização'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendLocation();
                  }),
            ]),
          ));

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1600);
      if (picked == null) return;
      if (mounted) snack(context, 'Enviando imagem...', bg: AppColors.primary);
      final url = await FS.uploadChatMedia(
          await picked.readAsBytes(), picked.name, widget.roomId);
      if (url != null) {
        await FS.sendMessage(
            roomId: widget.roomId,
            senderName: 'Você',
            text: '📷 Foto',
            mediaUrl: url);
        _scrollBottom();
      } else if (mounted) {
        snack(context, 'Falha ao enviar imagem. Verifique sua conexão.',
            bg: AppColors.error);
      }
    } catch (e) {
      if (mounted)
        snack(context, 'Não foi possível acessar a câmera/galeria.',
            bg: AppColors.error);
    }
  }

  // Documento real (Vol.3: Chat — documentos). Usa file_picker para
  // selecionar qualquer tipo de arquivo e envia via o mesmo pipeline
  // de upload já usado para fotos (FS.uploadChatMedia).
  Future<void> _pickAndSendDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes == null) {
        if (mounted) {
          snack(context, 'Não foi possível ler o arquivo selecionado.',
              bg: AppColors.error);
        }
        return;
      }
      final fileName = picked.name;
      if (mounted)
        snack(context, 'Enviando documento...', bg: AppColors.primary);
      final url = await FS.uploadChatMedia(bytes, fileName, widget.roomId);
      if (url != null) {
        await FS.sendMessage(
            roomId: widget.roomId,
            senderName: 'Você',
            text: '📄 $fileName',
            mediaUrl: url);
        _scrollBottom();
      } else if (mounted) {
        snack(context, 'Falha ao enviar documento. Verifique sua conexão.',
            bg: AppColors.error);
      }
    } catch (e) {
      if (mounted)
        snack(context, 'Não foi possível selecionar o arquivo.',
            bg: AppColors.error);
    }
  }

  // Localização real (Vol.3: Chat — localização). Captura a posição
  // atual via GPS e envia como link do Google Maps, clicável na bolha.
  Future<void> _sendLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted)
          snack(context, 'Permissão de localização negada.',
              bg: AppColors.error);
        return;
      }
      if (mounted)
        snack(context, 'Obtendo localização...', bg: AppColors.primary);
      final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 8));
      final mapsUrl =
          'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      await FS.sendMessage(
          roomId: widget.roomId,
          senderName: 'Você',
          text: '📍 Localização compartilhada\n$mapsUrl');
      _scrollBottom();
    } catch (e) {
      if (mounted)
        snack(context, 'Não foi possível obter sua localização.',
            bg: AppColors.error);
    }
  }

  // Gravação de áudio real (Vol.3: Chat — áudios). Usa ChatVoice
  // (import condicional) — no Web retorna indisponível sem tocar dart:io.
  Future<void> _startVoiceRecording() async {
    if (kIsWeb) {
      if (mounted) {
        snack(context, 'Gravação de áudio não está disponível no navegador.',
            bg: AppColors.warning);
      }
      return;
    }
    final hasPermission = await ChatVoice.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        snack(context, 'Permissão de microfone negada.', bg: AppColors.error);
      }
      return;
    }
    await ChatVoice.start();

    if (!mounted) return;
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Gravando mensagem de voz'),
        content: const Row(children: [
          Icon(Icons.mic_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Expanded(child: Text('Fale agora. Toque em Enviar quando terminar.'))
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.error))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar')),
        ],
      ),
    );

    final recordedPath = await ChatVoice.stop();
    if (sent != true || recordedPath == null) return;

    if (mounted) snack(context, 'Enviando áudio...', bg: AppColors.primary);
    final bytes = await ChatVoice.readBytes(recordedPath);
    if (bytes == null) {
      if (mounted) {
        snack(context, 'Falha ao ler o áudio gravado.', bg: AppColors.error);
      }
      return;
    }
    final url = await FS.uploadChatMedia(
        Uint8List.fromList(bytes), 'audio.m4a', widget.roomId);
    if (url != null) {
      await FS.sendMessage(
          roomId: widget.roomId,
          senderName: 'Você',
          text: '🎤 Mensagem de voz',
          mediaUrl: url);
      _scrollBottom();
    } else if (mounted) {
      snack(context, 'Falha ao enviar áudio. Verifique sua conexão.',
          bg: AppColors.error);
    }
  }

  void _requestCall({required bool isVideo}) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(isVideo ? 'Videochamada' : 'Ligação'),
            content: Text(
                'Deseja iniciar uma ${isVideo ? 'videochamada' : 'ligação'} com ${widget.otherName}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await FS.sendMessage(
                        roomId: widget.roomId,
                        senderName: 'Você',
                        text: isVideo
                            ? '📹 Solicitou uma videochamada'
                            : '📞 Solicitou uma ligação');
                    if (mounted)
                      snack(context,
                          '${isVideo ? 'Videochamada' : 'Ligação'} solicitada. Aguardando resposta...',
                          bg: AppColors.primary);
                  },
                  child: const Text('Chamar')),
            ],
          ));

  // roomId é formado por [meuUid, outroUid] ordenados e unidos com
  // '_' (ver FS.getOrCreateRoom) — extraímos o outro id removendo o
  // nosso próprio uid da lista.
  String get _otherUserId => widget.roomId
      .split('_')
      .firstWhere((id) => id != _uid, orElse: () => widget.roomId);

  void _reportUser(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Denunciar ${widget.otherName}'),
              content: TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Descreva o motivo da denúncia')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () async {
                      if (reasonCtrl.text.trim().isEmpty) return;
                      Navigator.pop(context);
                      await FS.createReport(
                          targetId: _otherUserId,
                          targetName: widget.otherName,
                          reason: reasonCtrl.text.trim());
                      if (context.mounted)
                        snack(context,
                            'Denúncia enviada. Nossa equipe vai analisar.',
                            bg: AppColors.secondary);
                    },
                    child: const Text('Enviar',
                        style: TextStyle(color: AppColors.error))),
              ],
            ));
  }

  static final _demo = [
    MessageModel(
        id: '1',
        senderId: 'pro',
        senderName: 'Profissional',
        text: 'Olá! Vi sua solicitação. Como posso ajudar? 😊',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8))),
    MessageModel(
        id: '2',
        senderId: 'me',
        senderName: 'Você',
        text: 'Preciso de ajuda urgente com um serviço.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 7))),
    MessageModel(
        id: '3',
        senderId: 'pro',
        senderName: 'Profissional',
        text: 'Claro! Me conta mais detalhes.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 6))),
    MessageModel(
        id: '4',
        senderId: 'me',
        senderName: 'Você',
        text: 'Tenho um vazamento na cozinha.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
    MessageModel(
        id: '5',
        senderId: 'pro',
        senderName: 'Profissional',
        text: 'Posso ir hoje às 16h. Fica bom? 👍',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 4))),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: widget.embedded && widget.onClose == null
              ? const SizedBox(width: 8)
              : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textDark),
              onPressed: () => _searching
                  ? setState(() {
                      _searching = false;
                      _searchQuery = '';
                    })
                  : (widget.onClose ?? () => Navigator.pop(context))()),
          title: _searching
              ? TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                      hintText: 'Pesquisar na conversa...',
                      border: InputBorder.none),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                )
              : Row(children: [
                  AppAvatar(
                      url: widget.otherPhoto,
                      name: widget.otherName,
                      size: 38,
                      bg: widget.avatarColor,
                      r: 11),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.otherName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Online agora',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textLight))
                        ]),
                      ]),
                ]),
          actions: [
            if (_searching)
              IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textDark),
                  onPressed: () => setState(() {
                        _searching = false;
                        _searchQuery = '';
                      }))
            else ...[
              IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textDark),
                  onPressed: () => setState(() => _searching = true)),
              IconButton(
                  icon:
                      const Icon(Icons.phone_rounded, color: AppColors.primary),
                  onPressed: () => _requestCall(isVideo: false)),
              IconButton(
                  icon: const Icon(Icons.videocam_rounded,
                      color: AppColors.primary),
                  onPressed: () => _requestCall(isVideo: true)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textDark),
                onSelected: (v) {
                  if (v == 'report') _reportUser(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        Icon(Icons.flag_outlined,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Denunciar usuário')
                      ]))
                ],
              ),
            ],
          ],
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.divider)),
        ),
        body: Column(children: [
          const InfoBanner(
              icon: '🔒',
              text:
                  'Pagamento protegido. Pague somente após o serviço concluído.',
              bg: Color(0xFFE8F5E9),
              fg: AppColors.secondary),
          Expanded(
              child: StreamBuilder<List<MessageModel>>(
            stream: FS.messagesStream(widget.roomId),
            builder: (_, snap) {
              final allMsgs = DemoData.orEmpty(snap.data, _demo);
              if (snap.hasData) FS.markMessagesRead(widget.roomId);
              if (snap.hasData && allMsgs.isEmpty) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(32),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          SvgPicture.asset(AppAssets.chatSemMensagens,
                              width: 150, height: 150),
                          const SizedBox(height: 16),
                          const Text('Nenhuma mensagem ainda',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                              'Envie a primeira mensagem para ${widget.otherName}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textLight)),
                        ])));
              }
              final msgs = _searchQuery.isEmpty
                  ? allMsgs
                  : allMsgs
                      .where((m) => m.text.toLowerCase().contains(_searchQuery))
                      .toList();
              if (msgs.isEmpty)
                return const EmptyState(
                    emoji: '🔍',
                    title: 'Nada encontrado',
                    subtitle: 'Nenhuma mensagem com esse termo');
              return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _bubble(msgs[i]));
            },
          )),
          _quickReplies(),
          if (_replyTo != null) _replyBar(),
          _inputBar(),
        ]),
      );

  // Diferencia o tipo de mídia pelo prefixo do texto (definido no
  // envio: 📷 foto, 📄 documento, 🎤 áudio) para renderizar cada um
  // corretamente — antes, tudo era tratado como imagem.
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      snack(context, 'Não foi possível abrir o link.', bg: AppColors.error);
    }
  }

  Widget _mediaContent(MessageModel msg, bool isMe) {
    if (msg.text.startsWith('📄')) {
      return InkWell(
        onTap: () => _openUrl(msg.mediaUrl!),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color:
                  (isMe ? Colors.white : AppColors.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.insert_drive_file_rounded,
                color: isMe ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
                child: Text(msg.text.replaceFirst('📄 ', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white : AppColors.textDark))),
          ]),
        ),
      );
    }
    if (msg.text.startsWith('🎤')) {
      return _AudioBubble(url: msg.mediaUrl!, isMe: isMe);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: msg.mediaUrl!,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
            width: 180,
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (_, __, ___) => const SizedBox(
            width: 180,
            height: 100,
            child: Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.grey))),
      ),
    );
  }

  Widget _requestCard(MessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: C360Card(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.event_note_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Agendamento de Serviço',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Text(msg.text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium, height: 1.35)),
                if (!isMe) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _send(
                          'Agendamento confirmado. Combinamos os detalhes por aqui.'),
                      child: const Text('Confirmar Agendamento'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(MessageModel msg) {
    final isMe = msg.senderId == _uid || msg.senderId == 'me';
    // Mensagem apagada para todos
    if (msg.deleted) {
      return Padding(
        padding: EdgeInsets.only(
            bottom: 8, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
        child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.block_rounded,
                        size: 14, color: AppColors.textLight),
                    SizedBox(width: 6),
                    Text('Mensagem apagada',
                        style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ])),
            ]),
      );
    }
    if (msg.text.contains('Nova solicitação')) {
      return _requestCard(msg, isMe);
    }
    return Padding(
      padding:
          EdgeInsets.only(bottom: 8, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
      child: GestureDetector(
        onLongPress: () => _onMessageLongPress(msg),
        child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                AppAvatar(
                    url: widget.otherPhoto,
                    name: widget.otherName,
                    size: 30,
                    bg: widget.avatarColor,
                    r: 9),
                const SizedBox(width: 8)
              ],
              Flexible(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: isMe ? AppColors.primarySoft : AppColors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06), blurRadius: 8)
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (msg.replyToText != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                              color: (isMe ? Colors.white : AppColors.primary)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                  left: BorderSide(
                                      color: isMe
                                          ? Colors.white70
                                          : AppColors.primary,
                                      width: 3))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(msg.replyToSender ?? '',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.primary)),
                                Text(msg.replyToText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isMe
                                            ? Colors.white70
                                            : AppColors.textLight)),
                              ]),
                        ),
                      if (msg.mediaUrl != null)
                        _mediaContent(msg, isMe)
                      else if (msg.text.contains('maps.google.com'))
                        InkWell(
                          onTap: () =>
                              _openUrl(msg.text.split('\n').last.trim()),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_on_rounded,
                                size: 18,
                                color: isMe ? Colors.white : AppColors.error),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text('Localização compartilhada',
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : AppColors.primary,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline))),
                          ]),
                        )
                      else
                        Text(msg.text,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                height: 1.4)),
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(fmtTime(msg.createdAt),
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 10)),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                              msg.read
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: msg.read
                                  ? AppColors.primary
                                  : AppColors.textHint)
                        ],
                      ]),
                    ]),
              )),
            ]),
      ),
    );
  }

  Widget _replyBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        color: AppColors.background,
        child: Row(children: [
          Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(
                    'Respondendo ${_replyTo!.senderId == _uid ? 'você' : widget.otherName}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text(_replyTo!.text.isEmpty ? 'Mídia' : _replyTo!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ])),
          IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => setState(() => _replyTo = null)),
        ]),
      );

  Widget _quickReplies() => SizedBox(
      height: 46,
      child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            'Sim, pode vir! 👍',
            'Qual o valor?',
            'Tem garantia?',
            'Quando pode?',
            'Combinado! ✅'
          ]
              .map((r) => GestureDetector(
                  onTap: () => _send(r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 7, bottom: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border)),
                    child: Center(
                        child: Text(r,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary))),
                  )))
              .toList()));

  Widget _inputBar() => Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.attach_file_rounded,
                  color: AppColors.textLight),
              onPressed: _showAttachMenu),
          Expanded(
              child: TextField(
            controller: _msgCtrl,
            onSubmitted: _send,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          )),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: () => _send(),
              child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20))),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// AUDIO BUBBLE (Vol.3: Chat — reprodução de mensagens de voz)
// ─────────────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  const _AudioBubble({required this.url, required this.isMe});
  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          GestureDetector(
              onTap: _toggle,
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white24
                          : AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: widget.isMe ? Colors.white : AppColors.primary,
                      size: 20))),
          const SizedBox(width: 8),
          Expanded(
              child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                      color: (widget.isMe ? Colors.white : AppColors.primary)
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(width: 8),
          Icon(Icons.mic_rounded,
              size: 16,
              color: widget.isMe ? Colors.white70 : AppColors.textLight),
        ]),
      );
}
