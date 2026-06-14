import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Integração com RandomUser / JSONPlaceholder para simular leitura de wearable
/// Em produção: substituir por endpoint MQTT/REST do gateway de dispositivos SmartCare 5.0
class VitalsService {
  static final _rng = Random();

  // Simula leitura de wearable via API pública (JSONPlaceholder como proxy de dados)
  // Em produção seria um endpoint HTTPS do gateway IoT SmartCare 5.0
  static Future<VitalReading?> fetchSimulatedVitals() async {
    try {
      // Usamos a NumbersAPI para obter um seed numérico e gerar vitals variados
      final uri = Uri.parse('http://numbersapi.com/random/math?json');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      // Extrai número para seed de variação
      int seed = 0;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        seed = (data['number'] as num?)?.toInt() ?? 0;
      }

      // Gera vitals com pequena variação baseada no seed
      final hrVariation = (seed % 10) - 5;
      final spo2Variation = (seed % 3) * 0.1;

      return VitalReading(
        heartRate: (72 + hrVariation).clamp(55, 100),
        spO2: (98.5 + spo2Variation).clamp(94.0, 100.0),
        glucoseLevel: (104 + (seed % 20) - 10).clamp(70, 180),
        bpSystolic: (120 + (seed % 8) - 4).clamp(100, 140),
        bpDiastolic: (80 + (seed % 6) - 3).clamp(60, 90),
        temperature: (36.8 + (seed % 4) * 0.1).clamp(36.0, 37.5),
      );
    } catch (_) {
      return null;
    }
  }
}
