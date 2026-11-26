import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';

/// Autorização de rotas/telas sensíveis (claims + perfil).
abstract final class AccessControl {
  static Future<bool> isAdmin() async {
    final user = AuthService.current;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? const <String, dynamic>{};
      if (claims['admin'] == true || claims['role'] == 'admin') {
        return true;
      }
    } on FirebaseAuthException {
      return false;
    }
    final profile = await FS.getUser();
    return profile?.type == UserType.admin || profile?.adminRole != null;
  }
}

class AdminGate extends StatelessWidget {
  final Widget child;
  const AdminGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return FutureBuilder<bool>(
      future: AccessControl.isAdmin(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == true) return child;
        return Scaffold(
          appBar: AppBar(title: const Text('Acesso negado')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('⛔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Você não tem permissão para abrir o painel admin.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, Routes.main),
                  child: const Text('Voltar ao início'),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

bool sessionActive() {
  try {
    return AuthService.isAuth;
  } catch (_) {
    return false;
  }
}

/// Leva ao login quando a ação grava dados. Explorar a plataforma não passa por aqui.
Future<bool> ensureSignedIn(BuildContext context) async {
  if (sessionActive()) return true;
  await Navigator.pushNamed(context, Routes.login);
  return sessionActive();
}

class RequireAuth extends StatelessWidget {
  final Widget child;
  final String title;
  const RequireAuth({super.key, required this.child, this.title = 'Área protegida'});

  @override
  Widget build(BuildContext context) {
    if (AuthService.isAuth) return child;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Faça login para continuar.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, Routes.login),
              child: const Text('Entrar'),
            ),
          ]),
        ),
      ),
    );
  }
}
