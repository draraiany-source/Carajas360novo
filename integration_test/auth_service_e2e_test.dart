import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:servico_conecta/core/utils/firebase_bootstrap.dart';
import 'package:servico_conecta/shared/models/models.dart';
import 'package:servico_conecta/shared/services/firebase_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cadastro login sessao logout via AuthService+Firestore',
      (tester) async {
    await FirebaseBootstrap.initialize();
    expect(FirebaseBootstrap.shouldUseEmulator, isTrue,
        reason: 'E2E exige emuladores (keys placeholder)');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final email = 'e2e_$ts@test.com';
    const password = 'Senha123';

    // 1) Cadastro (createUser + sessao automatica)
    final cred = await AuthService.signUpEmail(
      email: email,
      password: password,
      displayName: 'E2E User',
    );
    expect(cred.user, isNotNull);
    expect(AuthService.isAuth, isTrue);
    final uid = AuthService.uid!;

    // 2) Perfil Firestore
    await FS.saveUser(UserModel(
      id: uid,
      name: 'E2E User',
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
    expect(profile, isNotNull);
    expect(profile!.email, email);
    expect(profile.name, 'E2E User');

    // 3) Logout
    await AuthService.signOut();
    expect(AuthService.isAuth, isFalse);

    // 4) Login
    await AuthService.signInEmail(email, password);
    expect(AuthService.isAuth, isTrue);
    expect(AuthService.uid, uid);

    // 5) Permanecer autenticado + reler perfil
    final again = await FS.getUser(uid);
    expect(again?.email, email);

    // 6) Logout final
    await AuthService.signOut();
    expect(AuthService.isAuth, isFalse);
  });
}
