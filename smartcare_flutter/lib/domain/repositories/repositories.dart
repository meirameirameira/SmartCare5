import '../../core/result/result.dart';
import '../entities/entities.dart';

/// Contratos de repositório do SmartCare 5.0 (camada de domínio).
///
/// Aplicam o **Princípio da Inversão de Dependência**: os providers de UI
/// dependem destas interfaces, nunca das implementações concretas em `data/`.
/// Isso permite trocar a fonte de dados (REST, MQTT, Firebase, mock de demo)
/// e injetar fakes nos testes sem alterar uma linha de tela.

/// Dado com origem declarada — a UI precisa saber se está exibindo cache.
class Sourced<T> {
  const Sourced(this.value, {this.fromCache = false, this.updatedAt});

  final T value;
  final bool fromCache;
  final DateTime? updatedAt;
}

abstract interface class HealthRepository {
  /// Perfil do paciente monitorado.
  Future<Result<Patient>> loadPatient();

  /// Última leitura do wearable. Estratégia offline-first: em falha de rede
  /// devolve o cache local, se houver.
  Future<Result<Sourced<VitalReading>>> loadVitals();

  /// Condições climáticas usadas nas recomendações contextuais.
  Future<Result<Sourced<String>>> loadWeather();
}

abstract interface class DeliveryRepository {
  Future<Result<DeliveryOrder>> loadActiveOrder();
  Future<Result<HomeCareVisit>> loadNextVisit();
  Future<Result<DeliveryOrder>> confirmDelivery(String orderId);
}

abstract interface class ConsultaRepository {
  Future<Result<Appointment>> loadNextAppointment();
  Future<Result<List<Doctor>>> loadAvailableDoctors();
  Future<Result<NursingQueue>> loadNursingQueue();
}

abstract interface class AnalyticsRepository {
  Future<Result<List<MetricSeries>>> loadMetrics(int periodDays);
  Future<Result<List<AiInsight>>> loadInsights(int periodDays);
}

abstract interface class ChatRepository {
  /// Envia a pergunta ao assistente (Gemini ou fallback local).
  Future<Result<String>> ask(String question, {VitalReading? context});

  /// Histórico persistido localmente entre sessões.
  Future<List<ChatMessage>> loadHistory();
  Future<void> saveHistory(List<ChatMessage> messages);
  Future<void> clearHistory();
}

abstract interface class DeviceRepository {
  Future<Result<List<SmartDevice>>> loadDevices();
  Future<Result<({double lat, double lng})>> currentLocation();
}

/// Preferências de acessibilidade e aparência, persistidas no dispositivo.
abstract interface class SettingsRepository {
  Future<String?> readThemeMode();
  Future<void> writeThemeMode(String mode);
  Future<double?> readTextScale();
  Future<void> writeTextScale(double scale);
  Future<bool?> readAlertsEnabled();
  Future<void> writeAlertsEnabled(bool enabled);
}
