import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];
  bool isTyping = false;

  final List<QuickPrompt> quickPrompts = const [
    QuickPrompt(label: '📊 Minha glicemia', message: 'Como está minha glicemia nas últimas 24h?'),
    QuickPrompt(label: '💊 Medicamentos', message: 'Quais medicamentos devo tomar hoje?'),
    QuickPrompt(label: '🏃 Exercícios', message: 'Que exercícios são seguros para minha condição?'),
    QuickPrompt(label: '😴 Sono', message: 'Como o sono afeta minha pressão arterial?'),
  ];

  ChatProvider() {
    messages = [
      ChatMessage(
        id: 'm0',
        role: MessageRole.ai,
        content: 'Olá! Sou o assistente SmartCare 5.0. Posso analisar seus dados de saúde e responder dúvidas. Como posso ajudar?',
        timeLabel: _now(),
      ),
    ];
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages = [
      ...messages,
      ChatMessage(id: 'm${messages.length}', role: MessageRole.user, content: text, timeLabel: _now()),
    ];
    isTyping = true;
    notifyListeners();

    // Chama o serviço de IA (simulado com respostas pré-definidas ou API real)
    final response = await AiService.ask(text);

    messages = [
      ...messages,
      ChatMessage(id: 'm${messages.length}', role: MessageRole.ai, content: response, timeLabel: _now()),
    ];
    isTyping = false;
    notifyListeners();
  }

  String _now() {
    final t = DateTime.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
