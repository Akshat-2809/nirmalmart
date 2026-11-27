import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'models.dart';
import 'recent_and_pincode.dart';

/// Everything the product page shows (GET /products/{slug})
class ProductDetail {
  ProductDetail.fromJson(Map<String, dynamic> j)
      : product = Product.fromJson(j),
        description = (j['description'] as String?)?.trim(),
        descriptionMr = (j['description_mr'] as String?)?.trim(),
        highlights = [for (final h in (j['highlights'] as List? ?? const [])) if ('$h'.trim().isNotEmpty) '$h'.trim()],
        specs = {
          for (final e in ((j['specifications'] as Map?) ?? const {}).entries)
            if ('${e.value}'.trim().isNotEmpty) '${e.key}': '${e.value}',
        },
        categoryName = (j['category'] as Map?)?['name'] as String?,
        categoryNameMr = (j['category'] as Map?)?['name_mr'] as String?,
        categorySlug = (j['category'] as Map?)?['slug'] as String?;

  final Product product;
  final String? description;
  final String? descriptionMr;
  final List<String> highlights;
  final Map<String, String> specs;
  final String? categoryName;
  final String? categoryNameMr;
  final String? categorySlug;

  bool get hasMarathiDescription => descriptionMr != null && descriptionMr!.isNotEmpty;

  String? categoryIn(Locale l) => l.languageCode == 'mr' && (categoryNameMr?.isNotEmpty ?? false) ? categoryNameMr : categoryName;
}

class Review {
  Review.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        userName = (j['user_name'] as String?) ?? 'Customer',
        rating = j['rating'] as int,
        title = j['title'] as String?,
        comment = j['comment'] as String?,
        verified = j['is_verified_purchase'] as bool? ?? false,
        createdAt = DateTime.tryParse('${j['created_at']}')?.toLocal();

  final int id;
  final String userName;
  final int rating;
  final String? title;
  final String? comment;
  final bool verified;
  final DateTime? createdAt;
}

class ReviewSummary {
  ReviewSummary.fromJson(Map<String, dynamic> j)
      : average = (j['average'] as num?)?.toDouble() ?? 0,
        count = j['count'] as int? ?? 0,
        distribution = {
          for (var s = 1; s <= 5; s++) s: ((j['distribution'] as Map?)?['$s'] as num?)?.toInt() ?? 0,
        },
        reviews = [for (final r in (j['reviews'] as List? ?? const [])) Review.fromJson(r as Map<String, dynamic>)],
        canReview = j['can_review'] as bool? ?? false;

  final double average;
  final int count;
  final Map<int, int> distribution;
  final List<Review> reviews;
  final bool canReview;
}

final productDetailProvider = FutureProvider.family<ProductDetail, String>((ref, slug) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/products/$slug');
  return ProductDetail.fromJson(r.data!);
});

/// "You may also like": same category, best rated first (the website's related list)
final relatedProductsProvider = FutureProvider.family<List<Product>, String>((ref, slug) async {
  final r = await ref.watch(apiClientProvider).dio.get<List<dynamic>>('/products/$slug/related');
  return [for (final p in r.data!) Product.fromJson(p as Map<String, dynamic>)];
});

/// Reviews go with the login token (can_review depends on who's asking)
final reviewsProvider = FutureProvider.family<ReviewSummary, int>((ref, productId) async {
  final r = await ref.watch(apiClientProvider).dio.get<Map<String, dynamic>>('/products/$productId/reviews');
  return ReviewSummary.fromJson(r.data!);
});

/// Delivery date for a saved pincode, checked once per pincode
final deliveryCheckProvider = FutureProvider.family<DeliveryCheck, String>(
  (ref, pin) => checkDelivery(ref.watch(apiClientProvider), pin),
);
