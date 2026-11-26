import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/runtime_config.dart';
import '../../core/utils/firebase_bootstrap.dart';
import '../../firebase_options.dart';
import '../../core/utils/platform_info.dart';
import '../../core/security/order_policy.dart';
import 'apple_sign_in.dart';
import 'local_notifications.dart';

/// Erro de autenticação com mensagem amigável para a UI.
class AuthFailure implements Exception {
  final String message;
  final String? code;
  const AuthFailure(this.message, {this.code});
  @override
  String toString() => message;
}

class AuthService {
  static final _a = FirebaseAuth.instance;
  static User? get current => _a.currentUser;
  static String? get uid => _a.currentUser?.uid;
  static bool get isAuth => _a.currentUser != null;

  static Future<void> verifyPhone({
    required String phone,
    required void Function(String verId, int? token) onSent,
    required void Function(String error) onError,
  }) async {
    try {
      await _a.verifyPhoneNumber(
        phoneNumber: '+55${phone.replaceAll(RegExp(r'\D'), '')}',
        timeout: const Duration(seconds: AppConst.otpTimeoutSeconds),
        verificationCompleted: (cred) async =>
            await _a.signInWithCredential(cred),
        verificationFailed: (e) =>
            onError(e.message ?? 'Erro ao verificar telefone'),
        codeSent: (id, token) => onSent(id, token),
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      onError(e.message ?? 'Erro desconhecido');
    }
  }

  static Future<UserCredential?> confirmOtp(String verId, String otp) async {
    try {
      return await _a.signInWithCredential(
          PhoneAuthProvider.credential(verificationId: verId, smsCode: otp));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e), code: e.code);
    }
  }

  static Future<UserCredential> signInEmail(String email, String pass) async {
    try {
      return await _a.signInWithEmailAndPassword(
          email: email.trim(), password: pass);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e), code: e.code);
    }
  }

  /// Cria conta com e-mail/senha no Firebase Auth.
  /// Já deixa o usuário autenticado (login automático).
  static Future<UserCredential> signUpEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final cred = await _a.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      if (displayName != null && displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e), code: e.code);
    }
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Faça login.';
      case 'invalid-email':
        return 'Digite um e-mail válido.';
      case 'weak-password':
        return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail não está habilitado no Firebase.';
      case 'missing-email':
        return 'Digite um e-mail válido.';
      case 'auth/invalid-continue-uri':
      case 'invalid-continue-uri':
        return 'Não foi possível enviar a recuperação de senha.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Erro de autenticação (${e.code}).';
    }
  }

  static Future<void> resetPassword(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthFailure('Digite seu e-mail.');
    }
    try {
      await _a.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e), code: e.code);
    }
  }

  // ── Login com Google (Vol.3: Login e Cadastro) ────────────────
  // Emulador / Web: fluxo federado do Firebase Auth (popup/provider),
  // que funciona no Auth Emulator sem Client ID OAuth real.
  // Mobile produção: google_sign_in 7.x + credencial Firebase.
  static final _google = GoogleSignIn.instance;
  static bool _googleInitialized = false;

  static Future<bool> _ensureGoogleInitialized() async {
    if (_googleInitialized) return true;
    try {
      await _google.initialize();
      _googleInitialized = true;
      return true;
    } catch (e) {
      _googleInitialized = true;
      debugPrint('Google Sign-In init falhou: $e');
      return false;
    }
  }

  static GoogleAuthProvider _googleProvider() {
    final provider = GoogleAuthProvider();
    provider.addScope('email');
    provider.addScope('profile');
    provider.setCustomParameters({'prompt': 'select_account'});
    return provider;
  }

  static Future<UserCredential?> signInGoogle() async {
    try {
      // Auth Emulator + Web: signInWithPopup/Provider abre o IdP fake.
      if (FirebaseBootstrap.shouldUseEmulator || kIsWeb) {
        try {
          if (kIsWeb) {
            return await _a.signInWithPopup(_googleProvider());
          }
          return await _a.signInWithProvider(_googleProvider());
        } on FirebaseAuthException catch (e) {
          if (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request' ||
              e.code == 'web-context-cancelled') {
            return null;
          }
          // Sem Client ID real no Web de produção, tenta plugin nativo.
          if (!FirebaseBootstrap.shouldUseEmulator) {
            debugPrint('Google federado falhou, tentando plugin: ${e.code}');
          } else {
            throw AuthFailure(_mapAuthError(e), code: e.code);
          }
        }
      }

      final ok = await _ensureGoogleInitialized();
      if (!ok && kIsWeb) {
        throw const AuthFailure(
            'Configure o Google Client ID Web (meta google-signin-client_id).');
      }
      final account = await _google.authenticate();
      final auth = account.authentication;
      final authorization = await account.authorizationClient
          .authorizationForScopes(const ['email', 'profile']);
      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: auth.idToken,
      );
      return await _a.signInWithCredential(credential);
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure(
          'Não foi possível entrar com Google. Verifique a configuração OAuth.',
          code: e.code.name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e), code: e.code);
    } catch (e) {
      debugPrint('Erro no login com Google: $e');
      throw const AuthFailure(
          'Não foi possível entrar com Google. Tente novamente.');
    }
  }

  // ── Login com Apple (Vol.3: Login e Cadastro) ─────────────────
  // Import condicional: no Web usa stub; no iOS/macOS usa o pacote nativo.
  static Future<UserCredential?> signInApple() async {
    if (!PlatformInfo.isApple) return null;
    return signInWithAppleNative();
  }

  static Future<void> signOut() async {
    try {
      if (_googleInitialized) await _google.signOut();
    } catch (e) {
      debugPrint('Erro ao sair do Google: $e');
    }
    await _a.signOut();
  }

  /// Exclusão definitiva da conta (LGPD). Pode exigir login recente.
  static Future<void> deleteAccount() async {
    final user = _a.currentUser;
    if (user == null) {
      throw const AuthFailure('Faça login para excluir a conta.');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthFailure(
            'Por segurança, saia e entre novamente antes de excluir a conta.');
      }
      throw AuthFailure(_mapAuthError(e), code: e.code);
    }
  }
}

class FS {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => AuthService.uid;

  static Future<void> saveUser(UserModel u) async {
    final ref = _db.collection(Col.users).doc(u.id);
    var isNew = true;
    try {
      final existing = await ref.get(const GetOptions(source: Source.server));
      isNew = !existing.exists;
    } catch (e) {
      debugPrint('saveUser get: $e');
      try {
        final existing = await ref.get();
        isNew = !existing.exists;
      } catch (_) {
        isNew = true;
      }
    }
    // Campos privilegiados só na criação; updates não elevam privilégios.
    final data = u.toMap();
    if (!isNew) {
      data.remove('type');
      data.remove('adminRole');
      data.remove('verified');
      data.remove('status');
      data.remove('plan');
      data.remove('xp');
    } else {
      data.remove('adminRole');
      if (data['type'] == 'admin') data['type'] = 'client';
    }
    await ref.set({
      ...data,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<UserModel?> getUser([String? id]) async {
    final d = await _db.collection(Col.users).doc(id ?? _uid).get();
    return d.exists ? UserModel.fromMap(d.id, d.data()!) : null;
  }

  static Stream<UserModel?> userStream([String? id]) => _db
      .collection(Col.users)
      .doc(id ?? _uid)
      .snapshots()
      .map((s) => s.exists ? UserModel.fromMap(s.id, s.data()!) : null);

  static Future<void> updateUser(Map<String, dynamic> data) async {
    if (_uid == null) return;
    final sanitized = Map<String, dynamic>.from(data);
    for (final k in OrderPolicy.protectedUserFields) {
      sanitized.remove(k);
    }
    if (sanitized.isEmpty) return;
    await _db
        .collection(Col.users)
        .doc(_uid)
        .update({...sanitized, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Exportação LGPD (portabilidade) — perfil, pedidos e favoritos do usuário.
  static Future<Map<String, dynamic>> exportMyData() async {
    if (_uid == null) throw Exception('Não autenticado');
    final user = await getUser();
    final orders = await _db
        .collection(Col.orders)
        .where('clientId', isEqualTo: _uid)
        .limit(100)
        .get();
    final favs = await _db
        .collection(Col.favorites)
        .where('userId', isEqualTo: _uid)
        .limit(100)
        .get();
    final resolve = await _db
        .collection(Col.resolveRequests)
        .where('clientId', isEqualTo: _uid)
        .limit(50)
        .get();
    Map<String, dynamic> safe(Map<String, dynamic> m) => m.map((k, v) {
          if (v is Timestamp) return MapEntry(k, v.toDate().toIso8601String());
          if (v is Map) {
            return MapEntry(k, safe(Map<String, dynamic>.from(v)));
          }
          if (v is List) {
            return MapEntry(
                k,
                v.map((e) => e is Map
                    ? safe(Map<String, dynamic>.from(e as Map))
                    : e is Timestamp
                        ? e.toDate().toIso8601String()
                        : e).toList());
          }
          return MapEntry(k, v);
        });
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'user': user?.toMap() ?? {},
      'orders':
          orders.docs.map((d) => safe({'id': d.id, ...d.data()})).toList(),
      'favorites':
          favs.docs.map((d) => safe({'id': d.id, ...d.data()})).toList(),
      'resolveRequests':
          resolve.docs.map((d) => safe({'id': d.id, ...d.data()})).toList(),
    };
  }

  /// Apaga dados pessoais principais do Firestore antes da exclusão Auth.
  static Future<void> deleteMyAccountData() async {
    if (_uid == null) return;
    final uid = _uid!;
    try {
      final favs = await _db
          .collection(Col.favorites)
          .where('userId', isEqualTo: uid)
          .get();
      for (final d in favs.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      debugPrint('deleteMyAccountData favorites: $e');
    }
    try {
      await _db.collection(Col.users).doc(uid).delete();
    } catch (e) {
      debugPrint('deleteMyAccountData user: $e');
    }
  }

  // Upload de foto de perfil do usuário (Vol.3: Cadastro de
  // Clientes). Usa bytes (putData) para funcionar no Web e no mobile.
  static Future<String?> uploadUserPhoto(Uint8List bytes, String fileName) async {
    if (_uid == null) return null;
    try {
      final ext = _extOf(fileName);
      final ref = FirebaseStorage.instance.ref().child(
          'users/$_uid/photo/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, _metaFor(fileName));
      final url = await ref.getDownloadURL();
      await updateUser({'photoUrl': url});
      return url;
    } catch (e) {
      debugPrint('Upload de foto de perfil falhou: $e');
      return null;
    }
  }

  static String _extOf(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'bin';
  }

  static SettableMetadata _metaFor(String fileName) {
    final ext = _extOf(fileName);
    final type = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'm4a' || 'aac' || 'mp4' => 'audio/mp4',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
    return SettableMetadata(contentType: type);
  }

  static Future<void> updateFcmToken(String token) async {
    if (_uid == null) return;
    await _db.collection(Col.users).doc(_uid).update({'fcmToken': token});
  }

  static Future<void> addXp(int xp) async {
    // XP só via Cloud Functions (review / cadastro). Client não incrementa.
    debugPrint('addXp ignorado no client (xp=$xp)');
  }

  static Stream<List<ProviderModel>> providersStream(
      {String? category, int limit = 20}) {
    Query q = _db
        .collection(Col.providers)
        .where('active', isEqualTo: true)
        .where('verified', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit);
    if (category != null) q = q.where('categories', arrayContains: category);
    return q.snapshots().map((s) => s.docs
        .map((d) =>
            ProviderModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  static Stream<ProviderModel?> providerStream(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _db.collection(Col.providers).doc(id).snapshots().map((d) {
      final data = d.data();
      if (!d.exists || data == null) return null;
      return ProviderModel.fromMap(d.id, data);
    });
  }

  static Stream<List<ReviewModel>> reviewsForProvider(String providerId) {
    if (providerId.isEmpty) return Stream.value(const []);
    return _db
        .collection(Col.reviews)
        .where('providerId', isEqualTo: providerId)
        .limit(30)
        .snapshots()
        .map((s) {
      final list = s.docs
          .map((d) => ReviewModel.fromMap(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Cria o perfil de prestador (coleção providers) vinculado ao usuário
  // recém-cadastrado. Fica com verified:false até aprovação no painel
  // admin (Vol.6: Validação de Profissionais), quando então passa a
  // aparecer em providersStream() para os clientes.
  static Future<void> createProviderProfile({
    required String userId,
    required String name,
    required List<String> categories,
    String? city,
    List<String> modalities = const ['presential'],
    double? minPrice,
    String? photoUrl,
    String? documentUrl,
    String? selfieUrl,
    List<String> certificates = const [],
    List<String> serviceAreas = const [],
  }) async {
    await _db.collection(Col.providers).doc(userId).set({
      'userId': userId,
      'name': name,
      'categories': categories,
      'city': city,
      'modalities': modalities,
      'minPrice': minPrice,
      'photoUrl': photoUrl,
      'documentUrl': documentUrl,
      'selfieUrl': selfieUrl,
      'certificates': certificates,
      'serviceAreas': serviceAreas,
      'rating': 0.0,
      'totalReviews': 0,
      'active': false,
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> approveProvider(String id) => _db
      .collection(Col.providers)
      .doc(id)
      .update({'verified': true, 'active': true});

  // Atualiza os documentos de validação enviados no onboarding do
  // prestador (foto, RG/CNH, selfie, certificados, áreas atendidas).
  static Future<void> updateProviderDocuments({
    String? photoUrl,
    String? documentUrl,
    String? selfieUrl,
    List<String> certificates = const [],
    List<String> serviceAreas = const [],
  }) async {
    if (_uid == null) return;
    await _db.collection(Col.providers).doc(_uid).set({
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (documentUrl != null) 'documentUrl': documentUrl,
      if (selfieUrl != null) 'selfieUrl': selfieUrl,
      if (certificates.isNotEmpty) 'certificates': certificates,
      if (serviceAreas.isNotEmpty) 'serviceAreas': serviceAreas,
    }, SetOptions(merge: true));
  }

  static Future<String> createOrder(Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data);
    for (final k in OrderPolicy.sensitiveFields) {
      if (k != 'providerId' && k != 'price') sanitized.remove(k);
    }
    sanitized.remove('commission');
    sanitized.remove('platformFee');
    sanitized.remove('providerAmount');
    sanitized.remove('transactionId');
    sanitized.remove('cashbackGranted');
    final doc = await _db.collection(Col.orders).add({
      ...sanitized,
      'clientId': _uid,
      'status': 'pending',
      'paymentStatus': 'unpaid',
      'payoutProcessed': false,
      'payoutStatus': 'none',
      'createdAt': FieldValue.serverTimestamp()
    });
    return doc.id;
  }

  static Future<void> updateOrder(String orderId, Map<String, dynamic> data) {
    throw const CloudCallException(
        'Atualização direta de pedido bloqueada. Use as ações oficiais.',
        code: 'permission-denied');
  }

  static Future<Map<String, dynamic>> _transition(
      String orderId, String action, {Map<String, dynamic>? extra}) async {
    return CloudFn.call('transitionOrder', {
      'orderId': orderId,
      'action': action,
      ...?extra,
    });
  }

  static Future<void> completeOrder(String orderId) async {
    await _transition(orderId, 'complete');
    try {
      await grantCashback(orderId);
    } catch (e) {
      debugPrint('cashback: $e');
    }
  }

  static Stream<List<OrderModel>> myOrdersStream() => _db
      .collection(Col.orders)
      .where('clientId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList());

  // ── Pedidos do lado do Prestador (Vol.3: Perfil do Profissional) ─
  // Pedidos endereçados diretamente a este prestador (providerId == uid).
  /// Perfil de prestador do usuário logado (null se não for prestador).
  static Stream<ProviderModel?> myProviderStream() {
    if (_uid == null) return Stream.value(null);
    return _db
        .collection(Col.providers)
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : ProviderModel.fromMap(s.docs.first.id, s.docs.first.data()));
  }

  /// Liga/desliga o prestador. Offline (active=false) sai da busca
  /// imediatamente, pois providersStream filtra por active == true.
  static Future<void> setProviderOnline(String providerId, bool online) =>
      _db.collection(Col.providers).doc(providerId).update({'active': online});

  static Stream<List<OrderModel>> providerOrdersStream(
      {List<OrderStatus>? statuses}) {
    Query q = _db
        .collection(Col.orders)
        .where('providerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);
    if (statuses != null && statuses.isNotEmpty) {
      q = q.where('status', whereIn: statuses.map((s) => s.name).toList());
    }
    return q.snapshots().map((s) => s.docs
        .map((d) => OrderModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  static Future<void> acceptOrder(String orderId, {double? price}) async {
    await _transition(orderId, 'accept', extra: {
      if (price != null) 'price': price,
    });
  }

  static Future<void> declineOrder(String orderId) async {
    await _transition(orderId, 'decline');
  }

  static Future<void> cancelOrder(String orderId) async {
    await _transition(orderId, 'cancel', extra: {'reason': 'Cancelado pelo cliente'});
  }

  static Future<void> startOrder(String orderId) async {
    await _transition(orderId, 'start');
  }

  static Future<String> getOrCreateRoom(String otherUserId) async {
    final ids = [_uid ?? 'me', otherUserId]..sort();
    final id = ids.join('_');
    await _db.collection(Col.chatRooms).doc(id).set(
        {'participants': ids, 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    return id;
  }

  static Future<void> sendMessage(
      {required String roomId,
      required String senderName,
      required String text,
      String? mediaUrl,
      String? replyToText,
      String? replyToSender}) async {
    if (_uid == null) return;
    final batch = _db.batch();
    batch.set(
        _db
            .collection(Col.chatRooms)
            .doc(roomId)
            .collection(Col.messages)
            .doc(),
        {
          'senderId': _uid,
          'senderName': senderName,
          'text': text,
          'read': false,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
          if (replyToText != null) 'replyToText': replyToText,
          if (replyToSender != null) 'replyToSender': replyToSender,
          'createdAt': FieldValue.serverTimestamp(),
        });
    batch.set(
        _db.collection(Col.chatRooms).doc(roomId),
        {'lastMsg': text, 'lastMsgTime': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    await batch.commit();
  }

  // Apaga uma mensagem para todos: mantém o documento mas marca como
  // deletada (a UI mostra "mensagem apagada"), preservando a ordem.
  static Future<void> deleteMessageForAll(String roomId, String messageId) =>
      _db
          .collection(Col.chatRooms)
          .doc(roomId)
          .collection(Col.messages)
          .doc(messageId)
          .update(
              {'deleted': true, 'text': '', 'mediaUrl': FieldValue.delete()});

  // Indicador "digitando...": grava/limpa o estado do usuário na sala.
  static Future<void> setTyping(String roomId, bool typing) {
    if (_uid == null) return Future.value();
    return _db
        .collection(Col.chatRooms)
        .doc(roomId)
        .set({'typing_$_uid': typing}, SetOptions(merge: true));
  }

  static Stream<bool> typingStream(String roomId, String otherUid) => _db
      .collection(Col.chatRooms)
      .doc(roomId)
      .snapshots()
      .map((s) => (s.data()?['typing_$otherUid'] as bool?) ?? false);

  // ── Upload de mídia (Vol.2/Vol.3: chat com fotos/vídeos/documentos) ─
  static Future<String?> uploadChatMedia(
      Uint8List bytes, String fileName, String roomId) async {
    if (_uid == null) return null;
    try {
      final ext = _extOf(fileName);
      final ref = FirebaseStorage.instance.ref().child(
          'chat_media/$roomId/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, _metaFor(fileName));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload de mídia falhou: $e');
      return null;
    }
  }

  // Upload de documentos do cadastro de prestador (foto de perfil,
  // documento de identidade, selfie de validação, certificados —
  // Vol.3: Cadastro de Profissionais). O campo `kind` organiza os
  // arquivos em subpastas dentro de providers/{uid}/.
  static Future<String?> uploadProviderFile(
      Uint8List bytes, String fileName, String kind) async {
    if (_uid == null) return null;
    try {
      final ext = _extOf(fileName);
      final ref = FirebaseStorage.instance.ref().child(
          'providers/$_uid/$kind/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, _metaFor(fileName));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload de documento do prestador falhou: $e');
      return null;
    }
  }

  static Stream<List<MessageModel>> messagesStream(String roomId) => _db
      .collection(Col.chatRooms)
      .doc(roomId)
      .collection(Col.messages)
      .orderBy('createdAt')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => MessageModel.fromMap(d.id, d.data())).toList());

  // Marca como lidas todas as mensagens de outros remetentes na sala
  // (Vol.3: Chat — recibo de leitura ✓✓). Chamado ao abrir o chat.
  static Future<void> markMessagesRead(String roomId) async {
    if (_uid == null) return;
    final unread = await _db
        .collection(Col.chatRooms)
        .doc(roomId)
        .collection(Col.messages)
        .where('senderId', isNotEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  static Stream<WalletModel?> walletStream() => _db
      .collection(Col.wallets)
      .doc(_uid)
      .snapshots()
      .map((s) => s.exists ? WalletModel.fromMap(s.data()!) : null);

  static Stream<List<TransactionModel>> txStream() => _db
      .collection(Col.transactions)
      .where('userId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => TransactionModel.fromMap(d.id, d.data())).toList());

  static Future<bool> credit(double amount, String desc, String icon) async {
    // Crédito livre pelo client foi removido (fraude). Use recarga PIX
    // (Cloud Function checkPayment) ou cashback via walletOp.
    debugPrint(
        'FS.credit bloqueado no client ($amount / $desc). Use gateway/Functions.');
    return false;
  }

  static Future<bool> debit(double amount, String desc, String icon) async {
    return _walletOp(
      op: 'debit',
      amount: amount,
      description: desc,
      icon: icon,
    );
  }

  static Future<bool> payOrderWithWallet(String orderId) async {
    try {
      await CloudFn.call('payOrderWithWallet', {'orderId': orderId});
      return true;
    } catch (e) {
      debugPrint('payOrderWithWallet: $e');
      return false;
    }
  }

  static Future<bool> switchProfileType(String type) async {
    try {
      await CloudFn.call('switchProfileType', {'type': type});
      return true;
    } catch (e) {
      debugPrint('switchProfileType: $e');
      return false;
    }
  }

  // Saque para conta bancária via PIX. Cloud Function debita o saldo.
  static Future<bool> withdraw(double amount, String pixKey) async {
    if (amount < 10) return false;
    return _walletOp(
      op: 'withdraw',
      amount: amount,
      description: 'Saque para $pixKey',
      icon: '📤',
      pixKey: pixKey,
    );
  }

  static Future<bool> _walletOp({
    required String op,
    double? amount,
    String? description,
    String? icon,
    String? pixKey,
    String? orderId,
  }) async {
    if (_uid == null) return false;
    try {
      await CloudFn.call('walletOp', {
        'op': op,
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (pixKey != null) 'pixKey': pixKey,
        if (orderId != null) 'orderId': orderId,
      });
      return true;
    } catch (e) {
      debugPrint('walletOp error: $e');
      return false;
    }
  }

  static Future<void> saveReview(ReviewModel r) async {
    final reviewId = '${r.orderId}_${r.clientId}';
    await _db.collection(Col.reviews).doc(reviewId).set({
      'orderId': r.orderId,
      'clientId': r.clientId,
      'providerId': r.providerId,
      'clientName': r.clientName,
      'clientPhoto': r.clientPhoto,
      'stars': r.stars,
      'comment': r.comment,
      'tags': r.tags,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (r.orderId.isNotEmpty && r.orderId != 'demo') {
      await _db
          .collection(Col.orders)
          .doc(r.orderId)
          .update({'reviewed': true});
    }
  }

  static Future<void> pushNotif(
      String uid, String title, String body, String type) async {
    try {
      await CloudFn.call('createNotification', {
        'userId': uid,
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      debugPrint('createNotification error: $e');
    }
  }

  static Stream<List<NotifModel>> notifStream() => _db
      .collection(Col.notifications)
      .where('userId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NotifModel.fromMap(d.id, d.data())).toList());

  static Future<void> markNotifRead(String id) =>
      _db.collection(Col.notifications).doc(id).update({'read': true});

  static Future<CouponModel?> validateCoupon(String code) async {
    final q = await _db
        .collection(Col.coupons)
        .where('code', isEqualTo: code.toUpperCase())
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final c = CouponModel.fromMap(q.docs.first.id, q.docs.first.data());
    return c.isValid ? c : null;
  }

  static Stream<Map<String, dynamic>?> gpsStream(String id) =>
      _db.collection(Col.deliveries).doc(id).snapshots().map((s) => s.data());

  static Future<String> createAppointment(Map<String, dynamic> data) async {
    final doc = await _db.collection(Col.appointments).add({
      ...data,
      'clientId': _uid,
      'status': data['status'] == 'requested' ? 'requested' : 'scheduled',
      'createdAt': FieldValue.serverTimestamp()
    });
    return doc.id;
  }

  // Agenda do usuário (Vol.14: Saúde/Home Care — agendamentos). Lista
  // os agendamentos do cliente, mais recentes primeiro.
  static Stream<List<Map<String, dynamic>>> appointmentsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.appointments)
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Future<void> cancelAppointment(String id) =>
      _db.collection(Col.appointments).doc(id).update({'status': 'cancelled'});

  static Future<String> createCartOrder(Map<String, dynamic> data) async {
    final doc = await _db.collection(Col.orders).add({
      ...data,
      'clientId': _uid,
      'type': 'marketplace',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp()
    });
    return doc.id;
  }

  static Future<void> createSupportTicket(String subject, String message) =>
      _db.collection(Col.support).add({
        'userId': _uid,
        'userName': '',
        'subject': subject,
        'message': message,
        'status': 'open',
        'priority': 'normal',
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ── Companies (Vol.5: coleção companies) ──────────────────────
  static Future<void> saveCompany(CompanyModel c) => _db
      .collection(Col.companies)
      .doc(c.id)
      .set(c.toMap(), SetOptions(merge: true));

  static Future<CompanyModel?> getCompanyByOwner(String ownerId) async {
    final q = await _db
        .collection(Col.companies)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return CompanyModel.fromMap(q.docs.first.id, q.docs.first.data());
  }

  static Stream<CompanyModel?> companyStream(String id) => _db
      .collection(Col.companies)
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? CompanyModel.fromMap(s.id, s.data()!) : null);

  // ── Equipe da empresa (Vol.15: Empresas — Funcionários) ────────
  static Future<void> addEmployee(
      {required String companyId,
      required String name,
      required String role,
      String? email,
      String? phone}) async {
    await _db.collection(Col.employees).add({
      'companyId': companyId,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db
        .collection(Col.companies)
        .doc(companyId)
        .update({'teamSize': FieldValue.increment(1)});
  }

  static Future<void> removeEmployee(String id, String companyId) async {
    await _db.collection(Col.employees).doc(id).delete();
    await _db
        .collection(Col.companies)
        .doc(companyId)
        .update({'teamSize': FieldValue.increment(-1)});
  }

  static Stream<List<EmployeeModel>> employeesStream(String companyId) => _db
      .collection(Col.employees)
      .where('companyId', isEqualTo: companyId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => EmployeeModel.fromMap(d.id, d.data())).toList());

  // ── Filiais da empresa (Vol.15: Empresas — Filiais) ────────────
  static Future<void> addBranch(
          {required String companyId,
          required String name,
          required String address,
          required String city,
          required String state,
          String? phone}) =>
      _db.collection(Col.branches).add({
        'companyId': companyId,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'phone': phone,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> removeBranch(String id) =>
      _db.collection(Col.branches).doc(id).delete();

  // ── Marketplace: lojas e produtos (Vol.12) ─────────────────────
  // Empresas cadastram uma loja e anunciam produtos. Carrinho, pedidos,
  // cupons, favoritos e avaliações já existentes são reaproveitados.

  /// Cria ou atualiza a loja do usuário logado. Retorna o id da loja.
  static Future<String?> saveStore(StoreModel store) async {
    if (_uid == null) return null;
    final data = {...store.toMap(), 'ownerId': _uid};
    if (store.id.isEmpty) {
      final doc = await _db
          .collection(Col.stores)
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      return doc.id;
    }
    await _db
        .collection(Col.stores)
        .doc(store.id)
        .set(data, SetOptions(merge: true));
    return store.id;
  }

  /// Loja do usuário logado (null se ainda não cadastrou).
  static Stream<StoreModel?> myStoreStream() {
    if (_uid == null) return Stream.value(null);
    return _db
        .collection(Col.stores)
        .where('ownerId', isEqualTo: _uid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : StoreModel.fromMap(s.docs.first.id, s.docs.first.data()));
  }

  /// Envia logo ou banner da loja para o Storage e grava a URL.
  /// [kind] deve ser 'logo' ou 'banner'.
  static Future<String?> uploadStoreImage(
      String storeId, Uint8List bytes, String fileName, String kind) async {
    if (_uid == null) return null;
    try {
      final ext = _extOf(fileName);
      final ref = FirebaseStorage.instance.ref().child(
          'stores/$storeId/$kind/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, _metaFor(fileName));
      final url = await ref.getDownloadURL();
      await _db.collection(Col.stores).doc(storeId).set(
          {kind == 'logo' ? 'logoUrl' : 'bannerUrl': url},
          SetOptions(merge: true));
      return url;
    } catch (e) {
      debugPrint('Upload de imagem da loja falhou: $e');
      return null;
    }
  }

  // ── Locação: veículos e máquinas (Vol.13) ──────────────────────
  /// Cria ou atualiza um anúncio de locação do usuário logado.
  static Future<String?> saveRental(RentalModel r) async {
    if (_uid == null) return null;
    final data = {...r.toMap(), 'ownerId': _uid};
    if (r.id.isEmpty) {
      final doc = await _db
          .collection(Col.rentals)
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      return doc.id;
    }
    await _db
        .collection(Col.rentals)
        .doc(r.id)
        .set(data, SetOptions(merge: true));
    return r.id;
  }

  static Future<void> removeRental(String id) =>
      _db.collection(Col.rentals).doc(id).delete();

  static Future<void> setRentalAvailability(String id, bool available) =>
      _db.collection(Col.rentals).doc(id).update({'available': available});

  /// Anúncios ativos, opcionalmente filtrados por tipo e categoria.
  static Stream<List<RentalModel>> rentalsStream(
      {RentalKind? kind, String? category}) {
    Query<Map<String, dynamic>> q =
        _db.collection(Col.rentals).where('active', isEqualTo: true);
    if (kind != null)
      q = q.where('kind',
          isEqualTo: kind == RentalKind.machine ? 'machine' : 'vehicle');
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.snapshots().map(
        (s) => s.docs.map((d) => RentalModel.fromMap(d.id, d.data())).toList());
  }

  /// Anúncios do próprio usuário (para gerenciar).
  static Stream<List<RentalModel>> myRentalsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.rentals)
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => RentalModel.fromMap(d.id, d.data())).toList());
  }

  // ── Reservas de locação ────────────────────────────────────────
  /// Cria uma reserva para um anúncio. Notifica o anunciante.
  static Future<String?> createBooking(BookingModel b) async {
    if (_uid == null) return null;
    final doc = await _db.collection(Col.bookings).add({
      ...b.toMap(),
      'clientId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection(Col.notifications).add({
      'userId': b.ownerId,
      'title': 'Nova solicitação de reserva',
      'body': '${b.clientName} quer alugar ${b.rentalTitle}',
      'icon': '🔑',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<void> updateBookingStatus(String id, BookingStatus status) =>
      _db.collection(Col.bookings).doc(id).update({'status': status.name});

  /// Reservas feitas pelo usuário (como locatário).
  static Stream<List<BookingModel>> myBookingsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.bookings)
        .where('clientId', isEqualTo: _uid)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());
  }

  /// Reservas recebidas nos anúncios do usuário (como anunciante).
  static Stream<List<BookingModel>> receivedBookingsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.bookings)
        .where('ownerId', isEqualTo: _uid)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => BookingModel.fromMap(d.id, d.data())).toList());
  }

  /// Períodos já reservados de um anúncio, para bloquear conflito de datas.
  static Stream<List<BookingModel>> rentalBookingsStream(String rentalId) => _db
      .collection(Col.bookings)
      .where('rentalId', isEqualTo: rentalId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => BookingModel.fromMap(d.id, d.data()))
          .where((b) => b.isOpen)
          .toList());

  /// Envia uma foto do anúncio e devolve a URL.
  static Future<String?> uploadRentalPhoto(
      String rentalId, Uint8List bytes, String fileName) async {
    if (_uid == null) return null;
    try {
      final ext = _extOf(fileName);
      final ref = FirebaseStorage.instance.ref().child(
          'rentals/$rentalId/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(bytes, _metaFor(fileName));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload de foto do anúncio falhou: $e');
      return null;
    }
  }

  static Stream<List<StoreModel>> storesStream({String? category}) {
    Query<Map<String, dynamic>> q =
        _db.collection(Col.stores).where('active', isEqualTo: true);
    if (category != null) q = q.where('categories', arrayContains: category);
    return q.snapshots().map(
        (s) => s.docs.map((d) => StoreModel.fromMap(d.id, d.data())).toList());
  }

  static Future<String?> saveProduct(ProductModel p) async {
    if (_uid == null) return null;
    if (p.id.isEmpty) {
      final doc = await _db
          .collection(Col.products)
          .add({...p.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      await _db
          .collection(Col.stores)
          .doc(p.storeId)
          .update({'totalProducts': FieldValue.increment(1)});
      return doc.id;
    }
    await _db
        .collection(Col.products)
        .doc(p.id)
        .set(p.toMap(), SetOptions(merge: true));
    return p.id;
  }

  static Future<void> removeProduct(String productId, String storeId) async {
    await _db.collection(Col.products).doc(productId).delete();
    await _db
        .collection(Col.stores)
        .doc(storeId)
        .update({'totalProducts': FieldValue.increment(-1)});
  }

  /// Baixa o estoque após a venda (usado ao concluir o pedido).
  static Future<void> decrementStock(String productId, int qty) => _db
      .collection(Col.products)
      .doc(productId)
      .update({'stock': FieldValue.increment(-qty)});

  static Stream<List<ProductModel>> productsStream(
      {String? storeId, String? category}) {
    Query<Map<String, dynamic>> q =
        _db.collection(Col.products).where('active', isEqualTo: true);
    if (storeId != null) q = q.where('storeId', isEqualTo: storeId);
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.snapshots().map((s) =>
        s.docs.map((d) => ProductModel.fromMap(d.id, d.data())).toList());
  }

  static Stream<List<BranchModel>> branchesStream(String companyId) => _db
      .collection(Col.branches)
      .where('companyId', isEqualTo: companyId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BranchModel.fromMap(d.id, d.data())).toList());

  // ── Contratos da empresa (Vol.15: Empresas — Contratos) ────────
  static Future<void> createContract({
    required String companyId,
    required String clientName,
    required String title,
    String description = '',
    required double value,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _db.collection(Col.contracts).add({
        'companyId': companyId,
        'clientName': clientName,
        'title': title,
        'description': description,
        'value': value,
        'status': 'draft',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateContractStatus(String id, ContractStatus status) =>
      _db.collection(Col.contracts).doc(id).update({'status': status.name});

  static Stream<List<ContractModel>> contractsStream(String companyId) => _db
      .collection(Col.contracts)
      .where('companyId', isEqualTo: companyId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ContractModel.fromMap(d.id, d.data())).toList());

  // ── Admin: usuários e pedidos ──────────────────────────────────
  static Stream<QuerySnapshot> adminUsersStream({int limit = 50}) => _db
      .collection(Col.users)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
  static Stream<QuerySnapshot> adminOrdersStream({int limit = 50}) => _db
      .collection(Col.orders)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots();
  static Stream<QuerySnapshot> pendingProvidersStream() => _db
      .collection(Col.providers)
      .where('verified', isEqualTo: false)
      .snapshots();
  static Stream<QuerySnapshot> pendingCompaniesStream() => _db
      .collection(Col.companies)
      .where('verified', isEqualTo: false)
      .snapshots();

  // Dashboard KPIs em tempo real (Vol.6: usuários ativos, novos
  // cadastros, faturamento, serviços concluídos). Usa .count() do
  // Firestore, que agrega no servidor sem baixar os documentos.
  static Future<Map<String, dynamic>> fetchDashboardKpis() async {
    try {
      final usersCount = await _db.collection(Col.users).count().get();
      final providersCount = await _db
          .collection(Col.providers)
          .where('verified', isEqualTo: true)
          .count()
          .get();
      final completedOrders = await _db
          .collection(Col.orders)
          .where('status', isEqualTo: 'completed')
          .get();
      final revenue = completedOrders.docs.fold<double>(
          0, (sum, d) => sum + ((d.data()['price'] as num?)?.toDouble() ?? 0));
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final newUsers = await _db
          .collection(Col.users)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .count()
          .get();
      return {
        'totalUsers': usersCount.count ?? 0,
        'totalProviders': providersCount.count ?? 0,
        'revenue': revenue,
        'completedOrders': completedOrders.docs.length,
        'newUsersThisWeek': newUsers.count ?? 0,
      };
    } catch (e) {
      debugPrint('Erro ao buscar KPIs do dashboard: $e');
      return {
        'totalUsers': 0,
        'totalProviders': 0,
        'revenue': 0.0,
        'completedOrders': 0,
        'newUsersThisWeek': 0
      };
    }
  }

  // Relatório financeiro real (Vol.6: Financeiro — comissões,
  // repasses, saques, estornos, assinaturas). Agrega orders (receita
  // bruta, comissão) e transactions (PIX, estornos).
  static Future<Map<String, dynamic>> fetchFinancialReport() async {
    try {
      final completed = await _db
          .collection(Col.orders)
          .where('status', isEqualTo: 'completed')
          .get();
      final grossRevenue = completed.docs.fold<double>(
          0, (sum, d) => sum + ((d.data()['price'] as num?)?.toDouble() ?? 0));
      final commission = grossRevenue * AppConst.commission;
      final netToProviders = grossRevenue - commission;

      final cancelled = await _db
          .collection(Col.orders)
          .where('status', isEqualTo: 'cancelled')
          .where('refunded', isEqualTo: true)
          .get();
      final refunds = cancelled.docs.fold<double>(
          0,
          (sum, d) =>
              sum + ((d.data()['refundAmount'] as num?)?.toDouble() ?? 0));

      final pixTx = await _db
          .collection(Col.transactions)
          .where('type', isEqualTo: 'credit')
          .get();
      final pixTotal = pixTx.docs.fold<double>(
          0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));

      return {
        'grossRevenue': grossRevenue,
        'commission': commission,
        'netToProviders': netToProviders,
        'pixProcessed': pixTotal,
        'refunds': refunds,
        'completedCount': completed.docs.length,
      };
    } catch (e) {
      debugPrint('Erro ao buscar relatório financeiro: $e');
      return {
        'grossRevenue': 0.0,
        'commission': 0.0,
        'netToProviders': 0.0,
        'pixProcessed': 0.0,
        'refunds': 0.0,
        'completedCount': 0
      };
    }
  }

  static Future<void> suspendUser(String uid, {String? adminName}) async {
    await _db.collection(Col.users).doc(uid).update({'status': 'suspended'});
    await logAdminAction('Suspendeu usuário',
        target: uid, adminName: adminName);
  }

  static Future<void> reactivateUser(String uid, {String? adminName}) async {
    await _db.collection(Col.users).doc(uid).update({'status': 'active'});
    await logAdminAction('Reativou usuário', target: uid, adminName: adminName);
  }

  static Future<void> approveCompany(String id, {String? adminName}) async {
    await _db
        .collection(Col.companies)
        .doc(id)
        .update({'verified': true, 'active': true});
    await logAdminAction('Aprovou empresa', target: id, adminName: adminName);
  }

  // ── Admin: categorias (Vol.6: criar/editar/excluir/ordenação) ─
  static Future<void> saveCategory(Map<String, dynamic> data,
      {String? id}) async {
    if (id != null) {
      await _db
          .collection(Col.categories)
          .doc(id)
          .set(data, SetOptions(merge: true));
    } else {
      await _db.collection(Col.categories).add(data);
    }
  }

  static Future<void> deleteCategory(String id) =>
      _db.collection(Col.categories).doc(id).delete();
  static Stream<QuerySnapshot> categoriesStream() =>
      _db.collection(Col.categories).orderBy('order').snapshots();

  // ── Admin: marketing / banners (Vol.6) ─────────────────────────
  static Future<void> saveBanner(Map<String, dynamic> data,
      {String? id}) async {
    if (id != null) {
      await _db
          .collection(Col.banners)
          .doc(id)
          .set(data, SetOptions(merge: true));
    } else {
      await _db
          .collection(Col.banners)
          .add({...data, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  static Future<void> deleteBanner(String id) =>
      _db.collection(Col.banners).doc(id).delete();
  static Stream<List<BannerModel>> bannersStream() => _db
      .collection(Col.banners)
      .where('active', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BannerModel.fromMap(d.id, d.data())).toList());
  static Stream<QuerySnapshot> adminBannersStream() =>
      _db.collection(Col.banners).orderBy('order').snapshots();

  static Future<void> createCoupon(Map<String, dynamic> data) =>
      _db.collection(Col.coupons).add(
          {...data, 'active': true, 'createdAt': FieldValue.serverTimestamp()});
  static Stream<QuerySnapshot> adminCouponsStream() => _db
      .collection(Col.coupons)
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── Admin: atendimento / tickets (Vol.6) ───────────────────────
  static Stream<List<TicketModel>> adminTicketsStream({String? status}) {
    Query q =
        _db.collection(Col.support).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => s.docs
        .map((d) => TicketModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  static Future<void> updateTicketStatus(String id, String status,
      {String? adminName}) async {
    await _db.collection(Col.support).doc(id).update({'status': status});
    await logAdminAction('Atualizou chamado',
        target: id, adminName: adminName, details: {'status': status});
  }

  // ── Denúncias (Vol.20: Administração) ──────────────────────────
  // Qualquer usuário pode denunciar outro (prestador, cliente ou
  // conteúdo). O admin modera pelo painel (ver reportsStream abaixo).
  static Future<void> createReport({
    required String targetId,
    required String targetName,
    required String reason,
    String details = '',
  }) async {
    if (_uid == null) return;
    final me = await getUser();
    await _db.collection(Col.reports).add({
      'reporterId': _uid,
      'reporterName': me?.name ?? 'Usuário',
      'targetId': targetId,
      'targetName': targetName,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<ReportModel>> reportsStream({ReportStatus? status}) {
    Query q =
        _db.collection(Col.reports).orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs
        .map((d) => ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  static Future<void> updateReportStatus(String id, ReportStatus status,
      {String? adminName}) async {
    await _db.collection(Col.reports).doc(id).update({'status': status.name});
    await logAdminAction('Atualizou denúncia',
        target: id, adminName: adminName, details: {'status': status.name});
  }

  // ── Admin: financeiro (Vol.6: comissões, repasses, saques, estornos) ─
  static Future<void> processRefund(String orderId, double amount,
      {String? adminName}) async {
    await _db.collection(Col.orders).doc(orderId).update(
        {'status': 'cancelled', 'refunded': true, 'refundAmount': amount});
    await logAdminAction('Processou estorno',
        target: orderId, adminName: adminName, details: {'amount': amount});
  }

  // ── Auditoria (Vol.6: toda ação crítica registrada) ────────────
  static Future<void> logAdminAction(String action,
          {required String target,
          String? adminName,
          Map<String, dynamic>? details}) =>
      _db.collection(Col.auditLogs).add({
        'adminId': _uid,
        'adminName': adminName ?? 'Admin',
        'action': action,
        'target': target,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });

  // ── Configurações gerais da plataforma (Vol.20: Administração) ──
  // Documento único em config/platform. Lido pelo app inteiro (ex.:
  // AppConst.commission é o valor padrão de fallback caso este
  // documento ainda não exista) e editável apenas pelo admin.
  static Stream<Map<String, dynamic>> platformConfigStream() =>
      _db.collection('config').doc('platform').snapshots().map((d) =>
          d.data() ??
          {
            'commissionRate': AppConst.commission,
            'maintenanceMode': false,
            'supportEmail': 'suporte@servicoconecta.com.br',
            'supportPhone': '(11) 4000-0000'
          });

  static Future<void> updatePlatformConfig(Map<String, dynamic> data,
      {String? adminName}) async {
    await _db.collection('config').doc('platform').set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    await logAdminAction('Atualizou configurações da plataforma',
        target: 'platform', adminName: adminName, details: data);
  }

  static Stream<List<AuditLogModel>> auditLogStream({int limit = 100}) => _db
      .collection(Col.auditLogs)
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => AuditLogModel.fromMap(d.id, d.data())).toList());

  // ── Favoritos (Vol.2/Vol.5: coleção favorites) ─────────────────
  static Future<bool> toggleFavorite(String providerId) async {
    if (_uid == null) return false;
    final ref = _db.collection(Col.favorites).doc('${_uid}_$providerId');
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false;
    } else {
      await ref.set({
        'userId': _uid,
        'providerId': providerId,
        'createdAt': FieldValue.serverTimestamp()
      });
      return true;
    }
  }

  static Stream<bool> isFavoriteStream(String providerId) => _db
      .collection(Col.favorites)
      .doc('${_uid}_$providerId')
      .snapshots()
      .map((s) => s.exists);

  static Stream<List<ProviderModel>> favoritesStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.favorites)
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .asyncMap((favSnap) async {
      final providerIds =
          favSnap.docs.map((d) => d.data()['providerId'] as String).toList();
      if (providerIds.isEmpty) return <ProviderModel>[];
      final providers = <ProviderModel>[];
      for (final id in providerIds) {
        final doc = await _db.collection(Col.providers).doc(id).get();
        if (doc.exists)
          providers.add(ProviderModel.fromMap(doc.id, doc.data()!));
      }
      return providers;
    });
  }

  // ── Favoritos de produtos (Vol.12: Marketplace) ────────────────
  // Usa o mesmo padrão dos favoritos de prestador, mas com prefixo
  // próprio no id do documento para não colidir e permitir listar
  // separadamente. Como os produtos do Marketplace ainda vivem numa
  // lista estática no client (não há coleção `products` no Firestore
  // ainda), aqui expomos só o conjunto de IDs favoritados; a tela
  // filtra a lista local por esses IDs.
  static Future<bool> toggleProductFavorite(String productId) async {
    if (_uid == null) return false;
    final ref = _db.collection(Col.favorites).doc('${_uid}_product_$productId');
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false;
    } else {
      await ref.set({
        'userId': _uid,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp()
      });
      return true;
    }
  }

  static Stream<bool> isProductFavoriteStream(String productId) => _db
      .collection(Col.favorites)
      .doc('${_uid}_product_$productId')
      .snapshots()
      .map((s) => s.exists);

  static Stream<Set<String>> favoriteProductIdsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.favorites)
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs
            .where((d) => d.data().containsKey('productId'))
            .map((d) => d.data()['productId'] as String)
            .toSet());
  }

  // ── Histórico de pedidos do cliente (Vol.3: Perfil do Cliente) ──
  static Stream<List<OrderModel>> orderHistoryStream({OrderStatus? status}) {
    Query q = _db
        .collection(Col.orders)
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) => s.docs
        .map((d) => OrderModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // Cashback = 2% — taxa aplicada na Cloud Function walletOp.
  static Future<void> grantCashback(String orderId) async {
    await _walletOp(op: 'cashback', orderId: orderId);
  }

  // ── Resolve Carajás ─────────────────────────────────────────
  static Future<String> createResolveRequest({
    required String description,
    required String category,
    required String city,
    String? address,
    String? clientName,
  }) async {
    final doc = await _db.collection(Col.resolveRequests).add({
      'clientId': _uid,
      'clientName': clientName ?? '',
      'description': description,
      'category': category,
      'city': city,
      'address': address,
      'status': 'open',
      'proposalCount': 0,
      'leadMonetizationReady': true,
      'leadFee': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notifica prestadores compatíveis (até 20) — base para lead pago.
    final providers = await _db
        .collection(Col.providers)
        .where('active', isEqualTo: true)
        .where('categories', arrayContains: category)
        .limit(20)
        .get();
    for (final p in providers.docs) {
      final pid = (p.data()['userId'] as String?) ?? p.id;
      await pushNotif(
          pid,
          '⚡ Nova oportunidade Resolve',
          description.length > 80
              ? '${description.substring(0, 80)}…'
              : description,
          'resolve');
    }
    return doc.id;
  }

  static Stream<List<ResolveRequest>> myResolveRequestsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection(Col.resolveRequests)
        .where('clientId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ResolveRequest.fromMap(d.id, d.data()))
            .toList());
  }

  static Stream<ResolveRequest?> resolveRequestStream(String id) => _db
      .collection(Col.resolveRequests)
      .doc(id)
      .snapshots()
      .map((s) =>
          s.exists ? ResolveRequest.fromMap(s.id, s.data()!) : null);

  static Stream<List<ResolveRequest>> resolveOpportunitiesStream({
    String? category,
    String? city,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection(Col.resolveRequests)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(40);
    if (category != null) {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map((s) {
      var list = s.docs
          .map((d) => ResolveRequest.fromMap(d.id, d.data()))
          .toList();
      if (city != null && city.isNotEmpty) {
        final c = city.toLowerCase();
        list = list
            .where((r) => r.city.toLowerCase().contains(c))
            .toList();
      }
      return list;
    });
  }

  static Future<String> submitResolveProposal({
    required String requestId,
    required String providerName,
    String? providerPhoto,
    required double price,
    required int deadlineDays,
    String? message,
    double rating = 0,
    int totalServices = 0,
  }) async {
    final id = await _db.collection(Col.resolveProposals).add({
      'requestId': requestId,
      'providerId': _uid,
      'providerName': providerName,
      'providerPhoto': providerPhoto,
      'price': price,
      'deadlineDays': deadlineDays,
      'message': message,
      'rating': rating,
      'totalServices': totalServices,
      'available': true,
      'accepted': false,
      'createdAt': FieldValue.serverTimestamp(),
    }).then((d) => d.id);

    await _db.collection(Col.resolveRequests).doc(requestId).update({
      'proposalCount': FieldValue.increment(1),
    });

    final req = await _db.collection(Col.resolveRequests).doc(requestId).get();
    final clientId = req.data()?['clientId'] as String?;
    if (clientId != null) {
      await pushNotif(clientId, '💬 Nova proposta Resolve',
          '$providerName enviou uma proposta para seu pedido.', 'resolve');
    }
    return id;
  }

  static Stream<List<ResolveProposal>> resolveProposalsStream(
          String requestId) =>
      _db
          .collection(Col.resolveProposals)
          .where('requestId', isEqualTo: requestId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => ResolveProposal.fromMap(d.id, d.data()))
              .toList());

  static Future<void> acceptResolveProposal({
    required String requestId,
    required String proposalId,
    required String providerId,
    required String providerName,
  }) async {
    await _db.collection(Col.resolveProposals).doc(proposalId).update({
      'accepted': true,
    });
    await _db.collection(Col.resolveRequests).doc(requestId).update({
      'status': 'matched',
      'matchedProviderId': providerId,
      'matchedProposalId': proposalId,
    });
    await pushNotif(providerId, '✅ Proposta aceita!',
        'Sua proposta Resolve foi aceita. Fale com o cliente no chat.',
        'resolve');
  }

  /// Lista salas do usuário autenticado (inbox unificado).
  static Stream<List<ChatRoomPreview>> chatRoomsStream() {
    if (_uid == null) return const Stream.empty();
    final me = _uid!;
    // Sem orderBy no Firestore para evitar exclusão de salas antigas
    // sem lastMsgTime; ordenação feita no client.
    return _db
        .collection(Col.chatRooms)
        .where('participants', arrayContains: me)
        .limit(50)
        .snapshots()
        .asyncMap((snap) async {
      final out = <ChatRoomPreview>[];
      for (final d in snap.docs) {
        final data = d.data();
        final parts = List<String>.from(data['participants'] ?? []);
        final otherId = parts.firstWhere((p) => p != me, orElse: () => '');
        String otherName = 'Contato';
        String? otherPhoto;
        if (otherId.isNotEmpty) {
          try {
            final u = await getUser(otherId);
            if (u != null) {
              otherName = u.name.isNotEmpty ? u.name : otherName;
              otherPhoto = u.photoUrl;
            }
          } catch (_) {}
        }
        out.add(ChatRoomPreview(
          id: d.id,
          otherUserId: otherId,
          otherName: otherName,
          otherPhoto: otherPhoto,
          lastMsg: (data['lastMsg'] as String?) ?? '',
          lastMsgTime: (data['lastMsgTime'] as Timestamp?)?.toDate(),
        ));
      }
      out.sort((a, b) {
        final ta = a.lastMsgTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.lastMsgTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return out;
    });
  }
}

/// Callables autenticadas (região us-central1). Sem CORS aberto.
abstract final class CloudFn {
  static String get projectId =>
      DefaultFirebaseOptions.currentPlatform.projectId;
  static String get base =>
      'https://us-central1-$projectId.cloudfunctions.net';

  static FirebaseFunctions get _fn =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  static Future<Map<String, dynamic>> call(
      String name, [Map<String, dynamic>? data]) async {
    try {
      final result = await _fn.httpsCallable(name).call(data ?? {});
      final raw = result.data;
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {'data': raw};
    } on FirebaseFunctionsException catch (e) {
      throw CloudCallException(e.message ?? 'Falha na operação',
          code: e.code);
    }
  }
}

class PaySvc {
  // Public Key do Mercado Pago via --dart-define=MERCADOPAGO_PUBLIC_KEY=...
  static String get _mpPublicKey => RuntimeConfig.mercadoPagoPublicKey;

  static Future<Map<String, dynamic>?> generatePix(
      {required double amount,
      required String description,
      required String email,
      required String orderId,
      String? userId,
      String purpose = 'order'}) async {
    try {
      return await CloudFn.call('generatePix', {
        'amount': amount,
        'description': description,
        'email': email,
        if (orderId.isNotEmpty) 'orderId': orderId,
        'purpose': purpose,
      });
    } catch (e) {
      debugPrint('PIX error: $e');
      return null;
    }
  }

  static Future<String?> checkPayment(String paymentId) async {
    try {
      final data = await CloudFn.call('checkPayment', {'id': paymentId});
      return data['status'] as String?;
    } catch (e) {
      debugPrint('checkPayment error: $e');
      return null;
    }
  }

  // ── Cartão de crédito (Vol.17: Pagamentos) ─────────────────────
  // Tokeniza o cartão direto com o Mercado Pago (nunca passa pelo
  // nosso backend em texto puro — exigência de PCI-DSS) e então
  // envia apenas o token para a Cloud Function processar a cobrança.
  static Future<String?> tokenizeCard({
    required String cardNumber,
    required String holderName,
    required String expMonth,
    required String expYear,
    required String cvv,
    required String docNumber,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse(
                'https://api.mercadopago.com/v1/card_tokens?public_key=$_mpPublicKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'card_number': cardNumber.replaceAll(' ', ''),
              'cardholder': {
                'name': holderName,
                'identification': {'type': 'CPF', 'number': docNumber}
              },
              'expiration_month': int.tryParse(expMonth) ?? 1,
              'expiration_year':
                  int.tryParse('20$expYear') ?? DateTime.now().year,
              'security_code': cvv,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200 || r.statusCode == 201)
        return (jsonDecode(r.body) as Map)['id'] as String?;
      debugPrint('Tokenização de cartão falhou: ${r.body}');
      return null;
    } catch (e) {
      debugPrint('Erro ao tokenizar cartão: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> payWithCard({
    required double amount,
    required String description,
    required String email,
    required String orderId,
    required String cardToken,
    int installments = 1,
    String? docNumber,
  }) async {
    try {
      return await CloudFn.call('processCardPayment', {
        'description': description,
        'email': email,
        'orderId': orderId,
        'cardToken': cardToken,
        'installments': installments,
        'payerDocNumber': docNumber,
      });
    } catch (e) {
      debugPrint('Erro no pagamento com cartão: $e');
      return null;
    }
  }

  static Future<bool> payWallet(double amount, String desc, String icon) =>
      FS.debit(amount, desc, icon);
  static double fee(double amount) => amount * AppConst.commission;
  static String fmt(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
}

// ── Assistente de IA (Vol.28: IA e Automações) ────────────────
// Usa a Cloud Function `aiAssistant` (Claude API). Se o backend não
// estiver configurado ou a chamada falhar, retorna null e a tela de
// IA cai automaticamente no modo de respostas locais (fallback),
// garantindo que o assistente nunca trave para o usuário.
class AiSvc {
  static Future<String?> ask(
      String message, List<Map<String, dynamic>> history) async {
    try {
      final data = await CloudFn.call('tiaChat', {
        'message': message,
        'history': history,
      });
      if (data['available'] == false) return null;
      final reply = data['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) return null;
      return reply;
    } catch (e) {
      debugPrint('IA error: $e');
      return null;
    }
  }

  static Future<String?> suggestDescription(
      {required String category, required String draft}) async {
    if (draft.trim().isEmpty) return null;
    final prompt =
        'Reescreva a descrição de um pedido de $category de forma clara e objetiva, '
        'em no máximo 3 frases, sem inventar detalhes: "$draft"';
    final reply = await ask(prompt, const []);
    return reply?.trim();
  }

  static Future<String?> suggestBudget(
      {required String category, required String description}) async {
    try {
      final data = await CloudFn.call('tiaEstimate', {'category': category});
      if (data['sufficient'] != true) return null;
      return data['message'] as String?;
    } catch (e) {
      debugPrint('Estimativa: $e');
      return null;
    }
  }

  static Future<String?> smartSearchCategory(
      String query, List<String> availableCategories) async {
    if (query.trim().isEmpty) return null;
    final prompt =
        'Dado o pedido: "$query", qual categoria da lista é a mais adequada? '
        'Responda só com o nome exato, ou "nenhuma" se não houver: ${availableCategories.join(", ")}';
    final reply = await ask(prompt, const []);
    if (reply == null) return null;
    final cleaned = reply.trim().toLowerCase();
    final match = availableCategories
        .where((c) => cleaned.contains(c.toLowerCase()))
        .toList();
    return match.isEmpty ? null : match.first;
  }
}

class PushSvc {
  static Future<void> init() async {
    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('FCM permission: $e');
    }

    // Plugin nativo só via import condicional (stub no Web).
    // Sem google-services real / emulador, FCM pode falhar — nao derruba o app.
    if (!kIsWeb) {
      try {
        await initLocalNotificationsPlugin((_, __) {});
        FirebaseMessaging.onMessage.listen((msg) {
          if (msg.notification != null) {
            _show(msg.notification!.title ?? 'Carajás 360',
                msg.notification!.body ?? '');
          }
        });
      } catch (e) {
        debugPrint('FCM/local notifications: $e');
      }
    }
  }

  static Future<void> saveToken(String uid) async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) await FS.updateFcmToken(t);
    } catch (e) {
      debugPrint('FCM token: $e');
    }
  }

  static Future<void> _show(String title, String body) async {
    if (kIsWeb) return;
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }
}

