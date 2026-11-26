import 'package:flutter/material.dart';

import '../../core/catalog/service_catalog.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/c360_nav.dart';
import '../../shared/widgets/official_icon.dart';

enum CategoryBoardMode { all, extras }

/// Abre a categoria no shell quando ele existe; senão, pela rota nomeada.
void openCatalogCategory(BuildContext context, CatalogCategory category) {
  final Widget page;
  final Map<String, dynamic> args;
  if (category.opens == 'todas') {
    page = const CategoryBoardScreen(mode: CategoryBoardMode.all);
    args = {'view': 'board', 'mode': 'all'};
  } else if (category.opens == 'extras') {
    page = const CategoryBoardScreen(mode: CategoryBoardMode.extras);
    args = {'view': 'board', 'mode': 'extras'};
  } else {
    page = SubcategoryScreen(categoryId: category.id);
    args = {'view': 'sub', 'category': category.id};
  }
  final nav = C360Nav.maybeOf(context);
  if (nav != null) {
    nav.push(page);
    return;
  }
  Navigator.pushNamed(context, Routes.search, arguments: args);
}

void openProfessionList(BuildContext context, String professionId) {
  Navigator.pushNamed(
    context,
    Routes.search,
    arguments: {'category': professionId, 'mode': 'professionals'},
  );
}

void openQuoteForProfession(BuildContext context, String professionId) {
  Navigator.pushNamed(
    context,
    Routes.tiaRequest,
    arguments: {'category': professionId},
  );
}

class CategoryBoardScreen extends StatelessWidget {
  final CategoryBoardMode mode;
  const CategoryBoardScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final items = mode == CategoryBoardMode.extras
        ? ServiceCatalog.extraCategories
        : ServiceCatalog.serviceCategories;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        leading: BackButton(onPressed: () => c360Pop(context)),
        title: Text(mode == CategoryBoardMode.extras
            ? 'Mais Categorias'
            : 'Todas as categorias'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          OfficialIconGrid(
            items: items.map(OfficialIconData.category).toList(),
            keyPrefix: 'categoria-',
            onTap: (item) {
              final category = ServiceCatalog.categoryById(item.id);
              if (category != null) openCatalogCategory(context, category);
            },
          ),
        ],
      ),
    );
  }
}

class SubcategoryScreen extends StatelessWidget {
  final String categoryId;
  const SubcategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final category = ServiceCatalog.categoryById(categoryId);
    final professions = ServiceCatalog.professionsOf(categoryId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        leading: BackButton(key: const Key('voltar'), onPressed: () => c360Pop(context)),
        title: Text(category?.name ?? 'Subcategorias'),
      ),
      body: professions.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não há profissionais cadastrados nesta categoria',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                OfficialIconGrid(
                  items: professions.map(OfficialIconData.profession).toList(),
                  keyPrefix: 'profissao-',
                  onTap: (item) => openProfessionList(context, item.id),
                ),
              ],
            ),
    );
  }
}
