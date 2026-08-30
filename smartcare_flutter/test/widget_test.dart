import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/storage/local_cache.dart';
import 'package:smartcare_flutter/core/theme/app_theme.dart';
import 'package:smartcare_flutter/data/repositories/settings_repository_impl.dart';
import 'package:smartcare_flutter/presentation/providers/home_provider.dart';
import 'package:smartcare_flutter/presentation/providers/settings_provider.dart';
import 'package:smartcare_flutter/presentation/screens/home_screen.dart';

import 'presentation/fake_health_repository.dart';

void main() {
  late FakeHealthRepository repository;
  late HomeProvider home;

  Future<void> pumpDashboard(WidgetTester tester,
      {ThemeMode themeMode = ThemeMode.light}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: home),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              SettingsRepositoryImpl(InMemoryCache()),
            ),
          ),
        ],
        child: MaterialApp(
          theme: SmartCareTheme.light,
          darkTheme: SmartCareTheme.dark,
          themeMode: themeMode,
          home: const HomeScreen(),
        ),
      ),
    );
    // `pumpAndSettle` não serve aqui: o indicador de monitoramento
    // (PulsingDot) tem animação contínua e a árvore nunca fica ociosa.
    await tester.pump(const Duration(milliseconds: 50));
  }

  setUp(() {
    repository = FakeHealthRepository();
    home = HomeProvider(repository: repository, autoStart: false);
  });

  tearDown(() => home.dispose());

  testWidgets('dashboard exibe o score calculado e o nome do paciente',
      (tester) async {
    await home.refresh();
    await pumpDashboard(tester);

    expect(find.text('Score de saúde'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('EXCELENTE'), findsOneWidget);
    expect(find.text('Felipe Meira'), findsOneWidget);
  });

  testWidgets('alerta gerado pelo motor de regras aparece na lista',
      (tester) async {
    repository.reading =
        FakeHealthRepository.stable.copyWith(glucoseLevel: 210);
    await home.refresh();
    await pumpDashboard(tester);

    expect(find.textContaining('Glicemia: 210'), findsOneWidget);
  });

  testWidgets('modo offline mostra a faixa de aviso', (tester) async {
    repository.fromCache = true;
    await home.refresh();
    await pumpDashboard(tester);

    expect(find.textContaining('Sem conexão com o gateway'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
  });

  testWidgets('falha de rede exibe mensagem com ação de nova tentativa',
      (tester) async {
    repository.failure = const NetworkFailure();
    await home.refresh();
    await pumpDashboard(tester);

    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('o tema escuro é aplicado sem quebrar o dashboard',
      (tester) async {
    await home.refresh();
    await pumpDashboard(tester, themeMode: ThemeMode.dark);

    expect(find.text('Score de saúde'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
