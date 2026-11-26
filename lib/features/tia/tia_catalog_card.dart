import 'package:flutter/material.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/home_layout.dart';
import '../../shared/widgets/official_icon.dart';
import '../catalog/category_browse.dart';

/// Ícone oficial identificado no catálogo, com as duas ações reais.
/// Não substitui a resposta da IA e não inventa texto de assistente.
class TiaCatalogCard extends StatelessWidget {
  final CatalogMatch match;
  const TiaCatalogCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final profession = match.profession;
    final category = match.category;
    final asset = profession?.asset256 ?? category?.asset256;
    final pending = asset == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identificado no catálogo oficial',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OfficialIcon(
                  label: match.name,
                  assetPath: asset,
                  pendingArt: pending,
                  tier: IconTier.list,
                  size: 48,
                  caption: true,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(
                  key: const Key('tia-ver-profissionais'),
                  onPressed: () {
                    if (profession != null) {
                      openProfessionList(context, profession.id);
                    } else if (category != null) {
                      openCatalogCategory(context, category);
                    }
                  },
                  child: const Text('Ver profissionais'),
                ),
                OutlinedButton(
                  key: const Key('tia-pedir-orcamento'),
                  onPressed: () {
                    if (profession != null) {
                      openQuoteForProfession(context, profession.id);
                    } else if (category != null) {
                      openCatalogCategory(context, category);
                    }
                  },
                  child: const Text('Pedir orçamento'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
