import 'dart:math';

import '../../../core/network/api_client.dart';
import '../../../domain/entities/entities.dart';

/// Fonte de leituras do wearable.
///
/// A interface permite duas implementações intercambiáveis: o gateway IoT real
/// e um simulador determinístico usado em demonstração e em testes.
abstract interface class VitalsDataSource {
  Future<VitalReading> fetchLatest();
}

/// Gateway IoT SmartCare 5.0 (REST/HTTPS).
///
/// A URL base vem de `--dart-define=SMARTCARE_API_URL=...`; sem ela o app usa
/// o simulador, em vez de quebrar ou apontar para um host inexistente.
class WearableGatewayDataSource implements VitalsDataSource {
  WearableGatewayDataSource(this._client, {required this.baseUrl});

  final ApiClient _client;
  final String baseUrl;

  static const configuredBaseUrl =
      String.fromEnvironment('SMARTCARE_API_URL', defaultValue: '');

  static bool get isConfigured => configuredBaseUrl.isNotEmpty;

  @override
  Future<VitalReading> fetchLatest() => _client.getJson(
        '$baseUrl/v1/devices/wearable/latest',
        decode: VitalReading.fromJson,
      );
}

/// Simulador de wearable com passeio aleatório em torno da linha de base do
/// paciente. Determinístico quando recebe uma `seed`, o que torna possível
/// testar o motor de score com dados reprodutíveis.
class SimulatedVitalsDataSource implements VitalsDataSource {
  SimulatedVitalsDataSource({int? seed, VitalReading? baseline})
      : _rng = Random(seed),
        _current = baseline ?? defaultBaseline;

  final Random _rng;
  VitalReading _current;

  static const defaultBaseline = VitalReading(
    heartRate: 72,
    spO2: 98.5,
    glucoseLevel: 104,
    bpSystolic: 120,
    bpDiastolic: 80,
    temperature: 36.6,
  );

  @override
  Future<VitalReading> fetchLatest() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _current = _current.copyWith(
      heartRate: _walkInt(_current.heartRate, 4, 52, 118),
      spO2: _walkDouble(_current.spO2, 0.4, 92, 100),
      glucoseLevel: _walkInt(_current.glucoseLevel, 9, 68, 190),
      bpSystolic: _walkInt(_current.bpSystolic, 4, 96, 152),
      bpDiastolic: _walkInt(_current.bpDiastolic, 3, 58, 98),
      temperature: _walkDouble(_current.temperature, 0.15, 35.6, 38.4),
      measuredAt: DateTime.now(),
    );
    return _current;
  }

  int _walkInt(int value, int step, int min, int max) =>
      (value + _rng.nextInt(step * 2 + 1) - step).clamp(min, max);

  double _walkDouble(double value, double step, double min, double max) {
    final delta = (_rng.nextDouble() * 2 - 1) * step;
    return double.parse((value + delta).clamp(min, max).toStringAsFixed(1));
  }
}
