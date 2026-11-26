import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/auth/access_control.dart';
import '../../core/catalog/service_catalog.dart';
import '../../core/constants/app_constants.dart';
import '../../core/modules/platform_modules.dart';
import '../../core/theme/app_colors.dart';
import 'official_icon.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import 'c360_nav.dart';

/// Atalho da home. Os dados vêm do catálogo oficial.
class C360Category {
  final String label;
  final IconData icon;
  final String? categoryId;
  final String? route;
  final String? iconAsset;
  final String catalogId;
  final bool pendingArt;
  const C360Category(
    this.label,
    this.icon, {
    this.categoryId,
    this.route,
    this.iconAsset,
    this.catalogId = '',
    this.pendingArt = false,
  });
}

abstract class C360Categories {
  static List<C360Category> get home => [
        for (final category in ServiceCatalog.homeCategories)
          C360Category(
            category.name,
            Icons.apps_rounded,
            categoryId: category.navigation ? null : category.id,
            iconAsset: category.asset256,
            catalogId: category.id,
            pendingArt: category.pendingArt || category.asset == null,
          ),
      ];
}

enum C360Tone { neutral, progress, success, warning, danger }

class C360StatusChip extends StatelessWidget {
  final String label;
  final C360Tone tone;
  final IconData? icon;
  const C360StatusChip(this.label,
      {super.key, this.tone = C360Tone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      C360Tone.progress => (AppColors.chipYellowBg, AppColors.chipYellowFg),
      C360Tone.success => (AppColors.chipGreenBg, AppColors.chipGreenFg),
      C360Tone.warning => (AppColors.chipYellowBg, AppColors.chipYellowFg),
      C360Tone.danger => (AppColors.chipRedBg, AppColors.chipRedFg),
      C360Tone.neutral => (AppColors.surfaceMuted, AppColors.textMedium),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

C360Tone toneForOrder(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
    case OrderStatus.accepted:
    case OrderStatus.inProgress:
      return C360Tone.progress;
    case OrderStatus.completed:
      return C360Tone.success;
    case OrderStatus.cancelled:
    case OrderStatus.disputed:
      return C360Tone.danger;
  }
}

String labelForOrder(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Aguardando';
    case OrderStatus.accepted:
      return 'Aceito';
    case OrderStatus.inProgress:
      return 'Em Andamento';
    case OrderStatus.completed:
      return 'Concluído';
    case OrderStatus.cancelled:
      return 'Cancelado';
    case OrderStatus.disputed:
      return 'Em disputa';
  }
}

IconData iconForOrder(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.schedule_rounded;
    case OrderStatus.accepted:
      return Icons.thumb_up_alt_outlined;
    case OrderStatus.inProgress:
      return Icons.timelapse_rounded;
    case OrderStatus.completed:
      return Icons.check_circle_outline_rounded;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
    case OrderStatus.disputed:
      return Icons.report_gmailerrorred_rounded;
  }
}

class C360Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const C360Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: AppDecorations.card(r: 18, color: color, context: context),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: box,
      ),
    );
  }
}

class C360SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  const C360SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
      ],
      Expanded(
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.2)),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(action!,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
    ]);
  }
}

class C360KpiCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String? hint;
  const C360KpiCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return C360Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: tint, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.4)),
            if (hint != null)
              Text(hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

class C360PageBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const C360PageBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: C360LandscapePainter())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.sidebar, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          height: 1.3)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class C360LandscapePainter extends CustomPainter {
  const C360LandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hill = Paint()..color = const Color(0xFF1F8A45).withValues(alpha: 0.55);
    final path = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.15,
          size.width * 0.78, size.height * 0.42)
      ..quadraticBezierTo(
          size.width * 0.9, size.height * 0.62, size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hill);
    final far = Paint()..color = const Color(0xFFF6C445).withValues(alpha: 0.18);
    final sun = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width * 0.86, size.height * 0.28), radius: 18));
    canvas.drawPath(sun, far);
    final ridge = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mountains = Path()
      ..moveTo(size.width * 0.58, size.height * 0.78)
      ..lineTo(size.width * 0.7, size.height * 0.28)
      ..lineTo(size.width * 0.84, size.height * 0.7);
    canvas.drawPath(mountains, ridge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class C360CategoryTile extends StatelessWidget {
  final C360Category category;
  final bool selected;
  final VoidCallback onTap;
  const C360CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return OfficialIcon(
      label: category.label,
      assetPath: category.iconAsset,
      pendingArt: category.pendingArt || category.iconAsset == null,
      selected: selected,
      onTap: onTap,
    );
  }
}

class C360FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const C360FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textMedium),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textDark)),
            ]),
          ),
        ),
      ),
    );
  }
}

class C360Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  final bool verified;
  const C360Avatar({
    super.key,
    required this.name,
    this.url,
    this.size = 56,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    Widget face;
    if (url != null && url!.isNotEmpty) {
      face = CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallback(letter),
        placeholder: (_, __) => _fallback(letter),
      );
    } else {
      face = _fallback(letter);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: SizedBox(width: size, height: size, child: face),
        ),
        if (verified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ]),
    );
  }

  Widget _fallback(String letter) => Container(
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: Text(letter,
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38)),
      );
}

class _FavHeart extends StatelessWidget {
  final String providerId;
  const _FavHeart({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FS.isFavoriteStream(providerId),
      builder: (_, snap) {
        final on = snap.data ?? false;
        return IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            if (!sessionActive()) {
              Navigator.pushNamed(context, Routes.login);
              return;
            }
            FS.toggleFavorite(providerId);
          },
          icon: Icon(
            on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: on ? AppColors.error : AppColors.textHint,
            size: 20,
          ),
        );
      },
    );
  }
}

class C360Rating extends StatelessWidget {
  final double rating;
  final int reviews;
  final String? trailing;
  const C360Rating({
    super.key,
    required this.rating,
    required this.reviews,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = reviews > 0
        ? '${rating.toStringAsFixed(1)} ($reviews)'
        : (rating > 0 ? rating.toStringAsFixed(1) : 'Sem avaliações');
    return Row(children: [
      const Icon(Icons.star_rounded, color: AppColors.yellowDeep, size: 16),
      const SizedBox(width: 2),
      Flexible(
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMedium)),
      ),
      if (trailing != null) ...[
        const SizedBox(width: 6),
        Flexible(
          child: Text(trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ),
      ],
    ]);
  }
}

class C360HighlightCard extends StatelessWidget {
  final String name;
  final String role;
  final double rating;
  final int reviews;
  final String? photoUrl;
  final bool verified;
  final String? place;
  final String? providerId;
  final VoidCallback? onProfile;
  final String? demoLabel;
  final Widget? emblem;
  const C360HighlightCard({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    this.photoUrl,
    this.verified = false,
    this.place,
    this.providerId,
    this.onProfile,
    this.demoLabel,
    this.emblem,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: C360Card(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            C360Avatar(
                name: name, url: photoUrl, size: 54, verified: verified),
            const Spacer(),
            if (providerId != null) _FavHeart(providerId: providerId!),
          ]),
          const SizedBox(height: 10),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14)),
          if (emblem != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: emblem!,
            )
          else
            Text(role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 6),
          if (demoLabel != null)
            Text(demoLabel!,
                maxLines: 2,
                style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A5B00)))
          else
            C360Rating(
                rating: rating,
                reviews: reviews,
                trailing: place == null ? null : '· $place'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Ver perfil'),
            ),
          ),
        ]),
      ),
    );
  }
}

class C360ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final int reviews;
  final String? photoUrl;
  final bool verified;
  final String? place;
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  const C360ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.reviews,
    this.photoUrl,
    this.verified = false,
    this.place,
    this.onProfile,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return C360Card(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _photoFallback(),
                  )
                : _photoFallback(),
          ),
        ),
        const SizedBox(height: 10),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 2),
        Text(subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textLight, height: 1.3)),
        const SizedBox(height: 8),
        C360Rating(rating: rating, reviews: reviews, trailing: place),
        if (verified) ...[
          const SizedBox(height: 6),
          const C360StatusChip('Verificado',
              tone: C360Tone.success, icon: Icons.verified_rounded),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onProfile,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text('Ver perfil', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10)),
            child: const Text('Solicitar serviço →',
                style: TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _photoFallback() => Container(
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: const Icon(Icons.home_repair_service_rounded,
            color: AppColors.primary, size: 36),
      );
}

class C360PersonCard extends StatelessWidget {
  final String name;
  final String role;
  final String? bio;
  final double rating;
  final int reviews;
  final String? photoUrl;
  final bool verified;
  final String? place;
  final VoidCallback? onChat;
  final VoidCallback? onRequest;
  const C360PersonCard({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    this.bio,
    this.photoUrl,
    this.verified = false,
    this.place,
    this.onChat,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return C360Card(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 132,
            width: double.infinity,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          if (verified)
            const Icon(Icons.verified_rounded,
                color: AppColors.primary, size: 18),
        ]),
        const SizedBox(height: 4),
        C360Rating(rating: rating, reviews: reviews, trailing: place),
        const SizedBox(height: 6),
        Text(bio?.isNotEmpty == true ? bio! : role,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textLight, height: 1.3)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text('Solicitar Serviço',
                  style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.primary),
        ),
      );
}

class C360TrustStrip extends StatelessWidget {
  final int activeProviders;
  const C360TrustStrip({super.key, required this.activeProviders});

  @override
  Widget build(BuildContext context) {
    final countLabel = activeProviders > 0
        ? '+$activeProviders'
        : '—';
    final items = <(IconData, String, String)>[
      (Icons.verified_user_outlined, 'Profissionais', 'Verificados'),
      (Icons.credit_card_rounded, 'Pagamento', 'Seguro'),
      (Icons.place_outlined, 'Serviços', 'Perto de Você'),
      (Icons.headset_mic_outlined, 'Suporte', 'Especializado'),
      (Icons.bar_chart_rounded, countLabel, 'Profissionais ativos'),
    ];
    return C360Card(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 720;
        return Wrap(
          alignment: WrapAlignment.spaceAround,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: narrow ? c.maxWidth / 2 - 8 : null,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.$1, color: AppColors.primary, size: 26),
                  const SizedBox(width: 8),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(item.$3,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight)),
                      ]),
                ]),
              ),
          ],
        );
      }),
    );
  }
}

class C360Sparkline extends StatelessWidget {
  final List<double> values;
  final String caption;
  const C360Sparkline({super.key, required this.values, required this.caption});

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v > 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 120,
        width: double.infinity,
        child: hasData
            ? CustomPaint(
                painter: _LinePainter(values),
                child: const SizedBox.expand(),
              )
            : const Center(
                child: Text(
                  'O gráfico aparece quando houver faturamento no período.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ),
      ),
      const SizedBox(height: 6),
      Text(caption,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i / (values.length - 1) * size.width;
      final y = size.height -
          (maxV <= 0 ? 0 : (values[i] / maxV) * (size.height - 8)) -
          4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.28),
              AppColors.primary.withValues(alpha: 0.02),
            ],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class C360Stepper extends StatelessWidget {
  final List<String> steps;
  final int current;
  const C360Stepper({super.key, required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < steps.length; i++) ...[
        if (i > 0)
          Expanded(
            child: Container(
              height: 3,
              color: i <= current ? AppColors.primary : AppColors.border,
            ),
          ),
        Column(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: i <= current ? AppColors.primary : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: i <= current ? AppColors.primary : AppColors.border,
                  width: 2),
            ),
            child: i < current
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : i == current
                    ? const Icon(Icons.circle, size: 8, color: Colors.white)
                    : null,
          ),
        ]),
      ],
    ]);
  }
}

class C360StepLabels extends StatelessWidget {
  final List<String> steps;
  final int current;
  const C360StepLabels({super.key, required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Text(steps[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : i == steps.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight:
                        i == current ? FontWeight.w800 : FontWeight.w600,
                    color: i <= current
                        ? AppColors.primary
                        : AppColors.textLight)),
          ),
      ],
    );
  }
}

Future<void> showCityPicker(BuildContext context) {
  final cities = [...RegionCities.priority, ...RegionCities.nearby];
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.55,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4))),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Sua localização',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: RegionController.instance.city,
              builder: (_, selected, __) => ListView.builder(
                itemCount: cities.length,
                itemBuilder: (_, i) {
                  final city = cities[i];
                  final sel = city == selected;
                  return ListTile(
                    leading: Icon(
                      sel
                          ? Icons.location_on_rounded
                          : Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(city,
                        style: TextStyle(
                            fontWeight:
                                sel ? FontWeight.w800 : FontWeight.w500)),
                    trailing: sel
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () async {
                      await RegionController.instance.setCity(city);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

String c360Money(double? value) {
  if (value == null) return 'A combinar';
  return PaySvc.fmt(value);
}

String c360Place(ProviderModel provider, String selectedCity) {
  final city = provider.city?.trim();
  if (city == null || city.isEmpty) return 'Região dos Carajás';
  if (city == selectedCity) return city;
  return city;
}
