import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/theme.dart';

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
  String _sessionId = 'mobile-${const Uuid().v4()}';
  bool _sending = false;
  bool _restoring = true;

  String get _historyKey =>
      'citizen.chat.${widget.session.user?.username ?? 'unknown'}';

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text:
            'Hola. Soy el asistente de Cartagena Segura. Puedo orientarte sobre reportes, zonas de riesgo y servicios de emergencia. Si hay peligro inmediato, llama al 123.',
      ),
    );
    _restoreHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? retryText]) async {
    final text = (retryText ?? _input.text).trim();
    if (text.isEmpty || _sending || _restoring) return;

    if (retryText == null) {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _input.clear();
    }
    setState(() => _sending = true);
    _scrollToEnd();

    try {
      final history = _messages
          .where((m) => !m.error && m.text.isNotEmpty)
          .toList();
      final recentHistory = (history.length > 10
              ? history.sublist(history.length - 10)
              : history)
          .map((m) => {
                'role': m.fromUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await widget.session.api.post('Ai/Chat', {
        'message': text,
        'sessionId': _sessionId,
        'history': recentHistory,
      });
      if (response is! Map<String, dynamic> ||
          response['reply'] is! String ||
          (response['reply'] as String).trim().isEmpty) {
        throw const FormatException(
          'El asistente devolvió una respuesta vacía o inválida.',
        );
      }
      if (!mounted) return;

      List<Map<String, String>>? actions;
      if (response['actions'] is List) {
        actions = (response['actions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => {
                  'type': item['type']?.toString() ?? '',
                  'label': item['label']?.toString() ?? '',
                  'payload': item['payload']?.toString() ?? '',
                })
            .where((item) => item['label']!.isNotEmpty)
            .toList();
      }

      _messages.add(
        _ChatMessage(
          text: response['reply'] as String,
          actions: actions,
        ),
      );
      await _saveHistory();
    } on ApiException catch (error) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(text: error.message, error: true, retry: text),
      );
      await _saveHistory();
    } on FormatException catch (error) {
      if (!mounted) return;
      _messages.add(
        _ChatMessage(text: error.message, error: true, retry: text),
      );
      await _saveHistory();
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
    if (_sending || _restoring) return;
    setState(() {
      _sessionId = 'mobile-${const Uuid().v4()}';
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text:
                'Conversación nueva. ¿En qué puedo orientarte sobre seguridad ciudadana?',
          ),
        );
    });
    widget.session.storage.delete(_historyKey).catchError((Object error) {
      if (mounted) _showMessage('No se pudo borrar el historial local: $error');
    });
  }

  Future<void> _restoreHistory() async {
    try {
      final saved = await widget.session.storage.read(_historyKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        final List<dynamic> savedMessages;
        if (decoded is List) {
          savedMessages = decoded;
        } else if (decoded is Map<String, dynamic> &&
            decoded['messages'] is List) {
          savedMessages = decoded['messages'] as List;
          final savedSessionId = decoded['sessionId'];
          if (savedSessionId is String && savedSessionId.isNotEmpty) {
            _sessionId = savedSessionId;
          }
        } else {
          throw const FormatException('El historial guardado no es válido');
        }
        final restored = savedMessages
            .whereType<Map<String, dynamic>>()
            .map(
              (item) {
                List<Map<String, String>>? actions;
                if (item['actions'] is List) {
                  actions = (item['actions'] as List)
                      .whereType<Map<String, dynamic>>()
                      .map((act) => {
                            'type': act['type']?.toString() ?? '',
                            'label': act['label']?.toString() ?? '',
                            'payload': act['payload']?.toString() ?? '',
                          })
                      .where((act) => act['label']!.isNotEmpty)
                      .toList();
                }
                return _ChatMessage(
                  text: item['text']?.toString() ?? '',
                  fromUser: item['fromUser'] == true,
                  error: item['error'] == true,
                  retry: item['retry']?.toString(),
                  actions: actions,
                );
              },
            )
            .where((message) => message.text.isNotEmpty)
            .toList();
        if (mounted && restored.isNotEmpty) {
          setState(() {
            _messages
              ..clear()
              ..addAll(restored);
          });
        }
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('No se pudo restaurar el historial local: $error');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final recent = _messages.length > 80
          ? _messages.sublist(_messages.length - 80)
          : _messages;
      await widget.session.storage.write(
        _historyKey,
        jsonEncode({
          'sessionId': _sessionId,
          'messages': recent
              .map(
                (message) => {
                  'text': message.text,
                  'fromUser': message.fromUser,
                  'error': message.error,
                  'retry': message.retry,
                  'actions': message.actions,
                },
              )
              .toList(),
        }),
      );
    } on Exception catch (error) {
      if (mounted) {
        _showMessage('No se pudo guardar el historial local: $error');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          const LiquidGlassToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: _sending || _restoring ? null : _clearConversation,
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
                    itemCount:
                        _messages.length + (_sending || _restoring ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _restoring) {
                        return const Center(child: CircularProgressIndicator());
                      }
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
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: LiquidGlassContainer(
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    elevation: 2,
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
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          tooltip: 'Enviar mensaje',
                          onPressed:
                              _sending || _restoring ? null : () => _send(),
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
    this.actions,
  });

  final String text;
  final bool fromUser;
  final bool error;
  final String? retry;
  final List<Map<String, String>>? actions;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onRetry});

  final _ChatMessage message;
  final VoidCallback? onRetry;

  void _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _onActionTap(BuildContext context, Map<String, String> action) {
    final type = action['type']?.toUpperCase() ?? '';
    final payload = action['payload'] ?? '';
    if (type == 'CALL') {
      _callNumber(payload);
    } else if (type == 'NAVIGATE') {
      if (payload.isNotEmpty) {
        context.push(payload);
      }
    } else if (type == 'REPORT') {
      context.push('/App/Incidents');
    } else if (payload.startsWith('CALL:')) {
      _callNumber(payload.replaceFirst('CALL:', ''));
    } else if (RegExp(r'^\d+$').hasMatch(payload)) {
      _callNumber(payload);
    } else {
      context.push('/App/Incidents');
    }
  }

  (IconData, Color) _actionStyle(Map<String, String> action) {
    final type = action['type']?.toUpperCase() ?? '';
    final payload = action['payload'] ?? '';
    final label = (action['label'] ?? '').toLowerCase();

    if (type == 'CALL' ||
        payload.contains('125') ||
        label.contains('crue') ||
        label.contains('ambulancia')) {
      if (payload == '125' ||
          label.contains('crue') ||
          label.contains('ambulancia')) {
        return (Icons.medical_services_outlined, const Color(0xFFDC2626));
      }
      if (payload == '127' ||
          label.contains('tránsito') ||
          label.contains('datt')) {
        return (Icons.traffic_outlined, const Color(0xFF2563EB));
      }
      if (payload == '155' || label.contains('púrpura')) {
        return (Icons.shield_outlined, const Color(0xFF9333EA));
      }
      if (payload == '119' || label.contains('bomberos')) {
        return (Icons.fire_truck_outlined, const Color(0xFFEA580C));
      }
      return (Icons.phone_in_talk, AppColors.red);
    }
    if (type == 'REPORT' ||
        label.contains('reporte') ||
        label.contains('radicar')) {
      return (Icons.add_alert_outlined, const Color(0xFFD97706));
    }
    if (type == 'NAVIGATE' || label.contains('mapa')) {
      return (Icons.map_outlined, const Color(0xFF2563EB));
    }
    return (Icons.touch_app_outlined, AppColors.brightBlue);
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensaje copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = message.error
        ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2))
        : message.fromUser
            ? AppColors.brightBlue
            : (isDark ? AppColors.darkCard : Colors.white);
    final textColor = message.error
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
        : message.fromUser
            ? Colors.white
            : (isDark ? AppColors.darkText : AppColors.navy);

    final show123Chip = !message.fromUser &&
        !message.error &&
        (message.text.contains('123') || message.text.contains('Policía'));
    final show119Chip = !message.fromUser &&
        !message.error &&
        (message.text.contains('119') || message.text.contains('Bomberos'));
    final show125Chip = !message.fromUser &&
        !message.error &&
        (message.text.contains('125') ||
            message.text.contains('CRUE') ||
            message.text.contains('Ambulancia'));
    final show127Chip = !message.fromUser &&
        !message.error &&
        (message.text.contains('127') ||
            message.text.contains('DATT') ||
            message.text.contains('Tránsito'));
    final show155Chip = !message.fromUser &&
        !message.error &&
        (message.text.contains('155') || message.text.contains('Púrpura'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.88,
            ),
            child: (!message.fromUser && !message.error)
                ? LiquidGlassContainer(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: _RichMarkdownView(
                      text: message.text,
                      baseColor: textColor,
                      isDark: isDark,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.fromUser ? 18 : 4),
                        bottomRight: Radius.circular(message.fromUser ? 4 : 18),
                      ),
                      border: Border.all(
                        color: message.error
                            ? (isDark
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFFFECACA))
                            : AppColors.brightBlue,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: message.fromUser
                        ? SelectableText(
                            message.text,
                            style: TextStyle(
                              color: textColor,
                              height: 1.4,
                              fontSize: 14,
                            ),
                          )
                        : _RichMarkdownView(
                            text: message.text,
                            baseColor: textColor,
                            isDark: isDark,
                          ),
                  ),
          ),
          if (!message.fromUser && !message.error) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Copiar texto',
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  color: AppColors.muted,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyToClipboard(context),
                ),
                if (message.actions != null && message.actions!.isNotEmpty)
                  ...message.actions!.map((action) {
                    final (icon, actColor) = _actionStyle(action);
                    return ActionChip(
                      avatar: Icon(icon, size: 13, color: actColor),
                      label: Text(
                        action['label'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: actColor,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () => _onActionTap(context, action),
                    );
                  })
                else ...[
                  if (show123Chip)
                    ActionChip(
                      avatar: const Icon(
                        Icons.phone_in_talk,
                        size: 13,
                        color: AppColors.red,
                      ),
                      label: const Text(
                        'Llamar al 123',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _callNumber('123'),
                    ),
                  if (show119Chip)
                    ActionChip(
                      avatar: const Icon(
                        Icons.fire_truck_outlined,
                        size: 13,
                        color: Color(0xFFF97316),
                      ),
                      label: const Text(
                        'Llamar al 119',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _callNumber('119'),
                    ),
                  if (show125Chip)
                    ActionChip(
                      avatar: const Icon(
                        Icons.medical_services_outlined,
                        size: 13,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'Llamar al CRUE 125',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _callNumber('125'),
                    ),
                  if (show127Chip)
                    ActionChip(
                      avatar: const Icon(
                        Icons.traffic_outlined,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      label: const Text(
                        'Llamar a Tránsito 127',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _callNumber('127'),
                    ),
                  if (show155Chip)
                    ActionChip(
                      avatar: const Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: Color(0xFF9333EA),
                      ),
                      label: const Text(
                        'Línea Púrpura 155',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _callNumber('155'),
                    ),
                ],
              ],
            ),
          ],
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

/// Renderizador visual para texto enriquecido y Markdown del Asistente
class _RichMarkdownView extends StatelessWidget {
  const _RichMarkdownView({
    required this.text,
    required this.baseColor,
    required this.isDark,
  });

  final String text;
  final Color baseColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Viñeta de lista (* o -)
      if (line.trimLeft().startsWith('* ') ||
          line.trimLeft().startsWith('- ')) {
        final content = line.trimLeft().substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: isDark ? AppColors.brightBlue : AppColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Expanded(child: _buildFormattedText(content)),
              ],
            ),
          ),
        );
        continue;
      }

      // Título con hashtag (## o ###)
      if (line.startsWith('#')) {
        final title = line.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        );
        continue;
      }

      // Párrafo estándar con formato
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildFormattedText(line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildFormattedText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.45),
          ),
        );
      }
      final boldContent = match.group(1) ?? '';
      spans.add(
        TextSpan(
          text: boldContent,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.45),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

/// Indicador animado de respuesta escribiendo (3 puntos pulsantes)
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cartagena Segura IA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  return Row(
                    children: List.generate(3, (i) {
                      final delay = i * 0.25;
                      final progress = (_anim.value - delay) % 1.0;
                      final bounce =
                          progress < 0.5 ? (progress * 2) : (2 - progress * 2);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Transform.translate(
                          offset: Offset(0, -4 * bounce),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.brightBlue.withValues(
                                alpha: 0.4 + (0.6 * bounce),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
