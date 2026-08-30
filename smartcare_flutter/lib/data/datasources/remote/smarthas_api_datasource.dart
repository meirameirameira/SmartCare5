import 'package:flutter/foundation.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../domain/entities/entities.dart';

/// Credenciais e endereço do back-end Spring Boot, definidos em tempo de
/// compilação (`--dart-define`). Sem eles o app roda em modo demonstração.
abstract final class SmartHasApiConfig {
  static const baseUrl =
      String.fromEnvironment('SMARTHAS_API_URL', defaultValue: '');
  static const email = String.fromEnvironment('SMARTHAS_EMAIL', defaultValue: '');
  static const password =
      String.fromEnvironment('SMARTHAS_PASSWORD', defaultValue: '');

  /// `true` quando há back-end configurado para este build.
  static bool get isConfigured =>
      baseUrl.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
}

/// Sessão autenticada contra a API Smart HAS.
///
/// Responsabilidades:
///  - trocar e-mail/senha por um JWT em `POST /api/v1/auth/login`;
///  - guardar o token e o `patientId` do usuário logado;
///  - anexar `Authorization: Bearer` a cada chamada;
///  - reautenticar uma única vez quando o servidor responder 401 (token
///    expirado), sem propagar o erro para a tela.
///
/// O token fica em cache local apenas para evitar um login a cada abertura do
/// app; a senha nunca é persistida.
class SmartHasApiSession {
  SmartHasApiSession(this._client, this._cache, {String? baseUrl})
      : baseUrl = baseUrl ?? SmartHasApiConfig.baseUrl;

  final ApiClient _client;
  final LocalCache _cache;
  final String baseUrl;

  static const _tokenKey = 'smartcare.api.token';

  String? _token;
  int? _patientId;

  // Credenciais da sessao corrente, mantidas apenas em memoria para permitir a
  // reautenticacao silenciosa quando o token expira. Nunca vao para o cache.
  String? _email;
  String? _password;

  int? get patientId => _patientId;
  bool get isAuthenticated => _token != null;

  /// Autentica e devolve o identificador do paciente vinculado ao usuário.
  Future<int> login({String? email, String? password}) async {
    final user = email ?? _email ?? SmartHasApiConfig.email;
    final secret = password ?? _password ?? SmartHasApiConfig.password;

    final payload = await _client.postJson<Map<String, dynamic>>(
      '$baseUrl/api/v1/auth/login',
      body: {'email': user, 'password': secret},
      decode: (json) => json,
    );

    final token = payload['accessToken'] as String?;
    final profile = (payload['user'] as Map?)?.cast<String, dynamic>();
    final id = (profile?['patientId'] as num?)?.toInt();

    if (token == null || id == null) {
      throw const ServerFailure(200,
          detail: 'A API não devolveu um token válido para este usuário.');
    }

    _token = token;
    _patientId = id;
    _email = user;
    _password = secret;
    await _cache.writeString(_tokenKey, token);
    return id;
  }

  /// Restaura um token salvo, se houver, evitando um login desnecessário.
  Future<void> restore() async {
    _token = await _cache.readString(_tokenKey);
  }

  Future<void> logout() async {
    _token = null;
    _patientId = null;
    _email = null;
    _password = null;
    await _cache.remove(_tokenKey);
  }

  /// GET autenticado com reautenticação automática em caso de 401.
  Future<T> get<T>(String path, {required T Function(Map<String, dynamic>) decode}) {
    return _authenticated(() => _client.getJson<T>(
          '$baseUrl$path',
          decode: decode,
          headers: _authHeaders,
        ));
  }

  /// GET autenticado para endpoints que devolvem uma lista JSON.
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic>) decode,
  }) {
    return _authenticated(() => _client.getJsonList<T>(
          '$baseUrl$path',
          decode: decode,
          headers: _authHeaders,
        ));
  }

  /// POST autenticado com reautenticação automática em caso de 401.
  Future<T> post<T>(
    String path, {
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) decode,
  }) {
    return _authenticated(() => _client.postJson<T>(
          '$baseUrl$path',
          body: body,
          decode: decode,
          headers: _authHeaders,
        ));
  }

  Map<String, String> get _authHeaders =>
      _token == null ? const {} : {'Authorization': 'Bearer $_token'};

  Future<T> _authenticated<T>(Future<T> Function() call) async {
    if (_token == null) {
      await login();
    }
    try {
      return await call();
    } on ServerFailure catch (failure) {
      if (failure.statusCode != 401) rethrow;
      // Token expirado: uma única tentativa de renovação, e então repete.
      debugPrint('[SmartHasApi] token expirado — reautenticando');
      await login();
      return call();
    }
  }
}

/// Endpoints da API consumidos pelo app.
class SmartHasApiDataSource {
  SmartHasApiDataSource(this.session);

  final SmartHasApiSession session;

  /// Garante que há sessão ativa e devolve o id do paciente do usuário.
  Future<int> ensurePatientId() async {
    if (session.patientId != null) return session.patientId!;
    return session.login();
  }

  Future<Patient> fetchPatient() async {
    final id = await ensurePatientId();
    return session.get('/api/v1/patients/$id', decode: _patientFromJson);
  }

  Future<VitalReading> fetchLatestVitals() async {
    final id = await ensurePatientId();
    return session.get(
      '/api/v1/patients/$id/vitals/latest',
      decode: _vitalsFromJson,
    );
  }

  /// Envia ao servidor uma leitura capturada pelo wearable no dispositivo.
  Future<VitalReading> pushVitals(VitalReading reading) async {
    final id = await ensurePatientId();
    return session.post(
      '/api/v1/patients/$id/vitals',
      body: {
        'heartRate': reading.heartRate,
        'spO2': reading.spO2,
        'glucoseLevel': reading.glucoseLevel,
        'bpSystolic': reading.bpSystolic,
        'bpDiastolic': reading.bpDiastolic,
        'temperature': reading.temperature,
        'measuredAt': (reading.measuredAt ?? DateTime.now()).toUtc().toIso8601String(),
      },
      decode: _vitalsFromJson,
    );
  }

  Future<List<HealthAlert>> fetchOpenAlerts() async {
    final id = await ensurePatientId();
    return session.getList(
      '/api/v1/patients/$id/alerts?onlyOpen=true',
      decode: _alertFromJson,
    );
  }

  static Patient _patientFromJson(Map<String, dynamic> json) => Patient(
        id: json['id'].toString(),
        name: json['name'] as String,
        initials: json['initials'] as String? ?? '--',
        age: (json['age'] as num).toInt(),
        conditions: ((json['conditions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        wearableConnected: json['wearableConnected'] as bool? ?? true,
      );

  static VitalReading _vitalsFromJson(Map<String, dynamic> json) => VitalReading(
        heartRate: (json['heartRate'] as num).toInt(),
        spO2: (json['spO2'] as num).toDouble(),
        glucoseLevel: (json['glucoseLevel'] as num).toInt(),
        bpSystolic: (json['bpSystolic'] as num).toInt(),
        bpDiastolic: (json['bpDiastolic'] as num).toInt(),
        temperature: (json['temperature'] as num).toDouble(),
        measuredAt: json['measuredAt'] == null
            ? null
            : DateTime.tryParse(json['measuredAt'] as String)?.toLocal(),
      );

  static HealthAlert _alertFromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    return HealthAlert(
      id: json['id'].toString(),
      type: switch (json['type'] as String? ?? 'INFO') {
        'URGENT' => AlertType.urgent,
        'WARNING' => AlertType.warning,
        'OK' => AlertType.ok,
        _ => AlertType.info,
      },
      title: json['title'] as String,
      description: json['description'] as String,
      timeLabel: createdAt == null
          ? ''
          : '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
              '${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
    );
  }
}
