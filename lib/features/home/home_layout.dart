/// Medidas da home. Os tiles de categoria não podem crescer com a largura:
/// em 1280×800 a área útil (janela menos a sidebar de 248) fica perto de
/// 1032 px e, com 2 colunas, os cards passavam de 400 px de altura.
abstract final class HomeLayout {
  static const tileMaxCrossAxisExtent = 168.0;
  static const tileMainAxisExtent = 112.0;
  static const heroStackBreakpoint = 720.0;

  static bool stackedHeroButtons(double width) => width < heroStackBreakpoint;

  static bool showHeroPortrait(double width) => width >= heroStackBreakpoint;

  /// Largura máxima de um tile. Nunca ultrapassa [tileMaxCrossAxisExtent].
  static double estimatedTileWidth(double contentWidth) {
    if (contentWidth <= 0) return tileMaxCrossAxisExtent;
    final columns =
        (contentWidth / tileMaxCrossAxisExtent).floor().clamp(2, 8);
    final spacing = 10.0 * (columns - 1);
    final width = (contentWidth - spacing) / columns;
    return width > tileMaxCrossAxisExtent ? tileMaxCrossAxisExtent : width;
  }
}
