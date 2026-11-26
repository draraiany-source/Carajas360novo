import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faq = [
    {
      'q': 'Como contratar um profissional?',
      'a':
          'Busque a categoria, escolha o profissional, veja avaliações, contrate e pague com segurança.'
    },
    {
      'q': 'O pagamento é seguro?',
      'a':
          'Sim! O valor fica retido até a conclusão do serviço. PIX, cartão e carteira digital.'
    },
    {
      'q': 'Como cancelar um pedido?',
      'a':
          'Acesse o pedido em andamento e toque em "Cancelar". Dependendo do status, pode haver taxa.'
    },
    {
      'q': 'Como avaliar um profissional?',
      'a':
          'Após concluído o serviço, você receberá uma notificação para avaliar com estrelas e comentário.'
    },
    {
      'q': 'Como me tornar prestador?',
      'a':
          'Acesse "Cadastrar como prestador" no menu, envie documentos e aguarde aprovação em até 24h.'
    },
    {
      'q': 'Como usar cupom de desconto?',
      'a': 'Na tela de pagamento, toque em "Adicionar cupom" e insira o código.'
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Central de Ajuda')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
              decoration: AppDecorations.gradient(AppGradients.primary, r: 20),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('❓', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text('Como podemos ajudar?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _contactBtn(
                          '💬', 'Chat', () => _openTicket(context))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _contactBtn(
                          '📧',
                          'E-mail',
                          () => _launch(
                              'mailto:suporte@servicoconecta.com.br?subject=Ajuda%20ServiçoConecta'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _contactBtn(
                          '📞', 'Ligar', () => _launch('tel:+551140000000')))
                ]),
              ])),
          const SizedBox(height: 20),
          const SecHeader(title: 'Perguntas frequentes'),
          const SizedBox(height: 12),
          for (final item in _faq) _FaqTile(q: item['q']!, a: item['a']!),
          const SizedBox(height: 20),
          Container(
              decoration: AppDecorations.card(r: 18),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('🎟️ Abrir chamado',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Não encontrou o que procurava?',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed: () => _openTicket(context),
                        icon: const Icon(Icons.support_agent_rounded),
                        label: const Text('Falar com suporte',
                            style: TextStyle(fontWeight: FontWeight.w700)))),
              ])),
          const SizedBox(height: 40),
        ]),
      );

  Widget _contactBtn(String icon, String label, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11))
              ])));

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openTicket(BuildContext ctx) {
    final subj = TextEditingController();
    final msg = TextEditingController();
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                const SheetHandle(),
                const SizedBox(height: 16),
                const Text('Abrir chamado',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                    controller: subj,
                    decoration: const InputDecoration(hintText: 'Assunto')),
                const SizedBox(height: 10),
                TextFormField(
                    controller: msg,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        hintText: 'Descreva o problema...')),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          await FS.createSupportTicket(subj.text, msg.text);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            snack(ctx,
                                '✅ Chamado enviado! Em breve entraremos em contato.',
                                bg: AppColors.secondary);
                          }
                        },
                        child: const Text('Enviar chamado'))),
              ]),
            ));
  }
}

class _FaqTile extends StatelessWidget {
  final String q, a;
  const _FaqTile({required this.q, required this.a});
  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: Text(q,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark)),
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(a,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium, height: 1.5)))
        ],
      );
}

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsState();
}

class _CouponsState extends State<CouponsScreen> {
  final _ctrl = TextEditingController();
  bool _checking = false;
  CouponModel? _found;
  String? _err;

  static final _demo = [
    CouponModel(
        id: '1',
        code: 'PROMO30',
        description: '30% OFF em qualquer serviço',
        discount: 30,
        isPercentage: true,
        minValue: 50,
        expiresAt: DateTime.now().add(const Duration(days: 7))),
    CouponModel(
        id: '2',
        code: 'FRETE0',
        description: 'Frete grátis no Mercado',
        discount: 15,
        isPercentage: false,
        minValue: 30,
        expiresAt: DateTime.now().add(const Duration(days: 3))),
    CouponModel(
        id: '3',
        code: 'SAUDE20',
        description: '20% OFF em consultas',
        discount: 20,
        isPercentage: true,
        minValue: 100,
        expiresAt: DateTime.now().add(const Duration(days: 14)),
        category: 'health'),
    CouponModel(
        id: '4',
        code: 'WELCOME50',
        description: 'R\$ 50 no 1º pedido',
        discount: 50,
        isPercentage: false,
        minValue: 80,
        expiresAt: DateTime.now().add(const Duration(days: 30))),
  ];

  Future<void> _check() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _checking = true;
      _found = null;
      _err = null;
    });
    final coupon = await FS.validateCoupon(code);
    if (!mounted) return;
    if (coupon != null) {
      setState(() {
        _found = coupon;
        _checking = false;
      });
      snack(context, '🎉 Cupom válido! ${coupon.label}',
          bg: AppColors.secondary);
    } else {
      CouponModel? demo;
      if (DemoData.allow) {
        demo = _demo.firstWhere((c) => c.code == code,
            orElse: () => CouponModel(
                id: '',
                code: '',
                description: '',
                discount: 0,
                expiresAt: DateTime.now().subtract(const Duration(days: 1))));
      }
      if (demo != null && demo.code.isNotEmpty && demo.isValid) {
        setState(() {
          _found = demo;
          _checking = false;
        });
        snack(context, '🎉 Cupom válido! ${demo.label}',
            bg: AppColors.secondary);
      } else {
        setState(() {
          _err = 'Cupom inválido ou expirado';
          _checking = false;
        });
        snack(context, '❌ Cupom inválido', bg: AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Meus Cupons')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
              decoration: AppDecorations.card(r: 18),
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Text('🎟️ Adicionar cupom',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: _ctrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                              hintText: 'CÓDIGO DO CUPOM'))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: _checking ? null : _check,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Verificar',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                ]),
                if (_err != null) ...[
                  const SizedBox(height: 8),
                  Text(_err!,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
                ],
                if (_found != null) ...[
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3))),
                      child: Row(children: [
                        const Text('🎉', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_found!.description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.secondary)),
                              Text('Desconto: ${_found!.label}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium))
                            ]))
                      ]))
                ],
              ])),
          const SizedBox(height: 20),
          const SecHeader(title: '🎁 Cupons disponíveis'),
          const SizedBox(height: 12),
          if (DemoData.allow)
            for (final c in _demo) _CouponCard(coupon: c)
          else
            const EmptyState(
                emoji: '🎟️',
                title: 'Sem cupons listados',
                subtitle: 'Digite um código acima para validar'),
        ]),
      );
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDecorations.card(r: 18),
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration:
                      AppDecorations.gradient(AppGradients.primary, r: 14),
                  child: Text(coupon.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(coupon.code,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(coupon.description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                            height: 1.4)),
                    if (coupon.minValue != null)
                      Text('Mín. ${PaySvc.fmt(coupon.minValue!)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    Text('Válido até ${fmtDate(coupon.expiresAt)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: coupon.isValid
                                ? AppColors.secondary
                                : AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ])),
              GestureDetector(
                  onTap: () => snack(context, '✅ Código copiado!',
                      bg: AppColors.secondary),
                  child: const Icon(Icons.content_copy_rounded,
                      color: AppColors.primary, size: 20)),
            ])),
      );
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
  @override
  State<DeliveryScreen> createState() => _DelivState();
}

class _DelivState extends State<DeliveryScreen> {
  int _tab = 0;
  bool _offerAvailable = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: GradHeader(
                  gradient: AppGradients.delivery,
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📦 EntregaConecta',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22)),
                                Text('Rastreamento em tempo real',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12))
                              ]),
                          GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(11)),
                                  child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 18))),
                        ]),
                    const SizedBox(height: 14),
                    TogglePills(
                        options: const [
                          '📦 Receber',
                          '🛵 Entregar',
                          '📋 Histórico'
                        ],
                        selected: _tab,
                        onSelect: (i) => setState(() => _tab = i),
                        activeColor: AppColors.delivery),
                  ]))),
          if (_tab == 0)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Container(
                          decoration: AppDecorations.gradient(
                              AppGradients.delivery,
                              r: 20),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📦 Enviar encomenda',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18)),
                                const SizedBox(height: 8),
                                const Text('Motoboy · Bike · Carro · Van',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                    onPressed: () => _requestDelivery(context),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.delivery,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    child: const Text(
                                        'Solicitar entrega agora →',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14))),
                              ])),
                      const SizedBox(height: 16),
                      Container(
                          decoration: AppDecorations.card(r: 18),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rastrear pedido ativo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 14),
                                Container(
                                    decoration: AppDecorations.gradient(
                                        AppGradients.delivery,
                                        r: 16),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(children: [
                                      const Text('🛵',
                                          style: TextStyle(fontSize: 28)),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text('Entregador a caminho',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14)),
                                            Text('Chegada estimada: 12 min',
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12))
                                          ])),
                                      ElevatedButton(
                                          onPressed: () => Navigator.pushNamed(
                                              context, Routes.gps,
                                              arguments: {'ctx': 'mercado'}),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  AppColors.delivery,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8)),
                                          child: const Text('GPS',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12))),
                                    ])),
                              ])),
                    ])))
          else if (_tab == 1)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Container(
                          decoration: AppDecorations.card(r: 18),
                          padding: const EdgeInsets.all(18),
                          child: Column(children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Seu status',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  Switch(
                                      value: true,
                                      onChanged: (_) {},
                                      activeColor: AppColors.success)
                                ]),
                            const Row(children: [
                              Icon(Icons.circle,
                                  color: AppColors.success, size: 12),
                              SizedBox(width: 8),
                              Text('Online — recebendo pedidos',
                                  style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))
                            ]),
                            const Divider(),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(children: [
                                    const Text('12',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: AppColors.delivery)),
                                    const Text('Entregas hoje',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight))
                                  ]),
                                  Column(children: [
                                    const Text('R\$86',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: AppColors.secondary)),
                                    const Text('Ganhos hoje',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight))
                                  ]),
                                  Column(children: [
                                    const Text('4.9★',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: AppColors.warning)),
                                    const Text('Avaliação',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight))
                                  ]),
                                ]),
                          ])),
                      const SizedBox(height: 16),
                      if (_offerAvailable)
                        Container(
                            decoration: AppDecorations.gradient(
                                AppGradients.delivery,
                                r: 18),
                            padding: const EdgeInsets.all(18),
                            child: Row(children: [
                              const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📦 Nova entrega disponível',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15)),
                                    SizedBox(height: 4),
                                    Text(
                                        'Centro → Bela Vista · 2,3km · R\$ 8,50',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12))
                                  ]),
                              const Spacer(),
                              Column(children: [
                                ElevatedButton(
                                    onPressed: () async {
                                      final orderId = await FS.createOrder({
                                        'category': 'entregador_moto',
                                        'title': 'Entrega Centro → Bela Vista',
                                        'description':
                                            'Entrega aceita pelo entregador',
                                        'address': 'Bela Vista',
                                        'price': 8.50
                                      });
                                      setState(() => _offerAvailable = false);
                                      if (mounted) {
                                        snack(context,
                                            '✅ Entrega aceita! Iniciando rota...',
                                            bg: AppColors.delivery);
                                        Navigator.pushNamed(context, Routes.gps,
                                            arguments: {
                                              'ctx': 'mercado',
                                              'orderId': orderId
                                            });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.delivery,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10))),
                                    child: const Text('Aceitar',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12))),
                                TextButton(
                                    onPressed: () {
                                      setState(() => _offerAvailable = false);
                                      snack(context, 'Entrega recusada',
                                          bg: AppColors.textLight);
                                    },
                                    child: const Text('Recusar',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11))),
                              ]),
                            ]))
                      else
                        Container(
                            decoration: AppDecorations.card(r: 18),
                            padding: const EdgeInsets.all(20),
                            child: const Column(children: [
                              Text('⏳', style: TextStyle(fontSize: 32)),
                              SizedBox(height: 8),
                              Text('Aguardando novas entregas...',
                                  style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ])),
                    ])))
          else
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      for (final h in [
                        'Entrega #4521 — Concluída',
                        'Entrega #4517 — Concluída',
                        'Entrega #4510 — Cancelada'
                      ])
                        Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: AppDecorations.card(r: 14),
                            child: ListTile(
                                leading: const Text('📦',
                                    style: TextStyle(fontSize: 22)),
                                title: Text(h,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                subtitle: const Text('Hoje · R\$ 8,50',
                                    style: TextStyle(fontSize: 11)),
                                trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textLight))),
                    ]))),
        ]),
      );

  void _requestDelivery(BuildContext ctx) => showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 8),
              const SheetHandle(),
              const SizedBox(height: 16),
              const Text('Solicitar entrega',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                  decoration: const InputDecoration(
                      hintText: 'Endereço de coleta',
                      prefixIcon: Icon(Icons.location_on_rounded))),
              const SizedBox(height: 10),
              TextFormField(
                  decoration: const InputDecoration(
                      hintText: 'Endereço de entrega',
                      prefixIcon: Icon(Icons.flag_rounded))),
              const SizedBox(height: 10),
              TextFormField(
                  decoration:
                      const InputDecoration(hintText: 'Descrição do pacote')),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        snack(ctx, '✅ Entregador buscado!',
                            bg: AppColors.delivery);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.delivery,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Encontrar entregador 🛵',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white)))),
            ]),
          ));
}

// ─────────────────────────────────────────────────────────────
// LEGAL SCREEN — Termos de Uso / Política de Privacidade (LGPD)
// ─────────────────────────────────────────────────────────────
class LegalScreen extends StatelessWidget {
  final bool isPrivacy;
  const LegalScreen({super.key, this.isPrivacy = false});

  static const _terms = '''
1. ACEITAÇÃO DOS TERMOS
Ao utilizar o ServiçoConecta, você concorda com estes Termos de Uso. Caso não concorde, não utilize a plataforma.

2. DESCRIÇÃO DO SERVIÇO
O ServiçoConecta é uma plataforma de intermediação entre clientes e prestadores de serviços, incluindo módulos de saúde, entregas, mercado e aluguel.

3. CADASTRO
O usuário deve fornecer informações verdadeiras e atualizadas. Contas falsas ou fraudulentas serão suspensas.

4. PAGAMENTOS
Os valores são retidos em custódia até a conclusão do serviço. A comissão da plataforma é de 15% sobre cada transação.

5. CANCELAMENTOS
Cancelamentos podem estar sujeitos a taxas, conforme o status do pedido no momento do cancelamento.

6. RESPONSABILIDADES
O ServiçoConecta atua como intermediário e não se responsabiliza pela execução técnica dos serviços prestados por terceiros.

7. CONDUTA
É proibido o uso da plataforma para fins ilícitos, discriminatórios ou que violem direitos de terceiros.

8. RESCISÃO
Reservamo-nos o direito de suspender ou encerrar contas que violem estes termos.

9. ALTERAÇÕES
Estes termos podem ser atualizados periodicamente. O uso continuado da plataforma implica aceitação das mudanças.
''';

  static const _privacy = '''
1. DADOS COLETADOS
Coletamos nome, e-mail, telefone, CPF/CNPJ, endereço e localização para viabilizar a prestação de serviços.

2. FINALIDADE
Os dados são usados para autenticação, processamento de pagamentos, geolocalização de profissionais e comunicação entre as partes.

3. BASE LEGAL (LGPD)
O tratamento de dados segue a Lei Geral de Proteção de Dados (Lei 13.709/2018), com base no consentimento do titular e na execução de contrato.

4. COMPARTILHAMENTO
Seus dados podem ser compartilhados com prestadores de serviço, processadores de pagamento (PIX/cartão) e autoridades quando exigido por lei.

5. SEGURANÇA
Utilizamos criptografia e controles de acesso para proteger seus dados contra acesso não autorizado.

6. RETENÇÃO
Os dados são mantidos pelo tempo necessário para cumprir as finalidades descritas ou obrigações legais.

7. SEUS DIREITOS
Você pode solicitar acesso, correção, portabilidade ou exclusão dos seus dados a qualquer momento pelo suporte.

8. COOKIES E RASTREAMENTO
Utilizamos identificadores para melhorar a experiência e segurança, sem venda de dados a terceiros para fins de marketing.

9. CONTATO DO ENCARREGADO (DPO)
Dúvidas sobre privacidade podem ser enviadas para privacidade@servicoconecta.com.br.
''';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(isPrivacy ? 'Política de Privacidade' : 'Termos de Uso')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              decoration: AppDecorations.gradient(
                  isPrivacy ? AppGradients.primary : AppGradients.dark,
                  r: 18),
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Text(isPrivacy ? '🔏' : '📄',
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          isPrivacy
                              ? 'Política de Privacidade'
                              : 'Termos de Uso',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      const Text('Última atualização: Julho de 2026',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
              ]),
            ),
            const SizedBox(height: 20),
            Text(
              (isPrivacy ? _privacy : _terms).trim(),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium, height: 1.7),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// REFERRAL SCREEN — Indique e ganhe (convide amigos)
// Gera um código de indicação a partir do uid, permite copiar e
// compartilhar. O crédito é concedido quando o convidado se
// cadastra usando o código (validado no cadastro / Cloud Function).
// ─────────────────────────────────────────────────────────────
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  String get _code {
    final uid = AuthService.uid ?? '';
    if (uid.isEmpty) return 'CONECTA';
    // Código curto, legível e determinístico a partir do uid.
    return 'SC${uid.substring(0, uid.length >= 6 ? 6 : uid.length).toUpperCase()}';
  }

  String get _shareMessage =>
      'Baixe o ServiçoConecta e use meu código $_code no cadastro. '
      'Você ganha R\$ 10 no primeiro serviço e eu também! 🎉';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Indique e ganhe')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              SvgPicture.asset(AppAssets.ilConvideAmigos, height: 200),
              const SizedBox(height: 24),
              const Text('Convide amigos e ganhem juntos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                  'A cada amigo que se cadastrar com o seu código e concluir o primeiro serviço, vocês dois ganham R\$ 10 de cashback na carteira.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textLight, height: 1.5)),
              const SizedBox(height: 28),
              Container(
                decoration:
                    AppDecorations.gradient(AppGradients.primary, r: 18),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(children: [
                  const Text('Seu código',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(_code,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _miniBtn(Icons.copy_rounded, 'Copiar', () {
                      Clipboard.setData(ClipboardData(text: _code));
                      snack(context, '✅ Código copiado!',
                          bg: AppColors.secondary);
                    }),
                    const SizedBox(width: 12),
                    _miniBtn(Icons.share_rounded, 'Compartilhar',
                        () => Share.share(_shareMessage)),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              _step('1', 'Compartilhe seu código com amigos'),
              _step('2', 'Eles se cadastram e usam o código'),
              _step('3', 'Vocês dois ganham R\$ 10 após o 1º serviço'),
            ])),
      );

  Widget _miniBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13))
          ]),
        ),
      );

  Widget _step(String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  color: AppColors.secondary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(n,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(width: 14),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
      );
}
