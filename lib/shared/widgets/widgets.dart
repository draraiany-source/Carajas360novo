import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../services/firebase_service.dart';
import 'micro_interactions.dart';

class GradHeader extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  final double br;
  const GradHeader(
      {super.key, required this.gradient, required this.child, this.br = 32});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(br),
              bottomRight: Radius.circular(br)),
          boxShadow: [
            BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 16, 20, 26),
        child: child,
      );
}

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  const AppSearchBar(
      {super.key,
      required this.hint,
      this.onChanged,
      this.onTap,
      this.readOnly = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: TextField(
              onChanged: onChanged,
              readOnly: readOnly,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ]),
        ),
      );
}

class AppAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final Color? bg;
  final double r;
  const AppAvatar(
      {super.key,
      this.url,
      required this.name,
      this.size = 44,
      this.bg,
      this.r = 12});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: bg ?? AppColors.primary,
            borderRadius: BorderRadius.circular(r)),
        clipBehavior: Clip.antiAlias,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _letter,
                errorWidget: (_, __, ___) => _letter)
            : _letter,
      );
  Widget get _letter => Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.4)));
}

class AppTag extends StatelessWidget {
  final String text;
  final Color bg, fg;
  final double fs;
  const AppTag(this.text,
      {super.key, required this.bg, this.fg = Colors.white, this.fs = 10});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: fs, fontWeight: FontWeight.w700)),
      );
}

class TogglePills extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final Color? activeColor;
  const TogglePills(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelect,
      this.activeColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(14)),
        child: Row(
            children: List.generate(
                options.length,
                (i) => Expanded(
                      child: GestureDetector(
                          onTap: () => onSelect(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: selected == i
                                    ? AppColors.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: selected == i
                                    ? [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 8)
                                      ]
                                    : []),
                            alignment: Alignment.center,
                            child: Text(options[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected == i
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: selected == i
                                        ? (activeColor ?? AppColors.primary)
                                        : AppColors.textLight)),
                          )),
                    ))),
      );
}

class SecHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SecHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (action != null)
            GestureDetector(
                onTap: onAction,
                child: Text(action!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary))),
        ]),
      );
}

class XpCard extends StatelessWidget {
  final int xp;
  const XpCard({super.key, required this.xp});
  @override
  Widget build(BuildContext context) {
    final level = xpLevel(xp);
    final toNext = nextLevelXp(xp);
    final prog = xpProgress(xp);
    return Container(
      decoration: AppDecorations.gradient(AppGradients.purple, r: 20),
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Seu progresso',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 12)),
          const SizedBox(height: 4),
          Text('$level · $xp XP',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: prog.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.warning),
                  minHeight: 8)),
          const SizedBox(height: 6),
          Text(
              toNext > 0
                  ? '$toNext XP para o próximo nível'
                  : '🎉 Nível máximo!',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ])),
        const SizedBox(width: 14),
        const Text('🏆', style: TextStyle(fontSize: 44)),
      ]),
    );
  }
}

class ProvCard extends StatelessWidget {
  final String name, role, badge, price;
  final double rating;
  final int reviews;
  final bool? isOnline;
  final Color avatarBg;
  final String? photo;
  final String? providerId;
  final VoidCallback? onTap, onChat;
  final Widget? emblem;
  const ProvCard(
      {super.key,
      required this.name,
      required this.role,
      required this.badge,
      required this.price,
      required this.rating,
      this.reviews = 0,
      this.isOnline,
      this.avatarBg = AppColors.primary,
      this.photo,
      this.providerId,
      this.onTap,
      this.onChat,
      this.emblem});
  @override
  Widget build(BuildContext context) => TapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppDecorations.card(),
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _avatar(),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text('$name ✅',
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis)),
                        if (providerId != null)
                          _FavToggle(providerId: providerId!),
                        Text(price,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.secondary)),
                      ]),
                  const SizedBox(height: 2),
                  if (emblem != null) emblem!
                  else
                    Text(role, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(spacing: 5, runSpacing: 4, children: [
                    AppTag('★ ${rating.toStringAsFixed(1)}',
                        bg: const Color(0xFFFFF8E1), fg: AppColors.warning),
                    AppTag(badge,
                        bg: const Color(0xFFE8F5E9), fg: AppColors.secondary),
                    if (isOnline == true)
                      AppTag('📹 Online',
                          bg: const Color(0xFFE3F0FF), fg: AppColors.primary),
                    if (isOnline == false)
                      AppTag('🏠 Presencial',
                          bg: const Color(0xFFFFF3E0), fg: AppColors.delivery),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline == true
                                    ? AppColors.success
                                    : AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text(
                                isOnline == true ? '📹 Online' : '📍 Contratar',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)))),
                    const SizedBox(width: 8),
                    GestureDetector(
                        onTap: onChat,
                        child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('💬',
                                style: TextStyle(fontSize: 16)))),
                  ]),
                ])),
          ]),
        ),
      );
  Widget _avatar() => Stack(children: [
        AppAvatar(url: photo, name: name, size: 52, bg: avatarBg, r: 14),
        if (isOnline == true)
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2)),
                  child: const Icon(Icons.videocam,
                      size: 8, color: Colors.white))),
      ]);
}

class _FavToggle extends StatelessWidget {
  final String providerId;
  const _FavToggle({required this.providerId});
  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
        stream: FS.isFavoriteStream(providerId),
        builder: (_, snap) {
          final isFav = snap.data ?? false;
          return GestureDetector(
            onTap: () async {
              final nowFav = await FS.toggleFavorite(providerId);
              if (context.mounted)
                snack(
                    context,
                    nowFav
                        ? '⭐ Adicionado aos favoritos'
                        : 'Removido dos favoritos',
                    bg: nowFav ? AppColors.warning : AppColors.textLight);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 2),
              child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? AppColors.warning : AppColors.textHint,
                  size: 20),
            ),
          );
        },
      );
}

class ShimCard extends StatelessWidget {
  const ShimCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _box(52, 52, r: 14),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _box(double.infinity, 14),
                const SizedBox(height: 8),
                _box(160, 11),
                const SizedBox(height: 8),
                _box(100, 11)
              ])),
        ]),
      );
  Widget _box(double w, double h, {double r = 8}) => Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.border,
      child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(r))));
}

class EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final String? asset;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.emoji,
      required this.title,
      required this.subtitle,
      this.asset,
      this.actionLabel,
      this.onAction});
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            asset != null
                ? SvgPicture.asset(asset!, width: 140, height: 140)
                : Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ])));
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
      child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2))));
}

class CatChip extends StatelessWidget {
  final String emoji, name;
  final String? categoryId;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const CatChip(
      {super.key,
      required this.emoji,
      required this.name,
      this.categoryId,
      required this.color,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final Widget icon = Text(emoji, style: const TextStyle(fontSize: 15));
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: selected ? color : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? color : AppColors.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            const SizedBox(width: 6),
            Text(name,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textDark))
          ]),
        ));
  }
}

class InfoBanner extends StatelessWidget {
  final String icon, text;
  final Color bg, fg;
  const InfoBanner(
      {super.key,
      required this.icon,
      required this.text,
      required this.bg,
      required this.fg});
  @override
  Widget build(BuildContext context) => Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11, color: fg, fontWeight: FontWeight.w600))),
      ]));
}

class StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const StatCard(
      {super.key,
      required this.value,
      required this.label,
      this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: AppDecorations.card(r: 14),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textLight),
                textAlign: TextAlign.center),
          ])));
}

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;
  const LoadingOverlay({super.key, required this.loading, required this.child});
  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        if (loading)
          Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()))
      ]);
}

void snack(BuildContext ctx, String msg, {Color bg = AppColors.primary}) =>
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));

String fmtDate(DateTime dt) {
  final n = DateTime.now();
  if (dt.day == n.day && dt.month == n.month && dt.year == n.year)
    return 'Hoje';
  if (dt.day == n.day - 1 && dt.month == n.month) return 'Ontem';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
