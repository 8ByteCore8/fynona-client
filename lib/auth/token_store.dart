import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

/// The refresh token in the platform's secret store (SEC-5): Keychain on iOS
/// and macOS, Keystore-backed storage on Android, libsecret on Linux, the
/// Credential Manager on Windows. Never used on web (cookie mode).
final class SecureRefreshTokenStore implements RefreshTokenStore {
  SecureRefreshTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'fynona.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
