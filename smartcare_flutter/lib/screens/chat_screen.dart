import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../core/theme.dart';
import '../models/models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(ChatProvider p) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    p.sendMessage(text).then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖 ', style: TextStyle(fontSize: 18)),
            Text('Assistente SmartCare'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: p.messages.length + (p.isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (p.isTyping && i == p.messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(message: p.messages[i]);
              },
            ),
          ),

          // Quick prompts
          if (p.messages.length <= 1)
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final q = p.quickPrompts[i];
                  return ActionChip(
                    label: Text(q.label, style: const TextStyle(fontSize: 12)),
                    onPressed: () => p.sendMessage(q.message),
                  );
                },
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Pergunte sobre sua saúde...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(p),
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: SmartCareTheme.primaryGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _send(p),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isAi = message.role == MessageRole.ai;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: SmartCareTheme.primaryGreenLight,
              child: Text('🤖', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAi ? Colors.white : SmartCareTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content,
                      style: TextStyle(
                          color: isAi ? Colors.black87 : Colors.white,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(message.timeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: isAi ? Colors.grey : Colors.white70)),
                ],
              ),
            ),
          ),
          if (!isAi) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: SmartCareTheme.primaryGreenLight,
          child: Text('🤖', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            width: 40, height: 16,
            child: Center(child: LinearProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
