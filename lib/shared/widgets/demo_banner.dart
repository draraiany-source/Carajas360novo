import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Faixa fixa. Só aparece no modo de demonstração local, com Firebase desligado.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7A5B00),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'DEMONSTRAÇÃO — exemplos locais, sem cadastro, avaliação ou pagamento reais. '
            'Nada aqui é um profissional de Canaã dos Carajás.',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
