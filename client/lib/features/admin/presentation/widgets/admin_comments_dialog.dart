import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';

/// Diálogo modal para consultar e interactuar con los comentarios internos y públicos de un incidente.
class AdminCommentsDialog extends StatefulWidget {
  const AdminCommentsDialog({
    required this.api,
    required this.incidentId,
    super.key,
  });

  final ApiClient api;
  final String incidentId;

  @override
  State<AdminCommentsDialog> createState() => _AdminCommentsDialogState();
}

class _AdminCommentsDialogState extends State<AdminCommentsDialog> {
  final _content = TextEditingController();
  late Future<dynamic> _comments;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _comments = widget.api.get('Incidents/${widget.incidentId}/Comments/All');
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _content.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.post('Incidents/${widget.incidentId}/Comments', {
        'content': text,
        'isInternal': true,
      });
      if (!mounted) return;
      _content.clear();
      setState(() {
        _comments = widget.api.get(
          'Incidents/${widget.incidentId}/Comments/All',
        );
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el comentario: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Comentarios del incidente'),
    content: SizedBox(
      width: 540,
      height: 420,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<dynamic>(
              future: _comments,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'No se pudieron cargar los comentarios: ${snapshot.error}',
                    ),
                  );
                }
                final comments = snapshot.data is List
                    ? (snapshot.data as List)
                    : const [];
                if (comments.isEmpty) {
                  return const Center(child: Text('No hay comentarios.'));
                }
                return ListView(
                  children: [
                    for (final item
                        in comments.whereType<Map<String, dynamic>>())
                      ListTile(
                        title: Text(item['content']?.toString() ?? ''),
                        subtitle: Text(
                          '${item['username'] ?? item['author'] ?? ''} · ${item['createdAt'] ?? ''}',
                        ),
                        trailing: item['isInternal'] == true
                            ? const Chip(label: Text('Interno'))
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
          TextField(
            controller: _content,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Nuevo comentario'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        child: const Text('Enviar'),
      ),
    ],
  );
}
