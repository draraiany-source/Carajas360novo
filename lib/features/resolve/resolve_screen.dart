import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/modules/platform_modules.dart';
import '../../core/utils/chat_nav.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';

/// Cliente: descreve necessidade e recebe propostas.
class ResolveScreen extends StatefulWidget {
  const ResolveScreen({super.key});
  @override
  State<ResolveScreen> createState() => _ResolveScreenState();
}

class _ResolveScreenState extends State<ResolveScreen> {
  final _desc = TextEditingController();
  final _city = TextEditingController(text: RegionCities.defaultCity);
  String? _category;
  bool _sending = false;

  @override
  void dispose() {
    _desc.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (AuthService.uid == null) {
      snack(context, 'Faca login para pedir orcamento');
      return;
    }
    if (_desc.text.trim().length < 10) {
      snack(context, 'Descreva melhor o que voce precisa (min. 10 caracteres)');
      return;
    }
    if (_category == null) {
      snack(context, 'Selecione uma categoria');
      return;
    }
    setState(() => _sending = true);
    try {
      final user = await FS.getUser();
      final id = await FS.createResolveRequest(
        description: _desc.text.trim(),
        category: _category!,
        city: _city.text.trim().isEmpty
            ? RegionCities.defaultCity
            : _city.text.trim(),
        clientName: user?.name,
      );
      if (!mounted) return;
      snack(context, 'Pedido enviado! Aguarde propostas.', bg: AppColors.secondary);
      Navigator.pushReplacementNamed(context, Routes.resolveDetail,
          arguments: {'id': id});
    } catch (e) {
      if (mounted) snack(context, 'Erro ao enviar: $e', bg: AppColors.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Carajas'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.myResolve),
            child: const Text('Meus pedidos'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Descreva o que voce precisa. Profissionais compativeis da regiao enviam propostas com valor, prazo e avaliacao.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text('O que voce precisa?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ex.: Preciso instalar 3 ar-condicionados no comercio.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Categoria',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Categories.all.length.clamp(0, 30),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = Categories.all[i];
                return CatChip(
                  emoji: c.emoji,
                  name: c.name,
                  categoryId: c.id,
                  color: c.color,
                  selected: _category == c.id,
                  onTap: () => setState(() => _category = c.id),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Cidade',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _city,
            decoration: const InputDecoration(
              hintText: 'Canaa dos Carajas',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Pedir orcamento',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.resolveOpportunities),
            child: const Text('Sou profissional — ver oportunidades'),
          ),
        ],
      ),
    );
  }
}

class ResolveDetailScreen extends StatelessWidget {
  final String requestId;
  const ResolveDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        title: const Text('Minhas Solicitações'),
      ),
      body: StreamBuilder<ResolveRequest?>(
        stream: FS.resolveRequestStream(requestId),
        builder: (_, reqSnap) {
          final req = reqSnap.data;
          if (req == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: C360Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(req.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        C360StatusChip(_resolveLabel(req.status),
                            tone: _resolveTone(req.status)),
                      ]),
                      const SizedBox(height: 14),
                      C360Stepper(
                        steps: const [
                          'Solicitação',
                          'Aceite',
                          'Execução',
                          'Concluído'
                        ],
                        current: _resolveStep(req.status),
                      ),
                      const SizedBox(height: 8),
                      C360StepLabels(
                        steps: const [
                          'Solicitação Confirmada',
                          'Profissional Aceitou',
                          'Em Execução',
                          'Concluído'
                        ],
                        current: _resolveStep(req.status),
                      ),
                      const SizedBox(height: 14),
                      Text(
                          '${Categories.byId(req.category)?.name ?? req.category} · ${req.city}',
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12)),
                      if (req.address != null && req.address!.isNotEmpty)
                        Text(req.address!,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                          req.status == ResolveStatus.open
                              ? 'Aguardando propostas (${req.proposalCount})'
                              : 'Status atualizado com base na solicitação.',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ResolveProposal>>(
                  stream: FS.resolveProposalsStream(requestId),
                  builder: (_, snap) {
                    final list = snap.data ?? [];
                    if (snap.connectionState == ConnectionState.waiting &&
                        list.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (list.isEmpty) {
                      return const EmptyState(
                        emoji: '⏳',
                        title: 'Aguardando propostas',
                        subtitle:
                            'Profissionais da regiao foram notificados. Volte em breve.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return _ProposalTile(
                          proposal: p,
                          canAccept: req.status == ResolveStatus.open &&
                              req.clientId == AuthService.uid,
                          onAccept: () async {
                            await FS.acceptResolveProposal(
                              requestId: requestId,
                              proposalId: p.id,
                              providerId: p.providerId,
                              providerName: p.providerName,
                            );
                            if (!context.mounted) return;
                            snack(context, 'Proposta aceita!',
                                bg: AppColors.secondary);
                            await ChatNav.open(context,
                                otherUserId: p.providerId,
                                otherName: p.providerName,
                                otherPhoto: p.providerPhoto);
                          },
                          onChat: () => ChatNav.open(context,
                              otherUserId: p.providerId,
                              otherName: p.providerName,
                              otherPhoto: p.providerPhoto),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProposalTile extends StatelessWidget {
  final ResolveProposal proposal;
  final bool canAccept;
  final VoidCallback onAccept, onChat;
  const _ProposalTile({
    required this.proposal,
    required this.canAccept,
    required this.onAccept,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: proposal.accepted
                ? AppColors.secondary
                : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppAvatar(
              url: proposal.providerPhoto,
              name: proposal.providerName,
              size: 44,
              r: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(proposal.providerName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    '⭐ ${proposal.rating.toStringAsFixed(1)} · ${proposal.totalServices} servicos',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          if (proposal.accepted)
            const AppTag('Aceita', bg: AppColors.secondary),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('R\$ ${proposal.price.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary)),
          const SizedBox(width: 12),
          Text('Prazo: ${proposal.deadlineDays} dia(s)',
              style: const TextStyle(fontSize: 13)),
          if (proposal.available) ...[
            const SizedBox(width: 8),
            const Text('· Disponivel',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
        if (proposal.message != null && proposal.message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(proposal.message!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium, height: 1.35)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          OutlinedButton(onPressed: onChat, child: const Text('Chat')),
          const SizedBox(width: 8),
          if (canAccept && !proposal.accepted)
            ElevatedButton(
                onPressed: onAccept, child: const Text('Aceitar')),
        ]),
      ]),
    );
  }
}

class MyResolveScreen extends StatelessWidget {
  final bool embedded;
  const MyResolveScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      if (embedded)
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Minhas Solicitações',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      Expanded(child: _list(context)),
    ]);
    if (embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        title: const Text('Minhas Solicitações'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.resolve),
        backgroundColor: AppColors.primary,
        label: const Text('Novo pedido'),
        icon: const Icon(Icons.add),
      ),
      body: body,
    );
  }

  Widget _list(BuildContext context) {
    return StreamBuilder<List<ResolveRequest>>(
        stream: FS.myResolveRequestsStream(),
        builder: (_, snap) {
          final list = snap.data ?? [];
          if (snap.connectionState == ConnectionState.waiting &&
              list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '📋',
              title: 'Nenhum pedido ainda',
              subtitle: 'Peca um orcamento e receba propostas da regiao.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = list[i];
              final cat = Categories.byId(r.category);
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border)),
                  title: Text(r.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${cat?.name ?? r.category} · ${r.city} · ${r.proposalCount} proposta(s)'),
                  trailing: C360StatusChip(
                    _resolveLabel(r.status),
                    tone: _resolveTone(r.status),
                    icon: Icons.circle,
                  ),
                  onTap: () => Navigator.pushNamed(
                      context, Routes.resolveDetail,
                      arguments: {'id': r.id}),
                ),
              );
            },
          );
        },
      );
  }
}

String _resolveLabel(ResolveStatus status) {
  switch (status) {
    case ResolveStatus.open:
      return 'Em Andamento';
    case ResolveStatus.matched:
      return 'Aceita';
    case ResolveStatus.closed:
      return 'Concluído';
    case ResolveStatus.cancelled:
      return 'Cancelado';
  }
}

int _resolveStep(ResolveStatus status) {
  switch (status) {
    case ResolveStatus.open:
      return 0;
    case ResolveStatus.matched:
      return 1;
    case ResolveStatus.closed:
      return 3;
    case ResolveStatus.cancelled:
      return 0;
  }
}

C360Tone _resolveTone(ResolveStatus status) {
  switch (status) {
    case ResolveStatus.open:
      return C360Tone.progress;
    case ResolveStatus.matched:
      return C360Tone.success;
    case ResolveStatus.closed:
      return C360Tone.success;
    case ResolveStatus.cancelled:
      return C360Tone.danger;
  }
}

class ResolveOpportunitiesScreen extends StatefulWidget {
  const ResolveOpportunitiesScreen({super.key});
  @override
  State<ResolveOpportunitiesScreen> createState() =>
      _ResolveOpportunitiesState();
}

class _ResolveOpportunitiesState extends State<ResolveOpportunitiesScreen> {
  Future<void> _propose(ResolveRequest req) async {
    if (AuthService.uid == null) {
      snack(context, 'Faca login para enviar propostas');
      return;
    }
    final prov = await FS.myProviderStream().first;
    if (!mounted) return;
    if (prov == null) {
      snack(context,
          'Cadastre-se como profissional para enviar propostas.',
          bg: AppColors.error);
      return;
    }
    final priceCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '3');
    final msgCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar proposta'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor (R\$)')),
          TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prazo (dias)')),
          TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mensagem')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      priceCtrl.dispose();
      daysCtrl.dispose();
      msgCtrl.dispose();
      return;
    }
    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final days = int.tryParse(daysCtrl.text) ?? 1;
    final message =
        msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim();
    priceCtrl.dispose();
    daysCtrl.dispose();
    msgCtrl.dispose();
    if (price <= 0) {
      snack(context, 'Informe um valor valido');
      return;
    }
    try {
      await FS.submitResolveProposal(
        requestId: req.id,
        providerName: prov.name,
        providerPhoto: prov.photoUrl,
        price: price,
        deadlineDays: days,
        message: message,
        rating: prov.rating,
        totalServices: prov.totalReviews,
      );
      if (!mounted) return;
      snack(context, 'Proposta enviada!', bg: AppColors.secondary);
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Erro: $e', bg: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oportunidades Resolve')),
      body: StreamBuilder<ProviderModel?>(
        stream: FS.myProviderStream(),
        builder: (_, provSnap) {
          final prov = provSnap.data;
          return StreamBuilder<List<ResolveRequest>>(
            stream: FS.resolveOpportunitiesStream(),
            builder: (_, snap) {
              var list = snap.data ?? [];
              if (prov != null && prov.categories.isNotEmpty) {
                list = list
                    .where((r) => prov.categories.contains(r.category))
                    .toList();
              }
              if (snap.connectionState == ConnectionState.waiting &&
                  list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (prov == null) {
                return const EmptyState(
                  emoji: '👷',
                  title: 'Area do profissional',
                  subtitle:
                      'Cadastre-se como prestador para ver oportunidades Resolve.',
                );
              }
              if (list.isEmpty) {
                return const EmptyState(
                  emoji: '📍',
                  title: 'Nenhuma oportunidade agora',
                  subtitle:
                      'Quando clientes pedirem orcamentos na sua categoria, eles aparecem aqui.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      color: AppColors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, height: 1.35)),
                        const SizedBox(height: 6),
                        Text(
                            '📍 ${r.city} · ${Categories.byId(r.category)?.name ?? r.category}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _propose(r),
                            child: const Text('Enviar proposta'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
