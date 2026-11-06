import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notifications;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _notifications = _load();
  }

  Future<List<AppNotification>> _load() async {
    final response = await widget.api.get('Notifications');
    if (response is! List) {
      throw const FormatException('La API devolvió notificaciones inválidas');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  void _reload() => setState(() => _notifications = _load());

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read || _updating) return;
    setState(() => _updating = true);
    try {
      await widget.api.patch('Notifications/${notification.id}/Read');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudo marcar como leída: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _updating = true);
    try {
      await widget.api.patch('Notifications/ReadAll');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudieron actualizar las notificaciones: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _delete(AppNotification notification) async {
    try {
      await widget.api.delete('Notifications/${notification.id}');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudo eliminar la notificación: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      actions: [
        IconButton(
          tooltip: 'Marcar todas como leídas',
          onPressed: _updating ? null : _markAllRead,
          icon: const Icon(Icons.done_all),
        ),
      ],
    ),
    body: FutureBuilder<List<AppNotification>>(
      future: _notifications,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar las notificaciones'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final notifications = snapshot.data ?? const <AppNotification>[];
        if (notifications.isEmpty) {
          return const Center(child: Text('No tienes notificaciones.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                child: ListTile(
                  onTap: () => _markRead(notification),
                  leading: CircleAvatar(
                    backgroundColor: notification.read
                        ? AppColors.border
                        : AppColors.blue.withValues(alpha: 0.1),
                    child: Icon(
                      notification.read
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                      color: notification.read
                          ? AppColors.muted
                          : AppColors.blue,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.read
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: IconButton(
                    tooltip: 'Eliminar notificación',
                    onPressed: () => _delete(notification),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
