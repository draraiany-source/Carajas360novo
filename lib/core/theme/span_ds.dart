import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Design System SpanEnglish adaptado para telas premium do ServiçoConecta.
/// Paleta oficial: Petroleum #13647C · Vibrant #307ABA · Accent #C14344 · Soft #F0F5F4
abstract final class SpanDs {
  // ── Cores oficiais (versão dark premium do SpanEnglish) ───────────────────
  static const primary = Color(0xFF2E9BBE);
  static const primaryDark = Color(0xFF13647C);
  static const secondary = Color(0xFF4D96CC);
  static const secondaryDark = Color(0xFF307ABA);
  static const accent = Color(0xFFE05758);
  static const accentDark = Color(0xFFC14344);
  static const background = Color(0xFF07171C);
  static const surface = Color(0xFF0F272E);
  static const surfaceVariant = Color(0xFF15333C);
  static const border = Color(0xFF1E4551);
  static const textPrimary = Color(0xFFEAF4F7);
  static const textSecondary = Color(0xFF9CBCC6);
  static const textTertiary = Color(0xFF6A8C97);
  static const success = Color(0xFF2ECC71);
  static const gold = Color(0xFFFFC24D);
  static const white = Color(0xFFFFFFFF);

  static const softWhite = Color(0xFFF0F5F4);

  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13647C), Color(0xFF307ABA)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D4A5C), Color(0xFF07171C)],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF307ABA), Color(0xFF2E9BBE)],
  );

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 32;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
            color: primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10)),
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6)),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8)),
      ];

  static TextStyle poppins({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      sans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
        height: height,
        letterSpacing: letterSpacing,
      );

  static BoxDecoration glass({double radius = radiusXl}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: white.withValues(alpha: 0.08),
        border: Border.all(color: white.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 30,
              offset: const Offset(0, 14)),
        ],
      );
}

/// Painel glassmorphism leve (blur σ12 — padrão SpanEnglish ranking).
class SpanGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const SpanGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = SpanDs.radiusXl,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: SpanDs.glass(radius: radius),
          child: child,
        ),
      ),
    );
  }
}
