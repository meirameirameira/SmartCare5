import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/result/result.dart';
import '../../core/storage/local_cache.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/ai_fallback_datasource.dart';
import '../datasources/remote/ai_remote_datasource.dart';

/// Assistente conversacional com **degradação graciosa**.
///
/// Se a API generativa não estiver configurada ou falhar, a resposta vem da
/// base local — o usuário nunca vê uma tela morta. O histórico é persistido,
/// de modo que a conversa sobrevive ao fechamento do app.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required AiRemoteDataSource remote,
    required LocalCache cache,
    this.fallback = const AiFallbackDataSource(),
    bool? remoteEnabled,
  })  : _remote = remote,
        _cache = cache,
        _remoteEnabled = remoteEnabled ?? AiRemoteDataSource.isConfigured;

  final AiRemoteDataSource _remote;
  final LocalCache _cache;
  final AiFallbackDataSource fallback;
  final bool _remoteEnabled;

  /// Limite de mensagens guardadas — evita crescer o cache indefinidamente.
  static const historyLimit = 100;

  @override
  Future<Result<String>> ask(String question, {VitalReading? context}) async {
    if (!_remoteEnabled) {
      return Ok(fallback.answer(question, vitals: context));
    }
    try {
      return Ok(await _remote.ask(question, vitals: context));
    } catch (error) {
      debugPrint('[ChatRepository] IA remota indisponível ($error) — usando base local');
      return Ok(fallback.answer(question, vitals: context));
    }
  }

  @override
  Future<List<ChatMessage>> loadHistory() async {
    final raw = await _cache.readString(CacheKeys.chatHistory);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ChatRepository] histórico corrompido, descartando: $e');
      await clearHistory();
      return const [];
    }
  }

  @override
  Future<void> saveHistory(List<ChatMessage> messages) async {
    final trimmed = messages.length > historyLimit
        ? messages.sublist(messages.length - historyLimit)
        : messages;
    await _cache.writeString(
      CacheKeys.chatHistory,
      jsonEncode(trimmed.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> clearHistory() => _cache.remove(CacheKeys.chatHistory);
}
