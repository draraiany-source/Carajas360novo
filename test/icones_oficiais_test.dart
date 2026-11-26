import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/catalog/service_catalog.dart';
import 'package:servico_conecta/core/constants/app_constants.dart';
import 'package:servico_conecta/features/catalog/category_browse.dart';
import 'package:servico_conecta/features/catalog/profession_picker.dart';
import 'package:servico_conecta/features/catalog/provider_filters.dart';
import 'package:servico_conecta/features/home/home_screen.dart';
import 'package:servico_conecta/features/orders/orders_screen.dart';
import 'package:servico_conecta/features/tia/tia_catalog_card.dart';
import 'package:servico_conecta/shared/models/models.dart';
import 'package:servico_conecta/shared/widgets/c360_nav.dart';
import 'package:servico_conecta/shared/widgets/official_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ServiceCatalog.load();
  });

  test('catálogo preserva ids legados e o serralheiro novo', () {
    expect(ServiceCatalog.professionById('eletricista'), isNotNull);
    expect(ServiceCatalog.professionById('pedreiro')!.categoryId,
        'construcao-e-reforma');
    expect(ServiceCatalog.professionById('pintor')!.categoryId,
        'construcao-e-reforma');
    expect(ServiceCatalog.professionById('marceneiro')!.categoryId,
        'construcao-e-reforma');
    expect(ServiceCatalog.professionById('serralheiro')!.categoryId,
        'construcao-e-reforma');
    expect(ServiceCatalog.professionById('encanador')!.categoryId, 'hidraulica');
    expect(ServiceCatalog.professionById('diarista')!.categoryId, 'limpeza');
    expect(ServiceCatalog.professionById('mecanico')!.categoryId,
        'veiculos-e-oficinas');
    expect(ServiceCatalog.professionById('jardineiro')!.categoryId, 'agro-e-rural');
    expect(ServiceCatalog.professionById('ar_condicionado')!.categoryId,
        'maquinas-e-equipamentos');
    expect(ServiceCatalog.professionById('ar_condicionado')!.asset,
        'tecnico-ar-condicionado');
    expect(Categories.byId('eletricista')!.group, 'Casa');
    expect(Categories.byId('odontologia')!.name, 'Odontologia');
    final ids = Categories.all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Máquinas e Ver Todas aguardam arte e não apontam arquivo', () {
    final maquinas = ServiceCatalog.categoryById('maquinas-e-equipamentos')!;
    final verTodas = ServiceCatalog.categoryById('ver-todas')!;
    expect(maquinas.pendingArt, isTrue);
    expect(maquinas.asset, isNull);
    expect(verTodas.pendingArt, isTrue);
    expect(verTodas.asset, isNull);
    expect(ServiceCatalog.categoryById('saude-e-bem-estar')!.asset,
        'saude-e-bem-estar');
    expect(ServiceCatalog.categoryById('educacao-e-cursos')!.home, isFalse);
  });

  test('Tia reconhece ar-condicionado e eletricista no catálogo', () {
    final ar = ServiceCatalog.matchText('consertar meu ar-condicionado');
    expect(ar, isNotNull);
    expect(ar!.id, 'ar_condicionado');
    expect(ar.kind, 'profissao');
    final luz = ServiceCatalog.matchText('preciso de eletricista');
    expect(luz!.id, 'eletricista');
    expect(ServiceCatalog.matchText(''), isNull);
  });

  test('filtros de busca por profissão, cidade e texto', () {
    final now = DateTime.utc(2026, 1, 1);
    final list = [
      ProviderModel(
        id: '1',
        userId: '1',
        name: 'Ana Pedras',
        city: 'Canaã dos Carajás',
        categories: const ['pedreiro'],
        verified: true,
        rating: 4,
        createdAt: now,
      ),
      ProviderModel(
        id: '2',
        userId: '2',
        name: 'Bruno Fios',
        city: 'Parauapebas',
        categories: const ['eletricista'],
        modalities: const ['online'],
        verified: false,
        rating: 5,
        createdAt: now,
      ),
    ];
    final pedreiros = applyProviderFilters(
      source: list,
      query: '',
      categoryId: 'pedreiro',
      onlineOnly: false,
      verifiedOnly: false,
      cityOnly: true,
      availableToday: false,
      city: 'Canaã dos Carajás',
      sort: 'rating',
    );
    expect(pedreiros.map((p) => p.id), ['1']);
    final obra = applyProviderFilters(
      source: list,
      query: 'ana',
      categoryId: 'construcao-e-reforma',
      onlineOnly: false,
      verifiedOnly: false,
      cityOnly: false,
      availableToday: false,
      city: '',
      sort: 'rating',
    );
    expect(obra.single.id, '1');
    final online = applyProviderFilters(
      source: list,
      query: '',
      categoryId: null,
      onlineOnly: true,
      verifiedOnly: false,
      cityOnly: false,
      availableToday: false,
      city: '',
      sort: 'rating',
    );
    expect(online.single.id, '2');
  });

  test('cada WebP oficial carrega no bundle', () async {
    Future<void> expectAsset(String? path) async {
      expect(path, isNotNull);
      final data = await rootBundle.load(path!);
      expect(data.lengthInBytes, greaterThan(400), reason: path);
    }

    for (final category in ServiceCatalog.categories) {
      if (category.asset == null) continue;
      await expectAsset(category.asset512);
      await expectAsset(category.asset256);
    }
    final withArt =
        ServiceCatalog.professions.where((p) => p.asset != null).toList();
    expect(withArt.length, 10);
    for (final profession in withArt) {
      await expectAsset(profession.asset512);
      await expectAsset(profession.asset256);
    }
  });

  testWidgets('ícone oficial mostra a arte e o tile neutro sem texto duplicado',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(children: [
          const SizedBox(
            width: 160,
            height: 160,
            child: OfficialIcon(
              label: 'Elétrica',
              assetPath: 'assets/icons/categories/256/eletrica.webp',
            ),
          ),
          const SizedBox(
            width: 160,
            height: 160,
            child: OfficialIcon(
              label: 'Máquinas e Equipamentos',
              pendingArt: true,
            ),
          ),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.bySemanticsLabel('Elétrica'), findsOneWidget);
    expect(find.text('Elétrica'), findsNothing);
    expect(find.text('Máquinas e Equipamentos'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('cada categoria e subcategoria navega e volta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;
        final view = args?['view'] as String?;
        final category = args?['category'] as String?;
        if (settings.name == Routes.search && view == 'sub' && category != null) {
          return MaterialPageRoute(
              builder: (_) => SubcategoryScreen(categoryId: category));
        }
        if (settings.name == Routes.search && view == 'board') {
          return MaterialPageRoute(
            builder: (_) => CategoryBoardScreen(
              mode: args?['mode'] == 'extras'
                  ? CategoryBoardMode.extras
                  : CategoryBoardMode.all,
            ),
          );
        }
        if (settings.name == Routes.search) {
          return MaterialPageRoute(
            builder: (_) => SearchScreen(
              initialCategory: category,
              mode: SearchMode.professionals,
              seedProviders: const [],
            ),
          );
        }
        return null;
      },
      home: Scaffold(
        body: Builder(
          builder: (context) => ListView(
            children: [
              OfficialIconGrid(
                items: ServiceCatalog.homeCategories
                    .map(OfficialIconData.category)
                    .toList(),
                keyPrefix: 'categoria-',
                onTap: (item) => openCatalogCategory(
                    context, ServiceCatalog.categoryById(item.id)!),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    for (final category in ServiceCatalog.homeCategories) {
      await tester.ensureVisible(find.byKey(Key('categoria-${category.id}')));
      await tester.tap(find.byKey(Key('categoria-${category.id}')));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsWidgets);
      if (category.navigation) {
        expect(find.byType(CategoryBoardScreen), findsOneWidget);
      } else {
        expect(find.byType(SubcategoryScreen), findsOneWidget);
        final first = ServiceCatalog.professionsOf(category.id).first;
        await tester.ensureVisible(find.byKey(Key('profissao-${first.id}')));
        await tester.tap(find.byKey(Key('profissao-${first.id}')));
        await tester.pumpAndSettle();
        expect(find.text('Ainda não há profissionais cadastrados nesta categoria'),
            findsOneWidget);
        expect(find.byKey(Key('lista-${first.id}')), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(Key('categoria-eletrica')), findsOneWidget);
    }
  });

  testWidgets('busca com semente vazia, filtro e cadastro selecionam a profissão',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: SearchScreen(
        initialCategory: 'encanador',
        mode: SearchMode.professionals,
        seedProviders: const [],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ainda não há profissionais cadastrados nesta categoria'),
        findsOneWidget);
    await tester.tap(find.text('Verificados'));
    await tester.pump();
    expect(find.text('Nenhum resultado'), findsOneWidget);

    var selected = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          return SingleChildScrollView(
            child: ProfessionPicker(
              selected: selected,
              onToggle: (id) => setState(() {
                if (selected.contains(id)) {
                  selected.remove(id);
                } else {
                  selected.add(id);
                }
              }),
            ),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profissao-pedreiro')));
    await tester.tap(find.byKey(const Key('profissao-pedreiro')));
    await tester.pump();
    expect(selected, contains('pedreiro'));
  });

  testWidgets('orçamento mostra o ícone da categoria sem repetir o nome',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: RequestServiceScreen(
        providerId: 'p1',
        providerName: 'Oficina do Zé',
        category: 'mecanico',
      ),
    ));
    await tester.pump();
    expect(find.text('Solicitar orçamento'), findsOneWidget);
    expect(find.text('Oficina do Zé'), findsOneWidget);
    expect(find.bySemanticsLabel('Mecânico'), findsOneWidget);
    expect(find.text('Mecânico'), findsNothing);
    expect(find.text('Descreva o que você precisa *'), findsOneWidget);
  });

  testWidgets('cartão da Tia oferece profissionais e orçamento', (tester) async {
    String? opened;
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        opened = '${settings.name}:${settings.arguments}';
        return MaterialPageRoute(
            builder: (_) => Scaffold(body: Text(opened!)));
      },
      home: Scaffold(
        body: TiaCatalogCard(
          match: ServiceCatalog.matchText('consertar meu ar-condicionado')!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Técnico em Ar-Condicionado'), findsOneWidget);
    expect(find.text('Técnico em Ar-Condicionado'), findsNothing);
    await tester.tap(find.byKey(const Key('tia-ver-profissionais')));
    await tester.pumpAndSettle();
    expect(opened, contains('ar_condicionado'));
    expect(find.text('Pedir orçamento'), findsNothing);
  });

  testWidgets('captura as telas pedidas', (tester) async {
    if (!autoUpdateGoldenFiles) return;
    final dir = Directory('/tmp/c360_shots');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    final previous = goldenFileComparator;
    goldenFileComparator = LocalFileComparator(Uri.file('${dir.path}/base.png'));
    addTearDown(() => goldenFileComparator = previous);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final preload = tester.element(find.byType(SizedBox));
    final paths = <String>{
      for (final category in ServiceCatalog.categories) ...[
        if (category.asset256 != null) category.asset256!,
        if (category.asset512 != null) category.asset512!,
      ],
      for (final profession in ServiceCatalog.professions) ...[
        if (profession.asset256 != null) profession.asset256!,
        if (profession.asset512 != null) profession.asset512!,
      ],
    };
    for (final path in paths) {
      await tester.runAsync(() => precacheImage(AssetImage(path), preload));
    }
    await tester.pump();

    Future<void> grab(String name, Size size, Widget child) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(key: const Key('shot-boundary'), child: child),
        ),
      ));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      await expectLater(
        find.byKey(const Key('shot-boundary')),
        matchesGoldenFile('$name.png'),
      );
      expect(File('${dir.path}/$name.png').lengthSync(), greaterThan(2000));
    }

    Widget homeGrid() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Categorias de Serviços',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            OfficialIconGrid(
              items: ServiceCatalog.homeCategories
                  .map(OfficialIconData.category)
                  .toList(),
              onTap: (_) {},
            ),
          ],
        );

    const desktop = Size(1280, 800);
    const mobile = Size(390, 844);
    await grab('home_desktop', desktop, homeGrid());
    await grab('home_mobile', mobile, homeGrid());
    await grab(
      'subcategoria_desktop',
      desktop,
      const SubcategoryScreen(categoryId: 'construcao-e-reforma'),
    );
    await grab(
      'subcategoria_mobile',
      mobile,
      const SubcategoryScreen(categoryId: 'eletrica'),
    );
    await grab(
      'profissionais_desktop',
      desktop,
      SearchScreen(
        initialCategory: 'serralheiro',
        mode: SearchMode.professionals,
        seedProviders: const [],
      ),
    );
    await grab(
      'profissionais_mobile',
      mobile,
      SearchScreen(
        initialCategory: 'diarista',
        mode: SearchMode.professionals,
        seedProviders: [
          ProviderModel(
            id: 'demo-1',
            userId: 'demo-1',
            name: 'Exemplo · diarista (demonstração)',
            city: 'Canaã dos Carajás',
            categories: const ['diarista'],
            bio: 'Cartão de demonstração. Não é um profissional cadastrado.',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      ),
    );
    await grab(
      'cadastro_desktop',
      desktop,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cadastro de prestador',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('Categorias de atuação'),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: ProfessionPicker(
                    selected: const {'pedreiro'},
                    onToggle: _noop,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await grab(
      'cadastro_mobile',
      mobile,
      SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: ProfessionPicker(selected: const {}, onToggle: _noop),
      ),
    );
    await grab(
      'tia_desktop',
      desktop,
      TiaCatalogCard(
          match: ServiceCatalog.matchText('consertar meu ar-condicionado')!),
    );
    await grab(
      'tia_mobile',
      mobile,
      TiaCatalogCard(match: ServiceCatalog.matchText('preciso de eletricista')!),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

void _noop(String _) {}
