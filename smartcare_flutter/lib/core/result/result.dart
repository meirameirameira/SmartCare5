import '../error/failures.dart';

/// Tipo `Result` selado — modela sucesso ou falha sem lançar exceções através
/// das camadas. Inspirado em `Either` (funcional) mas com nomes de domínio.
///
/// Uso típico:
/// ```dart
/// final result = await repository.loadVitals();
/// result.when(
///   ok: (vitals) => render(vitals),
///   err: (failure) => showError(failure.message),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// Constrói um resultado de sucesso.
  const factory Result.ok(T value) = Ok<T>;

  /// Constrói um resultado de falha.
  const factory Result.err(AppFailure failure) = Err<T>;

  /// Executa [body] capturando exceções e convertendo-as em [AppFailure].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on AppFailure catch (f) {
      return Err(f);
    } catch (e) {
      return Err(UnexpectedFailure(cause: e));
    }
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Valor em caso de sucesso, `null` em caso de falha.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// Falha em caso de erro, `null` em caso de sucesso.
  AppFailure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  /// Valor em caso de sucesso, [fallback] caso contrário.
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// Transforma o valor de sucesso, preservando a falha.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok(transform(value)),
        Err<T>(:final failure) => Err(failure),
      };

  /// Encadeia outra operação que também retorna [Result].
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => transform(value),
        Err<T>(:final failure) => Err(failure),
      };

  /// Reduz para um único valor tratando ambos os casos.
  R when<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;

  @override
  String toString() => 'Err($failure)';
}
