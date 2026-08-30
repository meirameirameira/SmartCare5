import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injector.dart';
import 'core/notifications/notification_service.dart';

/// Ponto de entrada.
///
/// Responsabilidade única: preparar plataforma (Firebase, notificações),
/// montar o grafo de dependências e subir a UI. Toda a lógica de negócio vive
/// em `domain/` e `data/`.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.init();
  await _setupFirebaseMessaging();

  final injector = await Injector.bootstrap();

  runApp(SmartCareApp(injector: injector));
}

/// Configura o FCM quando o projeto Firebase está disponível.
///
/// Sem `google-services.json` o app continua funcionando em modo demo com
/// notificações locais — antes essa falha era engolida sem qualquer registro.
Future<void> _setupFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      NotificationService.instance.show(
        title: notification.title ?? 'SmartCare 5.0',
        body: notification.body ?? '',
      );
    });
  } catch (e) {
    debugPrint('[main] Firebase indisponível ($e) — push remoto desativado, '
        'notificações locais seguem ativas');
  }
}
