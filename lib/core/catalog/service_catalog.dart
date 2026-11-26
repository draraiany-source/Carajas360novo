import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/service_category.dart';
import 'catalog_file_stub.dart'
    if (dart.library.io) 'catalog_file_io.dart';

/// Categoria visual do catálogo oficial (pai das profissões).
class CatalogCategory {
  final String id;
  final String name;
  final String? asset;
  final bool pendingArt;
  final bool home;
  final int homeOrder;
  final String kind;
  final String? opens;
  final bool extra;

  const CatalogCategory({
    required this.id,
    required this.name,
    required this.asset,
    required this.pendingArt,
    required this.home,
    required this.homeOrder,
    required this.kind,
    required this.opens,
    required this.extra,
  });

  bool get navigation => kind == 'navegacao';

  String? get asset512 =>
      asset == null ? null : 'assets/icons/categories/512/$asset.webp';

  String? get asset256 =>
      asset == null ? null : 'assets/icons/categories/256/$asset.webp';

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      asset: json['asset'] as String?,
      pendingArt: json['pendingArt'] == true,
      home: json['home'] == true,
      homeOrder: (json['homeOrder'] as num?)?.toInt() ?? 0,
      kind: json['kind'] as String? ?? 'servico',
      opens: json['opens'] as String?,
      extra: json['extra'] == true,
    );
  }
}

/// Profissão / subcategoria. O [id] é o valor gravado no Firestore.
class CatalogProfession {
  final String id;
  final String name;
  final String emoji;
  final String group;
  final int color;
  final String categoryId;
  final String? asset;
  final List<String> keywords;

  const CatalogProfession({
    required this.id,
    required this.name,
    required this.emoji,
    required this.group,
    required this.color,
    required this.categoryId,
    required this.asset,
    required this.keywords,
  });

  String? get asset512 =>
      asset == null ? null : 'assets/icons/subcategories/512/$asset.webp';

  String? get asset256 =>
      asset == null ? null : 'assets/icons/subcategories/256/$asset.webp';

  ServiceCategory asServiceCategory() => ServiceCategory(
        id: id,
        name: name,
        emoji: emoji,
        group: group,
        color: Color(color),
      );

  factory CatalogProfession.fromJson(Map<String, dynamic> json) {
    return CatalogProfession(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '•',
      group: json['group'] as String? ?? '',
      color: (json['color'] as num?)?.toInt() ?? 0xFF146B34,
      categoryId: json['categoryId'] as String,
      asset: json['asset'] as String?,
      keywords: ((json['keywords'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
    );
  }
}

/// Resultado de identificar um texto no catálogo. Não é resposta de IA.
class CatalogMatch {
  final String kind;
  final String id;
  final String name;
  final String categoryId;
  final CatalogProfession? profession;
  final CatalogCategory? category;

  const CatalogMatch({
    required this.kind,
    required this.id,
    required this.name,
    required this.categoryId,
    this.profession,
    this.category,
  });

  bool get isProfession => kind == 'profissao';
}

/// Fonte única do catálogo oficial. O JSON em
/// `functions/data/catalogo_categorias.json` também é lido pelas Cloud Functions.
abstract final class ServiceCatalog {
  static const assetPath = 'functions/data/catalogo_categorias.json';

  static bool _ready = false;
  static List<CatalogCategory> _categories = const [];
  static List<CatalogProfession> _professions = const [];
  static final Map<String, CatalogProfession> _byProfession = {};
  static final Map<String, CatalogCategory> _byCategory = {};

  static Future<void> load() async {
    if (_ready) return;
    final raw = await rootBundle.loadString(assetPath);
    _parse(raw);
  }

  static void ensureSync() {
    if (_ready) return;
    final raw = readCatalogFileSync();
    if (raw == null) {
      throw StateError(
          'Catálogo de categorias não carregado. Chame ServiceCatalog.load().');
    }
    _parse(raw);
  }

  static void _parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _categories = ((json['categories'] as List?) ?? const [])
        .map((e) => CatalogCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _professions = ((json['professions'] as List?) ?? const [])
        .map((e) => CatalogProfession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _byProfession
      ..clear()
      ..addEntries(_professions.map((p) => MapEntry(p.id, p)));
    _byCategory
      ..clear()
      ..addEntries(_categories.map((c) => MapEntry(c.id, c)));
    _ready = true;
  }

  static List<CatalogCategory> get categories {
    ensureSync();
    return _categories;
  }

  static List<CatalogProfession> get professions {
    ensureSync();
    return _professions;
  }

  static List<CatalogCategory> get homeCategories {
    final list = categories.where((c) => c.home).toList();
    list.sort((a, b) => a.homeOrder.compareTo(b.homeOrder));
    return list;
  }

  /// Categorias que a home não mostra: Saúde, Educação e os grupos sem arte.
  static List<CatalogCategory> get extraCategories =>
      categories.where((c) => c.kind == 'servico' && !c.home).toList();

  static List<CatalogCategory> get serviceCategories =>
      categories.where((c) => c.kind == 'servico').toList();

  static CatalogCategory? categoryById(String id) {
    ensureSync();
    return _byCategory[id];
  }

  static CatalogProfession? professionById(String id) {
    ensureSync();
    return _byProfession[id];
  }

  static List<CatalogProfession> professionsOf(String categoryId) =>
      professions.where((p) => p.categoryId == categoryId).toList();

  static String labelOf(String id) =>
      professionById(id)?.name ?? categoryById(id)?.name ?? id;

  /// Casa o texto com a profissão ou a categoria. Frase mais longa vence.
  /// Profissões são avaliadas antes: empate fica com a profissão.
  static CatalogMatch? matchText(String text) {
    final folded = fold(text);
    if (folded.isEmpty) return null;
    CatalogMatch? best;
    var bestLen = 0;
    void consider(List<String> phrases, CatalogMatch match) {
      for (final phrase in phrases) {
        final token = fold(phrase);
        if (token.length < 4) continue;
        if (folded.contains(token) && token.length > bestLen) {
          best = match;
          bestLen = token.length;
        }
      }
    }

    for (final profession in professions) {
      consider(
        [profession.name, ...profession.keywords],
        CatalogMatch(
          kind: 'profissao',
          id: profession.id,
          name: profession.name,
          categoryId: profession.categoryId,
          profession: profession,
          category: categoryById(profession.categoryId),
        ),
      );
    }
    for (final category in categories) {
      if (category.navigation) continue;
      consider(
        [category.name],
        CatalogMatch(
          kind: 'categoria',
          id: category.id,
          name: category.name,
          categoryId: category.id,
          category: category,
        ),
      );
    }
    return best;
  }

  static String fold(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    var text = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

/// Lista plana das profissões. O [group] legado permanece para aluguel
/// e para telas que filtram por segmento antigo.
abstract class Categories {
  static List<ServiceCategory> get all => ServiceCatalog.professions
      .map((p) => p.asServiceCategory())
      .toList(growable: false);

  static List<String> get groups {
    final seen = <String>[];
    for (final category in all) {
      if (!seen.contains(category.group)) seen.add(category.group);
    }
    return seen;
  }

  static ServiceCategory? byId(String id) =>
      ServiceCatalog.professionById(id)?.asServiceCategory();
}
