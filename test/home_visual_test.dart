import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/features/home/home_layout.dart';
import 'package:servico_conecta/shared/widgets/c360_ui.dart';

void main() {
  testWidgets('grade de categorias em largura de desktop 1280', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1032, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: HomeLayout.tileMaxCrossAxisExtent,
            mainAxisExtent: HomeLayout.tileMainAxisExtent,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: C360Categories.home.length,
          itemBuilder: (_, i) => C360CategoryTile(
            category: C360Categories.home[i],
            onTap: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byType(C360CategoryTile).first);
    expect(box.width, lessThanOrEqualTo(168));
    expect(box.height, lessThanOrEqualTo(112));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/categorias_desktop.png'),
    );
  });
}
