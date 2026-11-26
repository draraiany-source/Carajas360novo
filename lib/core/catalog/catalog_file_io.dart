import 'dart:io';

/// Leitura síncrona só na VM (testes e ferramentas). No aparelho o arquivo
/// não está no disco: o app usa [rootBundle].
String? readCatalogFileSync() {
  final file = File('functions/data/catalogo_categorias.json');
  if (!file.existsSync()) return null;
  return file.readAsStringSync();
}
