import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/failures.dart';

/// Entrada de cache com metadados de validade.
class CacheEntry<T> {
  const CacheEntry({required this.value, required this.savedAt});

  final T value;
  final DateTime savedAt;

  Duration get age => DateTime.now().difference(savedAt);
  bool isFresh(Duration ttl) => age <= ttl;
}

/// Contrato do cache local — permite substituir `SharedPreferences` por um
/// fake nos testes sem tocar nas camadas superiores.
abstract interface class LocalCache {
  Future<void> writeJson(String key, Map<String, dynamic> value);
  Future<CacheEntry<Map<String, dynamic>>?> readJson(String key);
  Future<void> writeString(String key, String value);
  Future<String?> readString(String key);
  Future<void> remove(String key);
}

/// Implementação sobre `SharedPreferences`, com carimbo de tempo por chave.
///
/// Viabiliza a estratégia **offline-first**: o repositório devolve o cache
/// imediatamente e revalida contra a rede em segundo plano.
class SharedPrefsCache implements LocalCache {
  SharedPrefsCache(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsCache> create() async =>
      SharedPrefsCache(await SharedPreferences.getInstance());

  static const _envelopeVersion = 1;

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    try {
      final envelope = <String, dynamic>{
        'v': _envelopeVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'data': value,
      };
      await _prefs.setString(key, jsonEncode(envelope));
    } catch (e) {
      throw CacheFailure(detail: 'Falha ao salvar "$key" no dispositivo.', cause: e);
    }
  }

  @override
  Future<CacheEntry<Map<String, dynamic>>?> readJson(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (envelope['v'] != _envelopeVersion) {
        await remove(key);
        return null;
      }
      return CacheEntry(
        value: (envelope['data'] as Map).cast<String, dynamic>(),
        savedAt: DateTime.parse(envelope['savedAt'] as String),
      );
    } catch (e) {
      // Cache corrompido: descarta em vez de derrubar a tela.
      debugPrint('[LocalCache] entrada corrompida em "$key": $e');
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> readString(String key) async => _prefs.getString(key);

  @override
  Future<void> remove(String key) async => _prefs.remove(key);
}

/// Cache em memória — usado nos testes e como fallback quando o
/// `SharedPreferences` não está disponível (ex.: testes de widget).
class InMemoryCache implements LocalCache {
  final Map<String, ({Map<String, dynamic> data, DateTime savedAt})> _json = {};
  final Map<String, String> _strings = {};

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    _json[key] = (data: value, savedAt: DateTime.now());
  }

  @override
  Future<CacheEntry<Map<String, dynamic>>?> readJson(String key) async {
    final entry = _json[key];
    if (entry == null) return null;
    return CacheEntry(value: entry.data, savedAt: entry.savedAt);
  }

  @override
  Future<void> writeString(String key, String value) async => _strings[key] = value;

  @override
  Future<String?> readString(String key) async => _strings[key];

  @override
  Future<void> remove(String key) async {
    _json.remove(key);
    _strings.remove(key);
  }
}

/// Chaves de cache centralizadas (evita strings mágicas espalhadas).
abstract final class CacheKeys {
  static const vitals = 'smartcare.vitals';
  static const weather = 'smartcare.weather';
  static const chatHistory = 'smartcare.chat.history';
  static const themeMode = 'smartcare.settings.themeMode';
  static const textScale = 'smartcare.settings.textScale';
  static const alertsEnabled = 'smartcare.settings.alertsEnabled';
}
