# Flujo de Datos - DriveGuard

Este documento detalla cómo fluyen los datos a través de las diferentes capas de la aplicación DriveGuard.

---

## 📊 Diagrama General de Flujo

```
┌─────────────────┐
│  ESP32-CAM      │
│  + Sensores     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ HTTP Server     │
│ (Puerto 8080)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  ┌──────────────┐   ┌────────────────┐ │
│  │ CameraBloc   │   │ DashboardBloc  │ │
│  └──────┬───────┘   └────────┬───────┘ │
│         │                    │         │
│         ▼                    ▼         │
│  ┌──────────────────────────────────┐  │
│  │         UI Widgets               │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │                    │
         ▼                    ▼
┌─────────────────────────────────────────┐
│           DOMAIN LAYER                  │
│  ┌──────────────┐   ┌────────────────┐ │
│  │  UseCases    │   │  Repositories  │ │
│  └──────┬───────┘   └────────┬───────┘ │
└─────────┼──────────────────────┼─────────┘
          │                      │
          ▼                      ▼
┌─────────────────────────────────────────┐
│            DATA LAYER                   │
│  ┌──────────────┐   ┌────────────────┐ │
│  │ Data Sources │   │ Repositories   │ │
│  │  (Firebase)  │   │ Implementation │ │
│  └──────┬───────┘   └────────┬───────┘ │
└─────────┼──────────────────────┼─────────┘
          │                      │
          ▼                      ▼
┌─────────────────────────────────────────┐
│     Firebase Cloud / Local Storage      │
└─────────────────────────────────────────┘
```

---

## 1️⃣ Flujo de Autenticación

### Login de Usuario

```
┌──────────────┐
│  LoginPage   │
│ (UI Input)   │
└──────┬───────┘
       │ AuthLoginRequested(email, password)
       ▼
┌──────────────┐
│  AuthBloc    │
│              │
└──────┬───────┘
       │ execute()
       ▼
┌──────────────┐
│ LoginUseCase │
│              │
└──────┬───────┘
       │ login(email, password)
       ▼
┌─────────────────────┐
│ AuthRepositoryImpl  │
│                     │
└──────┬──────────────┘
       │
       ├─► FirebaseAuthDataSource.login()
       │   └─► Firebase Auth API
       │
       └─► AuthLocalDataSource.cacheUser()
           └─► SharedPreferences

       ▼
┌──────────────┐
│  AuthResult  │
│ (User/Error) │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ AuthState        │
│ .Authenticated   │
│ .Error           │
└──────┬───────────┘
       │
       ▼
┌──────────────┐
│ UI Update    │
│ Navigate →   │
│ Dashboard    │
└──────────────┘
```

**Pasos:**
1. Usuario ingresa email/password en LoginPage
2. LoginPage dispara evento `AuthLoginRequested` al AuthBloc
3. AuthBloc ejecuta LoginUseCase
4. LoginUseCase llama a AuthRepository.login()
5. AuthRepositoryImpl:
   - Llama a FirebaseAuthDataSource para autenticar
   - Si es exitoso, guarda en cache con AuthLocalDataSource
6. Retorna AuthResult
7. AuthBloc emite nuevo estado:
   - `AuthAuthenticated` si OK → navega a Dashboard
   - `AuthError` si falla → muestra mensaje de error

---

## 2️⃣ Flujo de Monitoreo del Dashboard

### Inicio de Monitoreo

```
┌──────────────────┐
│ ControlPanel     │
│ (Play Button)    │
└────────┬─────────┘
         │ DashboardStartMonitoring
         ▼
┌──────────────────┐
│ DashboardBloc    │
│                  │
└────────┬─────────┘
         │ startSimulation()
         ▼
┌──────────────────┐
│ SensorSimulator  │
│ (Core/Mocks)     │
└────────┬─────────┘
         │ Stream<SensorData>
         │ cada 100ms
         ▼
┌──────────────────┐
│ DashboardBloc    │
│ _onSensorData()  │
└────────┬─────────┘
         │
         ├─► RiskCalculator.calculateRiskScore()
         │   └─► Analiza aceleración, giro, historial
         │
         ├─► Detecta patrones peligrosos:
         │   ├─► isRecklessDriving?
         │   ├─► isCrashDetected?
         │   └─► isDistracted?
         │
         └─► NotificationService.showAlert()
             └─► Audio + Vibración + Overlay

         ▼
┌──────────────────┐
│ DashboardState   │
│ (Updated)        │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────┐
│ UI Widgets                       │
├──────────────────────────────────┤
│ • RiskIndicator → muestra score  │
│ • StatusIndicator → animación    │
│ • StatsCards → contadores        │
│ • ControlPanel → cronómetro      │
└──────────────────────────────────┘
```

**Pasos:**
1. Usuario presiona botón "Iniciar" en ControlPanel
2. ControlPanel dispara `DashboardStartMonitoring`
3. DashboardBloc:
   - Cambia estado a `isMonitoring = true`
   - Inicia SensorSimulator
4. SensorSimulator genera stream de SensorData cada 100ms
5. DashboardBloc recibe cada SensorData:
   - Calcula riskScore con RiskCalculator
   - Detecta patrones peligrosos
   - Si hay peligro → dispara NotificationService
   - Actualiza estado con nuevos datos
6. UI se reconstruye automáticamente mostrando:
   - Score de riesgo actualizado
   - Animaciones de alerta
   - Contadores incrementados
   - Cronómetro en progreso

---

## 3️⃣ Flujo de Alertas

### Detección y Respuesta

```
┌──────────────────┐
│  SensorData      │
│ (accel > 3.0)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Pattern Detection│
│ isRecklessDriving│
│ = true           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ DashboardBloc    │
│ _triggerAlert()  │
└────────┬─────────┘
         │ DashboardTriggerAlert
         ▼
┌──────────────────────────┐
│ NotificationService      │
│ showAlert(type, severity)│
└────────┬─────────────────┘
         │
         ├─► _playAlertSound()
         │   └─► audioplayers
         │       ├─► Tono base (medium/high/critical)
         │       └─► Mensaje de voz
         │           ("Atención, conducción temeraria")
         │
         ├─► _triggerVibration()
         │   └─► vibration plugin
         │       └─► Patrón según severidad
         │
         └─► onShowOverlay()
             └─► AlertOverlay widget
                 └─► Dialog visual en pantalla

         ▼
┌──────────────────────────┐
│ DashboardState           │
│ • currentAlertType ✅    │
│ • recentAlerts.add() ✅  │
│ • recklessCount++ ✅     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ UI Response              │
├──────────────────────────┤
│ • StatusIndicator pulsa  │
│ • StatsCards actualiza   │
│ • RiskScore aumenta      │
│ • AlertOverlay aparece   │
└──────────────────────────┘
```

**Clasificación de Alertas:**
- **Distracción**: Uso de celular, mirada fuera del camino
- **Temeraria**: Aceleración > 3.0 m/s², giros > 45°/s
- **Emergencia**: Aceleración > 15.0 m/s² (posible impacto)

**Severidades:**
- **Low**: Eventos menores
- **Medium**: Distracciones, frenadas bruscas
- **High**: Conducción temeraria
- **Critical**: Impactos, emergencias

---

## 4️⃣ Flujo de Sesiones de Conducción

### Inicio de Sesión

```
┌──────────────────┐
│ DashboardPage    │
│ (Start Session)  │
└────────┬─────────┘
         │ SessionStartRequested
         ▼
┌──────────────────┐
│ SessionBloc      │
│                  │
└────────┬─────────┘
         │ execute()
         ▼
┌──────────────────┐
│ StartSessionUC   │
│                  │
└────────┬─────────┘
         │
         ├─► Geolocator.getCurrentPosition()
         │   └─► Captura ubicación GPS
         │
         └─► SessionRepository.startSession()
             └─► SessionRepositoryImpl
                 └─► Firestore.collection('driving_sessions')
                     .add({
                       userId: uid,
                       startLocation: GeoPoint,
                       startTime: Timestamp,
                       status: 'active'
                     })

         ▼
┌──────────────────┐
│ DrivingSession   │
│ (Entity)         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ SessionState     │
│ .Active          │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ UI Update        │
│ Session ID: xyz  │
└──────────────────┘
```

### Registro de Evento

```
┌──────────────────┐
│ DashboardBloc    │
│ (Alert Triggered)│
└────────┬─────────┘
         │ SessionAddEvent
         ▼
┌──────────────────┐
│ SessionBloc      │
│                  │
└────────┬─────────┘
         │ execute()
         ▼
┌──────────────────┐
│ AddSessionEventUC│
│                  │
└────────┬─────────┘
         │ addEvent(sessionId, event)
         ▼
┌──────────────────────────┐
│ SessionRepository        │
│ addEventToSession()      │
└────────┬─────────────────┘
         │
         └─► Firestore
             .collection('session_events')
             .add({
               sessionId: xyz,
               eventType: 'reckless_driving',
               severity: 'high',
               timestamp: now,
               sensorData: {...}
             })

         ▼
┌──────────────────┐
│ SessionState     │
│ events.add()     │
└──────────────────┘
```

### Fin de Sesión

```
┌──────────────────┐
│ DashboardPage    │
│ (Stop Session)   │
└────────┬─────────┘
         │ SessionEndRequested
         ▼
┌──────────────────┐
│ SessionBloc      │
│                  │
└────────┬─────────┘
         │ execute()
         ▼
┌──────────────────┐
│ EndSessionUC     │
│                  │
└────────┬─────────┘
         │
         ├─► Geolocator.getCurrentPosition()
         │   └─► Captura ubicación final
         │
         ├─► Calcula estadísticas:
         │   ├─► Duración total
         │   ├─► Total de eventos
         │   ├─► Score promedio
         │   └─► Clasificación por tipo
         │
         └─► SessionRepository.endSession()
             └─► Firestore.doc(sessionId).update({
                   endLocation: GeoPoint,
                   endTime: Timestamp,
                   duration: seconds,
                   totalEvents: count,
                   riskScore: avg,
                   status: 'completed'
                 })

         ▼
┌──────────────────┐
│ SessionState     │
│ .Ended           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Navigate →       │
│ HistoryPage      │
└──────────────────┘
```

---

## 5️⃣ Flujo de Integración ESP32-CAM

### Recepción de Frames

```
┌──────────────────┐
│   ESP32-CAM      │
│ (Capture Image)  │
└────────┬─────────┘
         │ HTTP POST /upload
         │ Body: {"image": "<base64>", "timestamp": 12345}
         ▼
┌──────────────────────────┐
│ HttpServerService        │
│ (Shelf Router)           │
└────────┬─────────────────┘
         │
         ├─► Validar JSON
         ├─► Decodificar Base64
         ├─► Verificar JPEG magic bytes
         ├─► Validar tamaño (<500KB)
         │
         └─► Si válido:
             ├─► Crear CameraFrame
             └─► Agregar a Stream

         ▼
┌──────────────────┐
│ CameraRepository │
│ frameStream      │
└────────┬─────────┘
         │ Stream<CameraFrame>
         ▼
┌──────────────────┐
│ CameraStreamBloc │
│ _onNewFrame()    │
└────────┬─────────┘
         │ CameraStreamNewFrame
         ▼
┌──────────────────┐
│ CameraStreamState│
│ .NewFrame        │
│ (frame, count)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│ ESP32DebugPanel          │
│ (Widget)                 │
├──────────────────────────┤
│ • Image.memory(bytes) ✅ │
│ • Timestamp ✅           │
│ • Counter ✅             │
│ • Fade Animation ✅      │
└──────────────────────────┘
```

**Respuesta al ESP32:**
```json
HTTP 200 OK
{
  "status": "success",
  "receivedAt": "2025-10-17T14:23:45.123Z",
  "frameNumber": 127
}
```

---

## 6️⃣ Flujo de Cálculo de Riesgo

### Algoritmo de RiskCalculator

```
┌──────────────────┐
│  SensorData      │
│ (Entrada)        │
└────────┬─────────┘
         │
         ▼
┌────────────────────────────┐
│ RiskCalculator             │
│ calculateRiskScore()       │
└────────┬───────────────────┘
         │
         ├─► Factor Aceleración (30%)
         │   └─► magnitude = sqrt(x² + y² + z²)
         │       └─► score += min(magnitude * 10, 30)
         │
         ├─► Factor Rotación (30%)
         │   └─► magnitude = sqrt(gx² + gy² + gz²)
         │       └─► score += min(magnitude / 2, 30)
         │
         └─► Factor Historial (40%)
             └─► recentAlerts.length * 5
                 └─► score += min(count * 5, 40)

         ▼
┌────────────────────────────┐
│ Risk Score (0-100)         │
├────────────────────────────┤
│ 0-30:  Verde (Seguro)      │
│ 30-60: Naranja (Moderado)  │
│ 60-100: Rojo (Peligroso)   │
└────────────────────────────┘
```

**Ejemplo de Cálculo:**

Entrada:
- Aceleración: (2.5, 1.2, 10.3) m/s²
- Giroscopio: (15, 8, 20) °/s
- Alertas recientes: 3

Cálculo:
1. Aceleración:
   - Magnitud = sqrt(2.5² + 1.2² + (10.3-9.8)²) = 2.8
   - Score = min(2.8 * 10, 30) = **28**

2. Rotación:
   - Magnitud = sqrt(15² + 8² + 20²) = 26.3
   - Score = min(26.3 / 2, 30) = **13.15**

3. Historial:
   - Score = min(3 * 5, 40) = **15**

**Risk Score Total = 28 + 13.15 + 15 = 56.15 (Moderado)**

---

## 7️⃣ Flujo de Datos de Firebase

### Estructura de Firestore

```
firestore/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── displayName: string
│       ├── createdAt: Timestamp
│       └── lastLogin: Timestamp
│
├── driving_sessions/
│   └── {sessionId}/
│       ├── userId: string
│       ├── startTime: Timestamp
│       ├── endTime: Timestamp?
│       ├── startLocation: GeoPoint
│       ├── endLocation: GeoPoint?
│       ├── duration: number (seconds)
│       ├── totalEvents: number
│       ├── riskScore: number
│       ├── status: 'active' | 'completed'
│       └── stats: {
│           distractionCount: number,
│           recklessCount: number,
│           emergencyCount: number
│       }
│
└── session_events/
    └── {eventId}/
        ├── sessionId: string
        ├── eventType: string
        ├── severity: string
        ├── timestamp: Timestamp
        ├── sensorData: {
        │   accelerationX: number,
        │   accelerationY: number,
        │   accelerationZ: number,
        │   gyroscopeX: number,
        │   gyroscopeY: number,
        │   gyroscopeZ: number
        └── }
```

### Queries Principales

**1. Obtener sesiones de un usuario:**
```dart
FirebaseFirestore.instance
  .collection('driving_sessions')
  .where('userId', isEqualTo: userId)
  .orderBy('startTime', descending: true)
  .limit(20)
  .get()
```

**2. Obtener eventos de una sesión:**
```dart
FirebaseFirestore.instance
  .collection('session_events')
  .where('sessionId', isEqualTo: sessionId)
  .orderBy('timestamp')
  .get()
```

**3. Actualizar sesión activa:**
```dart
FirebaseFirestore.instance
  .collection('driving_sessions')
  .doc(sessionId)
  .update({
    'endTime': FieldValue.serverTimestamp(),
    'status': 'completed',
    'totalEvents': count
  })
```

---

## 8️⃣ Flujo de Notificaciones

### Sistema Multimodal

```
┌──────────────────┐
│  Alert Trigger   │
│ (Evento Detectado│
└────────┬─────────┘
         │ showAlert(type, severity)
         ▼
┌─────────────────────────────┐
│ NotificationService         │
│ (Singleton)                 │
└────────┬────────────────────┘
         │
         ├─► Canal 1: Audio
         │   ├─► _playAlertSound()
         │   │   └─► audioplayers.play()
         │   │       ├─► Tono base (medium/high/critical)
         │   │       └─► Mensaje de voz específico
         │   │
         │   └─► Volumen según configuración
         │
         ├─► Canal 2: Vibración
         │   └─► _triggerVibration()
         │       └─► Vibration.vibrate(pattern)
         │           ├─► Low: 200ms
         │           ├─► Medium: [0,300,100,300]
         │           ├─► High: [0,500,200,500,200,500]
         │           └─► Critical: [0,1000,300,1000,300,1000]
         │
         └─► Canal 3: Visual
             └─► onShowOverlay()
                 └─► AlertOverlay.show()
                     ├─► Ícono según tipo
                     ├─► Color según severidad
                     ├─► Mensaje descriptivo
                     └─► Botón "Entendido"

         ▼
┌─────────────────────────────┐
│ Cooldown Manager            │
│ (Evita spam de alertas)     │
├─────────────────────────────┤
│ lastAlertTime[type] = now   │
│ Si (now - last) < 30s:      │
│   return (no mostrar)       │
└─────────────────────────────┘
```

**Assets de Notificación:**

Audio:
- `assets/sounds/alerts/medium_alert.mp3`
- `assets/sounds/alerts/high_alert.mp3`
- `assets/sounds/alerts/critical_alert.mp3`
- `assets/sounds/voices/distraction_warning_es.mp3`
- `assets/sounds/voices/reckless_warning_es.mp3`
- `assets/sounds/voices/impact_warning_es.mp3`
- `assets/sounds/voices/phone_use_warning_es.mp3`
- `assets/sounds/voices/look_away_warning_es.mp3`
- `assets/sounds/voices/sudden_brake_warning_es.mp3`

---

## 9️⃣ Flujo de Navegación

### Rutas Principales

```
/splash (Inicial)
  │
  ├─► Firebase Auth Check
  │   ├─► Autenticado → /dashboard
  │   └─► No autenticado → /login
  │
/login
  │
  ├─► Login Exitoso → /dashboard
  ├─► Olvidé contraseña → /forgot-password
  └─► Crear cuenta → /register

/dashboard (Protegida)
  │
  ├─► Menú lateral:
  │   ├─► Perfil → /profile
  │   ├─► Historial → /history
  │   ├─► Notificaciones → /notification-settings
  │   ├─► ESP32 Debug → /esp32-debug
  │   └─► Cerrar sesión → /login
  │
  └─► Botón emergencia → Dialog modal

/history
  │
  └─► Tap en sesión → /session-events?id={sessionId}

/profile
  │
  └─► Editar contactos → Dialog modal
```

**Protección de Rutas:**
```dart
redirect: (context, state) {
  final isLoggedIn = authBloc.state is AuthAuthenticated;
  final isGoingToLogin = state.location == '/login';

  if (!isLoggedIn && !isGoingToLogin) {
    return '/login'; // Redirige a login si no autenticado
  }

  if (isLoggedIn && isGoingToLogin) {
    return '/dashboard'; // Redirige a dashboard si ya autenticado
  }

  return null; // Permite navegación
}
```

---

## 🔟 Flujo de Ciclo de Vida

### Inicialización de la App

```
main()
  │
  ├─► WidgetsFlutterBinding.ensureInitialized()
  ├─► Firebase.initializeApp()
  ├─► NotificationService.initialize()
  │   ├─► Cargar assets de audio
  │   ├─► Inicializar vibration
  │   └─► Configurar local notifications
  │
  └─► runApp(MyApp)
      │
      └─► MultiBlocProvider
          ├─► AuthBloc (singleton)
          ├─► DashboardBloc
          ├─► SessionBloc
          └─► CameraStreamBloc

          └─► MaterialApp.router(AppRouter.router)
              │
              └─► SplashPage (inicial)
                  │
                  └─► AuthCheckRequested
                      ├─► Autenticado → Dashboard
                      └─► No autenticado → Login
```

### Cierre Limpio

```
DashboardPage.dispose()
  │
  ├─► SessionBloc.add(SessionEndRequested)
  │   └─► Guarda sesión en Firestore
  │
  ├─► DashboardBloc.add(DashboardStopMonitoring)
  │   └─► SensorSimulator.stopSimulation()
  │
  └─► CameraStreamBloc.add(CameraStreamStop)
      └─► HttpServerService.close()
          └─► Libera puerto 8080
```

---

## 📈 Métricas de Performance

### Intervalos de Actualización

| Componente | Intervalo | Justificación |
|---|---|---|
| SensorData | 100ms | Detección rápida de cambios |
| UI Dashboard | 300ms | Throttling para evitar renders excesivos |
| Risk Score | 300ms | Sincronizado con UI |
| Frame ESP32 | 500ms | Balance entre latencia y bandwidth |
| Session Update | 30s | Actualización periódica a Firestore |

### Optimizaciones

1. **Stream Throttling:**
   ```dart
   sensorStream
     .throttleTime(Duration(milliseconds: 300))
     .listen((data) => updateUI(data));
   ```

2. **Debouncing de Alertas:**
   - Cooldown de 30s entre alertas del mismo tipo
   - Cola máxima de 10 alertas

3. **Gestión de Memoria:**
   - ESP32: Solo guarda último frame
   - Firebase: Queries con límite de 20 registros
   - Audio: Pre-carga de assets en initState

---

## 🔄 Manejo de Estados de Error

### Estrategias de Recuperación

```
Error en Firebase Auth
  │
  ├─► AuthError state
  │   └─► Muestra mensaje al usuario
  │       └─► Permite reintentar
  │
Error en Firestore Write
  │
  ├─► SessionError state
  │   └─► Guarda en queue local
  │       └─► Reintenta en próxima conexión
  │
Error en HTTP Server (ESP32)
  │
  ├─► CameraStreamError state
  │   └─► Muestra mensaje de reconexión
  │       └─► Botón manual de reinicio
  │
Error en Sensor Simulator
  │
  └─► DashboardError state
      └─► Detiene monitoreo
          └─► Botón de reinicio
```

---

Este documento detalla el flujo completo de datos en la aplicación DriveGuard, desde la captura de sensores hasta la presentación en UI y persistencia en Firebase.
