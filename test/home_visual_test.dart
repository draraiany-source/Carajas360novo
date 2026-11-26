import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/catalog/service_catalog.dart';
import 'package:servico_conecta/features/home/home_layout.dart';
import 'package:servico_conecta/shared/widgets/official_icon.dart';

void main() {
  testWidgets('grade de categorias em largura de desktop 1280', (tester) async {
    const width = 1032.0;
    await tester.binding.setSurfaceSize(const Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
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
    final box = tester.getRect(find.byType(OfficialIcon).first);
    final columns = HomeLayout.columnsFor(width - 40);
    expect(columns, 5);
    expect(box.width, greaterThanOrEqualTo(140));
    expect(box.height, greaterThanOrEqualTo(140));
    expect(find.byType(OfficialIcon), findsNWidgets(ServiceCatalog.homeCategories.length));
  });
}
