import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/failures.dart';

/// Cliente HTTP único do SmartCare 5.0.
///
/// Antes cada service abria seu próprio `http.get` com timeout copiado e
/// tratamento de erro divergente. Agora existe um só ponto com:
///  - timeouts padronizados;
///  - retry com backoff exponencial para falhas transitórias;
///  - log estruturado apenas em modo debug;
///  - tradução de exceções de transporte para [AppFailure] tipada.
class ApiClient {
  ApiClient({Dio? dio, this.maxRetries = 2})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              headers: const {'Accept': 'application/json'},
            )) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, logPrint: (o) {
          debugPrint('[ApiClient] $o');
        }),
      );
    }
  }

  final Dio _dio;

  /// Número de novas tentativas após a primeira falha transitória.
  final int maxRetries;

  /// GET que devolve JSON decodificado, com retry e falhas tipadas.
  ///
  /// [decode] converte o corpo bruto no modelo desejado, mantendo o parsing
  /// fora das camadas de UI.
  Future<T> getJson<T>(
    String url, {
    required T Function(Map<String, dynamic> json) decode,
    Map<String, dynamic>? query,
  }) async {
    return _withRetry(() async {
      final response = await _dio.get<dynamic>(url, queryParameters: query);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ServerFailure(status);
      }
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ServerFailure(200, detail: 'Resposta em formato inesperado.');
      }
      return decode(body);
    });
  }

  /// POST com corpo JSON.
  Future<T> postJson<T>(
    String url, {
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic> json) decode,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    return _withRetry(() async {
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        queryParameters: query,
        options: Options(headers: {'Content-Type': 'application/json', ...?headers}),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ServerFailure(status);
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerFailure(200, detail: 'Resposta em formato inesperado.');
      }
      return decode(data);
    });
  }

  /// Executa [action] repetindo em falhas transitórias com backoff exponencial
  /// (300ms, 600ms, 1200ms...). Falhas definitivas (4xx) não são repetidas.
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        final failure = mapError(error);
        final canRetry = failure.isRetryable && attempt < maxRetries;
        if (!canRetry) throw failure;
        final delay = Duration(milliseconds: 300 * (1 << attempt));
        debugPrint('[ApiClient] tentativa ${attempt + 1} falhou (${failure.runtimeType}); '
            'repetindo em ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }

  /// Traduz qualquer erro de transporte em uma [AppFailure] de domínio.
  @visibleForTesting
  static AppFailure mapError(Object error) {
    if (error is AppFailure) return error;

    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          TimeoutFailure(cause: error),
        DioExceptionType.connectionError => NetworkFailure(cause: error),
        DioExceptionType.badResponse =>
          ServerFailure(error.response?.statusCode ?? 0, cause: error),
        _ => error.error is SocketException
            ? NetworkFailure(cause: error)
            : UnexpectedFailure(cause: error),
      };
    }

    if (error is TimeoutException) return TimeoutFailure(cause: error);
    if (error is SocketException) return NetworkFailure(cause: error);
    return UnexpectedFailure(cause: error);
  }
}
