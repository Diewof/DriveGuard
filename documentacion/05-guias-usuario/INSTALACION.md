# Guía de Instalación - DriveGuard

Esta guía te ayudará a instalar y configurar DriveGuard en tu dispositivo Android o iOS.

---

## 📋 Requisitos del Sistema

### Dispositivo Móvil

**Android:**
- Android 11 (API 30) o superior
- 100 MB de espacio disponible
- Conexión a Internet (WiFi o datos móviles)
- Permisos requeridos:
  - Ubicación (GPS)
  - Vibración
  - WiFi
  - Notificaciones

**iOS:**
- iOS 12.0 o superior
- 100 MB de espacio disponible
- Conexión a Internet
- Permisos requeridos:
  - Ubicación
  - Notificaciones

---

## 🚀 Instalación desde Código Fuente

### Paso 1: Requisitos Previos

1. **Instalar Flutter SDK:**
   - Descargar desde [flutter.dev](https://flutter.dev)
   - Versión requerida: Flutter 3.16.0 o superior
   - Verificar instalación:
     ```bash
     flutter --version
     ```

2. **Instalar Git:**
   - Descargar desde [git-scm.com](https://git-scm.com)

3. **Configurar Editor:**
   - Visual Studio Code (recomendado)
   - Android Studio
   - IntelliJ IDEA

### Paso 2: Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/driveguard.git
cd driveguard
```

### Paso 3: Instalar Dependencias

```bash
flutter pub get
```

Esto instalará todas las dependencias listadas en `pubspec.yaml`:
- firebase_core
- firebase_auth
- cloud_firestore
- flutter_bloc
- audioplayers
- vibration
- geolocator
- y más...

### Paso 4: Configurar Firebase

1. **Crear Proyecto en Firebase Console:**
   - Ir a [console.firebase.google.com](https://console.firebase.google.com)
   - Crear nuevo proyecto "DriveGuard"
   - Habilitar Google Analytics (opcional)

2. **Configurar Android:**
   ```bash
   # Instalar Firebase CLI
   npm install -g firebase-tools

   # Login en Firebase
   firebase login

   # Configurar FlutterFire
   flutterfire configure
   ```

3. **Habilitar Servicios:**
   - Authentication → Email/Password
   - Firestore Database → Modo producción
   - Storage (opcional)

4. **Verificar Archivos Generados:**
   - `lib/firebase_options.dart` ✅
   - `android/app/google-services.json` ✅
   - `ios/Runner/GoogleService-Info.plist` ✅

### Paso 5: Configurar Permisos

**Android** (`android/app/src/main/AndroidManifest.xml`):

Ya configurado en el proyecto, incluye:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

**iOS** (`ios/Runner/Info.plist`):

Agregar:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>DriveGuard necesita tu ubicación para registrar tus sesiones de conducción</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>DriveGuard necesita acceso a tu ubicación para monitoreo en tiempo real</string>
```

### Paso 6: Ejecutar en Dispositivo

**Android:**
```bash
# Conectar dispositivo por USB o emulador
flutter devices

# Ejecutar app
flutter run
```

**iOS:**
```bash
# Abrir Xcode
open ios/Runner.xcworkspace

# Seleccionar dispositivo
# Ejecutar desde Xcode
```

### Paso 7: Generar APK/IPA

**Android (APK):**
```bash
flutter build apk --release
```
El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

**Android (App Bundle):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 📦 Instalación desde APK Pre-compilado

### Para Android

1. **Descargar APK:**
   - Ir a la sección Releases del repositorio
   - Descargar `driveguard-v1.0.0.apk`

2. **Habilitar Fuentes Desconocidas:**
   - Configuración → Seguridad
   - Activar "Instalar apps desconocidas"

3. **Instalar APK:**
   - Abrir archivo APK descargado
   - Seguir instrucciones en pantalla
   - Aceptar permisos solicitados

4. **Verificar Instalación:**
   - Buscar ícono "DriveGuard" en cajón de apps
   - Abrir aplicación

---

## ⚙️ Configuración Inicial

### Primer Inicio

1. **Splash Screen:**
   - La app mostrará el logo de DriveGuard
   - Verificará conexión con Firebase
   - Redirigirá a Login

2. **Crear Cuenta:**
   - Presionar "Crear cuenta"
   - Ingresar email válido
   - Crear contraseña (mín. 6 caracteres)
   - Confirmar contraseña
   - Presionar "Registrarse"

3. **Iniciar Sesión:**
   - Ingresar email y contraseña
   - Presionar "Iniciar Sesión"
   - Accederás al Dashboard

### Configurar Perfil

1. **Ir a Perfil:**
   - Abrir menú lateral
   - Seleccionar "Perfil"

2. **Completar Información:**
   - Nombre completo
   - Teléfono
   - Foto de perfil (opcional)

3. **Agregar Contactos de Emergencia:**
   - Presionar "Agregar Contacto"
   - Nombre del contacto
   - Teléfono
   - Relación (familiar, amigo, etc.)
   - Guardar

### Configurar Notificaciones

1. **Ir a Configuración:**
   - Menú lateral → "Configuración de Notificaciones"

2. **Ajustar Preferencias:**
   - Habilitar/deshabilitar sonido
   - Ajustar volumen de alertas
   - Habilitar/deshabilitar vibración
   - Seleccionar tipos de alerta:
     - Distracción
     - Conducción temeraria
     - Emergencias

3. **Guardar Cambios:**
   - Presionar "Guardar Configuración"

---

## 🔧 Integración con Hardware (Opcional)

### Configurar ESP32-CAM

Si tienes el dispositivo ESP32-CAM:

1. **Iniciar Servidor en App:**
   - Menú lateral → "ESP32-CAM Debug"
   - Presionar "Iniciar Servidor"
   - Anotar la IP mostrada (ej: `192.168.1.100`)

2. **Configurar ESP32:**
   - Ver [ESP32_INTEGRATION_GUIDE.md](../../03-hardware/ESP32_INTEGRATION_GUIDE.md)
   - Actualizar IP en código del ESP32
   - Compilar y subir firmware

3. **Verificar Conexión:**
   - En panel de debug verás frames recibidos
   - Contador debe incrementar
   - Imagen debe actualizarse cada 500ms

---

## 🧪 Verificar Instalación

### Checklist de Verificación

- [ ] App se abre sin errores
- [ ] Puedes crear cuenta
- [ ] Puedes iniciar sesión
- [ ] Dashboard carga correctamente
- [ ] Botón "Iniciar Monitoreo" funciona
- [ ] Se muestran datos de sensores simulados
- [ ] Alertas suenan correctamente
- [ ] Vibración funciona
- [ ] Puedes ver historial (vacío inicialmente)
- [ ] Puedes cerrar sesión

### Probar Funcionalidades

**1. Iniciar Sesión de Monitoreo:**
- Dashboard → Presionar "Iniciar"
- Verificar que cronómetro inicie
- Verificar que Risk Score cambie
- Verificar que Stats Cards se actualicen

**2. Generar Alertas:**
- El simulador generará alertas aleatorias
- Verificar sonido de alerta
- Verificar vibración
- Verificar overlay visual

**3. Ver Historial:**
- Detener monitoreo
- Ir a Historial
- Verificar que aparezca sesión guardada
- Tap en sesión → ver detalles

---

## 🐛 Solución de Problemas

### Error: "Firebase not initialized"

**Solución:**
```bash
flutterfire configure
```

### Error: "Google Services file missing"

**Android:**
- Verificar que existe `android/app/google-services.json`
- Recompilar: `flutter clean && flutter pub get`

**iOS:**
- Verificar que existe `ios/Runner/GoogleService-Info.plist`
- Abrir Xcode y agregar archivo manualmente

### Error: "Permission denied" (Ubicación)

**Solución:**
- Configuración del dispositivo → Apps → DriveGuard → Permisos
- Habilitar "Ubicación" → "Permitir siempre" o "Solo mientras se usa"

### Error: "Unable to load asset"

**Solución:**
```bash
flutter clean
flutter pub get
flutter run
```

### App se cierra al iniciar monitoreo

**Causa probable:** Permisos no otorgados

**Solución:**
- Configuración → Apps → DriveGuard → Permisos
- Habilitar todos los permisos solicitados
- Reiniciar app

### No se escuchan alertas

**Solución:**
- Verificar volumen del dispositivo
- Ir a Configuración de Notificaciones
- Habilitar "Sonido de alertas"
- Ajustar volumen al 80%

### ESP32 no conecta

**Solución:**
- Verificar que ambos están en misma WiFi
- Verificar IP en panel de debug
- Reiniciar servidor en app
- Ver [ESP32_INTEGRATION_GUIDE.md](../../03-hardware/ESP32_INTEGRATION_GUIDE.md)

---

## 📱 Actualizar Aplicación

### Desde Código Fuente

```bash
git pull origin main
flutter pub get
flutter run
```

### Desde APK

1. Desinstalar versión anterior
2. Instalar nueva APK
3. Iniciar sesión nuevamente

**Nota:** Los datos de Firebase se conservan

---

## 🗑️ Desinstalar

### Android

1. Configuración → Apps → DriveGuard
2. Presionar "Desinstalar"
3. Confirmar

**Nota:** Los datos en Firebase NO se eliminan automáticamente. Para eliminar tu cuenta:
- Abrir app antes de desinstalar
- Perfil → "Eliminar Cuenta"

### iOS

1. Mantener presionado ícono de DriveGuard
2. Presionar "Eliminar App"
3. Confirmar

---

## 📞 Soporte

Si encuentras problemas durante la instalación:

1. Consulta la sección de Troubleshooting arriba
2. Revisa las [FAQ](FAQ.md)
3. Verifica los logs de Flutter:
   ```bash
   flutter logs
   ```
4. Contacta al equipo de desarrollo

---

## 🔄 Próximos Pasos

Después de instalar:

1. Lee el [Manual de Usuario](MANUAL_USUARIO.md)
2. Configura tus [Notificaciones](CONFIGURACION_NOTIFICACIONES.md)
3. Si tienes ESP32, sigue la [Guía de Integración](../../03-hardware/ESP32_INTEGRATION_GUIDE.md)

---

**Instalación exitosa!** 🎉

Ahora estás listo para usar DriveGuard y conducir de manera más segura.
