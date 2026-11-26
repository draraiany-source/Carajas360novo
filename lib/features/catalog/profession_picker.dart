import 'package:flutter/material.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/official_icon.dart';

/// Seleção de profissão usada no cadastro. O id gravado é o da profissão.
class ProfessionPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const ProfessionPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final parents = ServiceCatalog.serviceCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final parent in parents) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              parent.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textLight,
              ),
            ),
          ),
          OfficialIconGrid(
            items: ServiceCatalog.professionsOf(parent.id)
                .map(OfficialIconData.profession)
                .toList(),
            selected: selected,
            keyPrefix: 'profissao-',
            onTap: (item) => onToggle(item.id),
          ),
        ],
      ],
    );
  }
}
