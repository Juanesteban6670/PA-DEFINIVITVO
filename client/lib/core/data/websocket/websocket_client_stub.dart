import 'dart:async';
import 'dart:io' as io;

import 'websocket_client.dart';

Future<PlatformWebSocket> createPlatformWebSocket(String url) async {
  final socket = await io.WebSocket.connect(url);
  return IoPlatformWebSocket(socket);
}

class IoPlatformWebSocket implements PlatformWebSocket {
  IoPlatformWebSocket(this._socket) {
    _socket.listen(
      (data) {
        if (data is String) {
          _messageController.add(data);
        } else if (data is List<int>) {
          _messageController.add(String.fromCharCodes(data));
        }
      },
      onError: (err) => _errorController.add(err),
      onDone: () {
        _isOpen = false;
        _closeController.add(null);
      },
      cancelOnError: false,
    );
  }

  final io.WebSocket _socket;
  final _messageController = StreamController<String>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();
  final _closeController = StreamController<void>.broadcast();
  bool _isOpen = true;

  @override
  bool get isOpen => _isOpen && _socket.readyState == io.WebSocket.open;

  @override
  void send(String text) {
    if (isOpen) {
      _socket.add(text);
    }
  }

  @override
  void close() {
    _isOpen = false;
    _socket.close();
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
