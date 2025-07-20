import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  bool _isConnected = false;
  String? _lastError;

  // Getters
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  WebSocketService get webSocketService => _webSocketService;

  WebSocketProvider() {
    _initialize();
  }

  void _initialize() {
    // Escuchar cambios de conexión
    _webSocketService.connectionStream.listen((connected) {
      if (_isConnected != connected) {
        _isConnected = connected;
        notifyListeners();
      }
    });

    // Escuchar eventos generales (para debugging)
    _webSocketService.eventStream.listen((event) {
      print('📡 WebSocket event: ${event.type} - ${event.data}');
    });
  }

  /// Conectar al WebSocket
  Future<void> connect() async {
    try {
      _lastError = null;
      await _webSocketService.connect();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// Desconectar del WebSocket
  void disconnect() {
    _webSocketService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  /// Establecer token de autenticación
  void setToken(String token) {
    _webSocketService.setToken(token);
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
