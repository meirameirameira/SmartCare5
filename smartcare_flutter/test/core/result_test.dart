import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/result/result.dart';
import 'package:smartcare_flutter/core/state/view_state.dart';

void main() {
  group('Result', () {
    test('Ok carrega o valor e não carrega falha', () {
      const result = Result.ok(42);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.getOrElse(0), 42);
    });

    test('Err carrega a falha e usa o valor padrão', () {
      const result = Result<int>.err(NetworkFailure());
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.getOrElse(7), 7);
    });

    test('map transforma o sucesso e preserva a falha', () {
      expect(const Result.ok(2).map((v) => v * 3).valueOrNull, 6);
      expect(
        const Result<int>.err(TimeoutFailure()).map((v) => v * 3).failureOrNull,
        isA<TimeoutFailure>(),
      );
    });

    test('guard converte exceção inesperada em UnexpectedFailure', () async {
      final result = await Result.guard<int>(() async => throw StateError('x'));
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });

    test('guard preserva AppFailure lançada pela camada de dados', () async {
      final result = await Result.guard<int>(
        () async => throw const ServerFailure(503),
      );
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('AppFailure', () {
    test('falhas transitórias são elegíveis a retry', () {
      expect(const NetworkFailure().isRetryable, isTrue);
      expect(const TimeoutFailure().isRetryable, isTrue);
      expect(const ServerFailure(500).isRetryable, isTrue);
    });

    test('erro do cliente e permissão negada não são retentáveis', () {
      expect(const ServerFailure(404).isRetryable, isFalse);
      expect(const PermissionFailure('localização').isRetryable, isFalse);
    });
  });

  group('ViewState', () {
    test('falha preserva os dados anteriores para degradação graciosa', () {
      final state = ViewState<int>.fromResult(
        const Result<int>.err(NetworkFailure()),
        previousData: 10,
      );
      expect(state.dataOrNull, 10);
      expect(state.failureOrNull, isA<NetworkFailure>());
    });

    test('sucesso vira estado pronto com carimbo de atualização', () {
      final state = ViewState<int>.fromResult(const Result.ok(5));
      expect(state.dataOrNull, 5);
      expect(state.failureOrNull, isNull);
      expect((state as Ready<int>).updatedAt, isNotNull);
    });

    test('loading não expõe dados nem falha', () {
      const state = ViewState<int>.loading();
      expect(state.isLoading, isTrue);
      expect(state.dataOrNull, isNull);
      expect(state.failureOrNull, isNull);
    });
  });
}
