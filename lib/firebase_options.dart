// ════════════════════════════════════════════════════════════════
// FIREBASE OPTIONS — ServiçoConecta
//
// Gere este arquivo automaticamente com:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=SEU_PROJETO
//
// Depois substitua este arquivo pelo gerado.
// ════════════════════════════════════════════════════════════════
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma não suportada');
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'COLE_SUA_ANDROID_API_KEY',
    appId: '1:NUMERO:android:HASH',
    messagingSenderId: 'NUMERO',
    projectId: 'servicoconecta',
    storageBucket: 'servicoconecta.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'COLE_SUA_IOS_API_KEY',
    appId: '1:NUMERO:ios:HASH',
    messagingSenderId: 'NUMERO',
    projectId: 'servicoconecta',
    storageBucket: 'servicoconecta.appspot.com',
    iosBundleId: 'br.com.servicoconecta',
  );

  static const web = FirebaseOptions(
    apiKey: 'COLE_SUA_WEB_API_KEY',
    appId: '1:NUMERO:web:HASH',
    messagingSenderId: 'NUMERO',
    projectId: 'servicoconecta',
    storageBucket: 'servicoconecta.appspot.com',
    authDomain: 'servicoconecta.firebaseapp.com',
    measurementId: 'G-XXXXXXXXXX',
  );
}
