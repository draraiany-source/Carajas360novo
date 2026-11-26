import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';

import '../../core/security/order_policy.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import 'tia_models.dart';

/// Cliente da Tia. Sem chave e sem resposta pronta: se o backend não responde, a UI diz isso.
class TiaService {
  static bool get firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static TiaReply? get _blocked {
    if (!firebaseReady) {
      return TiaReply.unavailable(
          'IA indisponível: o Firebase não está configurado neste ambiente. O restante do app continua utilizável.');
    }
    if (c360Uid() == null) {
      return TiaReply.unavailable(
          'IA indisponível: entre na sua conta para falar com a Tia Carajás IA. Nenhuma resposta é simulada.');
    }
    return null;
  }

  static Future<TiaReply> send({
    required String message,
    String? conversationId,
    List<Map<String, dynamic>> history = const [],
    String audience = 'client',
  }) async {
    final blocked = _blocked;
    if (blocked != null) return blocked;
    try {
      final data = await CloudFn.call('tiaChat', {
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
        'history': history,
        'audience': audience,
      });
      return TiaReply.fromMap(data);
    } on CloudCallException catch (e) {
      return TiaReply.unavailable(e.message);
    } catch (_) {
      return TiaReply.unavailable(
          'Não foi possível falar com a Tia Carajás IA agora.');
    }
  }

  static Future<TiaPhotoInsight> analyzePhoto({
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
    String? note,
  }) async {
    final blocked = _blocked;
    if (blocked != null) return TiaPhotoInsight.unavailable(blocked.reason!);
    if (bytes.length > 1200000) {
      return TiaPhotoInsight.unavailable(
          'A foto passa de 1,2 MB. Escolha uma imagem menor para a análise.');
    }
    try {
      final data = await CloudFn.call('tiaAnalyzePhoto', {
        'imageBase64': base64Encode(bytes),
        'mimeType': mimeType,
        if (note != null) 'note': note,
      });
      return TiaPhotoInsight.fromMap(data);
    } on CloudCallException catch (e) {
      return TiaPhotoInsight.unavailable(e.message);
    } catch (_) {
      return TiaPhotoInsight.unavailable('A análise da foto não pôde ser feita.');
    }
  }

  static Future<TiaEstimate> estimate(String category) async {
    final blocked = _blocked;
    if (blocked != null) {
      return TiaEstimate(sufficient: false, message: blocked.reason!);
    }
    try {
      final data = await CloudFn.call('tiaEstimate', {'category': category});
      return TiaEstimate.fromMap(data);
    } on CloudCallException catch (e) {
      return TiaEstimate(sufficient: false, message: e.message);
    } catch (_) {
      return const TiaEstimate(
          sufficient: false, message: 'Estimativa indisponível.');
    }
  }

  static Future<TiaHistory?> history() async {
    if (_blocked != null) return null;
    try {
      final data = await CloudFn.call('tiaHistory');
      final messages = <TiaHistoryMessage>[];
      final raw = data['messages'];
      if (raw is List) {
        for (final item in raw) {
          if (item is! Map) continue;
          final text = '${item['text'] ?? ''}'.trim();
          if (text.isEmpty) continue;
          messages.add(TiaHistoryMessage(
            text: text,
            mine: item['role'] == 'user',
          ));
        }
      }
      return TiaHistory(
        conversationId: data['conversationId'] as String?,
        messages: messages,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> status() async {
    if (_blocked != null) return null;
    try {
      return await CloudFn.call('tiaStatus');
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> confirm(TiaProposedAction action) async {
    final blocked = _blocked;
    if (blocked != null) {
      return {'ok': false, 'error': blocked.reason};
    }
    if (action.type == 'request_quote') {
      final via = await _confirmQuote(action);
      if (via != null) return via;
    }
    try {
      return await CloudFn.call('tiaConfirm', action.toCall());
    } on CloudCallException catch (e) {
      return {'ok': false, 'error': e.message};
    } catch (_) {
      return {'ok': false, 'error': 'Não foi possível confirmar a ação.'};
    }
  }

  static Future<Map<String, dynamic>?> adminGet() async {
    try {
      return await CloudFn.call('tiaAdminGet');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> adminUpdate(Map<String, dynamic> body) async {
    try {
      await CloudFn.call('tiaAdminUpdate', body);
      return null;
    } on CloudCallException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível salvar.';
    }
  }

  static Future<String?> deleteUser(String uid) async {
    try {
      final data = await CloudFn.call('tiaAdminDeleteUser', {'uid': uid});
      return 'Conversas removidas: ${data['removed'] ?? 0}';
    } on CloudCallException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível apagar os dados.';
    }
  }

  static Future<Map<String, dynamic>?> _confirmQuote(TiaProposedAction action) async {
    final payload = action.payload;
    try {
      final draft = await CloudFn.call('criarRascunhoSolicitacao', {
        'category': payload['category'],
        'title': payload['title'],
        'description': payload['description'],
        'address': payload['address'],
        'city': payload['city'],
        'providerId': payload['providerId'],
      });
      if (draft['ok'] != true) {
        return {
          'ok': false,
          'error': draft['message'] ?? 'Não foi possível guardar o rascunho.',
        };
      }
      final draftId = (draft['data'] as Map?)?['draftId'];
      final confirmed = await CloudFn.call('confirmarSolicitacao', {
        'draftId': draftId,
        'confirmed': true,
      });
      if (confirmed['ok'] != true) {
        return {
          'ok': false,
          'error': confirmed['message'] ?? 'A confirmação não foi gravada.',
        };
      }
      final requestId = (confirmed['data'] as Map?)?['requestId'];
      final sent = await CloudFn.call('enviarSolicitacao', {
        'requestId': requestId,
        'confirmed': true,
      });
      return {
        'ok': sent['ok'] == true,
        'message': sent['message'],
        'error': sent['ok'] == true ? null : sent['message'],
        'id': (confirmed['data'] as Map?)?['orderId'],
      };
    } on CloudCallException catch (e) {
      if (e.code == 'not-found' || e.code == 'unimplemented') return null;
      return {'ok': false, 'error': e.message};
    }
  }

  static Future<String?> deleteMine() async {
    final blocked = _blocked;
    if (blocked != null) return blocked.reason;
    try {
      await CloudFn.call('tiaDeleteMyData');
      return null;
    } on CloudCallException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível apagar as conversas.';
    }
  }
}

class TiaHistoryMessage {
  final String text;
  final bool mine;
  const TiaHistoryMessage({required this.text, required this.mine});
}

class TiaHistory {
  final String? conversationId;
  final List<TiaHistoryMessage> messages;
  const TiaHistory({this.conversationId, this.messages = const []});
}
