import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirmal_mart/core/api/api_client.dart';
import 'package:nirmal_mart/core/api/token_storage.dart';
import 'package:nirmal_mart/core/prefs.dart';
import 'package:nirmal_mart/main.dart';
import 'package:nirmal_mart/shared/net_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Login tokens kept in memory instead of the phone's secure storage
class MemoryTokens extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> get access async => accessToken;
  @override
  Future<String?> get refresh async => refreshToken;
  @override
  Future<void> save({required String access, String? refresh}) async {
    accessToken = access;
    if (refresh != null) refreshToken = refresh;
  }

  @override
  Future<void> clear() async => accessToken = refreshToken = null;
}

typedef FakeReply = (int status, Object body);

/// Stands in for the NirmalMart API. Map "METHOD /path" to a reply; every request is recorded.
/// The shop catalogue ([catalogueRoutes]) is answered unless a test replaces those routes.
class FakeApi implements HttpClientAdapter {
  FakeApi([Map<String, FakeReply Function(RequestOptions)>? routes]) : routes = {...catalogueRoutes(), ...?routes};

  final Map<String, FakeReply Function(RequestOptions)> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    requests.add(o);
    // exact "GET /products" first, then patterns like "GET /products/*/related" (* = one path segment)
    var handler = routes['${o.method} ${o.path}'];
    if (handler == null) {
      final key = '${o.method} ${o.path}';
      for (final e in routes.entries) {
        if (!e.key.contains('*')) continue;
        final re = RegExp('^${RegExp.escape(e.key).replaceAll(r'\*', '[^/]+')}\$');
        if (re.hasMatch(key)) {
          handler = e.value;
          break;
        }
      }
    }
    final (status, data) = handler == null ? (404, {'detail': 'Not found'}) : handler(o);
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> fakeUser({String name = 'Ravi Patil', String role = 'customer'}) => {
      'id': 7,
      'email': 'ravi@example.com',
      'username': null,
      'full_name': name,
      'phone': '9876543210',
      'role': role,
      'is_active': true,
      'created_at': '2026-11-25T10:00:00Z',
    };

Map<String, Object?> fakeTokens({String name = 'Ravi Patil'}) =>
    {'access_token': 'acc', 'refresh_token': 'ref', 'token_type': 'bearer', 'user': fakeUser(name: name)};

class TestApp {
  TestApp(this.prefs, this.tokens, this.api);

  final SharedPreferences prefs;
  final MemoryTokens tokens;
  final FakeApi api;
}

/// Starts the app with saved preferences, in-memory tokens and a fake API. Animations are off unless
/// [animate] is set (pumpAndSettle can't finish while something animates).
Future<TestApp> startApp(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  FakeApi? api,
  MemoryTokens? tokens,
  bool animate = false,
  bool live = false,
  List<Object> extraOverrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final fake = api ?? FakeApi();
  final memory = tokens ?? MemoryTokens();
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: !animate);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(ProviderScope(
    retry: (_, _) => null,
    overrides: [
      networkImagesProvider.overrideWithValue(false),
      liveUpdatesProvider.overrideWithValue(live),
      sharedPrefsProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(memory),
      apiClientProvider.overrideWith((ref) {
        final client = ApiClient(memory, baseUrl: 'https://test.local/api');
        client.dio.httpClientAdapter = fake;
        ref.onDispose(client.dispose);
        return client;
      }),
      ...extraOverrides.cast(),
    ],
    child: const NirmalMartApp(),
  ));
  if (animate) {
    await tester.pump(const Duration(milliseconds: 700));
  } else {
    await tester.pumpAndSettle();
  }
  return TestApp(prefs, memory, fake);
}

/// Saved preferences for someone who has already been through the welcome screen
const onboarded = <String, Object>{'nm_onboarded': true, 'nm_locale': 'en'};

// ───────────── Sample catalogue ─────────────

Map<String, Object?> fakeCategory(int id, String name, String mr, String slug, int count) =>
    {'id': id, 'name': name, 'name_mr': mr, 'slug': slug, 'image_url': null, 'parent_id': null, 'sort_order': id, 'product_count': count};

Map<String, Object?> fakeProduct(
  int id,
  String name, {
  String? mr,
  required num price,
  num? mrp,
  int stock = 10,
  int category = 1,
  bool trending = false,
  bool featured = false,
  num rating = 0,
  int ratings = 0,
}) =>
    {
      'id': id,
      'name': name,
      'name_mr': mr,
      'slug': name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-'),
      'brand': null,
      'price': price,
      'compare_at_price': mrp,
      'stock_quantity': stock,
      'is_active': true,
      'is_featured': featured,
      'is_trending': trending,
      'rating_avg': rating,
      'rating_count': ratings,
      'sold_count': 0,
      'category_id': category,
      'category': null,
      'ai_tags': [],
      'images': [
        {'id': id, 'image_url': 'https://img.test/$id.webp', 'alt_text': null, 'is_primary': true, 'sort_order': 1},
      ],
      'created_at': '2026-11-20T10:00:00Z',
    };

final sampleCategories = [
  fakeCategory(1, 'Home & Kitchen', 'घर आणि स्वयंपाकघर', 'home-kitchen', 4),
  fakeCategory(2, 'Car & Bike Care', 'कार आणि बाईक केअर', 'car-bike', 3),
  fakeCategory(3, 'Tools & Outdoor', 'टूल्स आणि आउटडोअर', 'tools-outdoor', 2),
];

final sampleProducts = [
  fakeProduct(1, 'Vacuum Cleaner', mr: 'व्हॅक्यूम क्लीनर', price: 1000, mrp: 2100, category: 2, trending: true, rating: 4.5, ratings: 12),
  fakeProduct(2, 'Portable Washer Gun', mr: 'पोर्टेबल वॉशर गन', price: 1500, mrp: 2000, category: 2, trending: true),
  fakeProduct(3, 'Mini Foot Pump', mr: 'मिनी फूट पंप', price: 400, mrp: 599, category: 2, stock: 0),
  fakeProduct(4, 'Steel Bottle', mr: 'स्टील बाटली', price: 200, mrp: 400, category: 1, featured: true),
  fakeProduct(5, 'Vegetable Chopper', mr: 'भाजी कटर', price: 299, mrp: 499, category: 1, trending: true),
  fakeProduct(6, 'Spice Rack', mr: 'मसाला रॅक', price: 650, category: 1),
  fakeProduct(7, 'Lunch Box', mr: 'डबा', price: 350, mrp: 380, category: 1),
  {...fakeProduct(8, 'LM 7703 Torch', mr: 'LM 7703 टॉर्च', price: 450, mrp: 599, category: 3), 'brand': 'LM'},
  {...fakeProduct(9, 'Garden Sprayer', price: 1800, mrp: 2400, category: 3), 'description': 'Fits on any bottle', 'brand': 'MZ'},
];

Map<String, Object?> page(List<Map<String, Object?>> items) =>
    {'items': items, 'total': items.length, 'page': 1, 'pages': 1, 'per_page': 100};

/// GET /products, /categories and /settings answered from the sample catalogue
Map<String, FakeReply Function(RequestOptions)> catalogueRoutes({
  List<Map<String, Object?>>? products,
  List<Map<String, Object?>>? categories,
  bool showBanner = true,
}) {
  final all = products ?? sampleProducts;
  return {
    'GET /categories': (_) => (200, categories ?? sampleCategories),
    'GET /settings': (_) => (200, {'show_banner': showBanner, 'cod_enabled': false}),
    'GET /products': (o) {
      final q = o.queryParameters;
      var items = all;
      if (q['trending'] == true || q['trending'] == 'true') items = [for (final p in items) if (p['is_trending'] == true) p];
      if (q['search'] != null) items = searchSample(items, '${q['search']}');
      if (q['in_stock'] == true || q['in_stock'] == 'true') items = [for (final p in items) if ((p['stock_quantity'] as int) > 0) p];
      if (q['max_price'] != null) items = [for (final p in items) if ((p['price'] as num) <= num.parse('${q['max_price']}')) p];
      if (q['category'] != null) {
        final cat = (categories ?? sampleCategories).where((c) => c['slug'] == q['category'] || '${c['id']}' == '${q['category']}').firstOrNull;
        items = [for (final p in items) if (cat != null && p['category_id'] == cat['id']) p];
      }
      if (q['min_price'] != null) items = [for (final p in items) if ((p['price'] as num) >= num.parse('${q['min_price']}')) p];
      if (q['brand'] != null) {
        final brands = q['brand'] is List ? {...(q['brand'] as List).map((b) => '$b')} : {'${q['brand']}'};
        items = [for (final p in items) if (brands.contains(p['brand'])) p];
      }
      if (q['ids'] != null) {
        final ids = '${q['ids']}'.split(',').map(int.parse).toSet();
        items = [for (final p in items) if (ids.contains(p['id'])) p];
      }
      num off(Map<String, Object?> p) => p['compare_at_price'] == null ? 0 : 1 - (p['price'] as num) / (p['compare_at_price'] as num);
      switch ('${q['sort_by']}') {
        case 'price_low':
          items = [...items]..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        case 'price_high':
          items = [...items]..sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        case 'discount':
          items = [...items]..sort((a, b) => off(b).compareTo(off(a)));
      }
      final per = int.tryParse('${q['per_page'] ?? 100}') ?? 100;
      final pageNo = int.tryParse('${q['page'] ?? 1}') ?? 1;
      final pages = items.isEmpty ? 1 : (items.length / per).ceil();
      return (200, {
        'items': items.skip((pageNo - 1) * per).take(per).toList(),
        'total': items.length,
        'page': pageNo,
        'pages': pages,
        'per_page': per,
      });
    },
    'GET /products/facets': (o) {
      final cat = (categories ?? sampleCategories).where((c) => c['slug'] == o.queryParameters['category']).firstOrNull;
      final items = [for (final p in all) if (cat == null || p['category_id'] == cat['id']) p];
      final prices = [for (final p in items) p['price'] as num];
      return (200, {
        'brands': {for (final p in items) if (p['brand'] != null) p['brand']}.toList()..sort(),
        'min_price': prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b),
        'max_price': prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b),
      });
    },
    'GET /products/suggest': (o) => (200, searchSample(all, '${o.queryParameters['q']}').take(6).toList()),
    'GET /products/*': (o) {
      final slug = o.path.split('/').last;
      final p = all.where((p) => p['slug'] == slug).firstOrNull;
      if (p == null) return (404, {'detail': 'Product not found'});
      final cat = (categories ?? sampleCategories).where((c) => c['id'] == p['category_id']).firstOrNull;
      return (200, {
        ...p,
        'sku': 'NM-${p['id']}',
        'description': 'All about ${p['name']}.',
        'description_mr': p['name_mr'] == null ? null : '${p['name_mr']} बद्दल माहिती.',
        'highlights': <String>[],
        'specifications': <String, String>{},
        'category': cat == null ? null : {'id': cat['id'], 'name': cat['name'], 'name_mr': cat['name_mr'], 'slug': cat['slug']},
        'updated_at': '2026-11-20T10:00:00Z',
      });
    },
    'GET /products/*/related': (o) {
      final slug = o.path.split('/')[2];
      final p = all.where((p) => p['slug'] == slug).firstOrNull;
      return (200, [for (final x in all) if (p != null && x['id'] != p['id'] && x['category_id'] == p['category_id']) x]);
    },
    'GET /products/*/reviews': (_) => (200, {'average': 0, 'count': 0, 'distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0}, 'reviews': [], 'can_review': false}),
  };
}

/// Same kind of matching as the server: the text anywhere in the English or Marathi name or description
List<Map<String, Object?>> searchSample(List<Map<String, Object?>> items, String q) {
  final t = q.trim().toLowerCase();
  return [
    for (final p in items)
      if ('${p['name']}'.toLowerCase().contains(t) || '${p['name_mr'] ?? ''}'.contains(t) || '${p['description'] ?? ''}'.toLowerCase().contains(t)) p,
  ];
}
