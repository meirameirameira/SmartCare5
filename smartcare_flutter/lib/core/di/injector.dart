import 'package:flutter/foundation.dart';

import '../../data/datasources/remote/ai_remote_datasource.dart';
import '../../data/datasources/remote/vitals_remote_datasource.dart';
import '../../data/datasources/remote/weather_remote_datasource.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../data/repositories/logistics_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/repositories.dart';
import '../network/api_client.dart';
import '../storage/local_cache.dart';

/// Composição de dependências do aplicativo (Composition Root).
///
/// Um único lugar decide qual implementação concreta atende cada contrato de
/// domínio. Os providers recebem as interfaces prontas — nenhum widget conhece
/// `Dio`, `SharedPreferences` ou `Geolocator`.
///
/// Nos testes basta construir um [Injector] com [LocalCache] em memória e
/// datasources falsos.
class Injector {
  Injector({
    required this.cache,
    ApiClient? apiClient,
    VitalsDataSource? vitalsDataSource,
  }) : apiClient = apiClient ?? ApiClient() {
    final weatherDs = WeatherRemoteDataSource(this.apiClient);

    // Sem gateway IoT configurado (--dart-define=SMARTCARE_API_URL), o app roda
    // com o simulador de wearable em vez de falhar silenciosamente.
    final vitalsDs = vitalsDataSource ??
        (WearableGatewayDataSource.isConfigured
            ? WearableGatewayDataSource(
                this.apiClient,
                baseUrl: WearableGatewayDataSource.configuredBaseUrl,
              )
            : SimulatedVitalsDataSource());

    health = HealthRepositoryImpl(
      vitals: vitalsDs,
      weather: weatherDs,
      cache: cache,
    );
    delivery = DeliveryRepositoryImpl();
    consulta = ConsultaRepositoryImpl();
    analytics = AnalyticsRepositoryImpl(health: health);
    chat = ChatRepositoryImpl(
      remote: AiRemoteDataSource(this.apiClient),
      cache: cache,
    );
    devices = const DeviceRepositoryImpl();
    settings = SettingsRepositoryImpl(cache);

    debugPrint('[Injector] gateway IoT: '
        '${WearableGatewayDataSource.isConfigured ? "remoto" : "simulado"} · '
        'IA generativa: ${AiRemoteDataSource.isConfigured ? "Gemini" : "base local"}');
  }

  /// Constrói o grafo real de produção (cache em `SharedPreferences`).
  static Future<Injector> bootstrap() async {
    LocalCache cache;
    try {
      cache = await SharedPrefsCache.create();
    } catch (e) {
      debugPrint('[Injector] SharedPreferences indisponível ($e) — cache em memória');
      cache = InMemoryCache();
    }
    return Injector(cache: cache);
  }

  final LocalCache cache;
  final ApiClient apiClient;

  late final HealthRepository health;
  late final DeliveryRepository delivery;
  late final ConsultaRepository consulta;
  late final AnalyticsRepository analytics;
  late final ChatRepository chat;
  late final DeviceRepository devices;
  late final SettingsRepository settings;
}
