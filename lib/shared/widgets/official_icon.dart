import 'package:flutter/material.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/home_layout.dart';

/// Tile do ícone oficial. A arte já traz o nome: não há texto por cima.
/// Sem arquivo, o tile é verde-esmeralda com borda dourada e o nome em texto.
class OfficialIcon extends StatelessWidget {
  final String label;
  final String? assetPath;
  final bool pendingArt;
  final bool selected;
  final VoidCallback? onTap;
  final double? size;

  const OfficialIcon({
    super.key,
    required this.label,
    this.assetPath,
    this.pendingArt = false,
    this.selected = false,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final child = assetPath == null
        ? _NeutralTile(label: label, selected: selected)
        : _ArtTile(path: assetPath!, selected: selected, label: label);
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      selected: selected,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: size == null
              ? child
              : SizedBox(width: size, height: size, child: child),
        ),
      ),
    );
  }
}

class _ArtTile extends StatelessWidget {
  final String path;
  final bool selected;
  final String label;
  const _ArtTile({
    required this.path,
    required this.selected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final logical = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : 160.0;
      final cache = (logical * MediaQuery.devicePixelRatioOf(context))
          .round()
          .clamp(64, 512);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(logical * 0.18),
          border: selected
              ? Border.all(color: AppColors.gold, width: 3)
              : null,
        ),
        child: Image(
          image: ResizeImage(AssetImage(path), width: cache),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _NeutralTile(label: label, selected: selected),
        ),
      );
    });
  }
}

class _NeutralTile extends StatelessWidget {
  final String label;
  final bool selected;
  const _NeutralTile({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF146B34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.gold,
          width: selected ? 4 : 3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class OfficialIconData {
  final String id;
  final String label;
  final String? asset256;
  final String? asset512;
  final bool pendingArt;
  const OfficialIconData({
    required this.id,
    required this.label,
    required this.asset256,
    required this.asset512,
    required this.pendingArt,
  });

  factory OfficialIconData.category(CatalogCategory category) {
    return OfficialIconData(
      id: category.id,
      label: category.name,
      asset256: category.asset256,
      asset512: category.asset512,
      pendingArt: category.pendingArt || category.asset == null,
    );
  }

  factory OfficialIconData.profession(CatalogProfession profession) {
    return OfficialIconData(
      id: profession.id,
      label: profession.name,
      asset256: profession.asset256,
      asset512: profession.asset512,
      pendingArt: profession.asset == null,
    );
  }
}

/// Grade dos pôsteres. Em grade usa o WebP de 256 px.
class OfficialIconGrid extends StatelessWidget {
  final List<OfficialIconData> items;
  final ValueChanged<OfficialIconData> onTap;
  final String keyPrefix;
  final Set<String> selected;
  final int? maxVisibleRows;

  const OfficialIconGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.keyPrefix = 'icone-',
    this.selected = const {},
    this.maxVisibleRows,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
      final columns = HomeLayout.columnsFor(width);
      final tile = HomeLayout.tileExtent(width);
      final rows = (items.length / columns).ceil().clamp(1, 99);
      final full = rows * tile + HomeLayout.tileGap * (rows - 1);
      final cap = maxVisibleRows == null
          ? full
          : (maxVisibleRows! * tile +
              HomeLayout.tileGap * (maxVisibleRows! - 1));
      final grid = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: HomeLayout.tileGap,
          crossAxisSpacing: HomeLayout.tileGap,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          return OfficialIcon(
            key: Key('$keyPrefix${item.id}'),
            label: item.label,
            assetPath: item.asset256,
            pendingArt: item.pendingArt,
            selected: selected.contains(item.id),
            onTap: () => onTap(item),
          );
        },
      );
      if (cap + 0.5 >= full) return grid;
      return SizedBox(
        height: cap,
        child: SingleChildScrollView(child: grid),
      );
    });
  }
}

/// Pré-carrega só os ícones da home (versão de grade).
void precacheHomeIcons(BuildContext context) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final cache = (200 * dpr).round().clamp(128, 512);
  for (final category in ServiceCatalog.homeCategories) {
    final path = category.asset256;
    if (path == null) continue;
    precacheImage(ResizeImage(AssetImage(path), width: cache), context);
  }
}
