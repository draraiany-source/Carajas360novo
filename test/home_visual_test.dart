import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/catalog/service_catalog.dart';
import 'package:servico_conecta/features/home/home_layout.dart';
import 'package:servico_conecta/shared/widgets/official_icon.dart';

void main() {
  testWidgets('grade de categorias em desktop cabe em 5 ou 6 colunas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: OfficialIconGrid(
            items: ServiceCatalog.homeCategories
                .map(OfficialIconData.category)
                .toList(),
            onTap: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(HomeLayout.columnsFor(1280), 6);
    expect(find.byType(OfficialIcon),
        findsNWidgets(ServiceCatalog.homeCategories.length));
    final box = tester.getSize(find.byType(OfficialIcon).first);
    expect(box.width, inInclusiveRange(88, 130));
  });
}
