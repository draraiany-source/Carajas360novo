import 'package:flutter/foundation.dart';

/// Configuração de runtime via --dart-define (sem secrets no repositório).
///
/// Exemplos:
///   flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
///   flutter run --dart-define=MERCADOPAGO_PUBLIC_KEY=APP_USR-...
///
/// Android Maps nativo: defina MAPS_API_KEY em android/local.properties
/// (ver comentário em android/app/build.gradle).
abstract final class RuntimeConfig {
  /// local | homolog | prod. Não troca chaves sozinho: cada ambiente
  /// precisa do próprio `flutterfire configure`.
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'local');

  /// Homologação web sem Firebase. Ignorado em release.
  static const devBypassLogin =
      bool.fromEnvironment('DEV_BYPASS_LOGIN', defaultValue: false);

  static bool firebaseReady = false;

  static bool get showLabeledDemo =>
      devBypassLogin && !kReleaseMode && !firebaseReady;

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'COLE_SUA_GOOGLE_MAPS_API_KEY_AQUI',
  );

  static const mercadoPagoPublicKey = String.fromEnvironment(
    'MERCADOPAGO_PUBLIC_KEY',
    defaultValue: 'COLE_SUA_MERCADOPAGO_PUBLIC_KEY_AQUI',
  );

  static bool get hasPlaceholderMaps =>
      googleMapsApiKey.contains('COLE_SUA');

  static bool get hasPlaceholderMercadoPago =>
      mercadoPagoPublicKey.contains('COLE_SUA');
}
