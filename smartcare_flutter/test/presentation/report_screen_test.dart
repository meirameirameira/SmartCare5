import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/result/result.dart';
import 'package:smartcare_flutter/core/theme/app_theme.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/repositories/repositories.dart';
import 'package:smartcare_flutter/presentation/providers/report_provider.dart';
import 'package:smartcare_flutter/presentation/screens/report_screen.dart';

class _FakeReportRepository implements ReportRepository {
  final List<int> requested = [];
  AppFailure? failure;
  bool fromCache = false;

  @override
  Future<Result<Sourced<ClinicalReport>>> loadReport(int periodDays) async {
    requested.add(periodDays);
    if (failure != null) return Err(failure!);
    return Ok(Sourced(report(periodDays), fromCache: fromCache));
  }

  static ClinicalReport report(int days) => ClinicalReport(
        patientName: 'Joao Silva',
        periodDays: days,
        generatedAt: DateTime(2026, 10, 2, 14, 30),
        readings: days * 6,
        averages: const VitalAverages(
          heartRate: 78.4,
          spO2: 96.2,
          glucose: 151.3,
          systolic: 128.9,
          diastolic: 82.0,
          temperature: 36.5,
        ),
        latestScore: 41,
        averageScore: 63.5,
        riskLevel: 'ATENCAO',
        glucoseTimeInRange: 18.3,
        openAlerts: 5,
        urgentAlerts: 1,
        alertsInPeriod: 5,
        deliveriesTotal: 2,
        deliveriesDelivered: 1,
        summary: 'Joao Silva, 68 anos (Diabetes tipo 2) | Score atual: 41/100 - ATENCAO',
        engine: ReportEngine.oraclePlsql,
      );
}

void main() {
  late _FakeReportRepository repository;
  late ReportProvider provider;

  setUp(() {
    repository = _FakeReportRepository();
    provider = ReportProvider(repository);
  });

  tearDown(() => provider.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    // Tela de celular alta o bastante para o relatorio inteiro (a lista e
    // preguicosa e nao constroi o que esta fora da area visivel).
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(theme: SmartCareTheme.light, home: const ReportScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ReportProvider', () {
    test('so carrega quando a tela pede e nao repete a carga', () async {
      expect(repository.requested, isEmpty);

      await provider.ensureLoaded();
      await provider.ensureLoaded();

      expect(repository.requested, [30]);
      expect(provider.report!.latestScore, 41);
    });

    test('trocar o periodo recarrega com o novo numero de dias', () async {
      await provider.ensureLoaded();
      provider.selectPeriod(7);
      await Future<void>.delayed(Duration.zero);

      expect(repository.requested, [30, 7]);
      expect(provider.report!.periodDays, 7);
    });

    test('falha sem dados anteriores fica exposta para a tela', () async {
      repository.failure = const NetworkFailure();

      await provider.ensureLoaded();

      expect(provider.state.failureOrNull, isA<NetworkFailure>());
      expect(provider.report, isNull);
    });
  });

  testWidgets('tela mostra o selo do Oracle, o score e o resumo do banco', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Consolidado no Oracle por procedures PL/SQL'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('ATENCAO'), findsOneWidget);
    expect(find.textContaining('Joao Silva, 68 anos'), findsOneWidget);
    expect(find.text('18,3%'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('relatorio em cache exibe aviso de desatualizado', (tester) async {
    repository.fromCache = true;

    await pumpScreen(tester);

    expect(find.textContaining('último relatório salvo'), findsOneWidget);
  });

  testWidgets('erro sem cache oferece nova tentativa', (tester) async {
    repository.failure = const TimeoutFailure();

    await pumpScreen(tester);
    expect(find.text('Tentar novamente'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('41'), findsOneWidget);
  });
}
