import 'package:flutter/foundation.dart';

/// Detecção de plataforma segura para Web, Android e iOS.
/// Evita `dart:io` Platform, que lança UnsupportedError no Flutter Web.
abstract final class PlatformInfo {
  static bool get isWeb => kIsWeb;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isMobile => isIOS || isAndroid;

  static bool get isApple => isIOS || isMacOS;
}
