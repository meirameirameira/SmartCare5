import 'package:flutter/foundation.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import 'home_provider.dart';

/// Provider do assistente conversacional.
///
/// Novidades desta fase: histórico persistido entre sessões e envio do
/// contexto clínico corrente (últimos sinais vitais) junto da pergunta.
class ChatProvider extends ChangeNotifier {
  ChatProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) _restore();
  }

  final ChatRepository _repository;

  List<ChatMessage> messages = const [];
  bool isTyping = false;

  /// Preenchido pela árvore de widgets (`ChangeNotifierProxyProvider`) para
  /// que a IA responda com os dados mais recentes do wearable.
  HomeProvider? _healthContext;

  final List<QuickPrompt> quickPrompts = const [
    QuickPrompt(label: '📊 Minha glicemia', message: 'Como está minha glicemia agora?'),
    QuickPrompt(label: '💊 Medicamentos', message: 'Quais medicamentos devo tomar hoje?'),
    QuickPrompt(label: '🏃 Exercícios', message: 'Que exercícios são seguros para minha condição?'),
    QuickPrompt(label: '🩺 Meu score', message: 'Como está meu score de saúde?'),
  ];

  static final _welcome = ChatMessage(
    id: 'welcome',
    role: MessageRole.ai,
    content: 'Olá! Sou o assistente SmartCare 5.0. Analiso seus sinais vitais em '
        'tempo real e respondo suas dúvidas de saúde. Como posso ajudar?',
    timeLabel: _hhmm(DateTime.now()),
  );

  /// Injeta o provider de saúde como fonte de contexto clínico.
  void attachHealthContext(HomeProvider home) => _healthContext = home;

  Future<void> _restore() async {
    final history = await _repository.loadHistory();
    messages = history.isEmpty ? [_welcome] : history;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final question = text.trim();
    if (question.isEmpty || isTyping) return;

    messages = [
      ...messages,
      ChatMessage(
        id: 'u${DateTime.now().microsecondsSinceEpoch}',
        role: MessageRole.user,
        content: question,
        timeLabel: _hhmm(DateTime.now()),
      ),
    ];
    isTyping = true;
    notifyListeners();

    final result =
        await _repository.ask(question, context: _healthContext?.vitals);
    final answer = result.when(
      ok: (text) => text,
      err: (failure) => failure.message,
    );

    messages = [
      ...messages,
      ChatMessage(
        id: 'a${DateTime.now().microsecondsSinceEpoch}',
        role: MessageRole.ai,
        content: answer,
        timeLabel: _hhmm(DateTime.now()),
      ),
    ];
    isTyping = false;
    notifyListeners();

    await _repository.saveHistory(messages);
  }

  /// Limpa a conversa e o histórico salvo no dispositivo.
  Future<void> clearConversation() async {
    messages = [_welcome];
    notifyListeners();
    await _repository.clearHistory();
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
