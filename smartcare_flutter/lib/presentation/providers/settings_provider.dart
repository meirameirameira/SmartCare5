import 'package:flutter/material.dart';

import '../../domain/repositories/repositories.dart';

/// Preferências de aparência e acessibilidade do usuário.
///
/// Funcionalidade nova desta fase: tema claro/escuro/automático e escala de
/// texto (importante para o público idoso do SmartCare), ambos persistidos
/// entre sessões.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository) {
    _restore();
  }

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  bool _alertsEnabled = true;
  bool _restored = false;

  ThemeMode get themeMode => _themeMode;
  double get textScale => _textScale;
  bool get alertsEnabled => _alertsEnabled;

  /// `true` quando as preferências salvas já foram lidas do dispositivo.
  bool get isRestored => _restored;

  static const textScaleOptions = <double>[0.9, 1.0, 1.15, 1.3];

  Future<void> _restore() async {
    final mode = await _repository.readThemeMode();
    if (mode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
    }
    _textScale = await _repository.readTextScale() ?? 1.0;
    _alertsEnabled = await _repository.readAlertsEnabled() ?? true;
    _restored = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.writeThemeMode(mode.name);
  }

  /// Alterna entre claro e escuro (usado pelo botão da AppBar).
  Future<void> toggleBrightness(Brightness current) => setThemeMode(
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );

  Future<void> setTextScale(double scale) async {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    await _repository.writeTextScale(scale);
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    if (_alertsEnabled == enabled) return;
    _alertsEnabled = enabled;
    notifyListeners();
    await _repository.writeAlertsEnabled(enabled);
  }
}
