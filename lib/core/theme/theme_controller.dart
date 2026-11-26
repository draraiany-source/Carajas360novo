import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o modo de tema (claro/escuro/sistema) e o persiste
/// localmente. Exposto como um ValueNotifier para o MaterialApp
/// reagir a mudanças sem depender de pacotes de state management.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  /// Carrega a preferência salva. Deve ser chamado no início do app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      mode.value = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode m) async {
    mode.value = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, m.name);
    } catch (_) {/* silencioso: persistência é best-effort */}
  }

  /// Respeita ThemeMode.system via brightness da plataforma.
  bool get isDark {
    switch (mode.value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }
}
