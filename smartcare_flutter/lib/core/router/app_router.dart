import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/analytics_screen.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/consulta_screen.dart';
import '../../presentation/screens/credits_screen.dart';
import '../../presentation/screens/delivery_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/map_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/shell_screen.dart';

/// Rotas nomeadas do aplicativo.
///
/// Centralizar os caminhos em constantes elimina strings mágicas espalhadas
/// pelas telas e evita erros de digitação em `context.go(...)`.
abstract final class Routes {
  static const home = '/home';
  static const delivery = '/delivery';
  static const consulta = '/consulta';
  static const analytics = '/analytics';
  static const chat = '/chat';
  static const map = '/map';
  static const credits = '/credits';
  static const settings = '/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Configuração de navegação: abas dentro do shell e telas modais na raiz.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: Routes.home, builder: (c, s) => const HomeScreen()),
        GoRoute(path: Routes.delivery, builder: (c, s) => const DeliveryScreen()),
        GoRoute(path: Routes.consulta, builder: (c, s) => const ConsultaScreen()),
        GoRoute(path: Routes.analytics, builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: Routes.chat, builder: (c, s) => const ChatScreen()),
        GoRoute(path: Routes.map, builder: (c, s) => const MapScreen()),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.credits,
      builder: (c, s) => const CreditsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: Routes.settings,
      builder: (c, s) => const SettingsScreen(),
    ),
  ],
  // Rota inexistente não pode derrubar o app: mostra uma tela de recuperação.
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Página não encontrada')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text('Não encontramos "${state.uri}".'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    ),
  ),
);
