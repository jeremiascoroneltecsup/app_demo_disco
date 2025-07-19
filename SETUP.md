# Configuración y Instalación - Peña Manager

## 🚀 Instalación Rápida

### 1. Prerrequisitos
- Flutter SDK (versión 3.7.2 o superior)
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android o emulador

### 2. Configuración del Proyecto

```bash
# Clonar o descargar el proyecto
cd app_demo_disco

# Instalar dependencias
flutter pub get

# Verificar configuración
flutter doctor
```

### 3. Configurar URL del Backend

Edita el archivo `lib/utils/api_config.dart`:

```dart
class ApiConfig {
  // Cambia esta URL por la de tu servidor
  static const String baseUrl = 'http://TU_SERVIDOR:PUERTO';
  
  // Ejemplo para servidor local:
  // static const String baseUrl = 'http://192.168.1.100:3000';
  
  // Ejemplo para servidor remoto:
  // static const String baseUrl = 'https://api.tu-empresa.com';
}
```

### 4. Ejecutar la Aplicación

```bash
# Modo debug
flutter run

# Modo release (para producción)
flutter run --release

# Para dispositivo específico
flutter devices
flutter run -d DEVICE_ID
```

## 🔧 Configuración Avanzada

### Variables de Entorno

Para diferentes entornos (desarrollo, staging, producción), puedes crear archivos de configuración:

```dart
// lib/config/environment.dart
class Environment {
  static const String current = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static String get apiUrl {
    switch (current) {
      case 'production':
        return 'https://api-prod.tu-empresa.com';
      case 'staging':
        return 'https://api-staging.tu-empresa.com';
      default:
        return 'http://localhost:3000';
    }
  }
}
```

Ejecutar con variables:
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### Configuración de Red

Para conectar desde dispositivo físico a servidor local:

1. **Obtén tu IP local:**
   ```bash
   # En Windows
   ipconfig
   
   # En macOS/Linux
   ifconfig
   ```

2. **Actualiza la URL del API:**
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:3000';
   ```

3. **Asegúrate de que el firewall permita conexiones**

## 📱 Uso de la Aplicación

### Credenciales de Prueba
```
Usuario: admin
Contraseña: password123
```

### Flujo Principal

1. **Login**
   - Ingresa credenciales
   - La app valida contra el backend
   - Se almacena el token localmente

2. **Dashboard**
   - Vista principal con estadísticas
   - Navegación a otras secciones
   - Datos en tiempo real

3. **Nueva Venta**
   - Paso 1: Seleccionar mesa (organizado por pisos)
   - Paso 2: Agregar productos/promociones
   - Paso 3: Configurar pago y finalizar

4. **Consultas**
   - **Productos**: Lista con filtros y búsqueda
   - **Ventas**: Historial con estadísticas
   - **Promociones**: Ofertas activas con detalles

## 🛠️ Personalización

### Colores y Tema

Edita `lib/utils/constants.dart`:

```dart
class AppConstants {
  // Cambiar colores principales
  static const Color primaryColor = Color(0xFF2E3440);
  static const Color secondaryColor = Color(0xFF5E81AC);
  static const Color accentColor = Color(0xFFD08770);
  
  // Agregar logo personalizado
  static const String logoPath = 'assets/images/logo.png';
}
```

### Textos y Etiquetas

Los textos están hardcodeados en español. Para internacionalización:

1. Agregar dependencia:
   ```yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
   ```

2. Crear archivos de traducción
3. Implementar `AppLocalizations`

## 🐛 Solución de Problemas

### Error de Conexión
```
Error: Connection refused
```
**Solución:**
- Verificar que el backend esté ejecutándose
- Confirmar la URL del API
- Revisar configuración de red/firewall

### Error de CORS (Web)
Si ejecutas en web y tienes problemas de CORS:

```bash
flutter run -d chrome --web-renderer html --web-browser-flag "--disable-web-security"
```

### Error de Certificados HTTPS
Para desarrollo con HTTPS auto-firmado:

```dart
// En api_service.dart, agregar:
import 'dart:io';

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

// En main.dart:
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}
```

### Performance
Para mejorar el rendimiento:

```bash
# Ejecutar en modo release
flutter run --release

# Analizar el bundle
flutter build apk --analyze-size
```

## 📊 Monitoreo y Logs

### Logs de Debug
Los logs aparecen en:
- Terminal durante `flutter run`
- Android Studio / VS Code debug console
- Device logs: `flutter logs`

### Crash Reporting (Producción)
Para producción, agregar:

```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

### Analytics
Para métricas de uso:

```yaml
dependencies:
  firebase_analytics: ^10.7.4
```

## 🔒 Seguridad

### Tokens
- Los tokens se almacenan en `SharedPreferences`
- Se incluyen automáticamente en las peticiones HTTP
- Se limpian al cerrar sesión

### Validaciones
- Validación de formularios en el frontend
- Verificación de tokens en el backend
- Manejo seguro de errores

### Datos Sensibles
```dart
// NO hacer esto:
const apiKey = 'mi-clave-secreta';

// Hacer esto:
const apiKey = String.fromEnvironment('API_KEY');
```

## 📦 Despliegue

### APK (Android)
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs por arquitectura
flutter build apk --split-per-abi
```

### AAB (Google Play)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Soporte

Para soporte técnico:
1. Revisar logs de error
2. Verificar configuración de red
3. Comprobar versión del backend
4. Contactar al equipo de desarrollo

## 📝 Notas Adicionales

- La aplicación maneja automáticamente la rotación de pantalla
- Los datos se refrescan automáticamente
- El carrito se mantiene mientras la app esté activa
- La sesión persiste entre reinicios de la app
