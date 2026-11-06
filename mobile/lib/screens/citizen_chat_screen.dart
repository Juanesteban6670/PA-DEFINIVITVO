import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/session_controller.dart';
import '../theme.dart';

class CitizenChatScreen extends StatefulWidget {
  const CitizenChatScreen({required this.session, super.key});

  final SessionController session;

  @override
  State<CitizenChatScreen> createState() => _CitizenChatScreenState();
}

class _CitizenChatScreenState extends State<CitizenChatScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  late final String _sessionId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _sessionId = 'mobile-${DateTime.now().microsecondsSinceEpoch}';
    _messages.add(
      const _ChatMessage(
        text: 'Hola. Soy el asistente de Cartagena Segura. Puedo orientarte sobre reportes, zonas de riesgo y servicios de emergencia. Si hay peligro inmediato, llama al 123.',
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    if (retryText == null) {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _input.clear();
    }
    setState(() => _sending = true);
    _scrollToEnd();

    try {
      final response = await widget.session.api.post('Ai/Chat', {
        'message': text,
        'sessionId': _sessionId,
      });
      if (response is! Map<String, dynamic> ||
          response['reply'] is! String ||
          (response['reply'] as String).trim().isEmpty) {
        throw const FormatException(
          'El asistente devolvió una respuesta vacía o inválida.',
        );
      }
      if (!mounted) return;
      _messages.add(_ChatMessage(text: response['reply'] as String));
    } on ApiException catch (error) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(text: error.message, error: true, retry: text),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(text: error.message, error: true, retry: text),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  void _retry(String text) {
    setState(() {
      _messages.removeWhere(
        (message) => message.error && message.retry == text,
      );
    });
    _send(text);
  }

  void _clearConversation() {
    if (_sending) return;
    setState(() {
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text: 'Conversación nueva. ¿En qué puedo orientarte sobre seguridad ciudadana?',
          ),
        );
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asistente ciudadano'),
            Text(
              'Orientación sobre seguridad',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: _clearConversation,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        onRetry: message.retry == null
                            ? null
                            : () => _retry(message.retry!),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu pregunta…',
                            prefixIcon: Icon(Icons.chat_bubble_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Enviar mensaje',
                        onPressed: _sending ? null : () => _send(),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    this.fromUser = false,
    this.error = false,
    this.retry,
  });

  final String text;
  final bool fromUser;
  final bool error;
  final String? retry;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onRetry});

  final _ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final alignment = message.fromUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = message.error
        ? const Color(0xFFFEF2F2)
        : message.fromUser
        ? AppColors.blue
        : Colors.white;
    final textColor = message.error
        ? const Color(0xFF991B1B)
        : message.fromUser
        ? Colors.white
        : AppColors.navy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.84,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: message.error
                      ? const Color(0xFFFECACA)
                      : message.fromUser
                      ? AppColors.blue
                      : AppColors.border,
                ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(color: textColor, height: 1.4),
              ),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('El asistente está respondiendo…'),
            ],
          ),
        ),
      ),
    ),
  );
}
