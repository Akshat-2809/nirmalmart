import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../catalog/models.dart';
import '../prefs.dart';

/// Saved products. Guests keep them on the phone; after sign-in they're added to the account
/// (same as the website's WishlistContext).
final wishlistProvider = AsyncNotifierProvider<WishlistController, List<Product>>(WishlistController.new);

class WishlistController extends AsyncNotifier<List<Product>> {
  static const _key = 'nm_guest_wishlist';

  ApiClient get _api => ref.read(apiClientProvider);

  List<Product> _guest() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return [];
    try {
      return [for (final p in jsonDecode(raw) as List) Product.fromJson(p as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveGuest(List<Product> items) =>
      ref.read(sharedPrefsProvider).setString(_key, jsonEncode([for (final p in items) p.json]));

  static List<Product> _list(Object? data) => [for (final p in data as List) Product.fromJson(p as Map<String, dynamic>)];

  @override
  Future<List<Product>> build() async {
    final user = await ref.watch(authProvider.future);
    final guest = _guest();
    if (user == null) return _noteSaved(guest);
    try {
      for (final p in guest) {
        try {
          await _api.dio.post('/wishlist/${p.id}');
        } catch (_) {} // e.g. that product was removed from the shop
      }
      final r = await _api.dio.get('/wishlist');
      await ref.read(sharedPrefsProvider).remove(_key);
      return _noteSaved(_list(r.data));
    } catch (_) {
      return const [];
    }
  }

  bool has(int productId) => (state.value ?? const []).any((p) => p.id == productId);

  /// Saves or un-saves [product]. Returns true when it's now saved. Throws if the server refused.
  Future<bool> toggle(Product product) async {
    final on = has(product.id);
    final before = state.value ?? const <Product>[];
    final next = on ? before.where((p) => p.id != product.id).toList() : [product, ...before];
    state = AsyncData(next); // show it straight away
    if (!on) await _setSavedPrice(product.id, product.price);
    if (ref.read(authProvider).value == null) {
      await _saveGuest(next);
      return !on;
    }
    try {
      final r = on ? await _api.dio.delete('/wishlist/${product.id}') : await _api.dio.post('/wishlist/${product.id}');
      state = AsyncData(_list(r.data));
      return !on;
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  static const _pricesKey = 'nm_wishlist_prices';

  Map<String, dynamic> _prices() {
    try {
      return (jsonDecode(ref.read(sharedPrefsProvider).getString(_pricesKey) ?? '{}') as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _setSavedPrice(int id, double price) async {
    final m = _prices()..['$id'] = price;
    await ref.read(sharedPrefsProvider).setString(_pricesKey, jsonEncode(m));
  }

  /// Remembers today's price for anything saved before prices were tracked (so it isn't a false "drop")
  List<Product> _noteSaved(List<Product> items) {
    final m = _prices();
    var changed = false;
    for (final p in items) {
      if (!m.containsKey('${p.id}')) {
        m['${p.id}'] = p.price;
        changed = true;
      }
    }
    if (changed) ref.read(sharedPrefsProvider).setString(_pricesKey, jsonEncode(m));
    return items;
  }

  /// The price when it was saved, if known
  double? savedPrice(int id) => (_prices()['$id'] as num?)?.toDouble();

  /// Fresh prices and stock: the account's list from the server, or (guests) each product again;
  /// products removed from the shop drop out
  Future<void> refresh() async {
    final items = state.value ?? const <Product>[];
    try {
      if (ref.read(authProvider).value != null) {
        final r = await _api.dio.get('/wishlist');
        state = AsyncData(_noteSaved(_list(r.data)));
        return;
      }
      if (items.isEmpty) return;
      final r = await _api.dio.get<Map<String, dynamic>>('/products', queryParameters: {
        'ids': items.map((p) => p.id).join(','),
        'per_page': items.length.clamp(1, 100),
      });
      final fresh = {for (final p in _list(r.data!['items'])) p.id: p};
      final next = [for (final p in items) ?fresh[p.id]];
      state = AsyncData(next);
      await _saveGuest(next);
    } catch (_) {}
  }

  /// Takes [product] off the list (Undo puts it back with [restore])
  Future<void> remove(Product product) async {
    if (has(product.id)) await toggle(product);
  }

  Future<void> restore(Product product, int index) async {
    if (has(product.id)) return;
    await toggle(product);
    if (ref.read(authProvider).value == null) {
      // back in its old place
      final items = [...(state.value ?? const <Product>[])]..removeWhere((p) => p.id == product.id);
      items.insert(index.clamp(0, items.length), product);
      state = AsyncData(items);
      await _saveGuest(items);
    }
  }
}
