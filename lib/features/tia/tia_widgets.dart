import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'tia_models.dart';

String tiaAsset(String pose) {
  const ready = {
    'recepcionando',
    'apresentando',
    'escutando_voz',
    'suporte',
    'confirmando',
    'orientando',
  };
  const fallback = {
    'analisando_fotos': 'apresentando',
    'processando': 'recepcionando',
    'apresentando_orcamentos': 'apresentando',
    'comemorando': 'recepcionando',
    'corpo_inteiro': 'recepcionando',
  };
  final file = ready.contains(pose) ? pose : (fallback[pose] ?? 'recepcionando');
  return 'assets/tia_carajas/$file.webp';
}

class TiaPortrait extends StatefulWidget {
  final String pose;
  final double height;
  final bool circle;
  final bool animate;
  const TiaPortrait({
    super.key,
    this.pose = 'recepcionando',
    this.height = 120,
    this.circle = false,
    this.animate = false,
  });

  @override
  State<TiaPortrait> createState() => _TiaPortraitState();
}

class _TiaPortraitState extends State<TiaPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TiaPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.circle
        ? Image.asset('assets/tia_carajas/avatar.webp',
            height: widget.height,
            width: widget.height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _fallback())
        : Image.asset(tiaAsset(widget.pose),
            height: widget.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _fallback());
    final child = widget.circle
        ? ClipOval(child: image)
        : image;
    if (!widget.animate) return child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -3 * _ctrl.value),
        child: child,
      ),
      child: child,
    );
  }

  Widget _fallback() => CircleAvatar(
        radius: widget.height / 2,
        backgroundColor: AppColors.primary,
        child: Text('TC',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: widget.height * 0.28)),
      );
}

class TiaVoiceWaves extends StatelessWidget {
  final bool active;
  const TiaVoiceWaves({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 28,
      child: CustomPaint(
        painter: _WavePainter(active: active, color: AppColors.primary),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final bool active;
  final Color color;
  _WavePainter({required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? color : color.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    const bars = [0.35, 0.7, 1.0, 0.55, 0.85, 0.4];
    final gap = size.width / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final h = size.height * (active ? bars[i] : 0.25);
      final x = gap * i + gap / 2;
      canvas.drawLine(
          Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.active != active;
}

class TiaBubble extends StatelessWidget {
  final String text;
  final bool mine;
  final bool alert;
  const TiaBubble({super.key, required this.text, this.mine = false, this.alert = false});

  @override
  Widget build(BuildContext context) {
    final bg = mine
        ? AppColors.primary
        : alert
            ? const Color(0xFFFFF4E5)
            : Colors.white;
    final fg = mine ? Colors.white : AppColors.textDark;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alert ? AppColors.warning : AppColors.divider),
        ),
        child: Text(text, style: TextStyle(color: fg, height: 1.35, fontSize: 14)),
      ),
    );
  }
}

class TiaProviderStrip extends StatelessWidget {
  final List<TiaProviderRef> providers;
  final void Function(TiaProviderRef provider) onOpen;
  const TiaProviderStrip({super.key, required this.providers, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: providers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = providers[i];
          return SizedBox(
            width: 210,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpen(p),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        p.rating == 0
                            ? 'Sem avaliações ainda'
                            : '${p.rating.toStringAsFixed(1)} · ${p.totalReviews} avaliações',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                      Text(p.city.isEmpty ? 'Cidade não informada' : p.city,
                          style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(
                        p.minPrice == null ? 'Preço não cadastrado' : 'A partir de R\$ ${p.minPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12),
                      ),
                      Text(p.registrationLabel,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TiaActionCard extends StatelessWidget {
  final TiaProposedAction action;
  final VoidCallback onConfirm;
  const TiaActionCard({super.key, required this.action, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.touch_app_rounded, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(action.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        FilledButton(onPressed: onConfirm, child: const Text('Confirmar')),
      ]),
    );
  }
}

class TiaCapability {
  final IconData icon;
  final String label;
  final String prompt;
  const TiaCapability(this.icon, this.label, this.prompt);
}

const tiaCapabilities = <TiaCapability>[
  TiaCapability(Icons.search_rounded, 'Buscar profissionais', 'Busque profissionais cadastrados para o que eu preciso.'),
  TiaCapability(Icons.request_quote_rounded, 'Solicitar orçamento', 'Quero solicitar um orçamento. Pergunte o que faltar antes de eu confirmar.'),
  TiaCapability(Icons.event_available_rounded, 'Agendar atendimento', 'Quero agendar um atendimento. Não confirme sem o meu toque.'),
  TiaCapability(Icons.photo_camera_rounded, 'Enviar fotos', 'Vou enviar fotos do local para você organizar a descrição.'),
  TiaCapability(Icons.home_work_outlined, 'Analisar ambiente', 'Me ajude a descrever o ambiente a partir das fotos, sem diagnóstico.'),
  TiaCapability(Icons.compare_arrows_rounded, 'Comparar preços', 'Compare só propostas que já existam no meu pedido.'),
  TiaCapability(Icons.near_me_rounded, 'Encontrar perto', 'Procure profissionais na minha cidade cadastrada.'),
  TiaCapability(Icons.help_outline_rounded, 'Tirar dúvidas', 'Tenho uma dúvida sobre como a plataforma funciona.'),
  TiaCapability(Icons.assignment_outlined, 'Acompanhar pedido', 'Mostre a situação dos meus pedidos e pagamentos.'),
];
