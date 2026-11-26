import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Allows real HTTP during Flutter tests (binding otherwise forces 400).
class _AllowHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}

Future<bool> _authEmulatorReachable() async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final req = await client.getUrl(
      Uri(scheme: 'http', host: '127.0.0.1', port: 9099, path: '/'),
    );
    final res = await req.close().timeout(const Duration(seconds: 5));
    final code = res.statusCode;
    await res.drain<void>();
    client.close(force: true);
    // ignore: avoid_print
    print('Auth emulator probe status=$code');
    return code >= 200 && code < 500;
  } catch (e) {
    // ignore: avoid_print
    print('Auth emulator probe FAILED: $e');
    return false;
  }
}

Future<Map<String, dynamic>> _httpJson(
  String method,
  Uri uri,
  Map<String, dynamic>? body, {
  String? bearer,
  bool expectError = false,
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, uri);
    req.headers.contentType = ContentType.json;
    if (bearer != null) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    if (body != null) {
      req.write(jsonEncode(body));
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    final decoded = text.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(text) as Map<String, dynamic>;
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (expectError) {
      if (ok) {
        throw StateError('Expected HTTP error but got ${res.statusCode}: $text');
      }
      return {
        'statusCode': res.statusCode,
        'body': decoded,
      };
    }
    if (!ok) {
      throw HttpException('HTTP ${res.statusCode}: $text', uri: uri);
    }
    return decoded;
  } finally {
    client.close(force: true);
  }
}

void _pass(String step) {
  // ignore: avoid_print
  print('PASS: $step');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowHttpOverrides();

  test('auth lifecycle against Auth+Firestore emulators', () async {
    final reachable = await _authEmulatorReachable();
    if (!reachable) {
      // Ambiente sem emuladores: não falha a suíte unitária local/CI.
      // Rode com Auth em :9099 e Firestore em :8080 para executar de fato.
      markTestSkipped(
          'Auth emulator not reachable on localhost:9099');
      return;
    }

    // firebase_core needs platform channels; unit tests run on the Dart VM.
    // Exercise Auth+Firestore emulators via REST (full product auth lifecycle).
    const projectId = 'servicoconecta';
    const apiKey = 'fake-api-key';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final email = 'auth_flow_$ts@test.com';
    const password = 'Senha123';
    const wrongPassword = 'SenhaErrada999';
    const name = 'Teste Auth Flow';
    const phone = '11999998888';
    const cpf = '12345678901';
    const city = 'Sao Paulo';
    const state = 'SP';
    const type = 'client';

    final signUpUri = Uri.parse(
      'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );
    final signInUri = Uri.parse(
      'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );
    final lookupUri = Uri.parse(
      'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey',
    );

    try {
      // 1) signUp / createUser
      final signUp = await _httpJson(
        'POST',
        signUpUri,
        {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );
      final uid = signUp['localId'] as String;
      var idToken = signUp['idToken'] as String;
      expect(uid, isNotEmpty);
      expect(idToken, isNotEmpty);
      _pass('signUp (createUser) -> uid=$uid email=$email');

      // 2) Firestore users/{uid} with app profile fields
      final docUri = Uri.parse(
        'http://127.0.0.1:8080/v1/projects/$projectId/databases/(default)/documents/users/$uid',
      );
      await _httpJson(
        'PATCH',
        docUri,
        {
          'fields': {
            'name': {'stringValue': name},
            'email': {'stringValue': email},
            'phone': {'stringValue': phone},
            'cpf': {'stringValue': cpf},
            'city': {'stringValue': city},
            'state': {'stringValue': state},
            'type': {'stringValue': type},
            'termsAccepted': {'booleanValue': true},
          },
        },
        bearer: idToken,
      );

      final snapAfterWrite =
          await _httpJson('GET', docUri, null, bearer: idToken);
      final fieldsAfterWrite =
          snapAfterWrite['fields'] as Map<String, dynamic>;
      expect(
        (fieldsAfterWrite['name'] as Map)['stringValue'],
        name,
      );
      expect(
        (fieldsAfterWrite['email'] as Map)['stringValue'],
        email,
      );
      expect(
        (fieldsAfterWrite['phone'] as Map)['stringValue'],
        phone,
      );
      expect(
        (fieldsAfterWrite['cpf'] as Map)['stringValue'],
        cpf,
      );
      expect(
        (fieldsAfterWrite['city'] as Map)['stringValue'],
        city,
      );
      expect(
        (fieldsAfterWrite['state'] as Map)['stringValue'],
        state,
      );
      expect(
        (fieldsAfterWrite['type'] as Map)['stringValue'],
        type,
      );
      expect(
        (fieldsAfterWrite['termsAccepted'] as Map)['booleanValue'],
        isTrue,
      );
      _pass(
        'Firestore users/$uid profile written '
        '(name,email,phone,cpf,city,state,type,termsAccepted)',
      );

      // 3) signOut simulation: discard client token
      idToken = '';
      _pass('signOut simulation: discarded idToken (client logout)');

      // 4) signInWithPassword (login again)
      final signIn = await _httpJson(
        'POST',
        signInUri,
        {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        },
      );
      expect(signIn['localId'], uid);
      idToken = signIn['idToken'] as String;
      expect(idToken, isNotEmpty);
      _pass('signInWithPassword (login) -> new idToken');

      // 5) accounts:lookup proves session token works (remain authenticated)
      final lookup = await _httpJson(
        'POST',
        lookupUri,
        {'idToken': idToken},
      );
      final users = lookup['users'] as List<dynamic>;
      expect(users, isNotEmpty);
      final lookedUp = users.first as Map<String, dynamic>;
      expect(lookedUp['localId'], uid);
      expect(lookedUp['email'], email);

      final snapAfterLogin =
          await _httpJson('GET', docUri, null, bearer: idToken);
      final emailField =
          (snapAfterLogin['fields'] as Map)['email'] as Map<String, dynamic>;
      expect(emailField['stringValue'], email);
      _pass(
        'accounts:lookup + Firestore read OK (session remains authenticated)',
      );

      // 6) wrong password must fail
      final wrong = await _httpJson(
        'POST',
        signInUri,
        {
          'email': email,
          'password': wrongPassword,
          'returnSecureToken': true,
        },
        expectError: true,
      );
      expect(wrong['statusCode'], greaterThanOrEqualTo(400));
      final errBody = wrong['body'] as Map<String, dynamic>;
      final err = errBody['error'] as Map<String, dynamic>?;
      final message = (err?['message'] ?? '').toString();
      expect(
        message.contains('INVALID_PASSWORD') ||
            message.contains('INVALID_LOGIN_CREDENTIALS') ||
            message.contains('EMAIL_NOT_FOUND'),
        isTrue,
        reason: 'unexpected error message: $message',
      );
      _pass('wrong password rejected ($message)');

      // 7) clear token again (logout)
      idToken = '';
      _pass('signOut simulation again: discarded idToken (logout)');

      // ignore: avoid_print
      print('PASS: full auth lifecycle OK for $email / users/$uid');
    } catch (e, st) {
      // ignore: avoid_print
      print('FAIL: $e\n$st');
      fail('Auth emulator lifecycle failed: $e');
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}