import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('globalThis.Notification')
external JSFunction? get _notificationConstructor;

bool get _notificationSupported => _notificationConstructor != null;

Future<bool> requestNotificationPermission() async {
  if (!_notificationSupported) return false;
  final permission = await web.Notification.requestPermission().toDart;
  return permission.toDart == 'granted';
}

bool get notificationPermissionGranted =>
    _notificationSupported && web.Notification.permission == 'granted';

void showBrowserNotification(String title, String body) {
  web.Notification(
    title,
    web.NotificationOptions(
      body: body,
      icon: '/icons/Icon-192.png',
      tag: 'cartagena-segura',
    ),
  );
}
