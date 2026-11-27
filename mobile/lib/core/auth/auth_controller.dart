import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'app_user.dart';

/// Who is signed in (null = guest). Same flow as the website's AuthContext.
final authProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<AppUser?> build() async {
    // The API client signs us out when the refresh token is rejected
    final sub = _api.sessionExpired.listen((_) => state = const AsyncData(null));
    ref.onDispose(sub.cancel);

    final tokens = ref.read(tokenStorageProvider);
    if (await tokens.access == null) return null;
    try {
      final r = await _api.dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(r.data!);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) await tokens.clear(); // signed out or disabled on the server
      // Offline / server asleep: carry on as a guest for now; the saved login is kept for next time
      return null;
    }
  }

  /// [login] is an email, or a username for staff accounts. Throws DioException on failure.
  Future<AppUser> signIn(String login, String password) =>
      _accept(_api.dio.post('/auth/login', data: {'email': login.trim(), 'password': password}));

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      _accept(_api.dio.post('/auth/register', data: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone,
        'password': password,
      }));

  /// Name and mobile (email can't change). Throws DioException with the server's reason.
  Future<AppUser> updateProfile({required String fullName, String? phone}) async {
    final r = await _api.dio.put<Map<String, dynamic>>('/users/me', data: {'full_name': fullName.trim(), 'phone': phone});
    final user = AppUser.fromJson(r.data!);
    state = AsyncData(user);
    return user;
  }

  Future<void> changePassword({required String current, required String next}) =>
      _api.dio.post('/auth/change-password', data: {'current_password': current, 'new_password': next});

  /// Erases the account on the server (password required), then signs out here.
  /// The server refuses while an order is still on its way; the reason comes back in the DioException.
  Future<void> deleteAccount(String password) async {
    await _api.dio.delete('/users/me', data: {'password': password});
    await signOut();
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<AppUser> _accept(Future<Response<dynamic>> call) async {
    final data = (await call).data as Map<String, dynamic>;
    await ref.read(tokenStorageProvider).save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String?,
        );
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    state = AsyncData(user);
    return user;
  }
}
