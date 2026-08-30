import '../../../core/network/api_client.dart';

/// Condições climáticas atuais já formatadas para o dashboard.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.label,
    required this.temperatureC,
    required this.humidity,
  });

  final String label;
  final double temperatureC;
  final int humidity;

  String get summary =>
      '$label · ${temperatureC.toStringAsFixed(0)}°C · Umidade $humidity%';

  Map<String, dynamic> toJson() => {
        'label': label,
        'temperatureC': temperatureC,
        'humidity': humidity,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) => WeatherSnapshot(
        label: json['label'] as String,
        temperatureC: (json['temperatureC'] as num).toDouble(),
        humidity: (json['humidity'] as num).toInt(),
      );
}

/// Integração com a Open-Meteo (HTTPS, sem chave de API).
///
/// A responsabilidade aqui é só falar HTTP e desserializar; retry, timeout e
/// tradução de erros ficam no [ApiClient], e a decisão de usar cache fica no
/// repositório.
class WeatherRemoteDataSource {
  WeatherRemoteDataSource(this._client);

  final ApiClient _client;

  static const _url = 'https://api.open-meteo.com/v1/forecast';

  /// Clima de São Paulo (coordenadas padrão do piloto SmartCare).
  Future<WeatherSnapshot> fetch({
    double latitude = -23.55,
    double longitude = -46.63,
  }) {
    return _client.getJson(
      _url,
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'current': 'temperature_2m,relative_humidity_2m,weathercode',
        'timezone': 'America/Sao_Paulo',
      },
      decode: (json) {
        final current = (json['current'] as Map).cast<String, dynamic>();
        return WeatherSnapshot(
          label: describeCode((current['weathercode'] as num).toInt()),
          temperatureC: (current['temperature_2m'] as num).toDouble(),
          humidity: (current['relative_humidity_2m'] as num).toInt(),
        );
      },
    );
  }

  /// Tradução dos códigos WMO usados pela Open-Meteo.
  static String describeCode(int code) {
    if (code == 0) return '☀️ Céu limpo';
    if (code <= 3) return '⛅ Parcialmente nublado';
    if (code <= 48) return '🌫️ Nublado/neblina';
    if (code <= 67) return '🌧️ Chuva';
    if (code <= 77) return '❄️ Neve';
    if (code <= 82) return '🌦️ Chuva leve';
    return '⛈️ Tempestade';
  }
}
