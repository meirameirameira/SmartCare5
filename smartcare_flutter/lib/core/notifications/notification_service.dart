import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/entities.dart';

/// Canal único de notificações locais e push (FCM) do SmartCare 5.0.
///
/// Substitui o antigo `FcmService` estático: agora há inicialização
/// idempotente, respeito à preferência do usuário (alertas ligados/desligados)
/// e um método que dispara alertas **derivados dos sinais vitais reais**, em
/// vez de textos fixos.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _enabled = true;

  static const _channel = AndroidNotificationDetails(
    'smartcare_alerts',
    'Alertas SmartCare 5.0',
    channelDescription: 'Notificações de saúde e logística do SmartCare 5.0',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  /// Liga/desliga o envio conforme a preferência do usuário.
  void setEnabled(bool enabled) => _enabled = enabled;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] inicialização indisponível: $e');
    }
  }

  Future<void> show({required String title, required String body}) async {
    if (!_enabled) {
      debugPrint('[NotificationService] alertas desativados pelo usuário');
      return;
    }
    await init();
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title,
        body,
        const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationService] falha ao exibir notificação: $e');
    }
  }

  /// Converte um alerta do motor de regras em notificação para o paciente.
  Future<void> pushHealthAlert(HealthAlert alert) => show(
        title: switch (alert.type) {
          AlertType.urgent => '🚨 ${alert.title}',
          AlertType.warning => '⚠️ ${alert.title}',
          AlertType.info => '💊 ${alert.title}',
          AlertType.ok => '✅ ${alert.title}',
        },
        body: alert.description,
      );

  Future<void> medicationReminder() => show(
        title: '💊 Lembrete de Medicamento',
        body: 'Hora de tomar Metformina 500mg — 14h00',
      );

  Future<void> deliveryAlert() => show(
        title: '🚚 Entrega Próxima',
        body: 'Seus medicamentos chegam em ~15 min. Pedido #SC-2024-0412',
      );
}
