import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/demo_data.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletState();
}

class _WalletState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _uid = AuthService.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) =>
              [SliverToBoxAdapter(child: _header())],
          body: TabBarView(
              controller: _tab, children: [_extract(), _pixTab(), _plans()]),
        ),
      );

  Widget _header() => GradHeader(
      gradient: AppGradients.primary,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('👜 Minha Carteira',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          StreamBuilder<UserModel?>(
              stream:
                  _uid.isNotEmpty ? FS.userStream(_uid) : const Stream.empty(),
              builder: (_, s) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(s.data?.levelName ?? '⭐ Iniciante',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)))),
        ]),
        const SizedBox(height: 18),
        StreamBuilder<WalletModel?>(
            stream: _uid.isNotEmpty ? FS.walletStream() : const Stream.empty(),
            builder: (_, s) {
              final bal = s.data?.balance ?? 0.0;
              return Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Text('Saldo disponível',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(PaySvc.fmt(bal),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    Row(children: [
                      _btn(
                          '💳',
                          'Adicionar',
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PixScreen(
                                      amount: 50,
                                      desc: 'Recarga',
                                      isRecharge: true)))),
                      const SizedBox(width: 8),
                      _btn('📤', 'Sacar', () => _showWithdraw(context)),
                      const SizedBox(width: 8),
                      _btn('⚡', 'PIX', () => _tab.animateTo(1)),
                      const SizedBox(width: 8),
                      _btn('📊', 'Extrato', () => _tab.animateTo(0)),
                    ]),
                  ]));
            }),
        const SizedBox(height: 14),
        TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Extrato'),
              Tab(text: 'PIX'),
              Tab(text: 'Planos')
            ]),
      ]));

  Widget _btn(String icon, String label, VoidCallback onTap) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600))
              ]))));

  void _showWithdraw(BuildContext context) {
    final amountCtrl = TextEditingController();
    final pixCtrl = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const SheetHandle(),
                    const SizedBox(height: 16),
                    const Text('Sacar saldo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Transferência via PIX. Saque mínimo de R\$ 10.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            prefixText: 'R\$ ', hintText: 'Valor a sacar')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: pixCtrl,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.key_rounded),
                            hintText: 'Sua chave PIX')),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  final amount = double.tryParse(amountCtrl.text
                                          .replaceAll(',', '.')) ??
                                      0;
                                  if (amount < 10) {
                                    snack(ctx, 'O saque mínimo é R\$ 10,00',
                                        bg: AppColors.error);
                                    return;
                                  }
                                  if (pixCtrl.text.trim().isEmpty) {
                                    snack(ctx, 'Informe sua chave PIX',
                                        bg: AppColors.error);
                                    return;
                                  }
                                  setSheet(() => submitting = true);
                                  final ok = await FS.withdraw(
                                      amount, pixCtrl.text.trim());
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  snack(
                                      context,
                                      ok
                                          ? '✅ Saque solicitado! O valor cairá na sua conta em até 1 dia útil.'
                                          : 'Saldo insuficiente para este saque.',
                                      bg: ok
                                          ? AppColors.secondary
                                          : AppColors.error);
                                },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Confirmar saque',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                        )),
                  ]),
                )));
  }

  Widget _extract() => StreamBuilder<List<TransactionModel>>(
      stream: _uid.isNotEmpty ? FS.txStream() : const Stream.empty(),
      builder: (_, s) {
        final txs = DemoData.orEmpty(s.data, _demoTxs);
        if (txs.isEmpty)
          return const EmptyState(
              emoji: '📋',
              title: 'Sem transações',
              subtitle: 'Suas movimentações aparecerão aqui',
              asset: AppAssets.walletExtrato);
        return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = txs[i];
              return Container(
                  decoration: AppDecorations.card(),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: (t.isCredit
                                    ? AppColors.secondary
                                    : AppColors.error)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child:
                            Text(t.icon, style: const TextStyle(fontSize: 22))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(t.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textDark)),
                          Text(fmtDate(t.createdAt),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textLight))
                        ])),
                    Text('${t.isCredit ? '+' : '-'}${PaySvc.fmt(t.amount)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: t.isCredit
                                ? AppColors.secondary
                                : AppColors.error)),
                  ]));
            });
      });

  Widget _pixTab() => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
            decoration: BoxDecoration(
                color: AppColors.pix.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.pix.withOpacity(0.3))),
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Text('⚡', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Pagamento via PIX',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.pix)),
                    const SizedBox(height: 4),
                    const Text('Instantâneo. 24h por dia, 7 dias por semana.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textLight))
                  ])),
            ])),
        const SizedBox(height: 20),
        Container(
            decoration: AppDecorations.card(),
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Suas chaves PIX',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 14),
              for (final k in [
                ['📱', 'Celular', '(11) 99999-9999'],
                ['📧', 'E-mail', 'contato@email.com'],
                ['🔑', 'Aleatória', 'a1b2-c3d4-...']
              ])
                Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Text(k[0], style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(k[1],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(k[2],
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textLight))
                          ])),
                      IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              color: AppColors.primary, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: k[2]));
                            snack(context, '✅ Copiado!',
                                bg: AppColors.secondary);
                          }),
                    ])),
            ])),
        const SizedBox(height: 14),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PixScreen(
                            amount: 50, desc: 'Pagamento via PIX'))),
                icon: const Text('⚡', style: TextStyle(fontSize: 18)),
                label: const Text('Fazer pagamento PIX',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pix,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))))),
        const SizedBox(height: 10),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CardPaymentScreen(
                            amount: 50, desc: 'Pagamento com Cartão'))),
                icon: const Icon(Icons.credit_card_rounded, size: 18),
                label: const Text('Pagar com cartão de crédito',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary)))),
      ]));

  Widget _plans() => StreamBuilder<UserModel?>(
        stream: _uid.isNotEmpty ? FS.userStream(_uid) : const Stream.empty(),
        builder: (_, snap) {
          final currentPlan = snap.data?.plan ?? PlanTier.free;
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Escolha seu plano',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Desbloqueie mais benefícios',
                style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 20),
            for (final p in _plansData)
              _planCard(p, isCurrent: p['tier'] == currentPlan),
          ]);
        },
      );

  Widget _planCard(Map<String, dynamic> p, {required bool isCurrent}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppDecorations.gradient(p['grad'] as Gradient, r: 20),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(p['name'] as String,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            if (isCurrent)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('✓ Ativo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)))
            else if (p['badge'] != null)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(p['badge'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          Text(p['price'] as String,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22)),
          const SizedBox(height: 12),
          for (final f in (p['features'] as List<String>))
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(f,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 13))
                ])),
          const SizedBox(height: 14),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent ? null : () => _subscribe(context, p),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.white.withOpacity(isCurrent ? 0.1 : 0.25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(isCurrent ? 'Plano atual' : 'Assinar ${p['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
        ]),
      );

  void _subscribe(BuildContext context, Map<String, dynamic> plan) {
    final price = plan['priceValue'] as double;
    if (price <= 0) {
      snack(context,
          'Planos pagos ficam disponíveis quando o faturamento real estiver ativo.',
          bg: AppColors.warning);
      return;
    }
    showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                Text('Assinar ${plan['name']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Escolha a forma de pagamento',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Text('⚡', style: TextStyle(fontSize: 22)),
                  title: const Text('PIX',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Confirmação instantânea',
                      style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PixScreen(
                                amount: price,
                                desc: 'Assinatura ${plan['name']}',
                                onPaid: () async {
                                  snack(context,
                                      'Assinatura depende de pagamento real (desligado em staging).',
                                      bg: AppColors.warning);
                                })));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded,
                      color: AppColors.primary),
                  title: const Text('Cartão de crédito',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle:
                      const Text('Em até 12x', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardPaymentScreen(
                                amount: price,
                                desc: 'Assinatura ${plan['name']}',
                                onPaid: () async {
                                  snack(context,
                                      'Assinatura depende de pagamento real (desligado em staging).',
                                      bg: AppColors.warning);
                                })));
                  },
                ),
              ]),
            ));
  }

  static final _demoTxs = [
    TransactionModel(
        id: '1',
        userId: 'u',
        type: 'credit',
        amount: 150,
        description: 'Pagamento recebido',
        icon: '💰',
        status: 'done',
        createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    TransactionModel(
        id: '2',
        userId: 'u',
        type: 'debit',
        amount: 120,
        description: 'Serviço de limpeza',
        icon: '🧹',
        status: 'done',
        createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    TransactionModel(
        id: '3',
        userId: 'u',
        type: 'credit',
        amount: 50,
        description: 'Bônus indicação',
        icon: '🎁',
        status: 'done',
        createdAt: DateTime.now().subtract(const Duration(days: 1))),
    TransactionModel(
        id: '4',
        userId: 'u',
        type: 'debit',
        amount: 80,
        description: 'Serviço elétrico',
        icon: '⚡',
        status: 'done',
        createdAt: DateTime.now().subtract(const Duration(days: 2))),
    TransactionModel(
        id: '5',
        userId: 'u',
        type: 'debit',
        amount: 87.40,
        description: 'MercadoConecta',
        icon: '🛒',
        status: 'done',
        createdAt: DateTime.now().subtract(const Duration(days: 3))),
  ];

  static final _plansData = [
    {
      'name': 'Básico',
      'price': 'Grátis',
      'priceValue': 0.0,
      'tier': PlanTier.free,
      'grad': AppGradients.dark,
      'badge': null,
      'features': ['1 solicitação por semana', 'Suporte por chat']
    },
    {
      'name': 'Profissional',
      'price': 'R\$ 49,90/mês',
      'priceValue': 49.90,
      'tier': PlanTier.professional,
      'grad': AppGradients.primary,
      'badge': '⭐ Popular',
      'features': [
        'Serviços ilimitados',
        'Destaque na busca',
        'Suporte prioritário',
        'Cupons exclusivos'
      ]
    },
    {
      'name': 'Premium',
      'price': 'R\$ 99,90/mês',
      'priceValue': 99.90,
      'tier': PlanTier.premium,
      'grad': AppGradients.gold,
      'badge': '💎 Melhor',
      'features': [
        'Tudo ilimitado',
        'IA Assistente',
        'Saúde incluída',
        'Aluguel com desconto',
        'Gerente dedicado'
      ]
    },
  ];
}

class PixScreen extends StatefulWidget {
  final double amount;
  final String desc;
  final bool isRecharge;
  final Future<void> Function()? onPaid;
  const PixScreen(
      {super.key,
      required this.amount,
      required this.desc,
      this.isRecharge = false,
      this.onPaid});
  @override
  State<PixScreen> createState() => _PixState();
}

class _PixState extends State<PixScreen> {
  bool _loading = true, _paid = false;
  String? _code;
  String? _paymentId;
  bool _polling = false;
  int _countdown = 30 * 60;
  final _uid = AuthService.uid ?? '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);

    // Tenta gerar um PIX real pela Cloud Function (Mercado Pago).
    final email = '${_uid.isNotEmpty ? _uid : 'demo'}@servicoconecta.com.br';
    final pix = await PaySvc.generatePix(
        amount: widget.amount,
        description: widget.desc,
        email: email,
        orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
        userId: _uid.isNotEmpty ? _uid : null,
        purpose: widget.isRecharge ? 'wallet_recharge' : 'order');

    if (!mounted) return;

    if (pix != null && (pix['qr_code'] != null || pix['id'] != null)) {
      // Gateway real configurado: usa o código PIX de verdade e faz
      // polling do status até aprovar.
      setState(() {
        _loading = false;
        _code = pix['qr_code']?.toString() ?? pix['qr_code_base64']?.toString();
        _paymentId = pix['id']?.toString();
      });
      _countdownStart();
      _startPolling();
    } else {
      // Sem gateway: não auto-credita (evita abuso em produção/demo).
      setState(() {
        _loading = false;
        _code =
            '00020126580014BR.GOV.BCB.PIX0136${_uid.isNotEmpty ? _uid : 'demo'}@servicoconecta.com.br5204000053039865802BR5925ServicoConecta6009SAO PAULO62070503***6304ABCD';
      });
      _countdownStart();
      if (mounted) {
        snack(context,
            'Pagamentos PIX ainda não configurados. Configure o gateway para confirmar recargas.',
            bg: AppColors.warning);
      }
    }
  }

  // Consulta o status do pagamento a cada 4s até aprovar, expirar o
  // contador, ou a tela ser descartada.
  void _startPolling() {
    _polling = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted ||
          !_polling ||
          _paid ||
          _countdown <= 0 ||
          _paymentId == null) return false;
      final status = await PaySvc.checkPayment(_paymentId!);
      if (status == 'approved') {
        await _confirmPaid();
        return false;
      }
      return _polling && !_paid;
    });
  }

  Future<void> _confirmPaid() async {
    // Recarga: crédito é feito na Cloud Function checkPayment (Admin SDK).
    if (widget.onPaid != null) await widget.onPaid!();
    if (mounted)
      setState(() {
        _paid = true;
        _polling = false;
      });
  }

  void _countdownStart() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _paid || _countdown <= 0) return false;
      setState(() => _countdown--);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('⚡ Pagamento PIX'),
            backgroundColor: AppColors.pix,
            foregroundColor: Colors.white),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                  decoration: AppDecorations.gradient(
                      _paid ? AppGradients.secondary : AppGradients.pix,
                      r: 20),
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _paid
                        ? Lottie.asset(AppAssets.lottiePagamentoAprovado,
                            width: 80, height: 80, repeat: false)
                        : const Text('⚡', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                        _paid
                            ? 'Pagamento confirmado!'
                            : _loading
                                ? 'Gerando QR Code...'
                                : 'Aguardando pagamento...',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(PaySvc.fmt(widget.amount),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28)),
                    Text(widget.desc,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                  ])),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.pix))
              else if (_paid)
                _success()
              else
                _qr(),
            ])),
      );

  Widget _qr() => Column(children: [
        Container(
            decoration: AppDecorations.card(r: 20),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Escaneie com seu banco',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Text('Qualquer banco com PIX instalado',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 20),
              if (_code != null)
                QrImageView(
                    data: _code!, size: 200, backgroundColor: Colors.white)
              else
                const SizedBox(
                    height: 200,
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.pix))),
              const SizedBox(height: 16),
              Text(
                  'Expira em ${(_countdown ~/ 60).toString().padLeft(2, '0')}:${(_countdown % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _countdown < 120
                          ? AppColors.error
                          : AppColors.textLight)),
              const SizedBox(height: 16),
              const Text('Ou copie o código Copia e Cola:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(
                        child: Text(_code ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.pix),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _code ?? ''));
                          snack(context, '✅ Código PIX copiado!',
                              bg: AppColors.secondary);
                        }),
                  ])),
            ])),
        const SizedBox(height: 14),
        Container(
            decoration: AppDecorations.card(r: 18),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              for (final r in [
                ['⚡', 'Confirmação instantânea', 'Segundos após o pagamento'],
                ['🔒', '100% seguro', 'Criptografia de ponta a ponta'],
                ['📱', 'Todos os bancos', 'Funciona em qualquer app']
              ])
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Text(r[0], style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(r[1],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(r[2],
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight))
                          ]))
                    ])),
            ])),
      ]);

  Widget _success() => Column(children: [
        const SizedBox(height: 32),
        const Text('🎉', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text('Tudo certo!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary)),
        const SizedBox(height: 8),
        const Text('Saldo adicionado à sua carteira.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight)),
        const SizedBox(height: 32),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Continuar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white)))),
      ]);
}

// ─────────────────────────────────────────────────────────────
// CARD PAYMENT SCREEN (Vol.17: Pagamentos — Cartão de Crédito)
// Tokeniza o cartão direto com o Mercado Pago e envia só o token
// para a Cloud Function processCardPayment processar a cobrança.
// ─────────────────────────────────────────────────────────────
class CardPaymentScreen extends StatefulWidget {
  final double amount;
  final String desc;
  final Future<void> Function()? onPaid;
  const CardPaymentScreen(
      {super.key, required this.amount, required this.desc, this.onPaid});
  @override
  State<CardPaymentScreen> createState() => _CardPaymentState();
}

class _CardPaymentState extends State<CardPaymentScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expMonth = TextEditingController();
  final _expYear = TextEditingController();
  final _cvv = TextEditingController();
  final _doc = TextEditingController();
  int _installments = 1;
  bool _loading = false, _paid = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expMonth.dispose();
    _expYear.dispose();
    _cvv.dispose();
    _doc.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await PaySvc.tokenizeCard(
      cardNumber: _number.text,
      holderName: _holder.text,
      expMonth: _expMonth.text,
      expYear: _expYear.text,
      cvv: _cvv.text,
      docNumber: _doc.text.replaceAll(RegExp(r'\D'), ''),
    );

    if (token == null) {
      setState(() {
        _loading = false;
        _error =
            'Não foi possível validar o cartão. Confira os dados e tente novamente.';
      });
      return;
    }

    final user = await FS.getUser();
    final result = await PaySvc.payWithCard(
      amount: widget.amount,
      description: widget.desc,
      email: user?.email ?? '',
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      cardToken: token,
      installments: _installments,
      docNumber: _doc.text.replaceAll(RegExp(r'\D'), ''),
    );

    if (result == null || result['status'] != 'approved') {
      setState(() {
        _loading = false;
        _error =
            'Pagamento recusado. Verifique os dados do cartão ou tente outro cartão.';
      });
      return;
    }

    if (widget.onPaid != null) await widget.onPaid!();
    if (mounted)
      setState(() {
        _loading = false;
        _paid = true;
      });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('💳 Pagamento com Cartão'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white),
        body: _paid
            ? _cardSuccess()
            : LoadingOverlay(
                loading: _loading,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                        key: _form,
                        child: Column(children: [
                          Container(
                              decoration: AppDecorations.gradient(
                                  AppGradients.primary,
                                  r: 20),
                              padding: const EdgeInsets.all(20),
                              child: Column(children: [
                                const Icon(Icons.credit_card_rounded,
                                    color: Colors.white, size: 32),
                                const SizedBox(height: 8),
                                Text(PaySvc.fmt(widget.amount),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28)),
                                Text(widget.desc,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13)),
                              ])),
                          const SizedBox(height: 20),
                          if (_error != null)
                            Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 12)))
                                ])),
                          TextFormField(
                              controller: _number,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  hintText: 'Número do cartão',
                                  prefixIcon: Icon(Icons.credit_card)),
                              validator: (v) =>
                                  (v?.replaceAll(' ', '').length ?? 0) < 13
                                      ? 'Número inválido'
                                      : null),
                          const SizedBox(height: 10),
                          TextFormField(
                              controller: _holder,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                  hintText: 'Nome impresso no cartão',
                                  prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Campo obrigatório'
                                  : null),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                                child: TextFormField(
                                    controller: _expMonth,
                                    keyboardType: TextInputType.number,
                                    maxLength: 2,
                                    decoration: const InputDecoration(
                                        hintText: 'MM', counterText: ''),
                                    validator: (v) =>
                                        (v?.length ?? 0) != 2 ? 'MM' : null)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: TextFormField(
                                    controller: _expYear,
                                    keyboardType: TextInputType.number,
                                    maxLength: 2,
                                    decoration: const InputDecoration(
                                        hintText: 'AA', counterText: ''),
                                    validator: (v) =>
                                        (v?.length ?? 0) != 2 ? 'AA' : null)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: TextFormField(
                                    controller: _cvv,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                        hintText: 'CVV', counterText: ''),
                                    validator: (v) =>
                                        (v?.length ?? 0) < 3 ? 'CVV' : null)),
                          ]),
                          const SizedBox(height: 10),
                          TextFormField(
                              controller: _doc,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  hintText: 'CPF do titular',
                                  prefixIcon: Icon(Icons.badge_outlined)),
                              validator: (v) =>
                                  (v?.replaceAll(RegExp(r'\D'), '').length ??
                                              0) <
                                          11
                                      ? 'CPF inválido'
                                      : null),
                          const SizedBox(height: 14),
                          Container(
                              decoration: AppDecorations.card(r: 14),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: DropdownButtonFormField<int>(
                                value: _installments,
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.repeat_rounded)),
                                items: [1, 2, 3, 6, 12]
                                    .map((n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(n == 1
                                            ? 'À vista — ${PaySvc.fmt(widget.amount)}'
                                            : '${n}x de ${PaySvc.fmt(widget.amount / n)}')))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _installments = v ?? 1),
                              )),
                          const SizedBox(height: 20),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _pay,
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14))),
                                child: Text(
                                    'Pagar ${PaySvc.fmt(widget.amount)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                              )),
                          const SizedBox(height: 12),
                          const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 14, color: AppColors.textLight),
                                SizedBox(width: 6),
                                Text(
                                    'Pagamento processado com segurança pelo Mercado Pago',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight))
                              ]),
                        ])))),
      );

  Widget _cardSuccess() => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 40),
        const Text('🎉', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        const Text('Pagamento aprovado!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary)),
        const SizedBox(height: 8),
        Text(PaySvc.fmt(widget.amount),
            style: const TextStyle(fontSize: 16, color: AppColors.textLight)),
        const SizedBox(height: 32),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Continuar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.white)))),
      ]));
}
