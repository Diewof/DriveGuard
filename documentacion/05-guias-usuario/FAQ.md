# Preguntas Frecuentes (FAQ) - DriveGuard

Respuestas a las preguntas más comunes sobre DriveGuard.

---

## 📱 General

### ¿Qué es DriveGuard?

DriveGuard es un sistema inteligente de prevención y respuesta ante crisis de conducción. Utiliza sensores (acelerómetro, giroscopio) y cámara (ESP32-CAM opcional) para detectar patrones de conducción peligrosos como distracciones, conducción temeraria e impactos, generando alertas multimodales (sonido, vibración, visuales) para advertir al conductor.

### ¿En qué plataformas funciona DriveGuard?

- **Android** 11 (API 30) o superior ✅
- **iOS** 12.0 o superior ✅ (en desarrollo)
- **Web** (próximamente)

### ¿DriveGuard es gratuito?

Sí, DriveGuard es un proyecto de código abierto completamente gratuito.

### ¿Necesito conexión a Internet?

Sí, DriveGuard requiere Internet para:
- Autenticación de usuarios (Firebase Auth)
- Guardar historial de sesiones (Firestore)
- Sincronización de datos

**Nota:** El monitoreo en tiempo real funciona offline, pero no guardará el historial hasta que se recupere la conexión.

---

## 🚗 Funcionalidades

### ¿Cómo detecta DriveGuard la conducción peligrosa?

DriveGuard analiza datos de sensores en tiempo real:

1. **Acelerómetro:** Detecta cambios bruscos de velocidad
   - Aceleración > 3.0 m/s² = Conducción temeraria
   - Aceleración > 15.0 m/s² = Posible impacto

2. **Giroscopio:** Identifica giros agresivos
   - Rotación > 45°/s = Giro brusco

3. **Historial:** Penaliza patrones repetitivos
   - Múltiples alertas incrementan el score de riesgo

4. **Cámara (opcional con ESP32-CAM):**
   - Detección de uso de celular
   - Detección de mirada fuera del camino

### ¿Qué tipos de alertas genera?

**Tipos:**
- **Distracción:** Uso de celular, mirada fuera
- **Conducción temeraria:** Aceleración/frenado brusco, giros agresivos
- **Emergencia:** Impacto detectado

**Severidades:**
- **Low:** Alertas informativas
- **Medium:** Distracciones leves, frenadas bruscas
- **High:** Conducción temeraria sostenida
- **Critical:** Impactos, emergencias

**Modalidades:**
- 🔊 **Audio:** Tono + mensaje de voz en español
- 📳 **Vibración:** Patrón según severidad
- 📱 **Visual:** Overlay en pantalla con ícono y mensaje

### ¿Puedo personalizar las alertas?

Sí, en **Menú → Configuración de Notificaciones** puedes:
- Habilitar/deshabilitar sonido
- Ajustar volumen de alertas
- Habilitar/deshabilitar vibración
- Seleccionar tipos de alerta a recibir
- Activar modo silencioso (solo visual)

### ¿Cómo se calcula el Risk Score?

El algoritmo pondera tres factores:

```
Risk Score = (Aceleración × 30%) + (Rotación × 30%) + (Historial × 40%)
```

**Rangos:**
- 0-30: 🟢 Conducción segura
- 30-60: 🟠 Riesgo moderado
- 60-100: 🔴 Conducción peligrosa

**Ejemplo:**
- Aceleración de 2.5 m/s² → 25 puntos
- Giros de 20°/s → 10 puntos
- 3 alertas recientes → 15 puntos
- **Total: 50 (Moderado)**

---

## 📊 Sesiones y Historial

### ¿Qué es una sesión de conducción?

Una sesión es un período de monitoreo continuo que registra:
- Hora de inicio y fin
- Ubicación GPS inicial y final
- Duración total
- Eventos detectados (alertas)
- Estadísticas (distracciones, conducción temeraria, emergencias)
- Score de riesgo promedio

### ¿Cómo inicio una sesión?

1. Abrir Dashboard
2. Presionar botón "Iniciar Monitoreo" (play)
3. El cronómetro comenzará
4. Los sensores se activarán automáticamente

### ¿Cómo finalizo una sesión?

1. Presionar botón "Detener Monitoreo" (stop)
2. La sesión se guardará automáticamente en Firestore
3. Podrás verla en el Historial

### ¿Dónde veo mis sesiones anteriores?

**Menú → Historial**

Aquí verás:
- Lista de sesiones ordenadas por fecha (más reciente primero)
- Duración de cada sesión
- Risk score promedio
- Total de eventos

**Tap en una sesión** para ver detalles:
- Ubicación inicial y final (mapa)
- Timeline de eventos
- Tipo de cada evento
- Severidad
- Timestamp

### ¿Puedo eliminar sesiones?

Actualmente no, pero está en el roadmap para futuras versiones.

### ¿Los datos se guardan localmente o en la nube?

**En la nube (Firebase Firestore):**
- Sesiones de conducción
- Eventos de sesión
- Perfil de usuario

**Ventajas:**
- Acceso desde cualquier dispositivo
- Backup automático
- Sincronización en tiempo real

**Localmente (SharedPreferences):**
- Cache de usuario para login rápido

---

## 🔐 Seguridad y Privacidad

### ¿Mis datos están seguros?

Sí, DriveGuard utiliza Firebase con las siguientes medidas:

- **Autenticación:** Firebase Auth con email/password
- **Reglas de seguridad:** Solo puedes ver/editar tus propios datos
- **Encriptación:** HTTPS para todas las comunicaciones
- **No compartimos datos:** Tus sesiones son privadas

### ¿Quién puede ver mis sesiones?

Solo tú. Las reglas de Firestore garantizan que:
```javascript
// Solo el usuario autenticado puede acceder a sus propios datos
match /driving_sessions/{sessionId} {
  allow read, write: if request.auth.uid == resource.data.userId;
}
```

### ¿DriveGuard rastrea mi ubicación constantemente?

No. La ubicación GPS se captura solo:
- Al inicio de una sesión (ubicación inicial)
- Al final de una sesión (ubicación final)

**No hay rastreo continuo.**

### ¿Qué pasa si pierdo mi teléfono?

1. Tus datos están en la nube (Firestore)
2. Instala DriveGuard en nuevo dispositivo
3. Inicia sesión con tu cuenta
4. Tendrás acceso a todo tu historial

### ¿Puedo eliminar mi cuenta?

Actualmente debes contactar al equipo de desarrollo. En futuras versiones habrá una opción "Eliminar cuenta" en el perfil.

---

## 🔧 Hardware (ESP32-CAM)

### ¿Necesito el ESP32-CAM para usar DriveGuard?

No, el ESP32-CAM es **opcional**. DriveGuard funciona completamente sin él usando sensores simulados.

**Con ESP32-CAM:**
- Análisis de video en tiempo real
- Detección de uso de celular
- Detección de mirada fuera del camino

**Sin ESP32-CAM:**
- Monitoreo basado solo en acelerómetro/giroscopio simulados
- No hay análisis de video

### ¿Dónde compro el ESP32-CAM?

El módulo ESP32-CAM está disponible en:
- Amazon
- AliExpress
- Tiendas de electrónica locales

**Precio aproximado:** $5-15 USD

### ¿Cómo configuro el ESP32-CAM?

Ver la guía completa: [ESP32_INTEGRATION_GUIDE.md](../../03-hardware/ESP32_INTEGRATION_GUIDE.md)

**Resumen:**
1. Cargar firmware en ESP32
2. Configurar WiFi (misma red que smartphone)
3. En DriveGuard: Menú → ESP32-CAM Debug → Iniciar
4. Anotar IP mostrada
5. Actualizar IP en código ESP32
6. Reiniciar ESP32

### ¿El ESP32 y el smartphone deben estar en la misma WiFi?

Sí, DriveGuard crea un servidor HTTP en el smartphone (puerto 8080) y el ESP32 envía imágenes a esa dirección.

**Ambos deben estar en la misma red local.**

### El ESP32 no se conecta, ¿qué hago?

**Checklist:**
1. ¿Ambos están en la misma WiFi?
   - Verificar IP del smartphone: Configuración → WiFi
   - Verificar IP del ESP32: Serial Monitor

2. ¿El servidor está iniciado?
   - Menú → ESP32-CAM Debug → Presionar "Iniciar"
   - Debe mostrar "Conectado" y una IP

3. ¿La IP está actualizada en el código ESP32?
   ```cpp
   const char* FLUTTER_IP = "192.168.1.100";  // Actualizar esto
   ```

4. ¿El puerto es correcto?
   ```cpp
   const int FLUTTER_PORT = 8080;  // Debe ser 8080 por defecto
   ```

5. ¿Hay firewall bloqueando?
   - Desactivar temporalmente firewall del smartphone

### Las imágenes del ESP32 no se muestran

**Posibles causas:**

1. **Base64 corrupto:**
   - Verificar logs de Flutter: `flutter logs | grep "📸"`
   - Debe mostrar "Frame recibido"

2. **Formato incorrecto:**
   - ESP32 debe enviar JPEG (no PNG/BMP)
   - Verificar configuración de cámara:
     ```cpp
     config.pixel_format = PIXFORMAT_JPEG;
     ```

3. **Imagen demasiado grande:**
   - Máximo: 500 KB
   - Reducir calidad JPEG:
     ```cpp
     config.jpeg_quality = 12;  // 0-63, menor = mejor compresión
     ```

---

## ⚙️ Configuración

### ¿Cómo cambio mi contraseña?

Actualmente no hay opción de cambio de contraseña en la app. Usa "Olvidé mi contraseña" en la pantalla de login para recibir email de restablecimiento.

### ¿Puedo usar DriveGuard sin cuenta?

No, DriveGuard requiere autenticación para:
- Guardar sesiones en la nube
- Asociar datos a tu perfil
- Sincronizar entre dispositivos

### ¿Cómo agrego contactos de emergencia?

1. Menú → Perfil
2. Sección "Contactos de Emergencia"
3. Presionar "Agregar Contacto"
4. Ingresar:
   - Nombre
   - Teléfono
   - Relación (familiar, amigo, etc.)
5. Guardar

**Nota:** En futuras versiones, estos contactos recibirán notificaciones automáticas en caso de emergencia.

---

## 🐛 Problemas Técnicos

### La app se cierra inesperadamente

**Causas comunes:**

1. **Permisos no otorgados:**
   - Configuración → Apps → DriveGuard → Permisos
   - Habilitar: Ubicación, Vibración, WiFi

2. **Memoria insuficiente:**
   - Cerrar apps en segundo plano
   - Reiniciar dispositivo

3. **Versión de Android antigua:**
   - DriveGuard requiere Android 11 (API 30)+

**Solución:**
```bash
# Ver logs de error
adb logcat | grep "DriveGuard"
```

### No se escuchan las alertas

**Checklist:**
1. ¿Volumen del dispositivo habilitado?
2. ¿Modo "No molestar" desactivado?
3. ¿Configuración de notificaciones correcta?
   - Menú → Configuración de Notificaciones
   - Habilitar "Sonido de alertas"
   - Volumen al 80%
4. ¿Assets de audio presentes?
   - Reinstalar app si falla

### Las alertas no vibran

**Checklist:**
1. ¿Dispositivo soporta vibración?
2. ¿Permiso de vibración otorgado?
3. ¿Configuración habilitada?
   - Menú → Configuración de Notificaciones
   - Habilitar "Vibración"

### Error: "Firebase not initialized"

**Solución:**
1. Verificar conexión a Internet
2. Reinstalar app
3. Si persiste, contactar soporte

### Error: "Unable to load asset"

**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

### El Risk Score no cambia

**Causas:**
1. **Monitoreo detenido:**
   - Presionar "Iniciar Monitoreo"

2. **Sensores no simulando:**
   - Reiniciar app

3. **Bug:**
   - Detener y reiniciar monitoreo

---

## 🔄 Actualizaciones

### ¿Cómo actualizo DriveGuard?

**Desde APK:**
1. Descargar nueva versión
2. Instalar sobre la existente (sin desinstalar)
3. Abrir app

**Desde código fuente:**
```bash
git pull origin main
flutter pub get
flutter run
```

### ¿Cómo sé si hay actualizaciones disponibles?

Actualmente no hay notificaciones automáticas. Visita el repositorio de GitHub para ver releases.

### ¿Perderé mis datos al actualizar?

No, los datos están en Firebase y se conservan.

---

## 🚀 Roadmap y Futuras Características

### ¿Qué funcionalidades están planeadas?

**Próximas versiones:**
- Modo offline con sincronización posterior
- Notificaciones automáticas a contactos de emergencia
- Integración con servicios de emergencia (911)
- Análisis con IA (detección de objetos con YOLO/MobileNet)
- App Web para visualización de estadísticas
- Exportar sesiones a PDF/CSV
- Soporte para múltiples dispositivos ESP32
- Detección de fatiga (análisis de parpadeo)

### ¿Puedo sugerir funcionalidades?

Sí, abre un Issue en GitHub con la etiqueta "feature request".

---

## 💻 Desarrollo

### ¿Puedo contribuir al proyecto?

Sí, DriveGuard es código abierto. Ver [CONTRIBUIR.md](../../06-desarrollo/CONTRIBUIR.md).

### ¿Dónde está el código fuente?

GitHub: [https://github.com/tu-usuario/driveguard](https://github.com/tu-usuario/driveguard)

### ¿Qué tecnologías usa DriveGuard?

**Frontend (App móvil):**
- Flutter 3.16.0+
- Dart 3.0+
- BLoC Pattern (flutter_bloc)

**Backend:**
- Firebase Authentication
- Cloud Firestore
- Cloud Functions (Node.js + Express)

**Hardware:**
- ESP32-CAM
- MPU-6050 (acelerómetro + giroscopio)

**Arquitectura:**
- Clean Architecture
- SOLID Principles

---

## 📞 Soporte

### ¿Cómo obtengo ayuda?

1. **Consulta esta FAQ**
2. **Lee la documentación:**
   - [Manual de Usuario](MANUAL_USUARIO.md)
   - [Guía de Instalación](INSTALACION.md)
3. **Busca en Issues de GitHub**
4. **Abre un nuevo Issue** con detalles del problema
5. **Contacta al equipo** (email en README)

### ¿Cómo reporto un bug?

**Abre un Issue en GitHub** con:
- Descripción del problema
- Pasos para reproducir
- Versión de DriveGuard
- Versión de Android/iOS
- Logs de Flutter (`flutter logs`)
- Screenshots (si aplica)

---

## 🌍 Idioma

### ¿DriveGuard está en español?

Sí, la interfaz y mensajes de voz están en español.

### ¿Habrá soporte para otros idiomas?

Está en el roadmap para futuras versiones.

---

**¿No encontraste tu pregunta?**

Contacta al equipo de desarrollo o abre un Issue en GitHub.
