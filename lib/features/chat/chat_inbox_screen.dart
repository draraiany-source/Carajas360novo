import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';
import 'chat_screen.dart';

/// Inbox unificado de conversas (reutiliza chatRooms existentes).
class ChatInboxScreen extends StatefulWidget {
  final bool embedded;
  const ChatInboxScreen({super.key, this.embedded = false});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  String _query = '';
  int _tab = 0;
  String? _openRoom;
  String? _openName;
  String? _openPhoto;

  @override
  Widget build(BuildContext context) {
    final uid = c360Uid();
    final body = uid == null
        ? EmptyState(
            emoji: '💬',
            title: 'Faça login',
            subtitle: 'Entre na conta para ver suas conversas',
            actionLabel: 'Entrar',
            onAction: () => Navigator.pushNamed(context, Routes.login),
          )
        : Column(children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: C360PageBanner(
                icon: Icons.forum_rounded,
                title: 'Mensagens',
                subtitle:
                    'Converse diretamente com profissionais e acompanhe seus atendimentos.',
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoomPreview>>(
                stream: c360Stream(FS.chatRoomsStream),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const EmptyState(
                      emoji: '💬',
                      title: 'Não foi possível carregar',
                      subtitle: 'Tente novamente em instantes.',
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all = snap.data ?? [];
                  final q = _query.trim().toLowerCase();
                  final filtered = all.where((r) {
                    if (q.isNotEmpty &&
                        !r.otherName.toLowerCase().contains(q) &&
                        !r.lastMsg.toLowerCase().contains(q)) {
                      return false;
                    }
                    return true;
                  }).toList();
                  final shown = _tab == 0 ? filtered : <ChatRoomPreview>[];
                  return LayoutBuilder(builder: (context, c) {
                    final split = c.maxWidth >= 860;
                    final list = _listPane(all.length, shown);
                    if (!split) return list;
                    return Row(children: [
                      SizedBox(width: 360, child: list),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _openRoom == null
                            ? const EmptyState(
                                emoji: '💬',
                                title: 'Selecione uma conversa',
                                subtitle:
                                    'As mensagens aparecem neste painel.',
                              )
                            : ChatScreen(
                                key: ValueKey(_openRoom),
                                roomId: _openRoom!,
                                otherName: _openName ?? 'Contato',
                                otherPhoto: _openPhoto,
                                embedded: true,
                                onClose: () => setState(() {
                                  _openRoom = null;
                                  _openName = null;
                                  _openPhoto = null;
                                }),
                              ),
                      ),
                    ]);
                  });
                },
              ),
            ),
          ]);

    if (widget.embedded) {
      return ColoredBox(color: AppColors.background, child: body);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
    );
  }

  Widget _listPane(int total, List<ChatRoomPreview> shown) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Buscar conversas...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          C360FilterChip(
            label: 'Todas ($total)',
            selected: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          C360FilterChip(
            label: 'Não lidas',
            selected: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
          C360FilterChip(
            label: 'Arquivadas',
            selected: _tab == 2,
            onTap: () => setState(() => _tab = 2),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: shown.isEmpty
            ? EmptyState(
                emoji: '💬',
                title: _tab == 0 ? 'Nenhuma conversa' : 'Nada por aqui',
                subtitle: _tab == 1
                    ? 'O app ainda não marca conversas como não lidas. Elas continuam em Todas.'
                    : _tab == 2
                        ? 'Nenhuma conversa arquivada.'
                        : 'Suas mensagens com profissionais e clientes aparecem aqui.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: shown.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final room = shown[i];
                  final selected = room.id == _openRoom;
                  return Material(
                    color: selected ? AppColors.primarySoft : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      leading: AppAvatar(
                          url: room.otherPhoto,
                          name: room.otherName,
                          size: 48,
                          r: 16),
                      title: Text(room.otherName,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        room.lastMsg.isEmpty
                            ? 'Conversa iniciada'
                            : room.lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 13),
                      ),
                      trailing: room.lastMsgTime != null
                          ? Text(_fmtTime(room.lastMsgTime!),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight))
                          : null,
                      onTap: () => _open(room),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  void _open(ChatRoomPreview room) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    if (wide) {
      setState(() {
        _openRoom = room.id;
        _openName = room.otherName;
        _openPhoto = room.otherPhoto;
      });
      return;
    }
    Navigator.pushNamed(context, Routes.chat, arguments: {
      'roomId': room.id,
      'name': room.otherName,
      if (room.otherPhoto != null) 'photo': room.otherPhoto,
    });
  }

  static String _fmtTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(t).inDays == 1) return 'Ontem';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }
}
