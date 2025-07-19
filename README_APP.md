# Peña Manager - Sistema de Gestión para Discotecas y Peñas

Una aplicación Flutter completa para la gestión de ventas, productos, promociones y mesas en establecimientos de entretenimiento como peñas y discotecas.

## Características Principales

### 🔐 Autenticación
- Login seguro con usuario y contraseña
- Gestión de sesiones con tokens JWT
- Almacenamiento local de credenciales

### 📊 Dashboard
- Estadísticas del día (ventas totales, número de órdenes)
- Contador de promociones activas
- Navegación rápida a las principales funciones
- Vista de resumen para el usuario logueado

### 🛍️ Gestión de Productos
- Lista completa de productos con stock
- Filtros por categoría
- Búsqueda en tiempo real
- Indicadores visuales de stock bajo/agotado
- Vista de inventario detallada

### 🎯 Promociones
- Visualización de promociones activas
- Detalles completos de productos incluidos
- Modal con información detallada
- Integración con el sistema de ventas

### 📈 Registro de Ventas
- Historial completo de transacciones
- Estadísticas de ventas (total, propinas, promedios)
- Información detallada por venta (mesero, mesa, método de pago)
- Vista ordenada por fecha

### 🛒 Proceso de Nueva Venta
#### Paso 1: Selección de Mesa
- Vista organizada por pisos
- Selección visual de mesas disponibles
- Indicador de progreso del proceso

#### Paso 2: Selección de Productos
- Pestañas separadas para productos y promociones
- Filtros por categoría
- Búsqueda integrada
- Carrito en tiempo real con contador
- Agregar productos y promociones al carrito

#### Paso 3: Carrito y Pago
- Gestión completa del carrito (modificar cantidades, eliminar items)
- Selección de método de pago
- Cálculo automático de propinas (con botones rápidos 10%, 15%, 20%)
- Resumen detallado de la orden
- Procesamiento de venta

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── user.dart
│   ├── product.dart
│   ├── category.dart
│   ├── promotion.dart
│   ├── payment_type.dart
│   ├── table.dart
│   ├── sale.dart
│   └── cart.dart
├── services/                 # Servicios de API y almacenamiento
│   ├── api_service.dart
│   └── storage_service.dart
├── providers/                # Gestión de estado con Provider
│   ├── auth_provider.dart
│   ├── data_provider.dart
│   └── sale_provider.dart
├── screens/                  # Pantallas de la aplicación
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── products_screen.dart
│   ├── sales_screen.dart
│   ├── promotions_screen.dart
│   └── new_sale/
│       ├── select_table_screen.dart
│       ├── select_products_screen.dart
│       └── cart_screen.dart
├── widgets/                  # Componentes reutilizables
│   └── common_widgets.dart
└── utils/                    # Utilidades y constantes
    ├── constants.dart
    └── app_utils.dart
```

## API Integration

La aplicación está configurada para consumir las siguientes APIs:

### Autenticación
- `POST /users/login` - Autenticación de usuario

### Datos Maestros
- `GET /users` - Lista de usuarios
- `GET /users/me` - Perfil del usuario actual
- `GET /categories` - Categorías de productos
- `GET /products` - Productos disponibles
- `GET /promotions` - Promociones activas
- `GET /payment-types` - Tipos de pago
- `GET /tables` - Mesas disponibles

### Ventas
- `GET /sales` - Historial de ventas
- `POST /sales` - Crear nueva venta

## Configuración

### 1. Configurar URL del API
Edita el archivo `lib/services/api_service.dart` y cambia la URL base:

```dart
static const String baseUrl = 'http://tu-servidor:puerto';
```

### 2. Dependencias
El proyecto utiliza las siguientes dependencias principales:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0           # Cliente HTTP
  shared_preferences: ^2.2.2  # Almacenamiento local
  provider: ^6.1.1       # Gestión de estado
  web_socket_channel: ^2.4.0  # WebSockets (para futuras funcionalidades)
  intl: ^0.19.0          # Internacionalización y formato
```

### 3. Instalación
```bash
flutter pub get
flutter run
```

## Uso de la Aplicación

### 1. Login
- Usa las credenciales proporcionadas por el sistema backend
- Ejemplo: usuario: `admin`, contraseña: `password123`

### 2. Dashboard
- Visualiza las estadísticas del día
- Navega a las diferentes secciones usando las tarjetas de acción rápida

### 3. Nueva Venta
1. **Seleccionar Mesa**: Elige el piso y luego la mesa
2. **Agregar Productos**: Usa las pestañas para alternar entre productos y promociones
3. **Finalizar**: Configura el método de pago, propina y confirma la venta

### 4. Consultas
- **Productos**: Filtra por categoría o busca por nombre
- **Ventas**: Revisa el historial y estadísticas
- **Promociones**: Ve los detalles de ofertas activas

## Características Técnicas

### Gestión de Estado
- **Provider Pattern** para manejo reactivo del estado
- Separación clara entre lógica de negocio y UI
- Estados de carga, error y éxito manejados consistentemente

### Diseño Responsivo
- Componentes adaptativos para diferentes tamaños de pantalla
- Material Design 3 con tema personalizado
- Navegación intuitiva y accesible

### Manejo de Errores
- Validaciones en formularios
- Manejo de errores de red
- Mensajes informativos para el usuario
- Estados de carga y error visuales

### Almacenamiento Local
- Persistencia de sesión de usuario
- Tokens de autenticación seguros
- Caché de datos cuando es apropiado

## Futuras Mejoras

- [ ] Sincronización en tiempo real con WebSockets
- [ ] Modo offline con sincronización posterior
- [ ] Reportes avanzados y gráficos
- [ ] Gestión de usuarios y permisos
- [ ] Configuración de establecimiento
- [ ] Integración con sistemas de pago
- [ ] Notificaciones push
- [ ] Backup y restauración de datos

## Soporte

Para soporte técnico o consultas sobre la implementación, contacta al equipo de desarrollo.

## Licencia

Este proyecto es propiedad del establecimiento y está destinado para uso interno.
