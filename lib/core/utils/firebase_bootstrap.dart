import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Inicializa Firebase. Emuladores so em debug/profile com keys placeholder
/// ou dart-define — nunca em release de loja.
abstract final class FirebaseBootstrap {
  static const useEmulatorDefine =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

  static bool get hasPlaceholderKeys {
    final key = DefaultFirebaseOptions.currentPlatform.apiKey;
    return key.contains('COLE_SUA') || key.contains('demo-api-key');
  }

  static bool get shouldUseEmulator {
    if (kReleaseMode) return false;
    return useEmulatorDefine || hasPlaceholderKeys;
  }

  static String get _emulatorHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    if (kIsWeb) return 'localhost';
    return '127.0.0.1';
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    if (!shouldUseEmulator) {
      if (hasPlaceholderKeys && kReleaseMode) {
        throw StateError(
          'firebase_options.dart ainda contém placeholders (COLE_SUA_*). '
          'Configure com `flutterfire configure` antes de um build de release/Play.',
        );
      }
      if (hasPlaceholderKeys) {
        debugPrint(
            'AVISO: firebase_options ainda tem placeholders — use emulador ou flutterfire configure.');
      }
      return;
    }

    final host = _emulatorHost;
    try {
      await FirebaseFirestore.instance.clearPersistence();
    } catch (e) {
      debugPrint('Firestore clearPersistence: $e');
    }

    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator(host, 5001);

    try {
      await FirebaseFirestore.instance.disableNetwork();
      await FirebaseFirestore.instance.enableNetwork();
    } catch (e) {
      debugPrint('Firestore network toggle: $e');
    }

    debugPrint(
        'Firebase emuladores: Auth/Firestore/Storage em $host (9099/8080/9199)');
  }
}
