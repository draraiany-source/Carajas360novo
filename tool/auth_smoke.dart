import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> httpJson(
  String method,
  Uri uri,
  Map<String, dynamic>? body, {
  String? bearer,
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, uri);
    req.headers.contentType = ContentType.json;
    if (bearer != null) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    if (body != null) req.write(jsonEncode(body));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}: $text', uri: uri);
    }
    return text.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Future<void> main() async {
  const projectId = 'servicoconecta';
  const apiKey = 'fake-api-key';
  final ts = DateTime.now().millisecondsSinceEpoch;
  final email = 'auth_smoke_$ts@test.com';
  const password = 'Senha123';
  try {
    final signUp = await httpJson(
      'POST',
      Uri.parse(
        'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      ),
      {'email': email, 'password': password, 'returnSecureToken': true},
    );
    final uid = signUp['localId'] as String;
    var idToken = signUp['idToken'] as String;
    final docUri = Uri.parse(
      'http://127.0.0.1:8080/v1/projects/$projectId/databases/(default)/documents/users/$uid',
    );
    await httpJson(
      'PATCH',
      docUri,
      {
        'fields': {
          'email': {'stringValue': email},
          'smoke': {'booleanValue': true},
          'uid': {'stringValue': uid},
        },
      },
      bearer: idToken,
    );
    final signIn = await httpJson(
      'POST',
      Uri.parse(
        'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      ),
      {'email': email, 'password': password, 'returnSecureToken': true},
    );
    if (signIn['localId'] != uid) throw StateError('uid mismatch after sign-in');
    idToken = signIn['idToken'] as String;
    final snap = await httpJson('GET', docUri, null, bearer: idToken);
    final emailVal =
        ((snap['fields'] as Map)['email'] as Map)['stringValue'] as String;
    if (emailVal != email) throw StateError('firestore email mismatch');
    stdout.writeln('PASS: created $email, wrote users/$uid, signed in, read OK');
  } catch (e, st) {
    stderr.writeln('FAIL: $e\n$st');
    exitCode = 1;
  }
}