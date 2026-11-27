import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../catalog/models.dart';
import '../config.dart';
import '../prefs.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.nameMr,
    required this.slug,
    required this.price,
    required this.mrp,
    required this.image,
    required this.stock,
    required this.quantity,
  });

  /// Same shape for the server's cart lines and the guest bag saved on the phone
  CartItem.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}',
        productId = j['product_id'] as int,
        name = j['product_name'] as String,
        nameMr = j['product_name_mr'] as String?,
        slug = j['product_slug'] as String,
        price = (j['product_price'] as num).toDouble(),
        mrp = (j['compare_at_price'] as num?)?.toDouble(),
        image = j['product_image'] as String?,
        stock = j['stock_quantity'] as int? ?? 0,
        quantity = j['quantity'] as int;

  final String id; // server line id, or "g-<product id>" for a guest
  final int productId;
  final String name;
  final String? nameMr;
  final String slug;
  final double price;
  final double? mrp;
  final String? image;
  final int stock;
  final int quantity;

  CartItem withQuantity(int q) => CartItem(
      id: id, productId: productId, name: name, nameMr: nameMr, slug: slug, price: price, mrp: mrp, image: image, stock: stock, quantity: q);

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': name,
        'product_name_mr': nameMr,
        'product_slug': slug,
        'product_price': price,
        'compare_at_price': mrp,
        'product_image': image,
        'stock_quantity': stock,
        'quantity': quantity,
      };
}

class Cart {
  const Cart({required this.items, required this.subtotal, required this.shipping, required this.total, this.tax = 0});

  /// Server answer (GET /cart and friends)
  Cart.fromJson(Map<String, dynamic> j)
      : items = [for (final i in j['items'] as List) CartItem.fromJson(i as Map<String, dynamic>)],
        subtotal = (j['subtotal'] as num).toDouble(),
        shipping = (j['shipping_amount'] as num).toDouble(),
        total = (j['total_amount'] as num).toDouble(),
        tax = (j['tax_amount'] as num?)?.toDouble() ?? 0;

  /// Guest totals, mirroring the backend's pricing so they match checkout
  factory Cart.of(List<CartItem> items) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.price * i.quantity);
    final shipping = subtotal == 0 || subtotal >= AppConfig.freeDeliveryThreshold ? 0.0 : AppConfig.deliveryFee.toDouble();
    // prices include 18% GST, as on the website
    final tax = double.parse((subtotal - subtotal / 1.18).toStringAsFixed(2));
    return Cart(items: items, subtotal: subtotal, shipping: shipping, total: subtotal + shipping, tax: tax);
  }

  static const empty = Cart(items: [], subtotal: 0, shipping: 0, total: 0);

  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double total;

  /// GST included in the prices
  final double tax;

  /// What the items would cost at full price (MRP), and how much the discounts take off
  double get mrpTotal => items.fold(0, (s, i) => s + (i.mrp != null && i.mrp! > i.price ? i.mrp! : i.price) * i.quantity);
  double get savings => mrpTotal - subtotal;

  /// Lines that can't be ordered as they are (sold out, or fewer left than in the bag)
  List<CartItem> get problems => [for (final i in items) if (i.stock <= 0 || i.quantity > i.stock) i];

  int get count => items.fold(0, (s, i) => s + i.quantity);
  int quantityOf(int productId) => items.where((i) => i.productId == productId).fold(0, (s, i) => s + i.quantity);
}

/// The bag. Guests keep it on the phone; after sign-in it's merged into the account (like the website).
final cartProvider = AsyncNotifierProvider<CartController, Cart>(CartController.new);

class CartController extends AsyncNotifier<Cart> {
  static const _key = 'nm_guest_cart';

  ApiClient get _api => ref.read(apiClientProvider);
  bool get _signedIn => ref.read(authProvider).value != null;

  List<CartItem> _guest() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return [];
    try {
      return [for (final i in jsonDecode(raw) as List) CartItem.fromJson(i as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Future<Cart> _saveGuest(List<CartItem> items) async {
    await ref.read(sharedPrefsProvider).setString(_key, jsonEncode([for (final i in items) i.toJson()]));
    return Cart.of(items);
  }

  @override
  Future<Cart> build() async {
    final user = await ref.watch(authProvider.future);
    final guest = _guest();
    if (user == null) return Cart.of(guest);
    try {
      final Response<dynamic> r = guest.isEmpty
          ? await _api.dio.get('/cart')
          : await _api.dio.post('/cart/merge', data: {
              'items': [for (final i in guest) {'product_id': i.productId, 'quantity': i.quantity}],
            });
      await ref.read(sharedPrefsProvider).remove(_key);
      return Cart.fromJson(r.data as Map<String, dynamic>);
    } catch (_) {
      return Cart.empty; // offline: shows empty until the next refresh; the guest bag is kept for the merge
    }
  }

  /// Adds [quantity] of [product]. Returns an error message to show, or null when it worked.
  Future<String?> add(Product product, {int quantity = 1}) async {
    if (_signedIn) {
      return _server(() => _api.dio.post('/cart/items', data: {'product_id': product.id, 'quantity': quantity}));
    }
    final items = [...(state.value ?? Cart.empty).items];
    final at = items.indexWhere((i) => i.productId == product.id);
    final next = (at < 0 ? 0 : items[at].quantity) + quantity;
    if (next > product.stock) return product.stock > 0 ? 'Only ${product.stock} left in stock' : 'Out of stock';
    if (at >= 0) {
      items[at] = items[at].withQuantity(next);
    } else {
      items.insert(
        0,
        CartItem(
          id: 'g-${product.id}',
          productId: product.id,
          name: product.name,
          nameMr: product.nameMr,
          slug: product.slug,
          price: product.price,
          mrp: product.mrp,
          image: product.image,
          stock: product.stock,
          quantity: quantity,
        ),
      );
    }
    state = AsyncData(await _saveGuest(items));
    return null;
  }

  /// Sets a line's quantity (0 removes it). Returns an error message, or null.
  Future<String?> setQuantity(CartItem item, int quantity) async {
    if (_signedIn) {
      return _server(() => quantity <= 0
          ? _api.dio.delete('/cart/items/${item.id}')
          : _api.dio.put('/cart/items/${item.id}', data: {'quantity': quantity}));
    }
    if (quantity > item.stock) return 'Only ${item.stock} left in stock';
    final items = [
      for (final i in (state.value ?? Cart.empty).items)
        if (i.id != item.id) i else if (quantity > 0) i.withQuantity(quantity),
    ];
    state = AsyncData(await _saveGuest(items));
    return null;
  }

  /// Fresh prices, stock and photos from the server (the bag may have been filled days ago).
  /// Guests: like the website, removed products drop out and quantities stay within stock.
  Future<void> refresh() async {
    if (_signedIn) {
      try {
        state = AsyncData(Cart.fromJson((await _api.dio.get('/cart')).data as Map<String, dynamic>));
      } catch (_) {}
      return;
    }
    final items = (state.value ?? Cart.empty).items;
    if (items.isEmpty) return;
    try {
      final r = await _api.dio.get<Map<String, dynamic>>('/products', queryParameters: {
        'ids': items.map((i) => i.productId).join(','),
        'per_page': items.length.clamp(1, 100),
      });
      final fresh = {for (final p in r.data!['items'] as List) (p as Map<String, dynamic>)['id'] as int: Product.fromJson(p)};
      final next = [
        for (final i in (state.value ?? Cart.empty).items)
          if (fresh[i.productId] case final p?)
            CartItem(
              id: i.id,
              productId: i.productId,
              name: p.name,
              nameMr: p.nameMr,
              slug: p.slug,
              price: p.price,
              mrp: p.mrp,
              image: p.image,
              stock: p.stock,
              quantity: i.quantity,
            ),
      ];
      state = AsyncData(await _saveGuest(next));
    } catch (_) {}
  }

  /// Puts a removed line back (Undo), in its old place for guests
  Future<String?> restore(CartItem item, int index) async {
    if (_signedIn) {
      return _server(() => _api.dio.post('/cart/items', data: {'product_id': item.productId, 'quantity': item.quantity}));
    }
    final items = [...(state.value ?? Cart.empty).items]..removeWhere((i) => i.productId == item.productId);
    items.insert(index.clamp(0, items.length), item);
    state = AsyncData(await _saveGuest(items));
    return null;
  }

  Future<String?> _server(Future<Response<dynamic>> Function() call) async {
    try {
      state = AsyncData(Cart.fromJson((await call()).data as Map<String, dynamic>));
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }
}
