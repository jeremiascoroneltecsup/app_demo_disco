import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../utils/api_config.dart';

enum WebSocketEventType {
  newSale,
  updateProduct,
  updatePromotion,
  updateTable,
  userConnected,
  userDisconnected,
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: WebSocketEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WebSocketEventType.newSale,
      ),
      data: json['data'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  bool _isEnabled = true; // Nueva flag para habilitar/deshabilitar
  String? _token;
  
  // Stream controllers para eventos
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  // Listeners específicos por tipo de evento
  final Map<WebSocketEventType, List<Function(WebSocketEvent)>> _listeners = {};
  
  // Getters para streams
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _channel != null && _isEnabled;
  bool get isEnabled => _isEnabled;

  /// Habilitar o deshabilitar WebSocket completamente
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      disconnect();
    } else {
      // Reset intentos cuando se habilita nuevamente
      _reconnectAttempts = 0;
    }
  }

  /// Resetear intentos de reconexión
  void resetReconnectionAttempts() {
    _reconnectAttempts = 0;
    _shouldReconnect = true;
  }

  void setToken(String token) {
    _token = token;
  }

  /// Conectar al WebSocket (versión optimizada)
  Future<void> connect() async {
    if (!_isEnabled || _isConnecting || isConnected) return;
    
    _isConnecting = true;
    _shouldReconnect = true;
    
    try {
      print('🔌 Intentando conectar WebSocket...');
      
      // Construir URL del WebSocket
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws') + '/ws';
      final uri = _token != null 
          ? Uri.parse('$wsUrl?token=$_token')
          : Uri.parse(wsUrl);
      
      // Timeout mucho más corto para no bloquear la app
      _channel = WebSocketChannel.connect(uri);
      
      // Timeout de solo 5 segundos para conexión inicial
      final connectTimeout = Timer(const Duration(seconds: 5), () {
        if (_isConnecting) {
          print('⏰ Timeout de conexión WebSocket');
          _isConnecting = false;
          _handleError('Timeout de conexión');
        }
      });
      
      // Escuchar mensajes de forma no bloqueante
      _channel!.stream.timeout(const Duration(seconds: 10)).listen(
        (message) {
          connectTimeout.cancel();
          if (!_isConnecting) return; // Ignorar si ya no estamos conectando
          
          _isConnecting = false;
          _reconnectAttempts = 0; // Reset counter on successful connection
          _handleMessage(message);
        },
        onError: (error) {
          connectTimeout.cancel();
          _handleError(error);
        },
        onDone: () {
          connectTimeout.cancel();
          _handleDisconnection();
        },
        cancelOnError: false, // No cancelar en caso de error menor
      );
      
      // Autenticación opcional y no bloqueante
      if (_token != null) {
        Future.microtask(() => _sendMessage({
          'type': 'auth',
          'token': _token,
        }));
      }
      
      // Marcar como conectado solo después del primer mensaje exitoso
      print('🔗 WebSocket iniciando conexión...');
      
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      _handleError(e);
    }
  }

  /// Desconectar WebSocket de forma limpia
  void disconnect() {
    print('🔌 Desconectando WebSocket...');
    _shouldReconnect = false;
    _reconnectAttempts = 0;
    
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    try {
      _channel?.sink.close(status.goingAway);
    } catch (e) {
      print('Error cerrando WebSocket: $e');
    }
    
    _channel = null;
    _isConnecting = false;
    _connectionController.add(false);
    print('✅ WebSocket desconectado');
  }

  /// Manejar mensajes entrantes de forma optimizada
  void _handleMessage(dynamic message) {
    try {
      // Marcar conexión como exitosa en el primer mensaje
      if (_isConnecting) {
        _isConnecting = false;
        _connectionController.add(true);
        print('✅ WebSocket conectado exitosamente');
        _startHeartbeat();
      }
      
      final data = jsonDecode(message);
      
      // Manejar diferentes tipos de mensajes
      switch (data['type']) {
        case 'pong':
          // Respuesta al ping, conexión activa
          break;
        case 'auth_success':
          print('🔐 Autenticación WebSocket exitosa');
          break;
        case 'error':
          print('❌ Error del servidor: ${data['message']}');
          break;
        default:
          // Solo procesar eventos si realmente tenemos listeners
          if (_listeners.isNotEmpty) {
            final event = WebSocketEvent.fromJson(data);
            _eventController.add(event);
            _notifyListeners(event);
          }
      }
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
      // No desconectar por errores de parsing menores
    }
  }

  /// Manejar errores de forma resiliente
  void _handleError(dynamic error) {
    print('❌ Error en WebSocket: $error');
    _isConnecting = false;
    _channel = null;
    _connectionController.add(false);
    _heartbeatTimer?.cancel();
    
    // Solo reconectar si realmente queremos hacerlo
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Manejar desconexión limpia
  void _handleDisconnection() {
    print('🔌 WebSocket desconectado');
    _isConnecting = false;
    _channel = null;
    _connectionController.add(false);
    _heartbeatTimer?.cancel();
    
    // Solo reconectar si no fue una desconexión intencional
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Programar reconexión con backoff exponencial
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    
    // Limitar intentos de reconexión
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('🚫 Máximo de intentos de reconexión alcanzado. WebSocket deshabilitado.');
      _shouldReconnect = false;
      return;
    }
    
    // Backoff exponencial: 30s, 1min, 2min, 5min, 10min
    final delays = [30, 60, 120, 300, 600];
    final delay = delays[_reconnectAttempts.clamp(0, delays.length - 1)];
    
    print('⏰ Programando reconexión #${_reconnectAttempts + 1} en ${delay}s...');
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_shouldReconnect && !isConnected) {
        _reconnectAttempts++;
        print('🔄 Intentando reconectar (intento #$_reconnectAttempts)...');
        connect();
      }
    });
  }

  /// Iniciar heartbeat optimizado para mantener conexión viva
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Heartbeat cada 45 segundos (menos frecuente para mejor rendimiento)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (isConnected && !_isConnecting) {
        _sendMessage({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }

  /// Enviar mensaje de forma segura y no bloqueante
  void _sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _isConnecting) return;
    
    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      
      // Solo log para mensajes importantes (no ping/pong)
      if (message['type'] != 'ping' && message['type'] != 'pong') {
        print('📤 Mensaje enviado: ${message['type']}');
      }
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      // No desconectar por errores de envío menores
    }
  }

  /// Agregar listener para un tipo específico de evento
  void addEventListener(WebSocketEventType type, Function(WebSocketEvent) listener) {
    _listeners[type] ??= [];
    _listeners[type]!.add(listener);
  }

  /// Remover listener
  void removeEventListener(WebSocketEventType type, Function(WebSocketEvent) listener) {
    _listeners[type]?.remove(listener);
  }

  /// Notificar a listeners específicos
  void _notifyListeners(WebSocketEvent event) {
    final listeners = _listeners[event.type] ?? [];
    for (final listener in listeners) {
      try {
        listener(event);
      } catch (e) {
        print('❌ Error en listener: $e');
      }
    }
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
    _listeners.clear();
  }

  // Métodos de conveniencia para eventos específicos
  void onNewSale(Function(WebSocketEvent) callback) {
    addEventListener(WebSocketEventType.newSale, callback);
  }

  void onProductUpdate(Function(WebSocketEvent) callback) {
    addEventListener(WebSocketEventType.updateProduct, callback);
  }

  void onPromotionUpdate(Function(WebSocketEvent) callback) {
    addEventListener(WebSocketEventType.updatePromotion, callback);
  }

  void onTableUpdate(Function(WebSocketEvent) callback) {
    addEventListener(WebSocketEventType.updateTable, callback);
  }
}
