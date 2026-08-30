import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injector.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/consulta_provider.dart';
import 'presentation/providers/delivery_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/settings_provider.dart';

/// Raiz do aplicativo.
///
/// Recebe o [Injector] já construído e apenas conecta os repositórios aos
/// providers — nenhuma tela instancia dependência concreta.
class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key, required this.injector});

  final Injector injector;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => SettingsProvider(injector.settings)),
        ChangeNotifierProvider(
            create: (_) => HomeProvider(repository: injector.health)),
        ChangeNotifierProvider(create: (_) => DeliveryProvider(injector.delivery)),
        ChangeNotifierProvider(create: (_) => ConsultaProvider(injector.consulta)),
        ChangeNotifierProvider(
            create: (_) => AnalyticsProvider(injector.analytics)),
        ChangeNotifierProvider(create: (_) => MapProvider(injector.devices)),

        // O chat depende do estado de saúde para enviar o contexto clínico
        // junto da pergunta — daí o proxy provider.
        ChangeNotifierProxyProvider<HomeProvider, ChatProvider>(
          create: (_) => ChatProvider(injector.chat),
          update: (_, home, chat) => (chat ?? ChatProvider(injector.chat))
            ..attachHealthContext(home),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Mantém o serviço de notificações alinhado à preferência do usuário.
    NotificationService.instance.setEnabled(settings.alertsEnabled);

    return MaterialApp.router(
      title: 'SmartCare 5.0',
      debugShowCheckedModeBanner: false,
      theme: SmartCareTheme.light,
      darkTheme: SmartCareTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        // Escala de texto controlada pelas preferências de acessibilidade,
        // respeitando também o ajuste do sistema operacional.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              media.textScaler.scale(1) * settings.textScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
