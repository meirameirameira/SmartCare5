import 'dart:convert';
import 'package:http/http.dart' as http;

/// Integração com Open-Meteo API (gratuita, sem API key)
/// Retorna condições climáticas de São Paulo para exibir no dashboard
class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<String> fetchSaoPauloWeather() async {
    // São Paulo: lat=-23.55, lon=-46.63
    final uri = Uri.parse(
      '$_baseUrl?latitude=-23.55&longitude=-46.63'
      '&current=temperature_2m,relative_humidity_2m,weathercode'
      '&timezone=America%2FSao_Paulo',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>;

    final temp = current['temperature_2m'];
    final humidity = current['relative_humidity_2m'];
    final code = (current['weathercode'] as num).toInt();

    final condition = _weatherLabel(code);
    return '$condition · ${temp}°C · Umidade ${humidity}%';
  }

  static String _weatherLabel(int code) {
    if (code == 0) return '☀️ Céu limpo';
    if (code <= 3) return '⛅ Parcialmente nublado';
    if (code <= 48) return '🌫️ Nublado/neblina';
    if (code <= 67) return '🌧️ Chuva';
    if (code <= 77) return '❄️ Neve';
    if (code <= 82) return '🌦️ Chuva leve';
    return '⛈️ Tempestade';
  }
}
