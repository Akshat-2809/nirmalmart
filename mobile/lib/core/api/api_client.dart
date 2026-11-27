import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final api = ApiClient(ref.watch(tokenStorageProvider));
  ref.onDispose(api.dispose);
  return api;
});

/// HTTP client for the NirmalMart API. Same rules as the website's axios client:
/// - catalogue reads (products, categories) go without the login token so the CDN can cache them
/// - on a 401, refresh the access token once and replay; concurrent failures share one refresh
class ApiClient {
  ApiClient(this._tokens, {String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 20), // a cold Render start can take a while
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: _attachToken, onError: _refreshOn401));
  }

  final Dio dio;
  final TokenStorage _tokens;
  final _expired = StreamController<void>.broadcast();
  Future<String?>? _refreshing;

  Stream<void> get sessionExpired => _expired.stream;

  static final _publicRead = RegExp(r'^/(categories|products)(/|$|\?)');
  static final _authCall = RegExp(r'/auth/(login|register|refresh)');

  Future<void> _attachToken(RequestOptions o, RequestInterceptorHandler h) async {
    final isPublic = o.method == 'GET' && _publicRead.hasMatch(o.path) && !o.path.contains('/reviews');
    if (!isPublic) {
      final t = await _tokens.access;
      if (t != null) o.headers['Authorization'] = 'Bearer $t';
    }
    h.next(o);
  }

  Future<void> _refreshOn401(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    if (e.response?.statusCode != 401 || o.extra['retried'] == true || _authCall.hasMatch(o.path)) {
      return h.next(e);
    }
    final access = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    if (access == null) return h.next(e);
    o.extra['retried'] = true;
    o.headers['Authorization'] = 'Bearer $access';
    try {
      h.resolve(await dio.fetch(o));
    } on DioException catch (err) {
      h.next(err);
    }
  }

  Future<String?> _refresh() async {
    final refresh = await _tokens.refresh;
    if (refresh == null) return null;
    try {
      // A bare Dio, so this call never loops through the interceptor
      final r = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post('/auth/refresh', data: {'refresh_token': refresh});
      final access = r.data['access_token'] as String;
      await _tokens.save(access: access);
      return access;
    } catch (_) {
      await _tokens.clear();
      _expired.add(null);
      return null;
    }
  }

  void dispose() => _expired.close();
}

/// Human-readable message from an API error, matching the website's errorMessage()
String errorMessage(Object error, {String fallback = 'Something went wrong'}) {
  if (error is! DioException) return fallback;
  if (error.response == null) return 'Network error — please check your connection';
  final data = error.response!.data;
  final d = data is Map ? data['detail'] : null;
  if (d is String) return d;
  if (d is List && d.isNotEmpty && d.first is Map) {
    final first = d.first as Map;
    final msg = '${first['msg'] ?? ''}';
    final loc = first['loc'];
    final field = loc is List && loc.isNotEmpty ? '${loc.last}' : '';
    if (RegExp('should match pattern', caseSensitive: false).hasMatch(msg)) {
      const labels = {
        'full_name': 'name (letters only)',
        'phone': '10-digit mobile number',
        'city': 'city name (letters only)',
        'postal_code': '6-digit pincode',
      };
      return 'Please enter a valid ${labels[field] ?? field}';
    }
    return msg.replaceFirst(RegExp(r'^Value error, '), '');
  }
  return fallback;
}
