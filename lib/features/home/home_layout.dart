/// Medidas compactas da home e dos ícones oficiais.
///
/// A arte já é um card com borda dourada. O ícone fica dentro de uma faixa
/// por breakpoint e nunca estica até o tamanho da célula.
abstract final class HomeLayout {
  static const tileGap = 8.0;
  static const heroStackBreakpoint = 720.0;

  static bool stackedHeroButtons(double width) => width < heroStackBreakpoint;

  /// O retrato entra em todas as larguras, menor no celular para caber no hero.
  static bool showHeroPortrait(double width) => width >= 340;

  static double heroHeight(double width) => width < heroStackBreakpoint ? 196 : 176;

  /// A arte da Tia em uso tem no máximo 250 px. A altura fica abaixo disso no 2x/3x.
  static double tiaHeroHeight(double width) => width < heroStackBreakpoint ? 64 : 96;

  /// Desktop 5 ou 6, tablet 4, celular 3 e 2 abaixo de 340 px.
  static int columnsFor(double width) {
    if (width < 340) return 2;
    if (width < 600) return 3;
    if (width < 1024) return 4;
    if (width >= 1180) return 6;
    return 5;
  }

  static double iconSize(IconTier tier, double width) {
    final (min, max) = _range(tier, width);
    return max;
  }

  static (double, double) _range(IconTier tier, double width) {
    final desktop = width >= 1024;
    final tablet = width >= 600 && width < 1024;
    switch (tier) {
      case IconTier.category:
        if (desktop) return (88, 100);
        if (tablet) return (76, 88);
        return (64, 76);
      case IconTier.subcategory:
        if (desktop) return (64, 80);
        if (tablet) return (56, 72);
        return (48, 64);
      case IconTier.list:
        if (desktop) return (40, 48);
        if (tablet) return (40, 44);
        return (36, 44);
    }
  }

  static bool iconInRange(IconTier tier, double width, double size) {
    final (min, max) = _range(tier, width);
    return size >= min - 0.1 && size <= max + 0.1;
  }
}

enum IconTier { category, subcategory, list }
