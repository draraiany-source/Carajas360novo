/// Medidas da home e da grade de ícones oficiais.
///
/// Desktop: 5 colunas quando o tile fica com pelo menos 140 px.
/// Abaixo disso, 3 colunas se a largura permitir e 2 no celular estreito.
abstract final class HomeLayout {
  static const tileGap = 12.0;
  static const minDesktopTile = 140.0;
  static const heroStackBreakpoint = 720.0;

  static bool stackedHeroButtons(double width) => width < heroStackBreakpoint;

  static bool showHeroPortrait(double width) => width >= heroStackBreakpoint;

  static int columnsFor(double width) {
    if (width <= 0) return 2;
    if (_tile(width, 5) >= minDesktopTile) return 5;
    if (width >= 520) return 3;
    return 2;
  }

  static double tileExtent(double width) {
    final columns = columnsFor(width);
    return _tile(width, columns);
  }

  /// Largura de um tile na área útil informada.
  static double estimatedTileWidth(double contentWidth) =>
      tileExtent(contentWidth);

  static double _tile(double width, int columns) {
    final spacing = tileGap * (columns - 1);
    return (width - spacing) / columns;
  }
}
