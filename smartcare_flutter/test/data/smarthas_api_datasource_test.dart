import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/network/api_client.dart';
import 'package:smartcare_flutter/core/storage/local_cache.dart';
import 'package:smartcare_flutter/data/datasources/remote/smarthas_api_datasource.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';

/// API Smart HAS simulada em um servidor HTTP local.
///
/// Testa o contrato real (rotas, cabeçalho `Authorization`, corpo JSON) sem
/// depender do back-end Spring Boot estar no ar.
class _FakeSmartHasServer {
  late HttpServer _server;

  final List<String> requestLog = [];
  final List<String?> authHeaders = [];

  /// Quando > 0, o servidor responde 401 nas próximas N chamadas autenticadas
  /// (simula token expirado).
  int rejectNextAuthenticated = 0;

  int loginCount = 0;

  /// Status recebidos em PATCH /deliveries/{id}/status.
  final List<String> statusPatches = [];

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    requestLog.add('${request.method} $path');

    if (path == '/api/v1/auth/login') {
      loginCount++;
      final body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      if (body['password'] != 'paciente123') {
        return _json(request, 401, {'message': 'E-mail ou senha incorretos.'});
      }
      return _json(request, 200, {
        'accessToken': 'token-$loginCount',
        'tokenType': 'Bearer',
        'expiresInMinutes': 480,
        'user': {
          'id': 3,
          'email': body['email'],
          'name': 'Felipe Meira',
          'role': 'PATIENT',
          'patientId': 7,
        },
      });
    }

    authHeaders.add(request.headers.value('Authorization'));

    if (rejectNextAuthenticated > 0) {
      rejectNextAuthenticated--;
      return _json(request, 401, {'message': 'Token expirado'});
    }

    if (path == '/api/v1/patients/7') {
      return _json(request, 200, {
        'id': 7,
        'name': 'Felipe Meira',
        'initials': 'FM',
        'age': 22,
        'conditions': ['Hipertensao leve', 'Diabetes tipo 2'],
        'wearableConnected': true,
      });
    }

    if (path == '/api/v1/patients/7/vitals/latest') {
      return _json(request, 200, _vitalsJson);
    }

    if (path == '/api/v1/patients/7/vitals') {
      return _json(request, 201, _vitalsJson);
    }

    if (path == '/api/v1/patients/7/alerts') {
      return _jsonList(request, 200, [
        {
          'id': 10,
          'patientId': 7,
          'type': 'URGENT',
          'title': 'SpO2: 84.0 %',
          'description': 'Valor critico.',
          'acknowledged': false,
          'createdAt': '2026-08-30T12:34:00Z',
        },
      ]);
    }

    if (path == '/api/v1/patients/7/deliveries') {
      return _jsonList(request, 200, [
        {
          'id': 1,
          'orderCode': 'SC-2026-0412',
          'patientId': 7,
          'description': 'Metformina 500mg (60cp)',
          'pharmacyName': 'Farmacia Leroy Health',
          'status': 'IN_TRANSIT',
          'currentStep': 2,
          'distanceKm': 3.2,
          'etaMinutes': 28,
          'proactiveMessage': 'IA detectou transito - rota alternativa ativa.',
          'updatedAt': '2026-09-01T10:00:00Z',
        },
        {
          'id': 2,
          'orderCode': 'SC-2026-0388',
          'patientId': 7,
          'description': 'Insulina NPH',
          'pharmacyName': 'Drogaria Central',
          'status': 'DELIVERED',
          'currentStep': 3,
          'distanceKm': 1.8,
          'etaMinutes': 0,
          'proactiveMessage': null,
          'updatedAt': '2026-09-02T10:00:00Z',
        },
      ]);
    }

    if (path == '/api/v1/deliveries/1/status') {
      final body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      statusPatches.add(body['status'] as String);
      return _json(request, 200, {
        'id': 1,
        'orderCode': 'SC-2026-0412',
        'patientId': 7,
        'description': 'Metformina 500mg (60cp)',
        'pharmacyName': 'Farmacia Leroy Health',
        'status': body['status'],
        'currentStep': 3,
        'distanceKm': 3.2,
        'etaMinutes': 0,
        'proactiveMessage': 'Entrega confirmada pelo paciente.',
        'updatedAt': '2026-09-02T12:00:00Z',
      });
    }

    return _json(request, 404, {'message': 'Rota inexistente'});
  }

  static const _vitalsJson = {
    'id': 99,
    'patientId': 7,
    'heartRate': 76,
    'spO2': 97.5,
    'glucoseLevel': 112,
    'bpSystolic': 121,
    'bpDiastolic': 79,
    'temperature': 36.7,
    'measuredAt': '2026-08-30T12:00:00Z',
  };

  Future<void> _json(HttpRequest request, int status, Map<String, dynamic> body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Future<void> _jsonList(HttpRequest request, int status, List<dynamic> body) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }
}

void main() {
  late _FakeSmartHasServer server;
  late SmartHasApiDataSource api;
  late SmartHasApiSession session;
  late InMemoryCache cache;

  setUp(() async {
    server = _FakeSmartHasServer();
    await server.start();
    cache = InMemoryCache();
    session = SmartHasApiSession(
      ApiClient(maxRetries: 0),
      cache,
      baseUrl: server.baseUrl,
    );
    api = SmartHasApiDataSource(session);
  });

  tearDown(() => server.stop());

  test('login troca credenciais por JWT e guarda o paciente vinculado', () async {
    final patientId = await session.login(
      email: 'felipe@smarthas.com',
      password: 'paciente123',
    );

    expect(patientId, 7);
    expect(session.isAuthenticated, isTrue);
    expect(await cache.readString('smartcare.api.token'), 'token-1');
  });

  test('as chamadas seguintes enviam o cabecalho Authorization', () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    final vitals = await api.fetchLatestVitals();

    expect(vitals.heartRate, 76);
    expect(vitals.spO2, 97.5);
    expect(server.authHeaders.last, 'Bearer token-1');
  });

  test('token expirado dispara reautenticacao automatica e repete a chamada',
      () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    server.rejectNextAuthenticated = 1;

    final vitals = await api.fetchLatestVitals();

    expect(vitals.glucoseLevel, 112, reason: 'a chamada foi refeita com sucesso');
    expect(server.loginCount, 2, reason: 'houve um novo login');
    expect(server.authHeaders.last, 'Bearer token-2');
  });

  test('prontuario do paciente e mapeado para a entidade do dominio', () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    final patient = await api.fetchPatient();

    expect(patient.name, 'Felipe Meira');
    expect(patient.initials, 'FM');
    expect(patient.conditions, hasLength(2));
  });

  test('envio de leitura usa POST e devolve a leitura persistida', () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');

    final saved = await api.pushVitals(const VitalReading(
      heartRate: 76,
      spO2: 97.5,
      glucoseLevel: 112,
      bpSystolic: 121,
      bpDiastolic: 79,
      temperature: 36.7,
    ));

    expect(saved.heartRate, 76);
    expect(server.requestLog, contains('POST /api/v1/patients/7/vitals'));
  });

  test('alertas abertos sao convertidos para o modelo do app', () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    final alerts = await api.fetchOpenAlerts();

    expect(alerts, hasLength(1));
    expect(alerts.first.type, AlertType.urgent);
    expect(alerts.first.title, contains('SpO2'));
  });

  test('pedidos da AI Logistics vem da API com a trilha e a mensagem da IA',
      () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    final pedidos = await api.fetchDeliveries();

    expect(pedidos, hasLength(2));
    expect(pedidos.first.orderCode, 'SC-2026-0412');
    expect(pedidos.first.status, DeliveryStatus.inTransit);
    expect(pedidos.first.currentStep, 2);
    expect(pedidos.first.minutesAway, 28);
    expect(pedidos.first.proactiveMessage, contains('rota alternativa'));
    // A API guarda minutos; a tela mostra uma janela de horario.
    expect(pedidos.first.etaFrom, matches(r'^\d{2}h\d{2}$'));
  });

  test('confirmar recebimento envia PATCH com o status DELIVERED', () async {
    await session.login(email: 'felipe@smarthas.com', password: 'paciente123');
    final atualizado =
        await api.changeDeliveryStatus('1', DeliveryStatus.delivered);

    expect(server.statusPatches, ['DELIVERED']);
    expect(atualizado.status, DeliveryStatus.delivered);
    expect(atualizado.currentStep, 3);
  });

  test('credenciais invalidas nao autenticam a sessao', () async {
    await expectLater(
      session.login(email: 'felipe@smarthas.com', password: 'errada'),
      throwsA(isA<Exception>()),
    );
    expect(session.isAuthenticated, isFalse);
  });
}
