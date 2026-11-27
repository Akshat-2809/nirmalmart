import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'models.dart';

enum ShopSort {
  newest('newest'),
  priceLow('price_low'),
  priceHigh('price_high'),
  discount('discount'),
  popular('popular');

  const ShopSort(this.api);
  final String api;

  static ShopSort parse(String? v) => ShopSort.values.firstWhereOrNull((s) => s.api == v) ?? ShopSort.newest;
}

/// What the Shop shows. Same query parameters as the website's /shop page, so the links on Home
/// (/shop?category=…, ?trending=true, ?max_price=999, ?sort_by=discount) open the same list.
class ShopFilters {
  const ShopFilters({
    this.category,
    this.trending = false,
    this.sort = ShopSort.newest,
    this.inStock = false,
    this.minPrice,
    this.maxPrice,
    this.brands = const {},
  });

  factory ShopFilters.fromQuery(Map<String, List<String>> q) {
    String? one(String k) => (q[k]?.isEmpty ?? true) ? null : q[k]!.first;
    int? number(String k) => double.tryParse(one(k) ?? '')?.round();
    return ShopFilters(
      category: one('category'),
      trending: one('trending') == 'true',
      sort: ShopSort.parse(one('sort_by')),
      inStock: one('in_stock') == 'true',
      minPrice: number('min_price'),
      maxPrice: number('max_price'),
      brands: {...?q['brand']},
    );
  }

  final String? category; // slug
  final bool trending;
  final ShopSort sort;
  final bool inStock;
  final int? minPrice;
  final int? maxPrice;
  final Set<String> brands;

  bool get hasPrice => minPrice != null || maxPrice != null;

  /// How many filters are on (the number on the Filters button; category and sort don't count)
  int get count => (inStock ? 1 : 0) + (hasPrice ? 1 : 0) + brands.length;

  ShopFilters copyWith({
    String? Function()? category,
    bool? trending,
    ShopSort? sort,
    bool? inStock,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    Set<String>? brands,
  }) =>
      ShopFilters(
        category: category == null ? this.category : category(),
        trending: trending ?? this.trending,
        sort: sort ?? this.sort,
        inStock: inStock ?? this.inStock,
        minPrice: minPrice == null ? this.minPrice : minPrice(),
        maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
        brands: brands ?? this.brands,
      );

  /// Keeps what's being browsed (category / trending, sort), drops the filters
  ShopFilters cleared() => ShopFilters(category: category, trending: trending, sort: sort);

  Map<String, Object> query({required int page, required int perPage}) => {
        'page': page,
        'per_page': perPage,
        'sort_by': sort.api,
        'category': ?category,
        if (trending) 'trending': true,
        if (inStock) 'in_stock': true,
        'min_price': ?minPrice,
        'max_price': ?maxPrice,
        if (brands.isNotEmpty) 'brand': brands.toList()..sort(),
      };

  static const _brandsEq = SetEquality<String>();

  @override
  bool operator ==(Object other) =>
      other is ShopFilters &&
      other.category == category &&
      other.trending == trending &&
      other.sort == sort &&
      other.inStock == inStock &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      _brandsEq.equals(other.brands, brands);

  @override
  int get hashCode => Object.hash(category, trending, sort, inStock, minPrice, maxPrice, _brandsEq.hash(brands));
}

class ShopPage {
  const ShopPage(this.items, this.total, this.pages);

  final List<Product> items;
  final int total;
  final int pages;
}

const shopPageSize = 24;

/// One page of the Shop list (pages load as you scroll)
final shopPageProvider = FutureProvider.family<ShopPage, (ShopFilters, int)>((ref, key) async {
  final (filters, page) = key;
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: filters.query(page: page, perPage: shopPageSize),
      );
  final d = r.data!;
  return ShopPage(
    [for (final p in d['items'] as List) Product.fromJson(p as Map<String, dynamic>)],
    d['total'] as int,
    d['pages'] as int,
  );
});

/// How many products the filters would show ("Show 9 products" in the Filters sheet)
final shopCountProvider = FutureProvider.family<int, ShopFilters>((ref, f) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/products', queryParameters: f.query(page: 1, perPage: 1));
  return r.data!['total'] as int;
});

class ShopFacets {
  const ShopFacets(this.brands, this.minPrice, this.maxPrice);

  final List<String> brands;
  final double minPrice;
  final double maxPrice;
}

/// Brands and the price range in a category (or the whole shop)
final shopFacetsProvider = FutureProvider.family<ShopFacets, String?>((ref, category) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>(
        '/products/facets',
        queryParameters: {'category': ?category},
      );
  final d = r.data!;
  return ShopFacets(
    [for (final b in d['brands'] as List) '$b'],
    (d['min_price'] as num?)?.toDouble() ?? 0,
    (d['max_price'] as num?)?.toDouble() ?? 0,
  );
});
