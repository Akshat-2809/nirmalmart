import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../prefs.dart';
import 'models.dart';
import 'smart_search.dart';

/// The last 8 searches, newest first, kept on the phone
final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(RecentSearches.new);

class RecentSearches extends Notifier<List<String>> {
  static const _key = 'nm_recent_searches';

  @override
  List<String> build() => ref.watch(sharedPrefsProvider).getStringList(_key) ?? const [];

  Future<void> add(String q) async {
    final t = q.trim();
    if (t.isEmpty) return;
    state = [t, ...state.where((x) => x.toLowerCase() != t.toLowerCase())].take(8).toList();
    await ref.read(sharedPrefsProvider).setStringList(_key, state);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPrefsProvider).remove(_key);
  }
}

/// Up to 6 quick suggestions while typing, best name matches first
final suggestionsProvider = FutureProvider.family<List<Product>, String>((ref, q) async {
  final r = await ref.watch(apiClientProvider).dio.get<List<dynamic>>('/products/suggest', queryParameters: {'q': q});
  return SmartSearch.rank([for (final p in r.data!) Product.fromJson(p as Map<String, dynamic>)], q);
});

enum SearchSort {
  best('popular'),
  priceLow('price_low'),
  priceHigh('price_high'),
  discount('discount'),
  newest('newest');

  const SearchSort(this.api);
  final String api;
}

class SearchQuery {
  const SearchQuery(this.text, {this.sort = SearchSort.best, this.inStock = false, this.maxPrice});

  final String text;
  final SearchSort sort;
  final bool inStock;
  final int? maxPrice;

  bool get filtered => inStock || maxPrice != null;

  SearchQuery copyWith({SearchSort? sort, bool? inStock, int? Function()? maxPrice}) =>
      SearchQuery(text, sort: sort ?? this.sort, inStock: inStock ?? this.inStock, maxPrice: maxPrice == null ? this.maxPrice : maxPrice());

  bool keeps(Product p) => (!inStock || !p.soldOut) && (maxPrice == null || p.price <= maxPrice!);

  @override
  bool operator ==(Object other) =>
      other is SearchQuery && other.text == text && other.sort == sort && other.inStock == inStock && other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(text, sort, inStock, maxPrice);
}

/// Full results from the server (same search as the website), name matches first for "Best match"
final searchResultsProvider = FutureProvider.family<List<Product>, SearchQuery>((ref, q) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/products', queryParameters: {
    'search': q.text,
    'per_page': 100,
    'sort_by': q.sort.api,
    if (q.inStock) 'in_stock': true,
    if (q.maxPrice != null) 'max_price': q.maxPrice,
  });
  final items = [for (final p in r.data!['items'] as List) Product.fromJson(p as Map<String, dynamic>)];
  return q.sort == SearchSort.best ? SmartSearch.rank(items, q.text) : items;
});
