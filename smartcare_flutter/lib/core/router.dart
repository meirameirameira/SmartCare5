import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/shell_screen.dart';
import '../screens/home_screen.dart';
import '../screens/delivery_screen.dart';
import '../screens/consulta_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/map_screen.dart';
import '../screens/credits_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/home',      builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/delivery',  builder: (c, s) => const DeliveryScreen()),
        GoRoute(path: '/consulta',  builder: (c, s) => const ConsultaScreen()),
        GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/chat',      builder: (c, s) => const ChatScreen()),
        GoRoute(path: '/map',       builder: (c, s) => const MapScreen()),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/credits',
      builder: (c, s) => const CreditsScreen(),
    ),
  ],
);
