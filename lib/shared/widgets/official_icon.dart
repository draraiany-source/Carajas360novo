import 'package:flutter/material.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/home_layout.dart';

/// Ícone oficial compacto. A arte já tem a borda dourada: o card não
/// desenha outra. Sem arquivo, o fallback é um cartão discreto com o nome.
class OfficialIcon extends StatefulWidget {
  final String label;
  final String? assetPath;
  final bool pendingArt;
  final bool selected;
  final VoidCallback? onTap;
  final double? size;
  final IconTier tier;
  final bool caption;

  const OfficialIcon({
    super.key,
    required this.label,
    this.assetPath,
    this.pendingArt = false,
    this.selected = false,
    this.onTap,
    this.size,
    this.tier = IconTier.category,
    this.caption = false,
  });

  @override
  State<OfficialIcon> createState() => _OfficialIconState();
}

class _OfficialIconState extends State<OfficialIcon> {
  bool _pressed = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final icon = widget.size ?? HomeLayout.iconSize(widget.tier, width);
    final showCaption = widget.caption || widget.assetPath == null;
    final art = widget.assetPath == null
        ? const _NeutralTile()
        : _ArtTile(path: widget.assetPath!, logical: icon);
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.label,
      selected: widget.selected,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: icon + 4,
                  height: icon + 4,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.selected
                          ? AppColors.primary
                          : const Color(0xFFE6EEE8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: _hover ? 0.10 : 0.05),
                        blurRadius: _hover ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(width: icon, height: icon, child: art),
                  ),
                ),
                if (showCaption) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: icon + 4,
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtTile extends StatelessWidget {
  final String path;
  final double logical;
  const _ArtTile({required this.path, required this.logical});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cache = (logical * dpr).round().clamp(1, 512);
    return SizedBox(
      width: logical,
      height: logical,
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFFF4F7F5)),
        Image(
          image: ResizeImage(AssetImage(path), width: cache),
          width: logical,
          height: logical,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _NeutralTile extends StatelessWidget {
  const _NeutralTile();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFF4F7F5));
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

/// Grade dos pôsteres. Listas de até 48 px usam o WebP de 256; o resto, o de 512.
class OfficialIconGrid extends StatelessWidget {
  final List<OfficialIconData> items;
  final ValueChanged<OfficialIconData> onTap;
  final String keyPrefix;
  final Set<String> selected;
  final int? maxVisibleRows;
  final IconTier tier;

  const OfficialIconGrid({
    super.key,
    required this.items,
    required this.onTap,
    this.keyPrefix = 'icone-',
    this.selected = const {},
    this.maxVisibleRows,
    this.tier = IconTier.category,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
      final screen = MediaQuery.sizeOf(context).width;
      // No celular a margem da página não pode derrubar 360 px para 2 colunas.
      final basis = screen < 600 ? screen : width;
      final icon = HomeLayout.iconSize(tier, screen);
      final card = icon + 4;
      var columns = HomeLayout.columnsFor(basis);
      while (columns > 1 &&
          (width - HomeLayout.tileGap * (columns - 1)) / columns < card - 1) {
        columns--;
      }
      final needsCaption = items.any((item) => item.asset256 == null && item.asset512 == null);
      final tile = card + (needsCaption ? 38 : 0);
      final gridWidth = columns * card + HomeLayout.tileGap * (columns - 1);
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
          mainAxisExtent: tile,
        ),
        itemBuilder: (_, i) {
          final item = items[i];
          final useListFile = tier == IconTier.list && icon <= 48;
          return Center(
            child: OfficialIcon(
              key: Key('$keyPrefix${item.id}'),
              label: item.label,
              assetPath: useListFile
                  ? (item.asset256 ?? item.asset512)
                  : (item.asset512 ?? item.asset256),
              pendingArt: item.pendingArt,
              selected: selected.contains(item.id),
              tier: tier,
              onTap: () => onTap(item),
            ),
          );
        },
      );
      final shown = cap + 0.5 >= full
          ? grid
          : SizedBox(height: cap, child: SingleChildScrollView(child: grid));
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: gridWidth.clamp(0, width), child: shown),
      );
    });
  }
}

/// Pré-carrega só os ícones da home (versão de grade).
void precacheHomeIcons(BuildContext context) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final logical = HomeLayout.iconSize(IconTier.category, MediaQuery.sizeOf(context).width);
  final cache = (logical * dpr).round().clamp(1, 512);
  for (final category in ServiceCatalog.homeCategories) {
    final path = category.asset512 ?? category.asset256;
    if (path == null) continue;
    precacheImage(ResizeImage(AssetImage(path), width: cache), context);
  }
}
