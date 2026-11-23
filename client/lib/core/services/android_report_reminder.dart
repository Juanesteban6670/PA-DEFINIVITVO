import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidReportReminder {
  static const _channel = MethodChannel('cartagena/report-reminder');

  static Future<void> schedule(String owner, DateTime dueAt) =>
      _invoke<void>('schedule', owner, dueAt);

  static Future<void> cancel(String owner) => _invoke<void>('cancel', owner);

  static Future<bool> consume(String owner, DateTime dueAt) async =>
      await _invoke<bool>('consume', owner, dueAt) ?? false;

  static Future<T?> _invoke<T>(
    String method,
    String owner, [
    DateTime? dueAt,
  ]) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMethod<T>(method, {
        'owner': owner,
        if (dueAt != null) 'dueAt': dueAt.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Android report reminder: ${error.code}');
      return null;
    }
  }
}
