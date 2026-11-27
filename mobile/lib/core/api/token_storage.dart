import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Login tokens, kept in the Android Keystore / iOS Keychain (not plain preferences).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;
  static const _access = 'nm_access';
  static const _refresh = 'nm_refresh';

  Future<String?> get access => _s.read(key: _access);
  Future<String?> get refresh => _s.read(key: _refresh);

  Future<void> save({required String access, String? refresh}) async {
    await _s.write(key: _access, value: access);
    if (refresh != null) await _s.write(key: _refresh, value: refresh);
  }

  Future<void> clear() async {
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
  }
}
