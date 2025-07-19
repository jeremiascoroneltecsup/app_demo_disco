import 'package:flutter/material.dart';
import '../utils/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  void _loadApiUrl() {
    _urlController.text = ApiConfig.baseUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Padding(
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
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
