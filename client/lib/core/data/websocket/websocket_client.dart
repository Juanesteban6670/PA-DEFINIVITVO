import 'websocket_client_stub.dart'
    if (dart.library.js_interop) 'websocket_client_web.dart'
    if (dart.library.html) 'websocket_client_web.dart';

/// Interfaz multiplataforma para conexiones WebSocket nativas (Web, iOS, Android).
abstract class PlatformWebSocket {
  /// Conecta a la URL WebSocket especificada (ws:// o wss://).
  static Future<PlatformWebSocket> connect(String url) =>
      createPlatformWebSocket(url);

  /// Envía texto crudo a través del canal.
  void send(String text);

  /// Cierra la conexión.
  void close();

  /// Flujo continuo de mensajes entrantes.
  Stream<String> get onMessage;

  /// Flujo de eventos de error.
  Stream<dynamic> get onError;

  /// Flujo de cierre de la conexión.
  Stream<void> get onClose;

  /// Indica si el socket está actualmente abierto y listo para transmitir.
  bool get isOpen;
}
