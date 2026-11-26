import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════
// MICROINTERAÇÕES — widgets reutilizáveis que dão a sensação
// "premium" ao app: resposta tátil ao toque, entradas suaves,
// skeleton loading e animações de estado. Todos puros em Flutter
// (sem dependências novas) e leves.
// ═══════════════════════════════════════════════════════════════

/// Envolve qualquer widget e o faz encolher suavemente ao ser
/// pressionado, dando feedback tátil de toque (como apps nativos).
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  const TapScale(
      {super.key,
      required this.child,
      this.onTap,
      this.scale = 0.95,
      this.duration = const Duration(milliseconds: 120)});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:
            widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                widget.onTap!();
              },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1.0,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Coração de favorito com animação de "pop" (escala + cor) ao
/// alternar. Mantém o estado visual controlado pelo pai.
class AnimatedFavorite extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  const AnimatedFavorite(
      {super.key,
      required this.isFavorite,
      required this.onToggle,
      this.size = 24});

  @override
  State<AnimatedFavorite> createState() => _AnimatedFavoriteState();
}

class _AnimatedFavoriteState extends State<AnimatedFavorite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handle() {
    _c.forward(from: 0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _handle,
        child: ScaleTransition(
          scale: _scale,
          child: Icon(
            widget.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.isFavorite ? AppColors.error : AppColors.textLight,
            size: widget.size,
          ),
        ),
      );
}

/// Faz um widget entrar com fade + leve deslize para cima. Ideal para
/// itens de lista, aplicando um pequeno atraso incremental por índice.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  const FadeSlideIn(
      {super.key,
      required this.child,
      this.index = 0,
      this.duration = const Duration(milliseconds: 400)});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 12)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
          child: widget.child,
        ),
      );
}

/// Bloco de skeleton loading com brilho animado (shimmer) — para
/// exibir enquanto dados reais carregam, no lugar de telas vazias.
class Skeleton extends StatefulWidget {
  final double width, height, radius;
  const Skeleton(
      {super.key,
      this.width = double.infinity,
      this.height = 16,
      this.radius = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * _c.value, 0),
              end: Alignment(1 - 2 * _c.value, 0),
              colors: const [
                Color(0xFFEDEDED),
                Color(0xFFF7F7F7),
                Color(0xFFEDEDED)
              ],
            ),
          ),
        ),
      );
}

/// Card de skeleton pronto para listas (avatar + 2 linhas).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: const [
          Skeleton(width: 52, height: 52, radius: 14),
          SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Skeleton(width: 140, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 12),
                SizedBox(height: 8),
                Skeleton(width: 180, height: 10),
              ])),
        ]),
      );
}

/// Transição de rota com fade + slide suave, para dar continuidade
/// premium na navegação entre telas.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeSlidePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.03), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        );
}
