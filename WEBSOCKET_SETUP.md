# WebSocket Implementation - Server Side Configuration

## Configuración del Servidor WebSocket

Para que el sistema de WebSockets funcione correctamente, necesitas implementar un servidor WebSocket que maneje los siguientes tipos de eventos:

### 1. Endpoint WebSocket
El cliente se conecta a: `ws://tu-servidor.com/ws`

### 2. Eventos que debe enviar el servidor

#### Cuando se crea una nueva venta:
```json
{
  "type": "newSale",
  "data": {
    "saleId": 123,
    "tableId": 5,
    "total": 45.50,
    "timestamp": "2025-07-20T10:30:00Z"
  },
  "timestamp": "2025-07-20T10:30:00Z"
}
```

#### Cuando se actualiza un producto:
```json
{
  "type": "updateProduct",
  "data": {
    "productId": 456,
    "action": "stock_updated",
    "newStock": 25
  },
  "timestamp": "2025-07-20T10:30:00Z"
}
```

#### Cuando se actualiza una promoción:
```json
{
  "type": "updatePromotion",
  "data": {
    "promotionId": 789,
    "action": "status_changed",
    "enabled": true
  },
  "timestamp": "2025-07-20T10:30:00Z"
}
```

#### Cuando se actualiza una mesa:
```json
{
  "type": "updateTable",
  "data": {
    "tableId": 12,
    "action": "status_changed",
    "status": "occupied"
  },
  "timestamp": "2025-07-20T10:30:00Z"
}
```

### 3. Autenticación
El cliente envía el token de autenticación de dos formas:

**Opción 1 - Query Parameter (Actual):**
```
ws://tu-servidor.com/ws?token=jwt_token_aqui
```

**Opción 2 - Mensaje de autenticación (Opcional):**
```json
{
  "type": "auth",
  "token": "jwt_token_aqui"
}
```

### 4. Heartbeat
El cliente envía pings cada 30 segundos:
```json
{
  "type": "ping"
}
```

El servidor debe responder:
```json
{
  "type": "pong"
}
```

### 5. Manejo de errores
En caso de error, el servidor puede enviar:
```json
{
  "type": "error",
  "message": "Descripción del error"
}
```

## Ejemplo de implementación en Node.js con Express y ws

```javascript
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const wss = new WebSocket.Server({
  port: 8080,
  verifyClient: (info) => {
    // Verificar token de autenticación
    const token = new URL(info.req.url, 'http://localhost:8080').searchParams.get('token');
    try {
      jwt.verify(token, 'tu-secret-key');
      return true;
    } catch (err) {
      return false;
    }
  }
});

wss.on('connection', (ws, req) => {
  console.log('Cliente WebSocket conectado');

  ws.on('message', (message) => {
    const data = JSON.parse(message.toString());
    
    if (data.type === 'ping') {
      ws.send(JSON.stringify({ type: 'pong' }));
    }
  });

  ws.on('close', () => {
    console.log('Cliente WebSocket desconectado');
  });
});

// Función para enviar eventos a todos los clientes conectados
function broadcastEvent(eventType, eventData) {
  const message = {
    type: eventType,
    data: eventData,
    timestamp: new Date().toISOString()
  };

  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(message));
    }
  });
}

// Ejemplo de uso cuando se crea una venta
function onSaleCreated(sale) {
  broadcastEvent('newSale', {
    saleId: sale.id,
    tableId: sale.tableId,
    total: sale.total,
    timestamp: sale.createdAt
  });
}
```

## ¿Cómo funciona en la app?

1. **Al hacer login**: Se conecta automáticamente al WebSocket
2. **Dashboard en tiempo real**: Recibe actualizaciones instantáneas sin necesidad de refrescar
3. **Indicador visual**: Muestra si está "En vivo" (conectado) o "Sin conexión"
4. **Reconexión automática**: Si se pierde la conexión, intenta reconectar cada 5 segundos
5. **Fallback**: Si no hay WebSocket, continúa funcionando con actualizaciones cada 5 minutos

## Beneficios

✅ **Actualizaciones instantáneas** - Los datos se actualizan en tiempo real sin polling
✅ **Mejor experiencia de usuario** - Información siempre actualizada
✅ **Eficiencia de red** - Menos requests HTTP innecesarios  
✅ **Escalabilidad** - Múltiples usuarios ven cambios al mismo tiempo
✅ **Indicador visual** - El usuario sabe si los datos están actualizados
