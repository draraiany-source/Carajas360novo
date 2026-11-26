import '../../core/catalog/service_catalog.dart';
import '../../shared/models/models.dart';

bool providerMatchesCategory(ProviderModel provider, String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) return true;
  if (provider.categories.contains(categoryId)) return true;
  final children =
      ServiceCatalog.professionsOf(categoryId).map((p) => p.id).toSet();
  if (children.isEmpty) return false;
  return provider.categories.any(children.contains);
}

List<ProviderModel> applyProviderFilters({
  required List<ProviderModel> source,
  required String query,
  String? categoryId,
  required bool onlineOnly,
  required bool verifiedOnly,
  required bool cityOnly,
  required bool availableToday,
  required String city,
  required String sort,
}) {
  var list = source.where((p) => providerMatchesCategory(p, categoryId)).toList();
  if (query.trim().isNotEmpty) {
    final q = query.toLowerCase();
    list = list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.categories.any((c) =>
                c.toLowerCase().contains(q) ||
                ServiceCatalog.labelOf(c).toLowerCase().contains(q)) ||
            (p.bio ?? '').toLowerCase().contains(q))
        .toList();
  }
  if (onlineOnly) {
    list = list.where((p) => p.modalities.contains('online')).toList();
  }
  if (verifiedOnly) {
    list = list.where((p) => p.verified).toList();
  }
  if (availableToday) {
    list = list
        .where((p) => p.availableToday || p.availabilitySlots.isNotEmpty)
        .toList();
  }
  if (cityOnly) {
    list = list
        .where((p) => (p.city ?? '').toLowerCase() == city.toLowerCase())
        .toList();
  }
  if (sort == 'reviews') {
    list.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
  } else if (sort == 'price_asc') {
    list.sort((a, b) =>
        (a.minPrice ?? double.infinity).compareTo(b.minPrice ?? double.infinity));
  } else {
    list.sort((a, b) => b.rating.compareTo(a.rating));
  }
  return list;
}
