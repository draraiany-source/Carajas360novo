import 'package:flutter/material.dart';
import '../auth/access_control.dart';
import '../constants/app_constants.dart';
import '../../shared/services/firebase_service.dart';

/// Abre o chat com roomId canônico `{uidA}_{uidB}` (getOrCreateRoom).
abstract final class ChatNav {
  static Future<void> open(
    BuildContext context, {
    required String otherUserId,
    required String otherName,
    String? otherPhoto,
  }) async {
    if (otherUserId.isEmpty) return;
    if (!await ensureSignedIn(context)) return;
    if (!context.mounted) return;
    final roomId = await FS.getOrCreateRoom(otherUserId);
    if (!context.mounted) return;
    await Navigator.pushNamed(context, Routes.chat, arguments: {
      'roomId': roomId,
      'name': otherName,
      if (otherPhoto != null) 'photo': otherPhoto,
    });
  }
}
