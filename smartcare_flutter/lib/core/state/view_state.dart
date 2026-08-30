import '../error/failures.dart';
import '../result/result.dart';

/// Estado de tela tipado — substitui a combinação frágil de
/// `bool isLoading` + `T? data` + `String? error` usada nos providers antigos.
///
/// Torna impossível representar estados inválidos (ex.: "carregando e com erro
/// ao mesmo tempo") e permite renderizar a UI com um único `switch` exaustivo.
sealed class ViewState<T> {
  const ViewState();

  const factory ViewState.idle() = Idle<T>;
  const factory ViewState.loading() = Loading<T>;
  const factory ViewState.ready(T data, {DateTime? updatedAt, bool fromCache}) =
      Ready<T>;
  const factory ViewState.failed(AppFailure failure, {T? staleData}) = Failed<T>;

  /// Converte um [Result] em estado de tela, preservando dados antigos em caso
  /// de falha (degradação graciosa — a tela continua útil offline).
  factory ViewState.fromResult(Result<T> result, {T? previousData}) =>
      result.when(
        ok: (value) => Ready<T>(value, updatedAt: DateTime.now()),
        err: (failure) => Failed<T>(failure, staleData: previousData),
      );

  bool get isLoading => this is Loading<T>;

  /// Dados disponíveis para renderizar (inclusive dados obsoletos após falha).
  T? get dataOrNull => switch (this) {
        Ready<T>(:final data) => data,
        Failed<T>(:final staleData) => staleData,
        _ => null,
      };

  AppFailure? get failureOrNull =>
      this is Failed<T> ? (this as Failed<T>).failure : null;

  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data, DateTime? updatedAt, bool fromCache) ready,
    required R Function(AppFailure failure, T? staleData) failed,
  }) =>
      switch (this) {
        Idle<T>() => idle(),
        Loading<T>() => loading(),
        Ready<T>(:final data, :final updatedAt, :final fromCache) =>
          ready(data, updatedAt, fromCache),
        Failed<T>(:final failure, :final staleData) => failed(failure, staleData),
      };
}

final class Idle<T> extends ViewState<T> {
  const Idle();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Ready<T> extends ViewState<T> {
  const Ready(this.data, {this.updatedAt, this.fromCache = false});
  final T data;
  final DateTime? updatedAt;

  /// `true` quando os dados vieram do cache local (app offline / API lenta).
  final bool fromCache;
}

final class Failed<T> extends ViewState<T> {
  const Failed(this.failure, {this.staleData});
  final AppFailure failure;

  /// Últimos dados válidos conhecidos, se houver.
  final T? staleData;
}
