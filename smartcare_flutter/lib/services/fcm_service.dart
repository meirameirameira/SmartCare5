import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Simula envio de notificação push via Firebase Cloud Messaging.
/// Em produção: o backend SmartCare 5.0 envia mensagens FCM usando o Admin SDK.
class FcmService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
    _initialized = true;
  }

  /// Simula um alerta de saúde recebido via FCM
  static Future<void> simulateHealthAlert({
    required String title,
    required String body,
  }) async {
    await init();
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smartcare_alerts',
          'Alertas SmartCare 5.0',
          channelDescription: 'Notificações de saúde e logística do SmartCare 5.0',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Simula alertas pré-definidos do sistema
  static Future<void> triggerMedicationReminder() => simulateHealthAlert(
    title: '💊 Lembrete de Medicamento',
    body: 'Hora de tomar Metformina 500mg — 14h00',
  );

  static Future<void> triggerVitalAlert() => simulateHealthAlert(
    title: '⚠️ Alerta de Glicemia',
    body: 'Glicemia acima de 140 mg/dL detectada. Verifique com seu médico.',
  );

  static Future<void> triggerDeliveryAlert() => simulateHealthAlert(
    title: '🚚 Entrega Próxima',
    body: 'Seus medicamentos chegam em ~15 min. Pedido #SC-2024-0412',
  );
}
