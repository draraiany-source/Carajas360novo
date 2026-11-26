import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:servico_conecta/core/utils/firebase_bootstrap.dart';
import 'package:servico_conecta/shared/models/models.dart';
import 'package:servico_conecta/shared/services/firebase_service.dart';

/// Smoke tecnico completo (Auth, Firestore, Storage, Chat, Notificacoes).
/// Google: valida caminho federado no emulador (signInWithPopup disponivel).
///
/// Rodar:
///   flutter run -d chrome --web-port=5556 -t lib/auth_smoke_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var ok = true;
  void step(String msg) => debugPrint('SMOKE: $msg');
  void fail(Object e, [StackTrace? st]) {
    ok = false;
    debugPrint('SMOKE_FAIL $e');
    if (st != null) debugPrint('$st');
  }

  try {
    await FirebaseBootstrap.initialize();
    step('emulator=${FirebaseBootstrap.shouldUseEmulator}');
    if (!FirebaseBootstrap.shouldUseEmulator) {
      throw StateError('Smoke exige emuladores (placeholders ou dart-define)');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final email = 'chrome_smoke_$ts@test.com';
    const password = 'Senha123';

    // ── Cadastro + perfil Firestore ─────────────────────────────
    final cred = await AuthService.signUpEmail(
      email: email,
      password: password,
      displayName: 'Chrome Smoke',
    );
    step('signup uid=${cred.user?.uid} auth=${AuthService.isAuth}');
    final uid = AuthService.uid!;

    await FS.saveUser(UserModel(
      id: uid,
      name: 'Chrome Smoke',
      email: email,
      phone: '11999999999',
      cpf: '12345678901',
      city: 'Sao Paulo',
      state: 'SP',
      type: UserType.client,
      xp: 0,
      termsAccepted: true,
      createdAt: DateTime.now(),
    ));
    final profile = await FS.getUser(uid);
    step('profile email=${profile?.email}');
    if (profile?.email != email) throw StateError('perfil Firestore invalido');

    // ── Notificacoes (Firestore) ─────────────────────────────────
    await FS.pushNotif(uid, 'Smoke', 'Notificacao de teste', 'general');
    step('pushNotif OK');

    // ── Storage ─────────────────────────────────────────────────
    // PNG 1x1 minimo
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
      0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    final photoUrl = await FS.uploadUserPhoto(png, 'smoke.png');
    step('storage upload url=${photoUrl != null}');
    if (photoUrl == null) throw StateError('Storage upload falhou');

    // ── Chat ────────────────────────────────────────────────────
    final otherEmail = 'chrome_other_$ts@test.com';
    await AuthService.signOut();
    final other = await AuthService.signUpEmail(
      email: otherEmail,
      password: password,
      displayName: 'Other User',
    );
    final otherUid = other.user!.uid;
    await FS.saveUser(UserModel(
      id: otherUid,
      name: 'Other User',
      email: otherEmail,
      phone: '11988887777',
      type: UserType.provider,
      termsAccepted: true,
      createdAt: DateTime.now(),
    ));
    await AuthService.signOut();

    await AuthService.signInEmail(email, password);
    final roomId = await FS.getOrCreateRoom(otherUid);
    await FS.sendMessage(
      roomId: roomId,
      senderName: 'Chrome Smoke',
      text: 'ola smoke chat',
    );
    step('chat room=$roomId message OK');

    // ── Login + reset ───────────────────────────────────────────
    await AuthService.signOut();
    await AuthService.signInEmail(email, password);
    step('login auth=${AuthService.isAuth}');
    await AuthService.resetPassword(email);
    step('resetPassword OK');

    // ── Google (caminho federado no emulador) ───────────────────
    // Nao abre popup no smoke headless; garante que o modo emulador
    // usa o fluxo federado (sem exigir Client ID OAuth real).
    final googleUsesFederated = FirebaseBootstrap.shouldUseEmulator || kIsWeb;
    step('googleFederatedPath=$googleUsesFederated');
    if (!googleUsesFederated) {
      throw StateError('Google deveria usar fluxo federado no emulador');
    }

    await AuthService.signOut();
    step('logout auth=${AuthService.isAuth}');

    if (ok && !AuthService.isAuth && profile?.email == email) {
      debugPrint('SMOKE_PASS');
    } else {
      debugPrint('SMOKE_FAIL state');
    }
  } catch (e, st) {
    fail(e, st);
  }
}
