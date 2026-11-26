import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/models.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/c360_ui.dart';
import '../../shared/widgets/widgets.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = c360Uid();
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const C360PageBanner(
            icon: Icons.workspace_premium_rounded,
            title: 'Planos e Assinaturas',
            subtitle:
                'O plano da sua conta no Carajás 360. Valores e contratação são confirmados com o suporte.',
          ),
          const SizedBox(height: 16),
          if (uid == null)
            const EmptyState(
              emoji: '👤',
              title: 'Faça login',
              subtitle: 'Entre para ver o plano vinculado à sua conta.',
            )
          else
            StreamBuilder<UserModel?>(
              stream: c360Stream(() => FS.userStream(uid)),
              builder: (_, snap) {
                final plan = snap.data?.plan ?? PlanTier.free;
                return Column(children: [
                  for (final tier in PlanTier.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: C360Card(
                        child: Row(children: [
                          Icon(
                            tier == plan
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: tier == plan
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_planLabel(tier),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15)),
                                Text(
                                  tier == plan
                                      ? 'Plano atual da sua conta'
                                      : 'Disponível mediante contratação',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.support),
                      child: const Text('Falar com o suporte'),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.companyProfile),
                    child: const Text('Carajás360 para Empresas'),
                  ),
                ]);
              },
            ),
        ],
      ),
    );
  }

  String _planLabel(PlanTier tier) {
    switch (tier) {
      case PlanTier.free:
        return 'Gratuito';
      case PlanTier.professional:
        return 'Profissional';
      case PlanTier.premium:
        return 'Premium';
      case PlanTier.corporate:
        return 'Empresas';
    }
  }
}
