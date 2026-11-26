import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

/// Implementação nativa (iOS/macOS/Android) do Sign in with Apple.
Future<UserCredential?> signInWithAppleNative() async {
  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final result =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    if (appleCredential.givenName != null &&
        result.user?.displayName == null) {
      final name =
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
              .trim();
      await result.user?.updateDisplayName(name);
    }
    return result;
  } catch (e) {
    debugPrint('Erro no login com Apple: $e');
    return null;
  }
}
