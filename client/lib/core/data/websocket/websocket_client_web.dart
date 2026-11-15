import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'websocket_client.dart';

Future<PlatformWebSocket> createPlatformWebSocket(String url) async {
  final completer = Completer<PlatformWebSocket>();
  final ws = web.WebSocket(url);
  final client = WebPlatformWebSocket(ws);

  ws.onopen = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.complete(client);
    }
  }).toJS;

  ws.onerror = ((web.Event err) {
    if (!completer.isCompleted) {
      completer.completeError(Exception('WebSocket error connecting to $url'));
    }
  }).toJS;

  return completer.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      try {
        ws.close();
      } catch (_) {}
      throw TimeoutException('WebSocket connection timed out on $url');
    },
  );
}

class WebPlatformWebSocket implements PlatformWebSocket {
  WebPlatformWebSocket(this._ws) {
    _ws.onmessage = ((web.MessageEvent e) {
      final data = e.data;
      if (data != null) {
        _messageController.add(data.toString());
      }
    }).toJS;

    _ws.onerror = ((web.Event e) {
      _errorController.add(e);
    }).toJS;

    _ws.onclose = ((web.CloseEvent _) {
      _isOpen = false;
      _closeController.add(null);
    }).toJS;
  }

  final web.WebSocket _ws;
  final _messageController = StreamController<String>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();
  final _closeController = StreamController<void>.broadcast();
  bool _isOpen = true;

  @override
  bool get isOpen => _isOpen && _ws.readyState == web.WebSocket.OPEN;

  @override
  void send(String text) {
    if (isOpen) {
      try {
        _ws.send(text.toJS);
      } catch (err) {
        _errorController.add(err);
      }
    }
  }

  @override
  void close() {
    _isOpen = false;
    try {
      _ws.close();
    } catch (_) {}
    _messageController.close();
    _errorController.close();
    _closeController.close();
  }

  @override
  Stream<String> get onMessage => _messageController.stream;

  @override
  Stream<dynamic> get onError => _errorController.stream;

  @override
  Stream<void> get onClose => _closeController.stream;
}
