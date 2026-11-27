import 'dart:ui';

/// Product as the API lists it (GET /products). The raw JSON is kept so a copy can be saved on the
/// phone (guest wishlist) and read back without a separate toJson.
class Product {
  Product.fromJson(this.json)
      : id = json['id'] as int,
        name = json['name'] as String,
        nameMr = json['name_mr'] as String?,
        slug = json['slug'] as String,
        brand = json['brand'] as String?,
        price = (json['price'] as num).toDouble(),
        mrp = (json['compare_at_price'] as num?)?.toDouble(),
        stock = json['stock_quantity'] as int? ?? 0,
        isFeatured = json['is_featured'] as bool? ?? false,
        isTrending = json['is_trending'] as bool? ?? false,
        rating = (json['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount = json['rating_count'] as int? ?? 0,
        categoryId = json['category_id'] as int?,
        images = [
          for (final i in (json['images'] as List? ?? const []))
            if (i is Map && i['image_url'] is String) i['image_url'] as String,
        ];

  final Map<String, dynamic> json;
  final int id;
  final String name;
  final String? nameMr;
  final String slug;
  final String? brand;
  final double price;
  final double? mrp;
  final int stock;
  final bool isFeatured;
  final bool isTrending;
  final double rating;
  final int ratingCount;
  final int? categoryId;
  final List<String> images;

  String? get image => images.isEmpty ? null : images.first;
  bool get soldOut => stock <= 0;

  /// Whole-number % off the MRP, same rounding as the website
  int get off => mrp != null && mrp! > price ? (((mrp! - price) / mrp!) * 100).round() : 0;

  /// Name in the app's language, falling back to English
  String nameIn(Locale l) => l.languageCode == 'mr' && (nameMr?.isNotEmpty ?? false) ? nameMr! : name;

  /// The other language's name, shown smaller underneath (null when there isn't one)
  String? altNameIn(Locale l) {
    if (nameMr == null || nameMr!.isEmpty) return null;
    return l.languageCode == 'mr' ? name : nameMr;
  }
}

class Category {
  Category.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        name = j['name'] as String,
        nameMr = j['name_mr'] as String?,
        slug = j['slug'] as String,
        image = j['image_url'] as String?,
        productCount = j['product_count'] as int? ?? 0;

  final int id;
  final String name;
  final String? nameMr;
  final String slug;
  final String? image;
  final int productCount;

  String nameIn(Locale l) => l.languageCode == 'mr' && (nameMr?.isNotEmpty ?? false) ? nameMr! : name;
  String? altNameIn(Locale l) {
    if (nameMr == null || nameMr!.isEmpty) return null;
    return l.languageCode == 'mr' ? name : nameMr;
  }
}
