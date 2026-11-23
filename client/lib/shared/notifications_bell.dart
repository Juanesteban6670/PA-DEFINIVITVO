import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';

import 'notification_bridge.dart';

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({
    required this.api,
    required this.onPressed,
    super.key,
  });

  final ApiClient api;
  final VoidCallback onPressed;

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  Timer? _timer;
  int? _unread;
  String? _pollError;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _checkUnread();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkUnread());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkUnread() async {
    if (_polling) return;
    _polling = true;
    try {
      final response = await widget.api.get('Notifications/Unread/Count');
      final count = switch (response) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };
      if (count == null || count < 0) {
        throw const FormatException('La API devolvió un conteo inválido');
      }

      final previous = _unread;
      if (mounted) {
        setState(() {
          _unread = count;
          _pollError = null;
        });
      }
      if (previous != null &&
          previous > 0 &&
          count > previous &&
          notificationPermissionGranted) {
        final unreadResponse = await widget.api.get('Notifications/Unread');
        if (unreadResponse is! List) {
          throw const FormatException(
            'La API devolvió una lista de notificaciones inválida',
          );
        }
        final unread = unreadResponse.whereType<Map<String, dynamic>>();
        if (unread.isNotEmpty) {
          final latest = unread.first;
          showBrowserNotification(
            latest['title']?.toString() ?? 'Cartagena Segura',
            latest['message']?.toString() ?? '',
          );
        }
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _pollError = error.toString());
    } finally {
      _polling = false;
    }
  }

  Future<void> _openNotifications() async {
    try {
      await requestNotificationPermission();
    } on Exception catch (error) {
      if (mounted) setState(() => _pollError = error.toString());
    }
    if (mounted) widget.onPressed();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _pollError ?? 'Notificaciones',
    onPressed: _openNotifications,
    icon: Badge(
      isLabelVisible: (_unread ?? 0) > 0,
      label: Text((_unread ?? 0) > 9 ? '9+' : '${_unread ?? 0}'),
      child: const Icon(Icons.notifications_outlined),
    ),
  );
}
