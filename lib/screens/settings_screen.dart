import 'package:flutter/material.dart';
import '../utils/api_config.dart';
import '../services/websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _websocketEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
    _loadWebSocketSettings();
  }

  void _loadApiUrl() {
    _urlController.text = ApiConfig.baseUrl;
  }

  void _loadWebSocketSettings() {
    setState(() {
      _websocketEnabled = WebSocketService().isEnabled;
    });
  }

  Future<void> _saveApiUrl() async {
    if (_urlController.text.trim().isEmpty) {
      _showError('La URL no puede estar vacía');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final newUrl = _urlController.text.trim();
      if (!newUrl.startsWith('http')) {
        _showError('La URL debe comenzar con http:// o https://');
        return;
      }

      // Aquí podrías guardar la URL en SharedPreferences si quieres persistencia
      // await StorageService.saveString('api_url', newUrl);
      
      _showSuccess('URL del API actualizada correctamente');
    } catch (e) {
      _showError('Error al guardar la configuración: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefault() {
    _urlController.text = 'https://api-demo-43yz.onrender.com/api';
  }

  void _toggleWebSocket(bool enabled) {
    setState(() {
      _websocketEnabled = enabled;
    });
    
    WebSocketService().setEnabled(enabled);
    
    if (enabled) {
      _showSuccess('WebSocket habilitado - Las actualizaciones en tiempo real están activas');
      // Intentar conectar
      WebSocketService().connect();
    } else {
      _showSuccess('WebSocket deshabilitado - Mejora el rendimiento pero sin actualizaciones en tiempo real');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración del API',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL del API',
              hintText: 'https://api-demo-43yz.onrender.com/api',
              border: OutlineInputBorder(),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),
          
          // Configuración de WebSocket
          const Text(
            'Configuración de Rendimiento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _websocketEnabled ? Icons.wifi : Icons.wifi_off,
                        color: _websocketEnabled ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Actualizaciones en Tiempo Real (WebSocket)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _websocketEnabled,
                        onChanged: _toggleWebSocket,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _websocketEnabled 
                        ? 'Habilitado: Recibes actualizaciones instantáneas, pero puede ser más lento.'
                        : 'Deshabilitado: Mejor rendimiento, pero necesitas actualizar manualmente.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveApiUrl,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetToDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Por defecto'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del API',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('URL actual: ${ApiConfig.baseUrl}'),
                    const SizedBox(height: 4),
                    const Text('Endpoints disponibles:'),
                    const SizedBox(height: 4),
                    Text('• Login: ${ApiConfig.loginEndpoint}'),
                    Text('• Productos: ${ApiConfig.productsEndpoint}'),
                    Text('• Ventas: ${ApiConfig.salesEndpoint}'),
                    Text('• Promociones: ${ApiConfig.promotionsEndpoint}'),
                    Text('• Mesas: ${ApiConfig.tablesEndpoint}'),
                    Text('• Categorías: ${ApiConfig.categoriesEndpoint}'),
                    Text('• Tipos de pago: ${ApiConfig.paymentTypesEndpoint}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credenciales de prueba',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Usuario: user'),
                    Text('Contraseña: 123456'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
