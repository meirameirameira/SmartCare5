import '../../core/storage/local_cache.dart';
import '../../domain/repositories/repositories.dart';

/// Preferências de aparência e acessibilidade persistidas no dispositivo.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._cache);

  final LocalCache _cache;

  @override
  Future<String?> readThemeMode() => _cache.readString(CacheKeys.themeMode);

  @override
  Future<void> writeThemeMode(String mode) =>
      _cache.writeString(CacheKeys.themeMode, mode);

  @override
  Future<double?> readTextScale() async {
    final raw = await _cache.readString(CacheKeys.textScale);
    return raw == null ? null : double.tryParse(raw);
  }

  @override
  Future<void> writeTextScale(double scale) =>
      _cache.writeString(CacheKeys.textScale, scale.toString());

  @override
  Future<bool?> readAlertsEnabled() async {
    final raw = await _cache.readString(CacheKeys.alertsEnabled);
    return raw == null ? null : raw == 'true';
  }

  @override
  Future<void> writeAlertsEnabled(bool enabled) =>
      _cache.writeString(CacheKeys.alertsEnabled, enabled.toString());
}
