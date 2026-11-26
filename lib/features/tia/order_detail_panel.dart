import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../home/provider_profile_screen.dart';
import '../support/support_screens.dart';
import 'tia_schedule_screen.dart';

class OrderDetailPanel extends StatelessWidget {
  final OrderModel order;
  const OrderDetailPanel({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _steps(order.status);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(order.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        Text('Pedido ${order.id}', style: const TextStyle(color: AppColors.textLight)),
        const SizedBox(height: 12),
        Text(order.price == null ? 'Valor ainda não definido' : 'R\$ ${order.price!.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.primary)),
        const SizedBox(height: 12),
        if (order.status == OrderStatus.cancelled)
          const Text('Pedido cancelado. A linha do tempo não segue como se ele tivesse sido concluído.')
        else
          Row(children: [
            for (final step in steps)
              Expanded(
                child: Column(children: [
                  Icon(step.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      color: step.current ? AppColors.primary : AppColors.textLight),
                  const SizedBox(height: 4),
                  Text(step.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ]),
        const SizedBox(height: 16),
        if ((order.providerId ?? '').isEmpty)
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profissional ainda não definido'),
          )
        else
          StreamBuilder<ProviderModel?>(
            stream: c360Stream(() => FS.providerStream(order.providerId!)),
            builder: (context, snap) {
              final provider = snap.data;
              return ListTile(
                leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                title: Text(provider?.name.isNotEmpty == true ? provider!.name : 'Profissional'),
                subtitle: Text(provider == null
                    ? 'Carregando cadastro…'
                    : (provider.rating == 0
                        ? 'Sem avaliações'
                        : '${provider.rating.toStringAsFixed(1)} (${provider.totalReviews} avaliações)')),
                trailing: TextButton(
                  onPressed: () => c360Open(
                    context,
                    route: Routes.providerProfile,
                    arguments: {
                      'providerId': order.providerId,
                      'providerName': provider?.name ?? 'Profissional',
                      'category': order.category,
                    },
                    page: ProviderProfileScreen(
                      providerId: order.providerId!,
                      providerName: provider?.name ?? 'Profissional',
                      category: order.category,
                    ),
                  ),
                  child: const Text('Ver perfil'),
                ),
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.place_outlined),
          title: const Text('Local do serviço'),
          subtitle: Text(order.address.isEmpty ? 'Endereço não informado' : order.address),
        ),
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: const Text('Pagamento'),
          subtitle: Text(_payment(order.paymentStatus)),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => c360Open(
              context,
              route: Routes.tiaSchedule,
              page: TiaScheduleScreen(
                category: order.category,
                providerId: order.providerId,
              ),
            ),
            icon: const Icon(Icons.event_repeat_rounded),
            label: const Text('Reagendar'),
          ),
          OutlinedButton.icon(
            onPressed: () => c360Open(
              context,
              route: Routes.support,
              page: const SupportScreen(),
            ),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Solicitar suporte'),
          ),
          if (order.status == OrderStatus.completed && !order.reviewed)
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.reviews, arguments: {
                'orderId': order.id,
                'providerId': order.providerId,
              }),
              icon: const Icon(Icons.star_rounded),
              label: const Text('Concluir e avaliar'),
            ),
        ]),
      ],
    );
  }

  String _payment(String? status) {
    switch (status) {
      case 'paid':
        return 'Pago';
      case 'pending':
        return 'Pagamento pendente';
      case 'unpaid':
        return 'Ainda não pago';
      case null:
      case '':
        return 'Situação de pagamento não informada';
      default:
        return status;
    }
  }
}

class _Step {
  final String label;
  final bool done;
  final bool current;
  const _Step(this.label, this.done, this.current);
}

List<_Step> _steps(OrderStatus status) {
  const labels = ['Solicitação', 'Aceito', 'Em execução', 'Concluído'];
  final index = switch (status) {
    OrderStatus.pending => 0,
    OrderStatus.accepted => 1,
    OrderStatus.inProgress => 2,
    OrderStatus.completed => 3,
    OrderStatus.cancelled => -1,
    OrderStatus.disputed => 2,
  };
  return [
    for (var i = 0; i < labels.length; i++)
      _Step(labels[i], index >= i, index == i),
  ];
}

void openOrderDetail(BuildContext context, OrderModel order) {
  c360Open(
    context,
    route: Routes.myOrders,
    page: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Acompanhar pedido')),
      body: OrderDetailPanel(order: order),
    ),
  );
}
