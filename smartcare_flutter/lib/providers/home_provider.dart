import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/weather_service.dart';
import '../services/vitals_service.dart';

class HomeProvider extends ChangeNotifier {
  Patient? patient;
  VitalReading? vitals;
  HealthScore? healthScore;
  List<HealthAlert> alerts = [];
  String greeting = 'Bom dia';
  bool isLoading = true;

  // Dados climáticos do serviço externo
  String? weatherInfo;

  // Dados de wearable simulado do serviço externo
  VitalReading? liveVitals;

  Timer? _vitalTimer;

  HomeProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 600));

    patient = const Patient(
      id: 'p001',
      name: 'Felipe Meira',
      initials: 'FM',
      age: 22,
      conditions: ['Hipertensão leve', 'Diabetes tipo 2'],
      wearableConnected: true,
      notificationCount: 3,
    );

    vitals = const VitalReading(
      heartRate: 72,
      spO2: 98.5,
      glucoseLevel: 104,
      bpSystolic: 120,
      bpDiastolic: 80,
      temperature: 36.8,
    );

    healthScore = const HealthScore(
      score: 84,
      level: HealthLevel.good,
      label: 'BOM',
      trend: TrendDirection.stable,
    );

    alerts = [
      const HealthAlert(
        id: 'a1',
        type: AlertType.warning,
        title: 'Glicemia levemente elevada',
        description: 'Leitura às 08:15 — 126 mg/dL. Considere ajuste alimentar.',
        timeLabel: '08:15',
        actionLabel: 'Ver detalhes',
      ),
      const HealthAlert(
        id: 'a2',
        type: AlertType.info,
        title: 'Medicamento às 14h',
        description: 'Metformina 500mg — não esqueça de tomar com água.',
        timeLabel: '14:00',
      ),
      const HealthAlert(
        id: 'a3',
        type: AlertType.ok,
        title: 'FreqCardíaca normal',
        description: 'Média de 71 bpm nas últimas 2h — dentro do esperado.',
        timeLabel: 'Agora',
      ),
    ];

    final now = DateTime.now();
    final h = now.hour;
    greeting = h < 12 ? 'Bom dia' : h < 18 ? 'Boa tarde' : 'Boa noite';

    isLoading = false;
    notifyListeners();

    // Busca dados externos
    _fetchWeather();
    _startVitalPolling();
  }

  Future<void> _fetchWeather() async {
    try {
      weatherInfo = await WeatherService.fetchSaoPauloWeather();
      notifyListeners();
    } catch (_) {}
  }

  void _startVitalPolling() {
    _vitalTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        liveVitals = await VitalsService.fetchSimulatedVitals();
        if (liveVitals != null) {
          vitals = liveVitals;
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _vitalTimer?.cancel();
    super.dispose();
  }
}
