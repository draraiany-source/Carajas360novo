import 'package:flutter/material.dart';

/// Identidade visual Carajás 360 — verde floresta, amarelo destaque,
/// cartões brancos. Os nomes históricos (primary, navy, secondary)
/// permanecem para o restante do app acompanhar a nova paleta.
abstract class AppColors {
  static const primary = Color(0xFF146B34);
  static const primaryLight = Color(0xFF1E8A45);
  static const primaryMid = Color(0xFF24964E);
  static const primarySoft = Color(0xFFE7F6EC);
  static const secondary = Color(0xFF0E5C30);
  static const secondaryLight = Color(0xFF1B8A48);
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFE6A817);
  static const error = Color(0xFFD92D20);
  static const info = Color(0xFF0E8F6E);
  static const health = Color(0xFF0F6B5C);
  static const delivery = Color(0xFFD4550A);
  static const navy = Color(0xFF0C2416);
  static const purple = Color(0xFF5B21B6);
  static const teal = Color(0xFF0E8F6E);
  static const orange = Color(0xFFD4550A);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF3F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF4F0);
  static const border = Color(0xFFE1EAE4);
  static const divider = Color(0xFFE6EEE8);
  static const textDark = Color(0xFF14221A);
  static const textMedium = Color(0xFF3D5246);
  static const textLight = Color(0xFF6B7F73);
  static const textHint = Color(0xFF93A399);
  static const shimmerBase = Color(0xFFE2E8F0);
  static const pix = Color(0xFF32BCAD);
  static const gold = Color(0xFFF5C400);

  /// Amarelo de destaque (pílula ativa, CTAs).
  static const yellow = Color(0xFFF6C445);
  static const yellowDeep = Color(0xFFE0AC12);

  /// Sidebar e faixas institucionais.
  static const sidebar = Color(0xFF0C3D24);
  static const sidebarDeep = Color(0xFF082E1B);

  static const chipYellowBg = Color(0xFFFFF4D2);
  static const chipGreenBg = Color(0xFFE5F6EA);
  static const chipRedBg = Color(0xFFFDECEC);
  static const chipBlueBg = Color(0xFFE7F3F6);
  static const chipYellowFg = Color(0xFF8A6400);
  static const chipGreenFg = Color(0xFF146B34);
  static const chipRedFg = Color(0xFFC62828);

  static const darkBackground = Color(0xFF07140E);
  static const darkSurface = Color(0xFF10241A);
  static const darkBorder = Color(0xFF1E3A2C);
  static const darkDivider = Color(0xFF173024);
  static const darkTextHigh = Color(0xFFF1F5F9);
  static const darkTextMed = Color(0xFFCBD5E1);
  static const darkTextLow = Color(0xFF94A3B8);
}

abstract class AppGradients {
  static const splash = LinearGradient(
      colors: [Color(0xFF082E1B), Color(0xFF0C3D24), Color(0xFF1B7A3A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const primary = LinearGradient(
      colors: [Color(0xFF0C3D24), Color(0xFF146B34), Color(0xFF1E8A45)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const hero = LinearGradient(
      colors: [Color(0xFF08301C), Color(0xFF0F5A2C), Color(0xFF1B7A3A)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight);
  static const secondary = LinearGradient(
      colors: [AppColors.secondary, AppColors.secondaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const health = LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight, AppColors.teal],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const delivery = LinearGradient(
      colors: [AppColors.delivery, Color(0xFFFF7A2F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const purple = LinearGradient(
      colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const pix = LinearGradient(
      colors: [AppColors.pix, Color(0xFF00BFA5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const dark = LinearGradient(
      colors: [Color(0xFF07140E), Color(0xFF123222)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const gold = LinearGradient(
      colors: [Color(0xFFE6A700), Color(0xFFF6C445)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const authHero = LinearGradient(
      colors: [Color(0xFF062416), Color(0xFF0C3D24), Color(0xFF146B34)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter);
}
