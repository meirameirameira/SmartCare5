/// Hierarquia selada de falhas do domínio SmartCare 5.0.
///
/// Substitui o antigo padrão `try { ... } catch (_) {}` espalhado pelos
/// providers: agora toda falha é um valor tipado que atravessa as camadas
/// (data -> domain -> presentation) e pode ser renderizada na UI.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  /// Mensagem pronta para exibição ao usuário (pt-BR).
  final String message;

  /// Erro original (para logging / debug), nunca exibido ao usuário.
  final Object? cause;

  /// Indica se faz sentido oferecer um botão "Tentar novamente" na UI.
  bool get isRetryable => switch (this) {
        NetworkFailure() => true,
        TimeoutFailure() => true,
        ServerFailure(:final statusCode) => statusCode >= 500,
        CacheFailure() => false,
        PermissionFailure() => false,
        UnexpectedFailure() => true,
      };

  @override
  String toString() => '$runtimeType($message)${cause == null ? '' : ' <- $cause'}';
}

/// Sem conectividade ou host inacessível.
class NetworkFailure extends AppFailure {
  const NetworkFailure({super.cause})
      : super('Sem conexão com a internet. Exibindo dados salvos.');
}

/// A requisição excedeu o tempo limite.
class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.cause})
      : super('O servidor demorou para responder. Tente novamente.');
}

/// O servidor respondeu com um status de erro.
class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode, {String? detail, super.cause})
      : super(detail ?? 'Falha no servidor SmartCare (código $statusCode).',
            );

  final int statusCode;
}

/// Falha ao ler/gravar o cache local.
class CacheFailure extends AppFailure {
  const CacheFailure({String? detail, super.cause})
      : super(detail ?? 'Não foi possível acessar os dados salvos no dispositivo.',
            );
}

/// Permissão de sistema negada (localização, notificação, etc.).
class PermissionFailure extends AppFailure {
  const PermissionFailure(this.permission, {super.cause})
      : super('Permissão necessária não concedida: $permission.');

  final String permission;
}

/// Qualquer erro não mapeado.
class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.cause})
      : super('Ocorreu um erro inesperado. Tente novamente.');
}
