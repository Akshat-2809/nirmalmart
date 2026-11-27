import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../prefs.dart';
import 'models.dart';

/// Catalogue reads, same calls as the website's Home page. They go without the login token so the
/// CDN can cache them (see ApiClient).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final r = await ref.watch(apiClientProvider).dio.get<List<dynamic>>('/categories');
  return [for (final c in r.data!) Category.fromJson(c as Map<String, dynamic>)];
});

/// Every product, newest first (the backend allows up to 100 per page; the shop has ~60)
final allProductsProvider = FutureProvider<List<Product>>(
  (ref) => _products(ref, {'sort_by': 'newest', 'per_page': 100}),
);

final trendingProductsProvider = FutureProvider<List<Product>>(
  (ref) => _products(ref, {'trending': true, 'sort_by': 'newest', 'per_page': 24}),
);

/// Products by id, in the order asked for; ids of removed products are dropped
final productsByIdsProvider = FutureProvider.family<List<Product>, String>((ref, csv) async {
  if (csv.isEmpty) return const [];
  final ids = csv.split(',').map(int.parse).toList();
  final found = await _products(ref, {'ids': csv, 'per_page': ids.length.clamp(1, 100)});
  final byId = {for (final p in found) p.id: p};
  return [for (final id in ids) ?byId[id]];
});

Future<List<Product>> _products(Ref ref, Map<String, Object> query) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/products', queryParameters: query);
  return [for (final p in r.data!['items'] as List) Product.fromJson(p as Map<String, dynamic>)];
}

/// Whether the owner shows the offer carousel (Admin → Settings). Until the server answers, the last
/// answer seen is used, so the banner doesn't pop in or out on every start.
final showBannerProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPrefsProvider);
  try {
    final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/settings');
    final show = r.data!['show_banner'] != false;
    await prefs.setBool('nm_show_banner', show);
    return show;
  } catch (_) {
    return prefs.getBool('nm_show_banner') ?? true;
  }
});

