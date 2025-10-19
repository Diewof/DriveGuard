# Guía de Configuración del Entorno de Desarrollo - DriveGuard

Esta guía te ayudará a configurar tu entorno de desarrollo para trabajar en el proyecto DriveGuard.

---

## 📋 Requisitos Previos

### Sistema Operativo

El desarrollo es compatible con:
- **Windows** 10/11
- **macOS** 10.14 o superior (requerido para desarrollo iOS)
- **Linux** (Ubuntu 20.04+ recomendado)

### Hardware Recomendado

- **RAM:** 8 GB mínimo (16 GB recomendado)
- **Disco:** 10 GB de espacio libre
- **Procesador:** Intel i5 o equivalente

---

## 🛠️ Instalación de Herramientas

### 1. Flutter SDK

**Instalar Flutter:**

**Windows:**
```bash
# Descargar Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# Agregar al PATH
setx PATH "%PATH%;C:\src\flutter\bin"
```

**macOS/Linux:**
```bash
# Descargar y extraer
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip
unzip flutter_macos_3.16.0-stable.zip

# Agregar al PATH
export PATH="$PATH:~/development/flutter/bin"

# Agregar permanentemente en ~/.zshrc o ~/.bashrc
echo 'export PATH="$PATH:~/development/flutter/bin"' >> ~/.zshrc
```

**Verificar Instalación:**
```bash
flutter doctor
```

Salida esperada:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.16.0, on macOS 13.0)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

### 2. Android Studio

**Descargar e Instalar:**
- [https://developer.android.com/studio](https://developer.android.com/studio)

**Configurar Android SDK:**
1. Abrir Android Studio
2. Settings → Appearance & Behavior → System Settings → Android SDK
3. Seleccionar:
   - Android 11 (API 30) ✅
   - Android 12 (API 31) ✅
   - Android 13 (API 33) ✅

**Instalar Flutter Plugin:**
1. Settings → Plugins
2. Buscar "Flutter"
3. Instalar plugin de Flutter (incluye Dart)

**Crear Emulador:**
1. Tools → Device Manager
2. Create Device
3. Seleccionar Pixel 5 (recomendado)
4. System Image: Android 11 (API 30)
5. Finish

### 3. Xcode (Solo macOS para iOS)

**Instalar desde App Store:**
- Buscar "Xcode"
- Descargar e instalar (12+ GB)

**Configurar Command Line Tools:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**Aceptar Licencia:**
```bash
sudo xcodebuild -license accept
```

**Instalar CocoaPods:**
```bash
sudo gem install cocoapods
```

**Crear Simulador:**
```bash
open -a Simulator
```

### 4. Visual Studio Code (Recomendado)

**Descargar:**
- [https://code.visualstudio.com/](https://code.visualstudio.com/)

**Extensiones Requeridas:**
1. **Flutter** (by Dart Code)
   - ID: `Dart-Code.flutter`
   - Incluye soporte para Dart

2. **Dart** (by Dart Code)
   - ID: `Dart-Code.dart-code`

3. **Firebase** (by Toba)
   - ID: `toba.vsfire`

**Extensiones Recomendadas:**
- **Error Lens** - Muestra errores inline
- **Better Comments** - Comentarios mejorados
- **Bracket Pair Colorizer** - Colores para brackets
- **Git Graph** - Visualización de Git
- **Todo Tree** - Gestión de TODOs
- **Pubspec Assist** - Autocompletado de dependencias

**Configurar VS Code:**

Crear `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 120,
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

### 5. Git

**Instalar:**

**Windows:**
- Descargar desde [git-scm.com](https://git-scm.com/download/win)

**macOS:**
```bash
brew install git
```

**Linux:**
```bash
sudo apt-get install git
```

**Configurar:**
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### 6. Firebase CLI

**Instalar Node.js:**
- Descargar desde [nodejs.org](https://nodejs.org/)
- Versión LTS recomendada

**Instalar Firebase Tools:**
```bash
npm install -g firebase-tools
```

**Login:**
```bash
firebase login
```

**Instalar FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
```

---

## 🚀 Configurar Proyecto DriveGuard

### 1. Clonar Repositorio

```bash
git clone https://github.com/tu-usuario/driveguard.git
cd driveguard
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

**Opción A: Usar Proyecto Existente**

Si ya existe el proyecto Firebase:
```bash
flutterfire configure
```

Seleccionar:
- Proyecto: `driveguard-prototipo`
- Plataformas: Android, iOS

**Opción B: Crear Nuevo Proyecto**

1. Ir a [console.firebase.google.com](https://console.firebase.google.com)
2. "Agregar proyecto"
3. Nombre: "DriveGuard Dev"
4. Ejecutar:
   ```bash
   flutterfire configure --project=driveguard-dev
   ```

**Verificar Archivos Generados:**
```bash
# Debe existir:
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 4. Configurar Firebase Services

**Habilitar Authentication:**
1. Firebase Console → Authentication
2. Sign-in method → Email/Password → Habilitar

**Configurar Firestore:**
1. Firebase Console → Firestore Database
2. "Crear base de datos"
3. Modo: Producción (o Prueba para desarrollo)
4. Ubicación: us-central1

**Reglas de Seguridad Iniciales:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Sesiones de conducción
    match /driving_sessions/{sessionId} {
      allow read: if request.auth != null &&
                    resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
                              resource.data.userId == request.auth.uid;
    }

    // Eventos de sesión
    match /session_events/{eventId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 5. Configurar Variables de Entorno

Crear archivo `.env` (opcional, para desarrollo local):

```env
FIREBASE_PROJECT_ID=driveguard-prototipo
FLUTTER_ENV=development
ESP32_DEFAULT_PORT=8080
```

**Nota:** Este archivo está en `.gitignore` y no se sube al repositorio.

### 6. Verificar Configuración

```bash
flutter doctor -v
```

Asegúrate de que todos los items tengan ✓:
- Flutter SDK
- Android toolchain
- Xcode (macOS)
- VS Code
- Dispositivos conectados

---

## 🏃 Ejecutar Proyecto

### Modo Debug (Desarrollo)

**En Emulador/Simulador:**
```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Ejecutar en Android
flutter run -d emulator-5554

# Ejecutar en iOS
flutter run -d "iPhone 14 Pro"
```

**En Dispositivo Físico:**

**Android:**
1. Habilitar "Opciones de Desarrollador" en dispositivo
2. Habilitar "Depuración USB"
3. Conectar por USB
4. Aceptar autorización en dispositivo
5. `flutter run`

**iOS:**
1. Conectar iPhone por USB
2. Confiar en computadora (en iPhone)
3. Xcode → Window → Devices and Simulators
4. Verificar que aparezca dispositivo
5. `flutter run`

### Modo Release (Testing)

```bash
# Android
flutter run --release

# iOS
flutter run --release --no-codesign
```

### Hot Reload

Mientras la app está corriendo:
- **r** - Hot reload (recarga cambios sin perder estado)
- **R** - Hot restart (reinicia app completa)
- **q** - Quit (salir)

---

## 🧪 Ejecutar Tests

### Unit Tests

```bash
flutter test test/unit/
```

### Widget Tests

```bash
flutter test test/widget/
```

### Integration Tests

```bash
flutter test integration_test/
```

### Todos los Tests

```bash
flutter test
```

### Con Cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📦 Gestión de Dependencias

### Agregar Dependencia

**Forma 1: Manual**

Editar `pubspec.yaml`:
```yaml
dependencies:
  nueva_dependencia: ^1.0.0
```

Luego:
```bash
flutter pub get
```

**Forma 2: Comando**

```bash
flutter pub add nueva_dependencia
```

### Actualizar Dependencias

```bash
# Actualizar todas
flutter pub upgrade

# Actualizar una específica
flutter pub upgrade cloud_firestore
```

### Ver Dependencias Obsoletas

```bash
flutter pub outdated
```

---

## 🔍 Debugging

### Logs en Tiempo Real

```bash
flutter logs
```

### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Luego ejecutar app y abrir URL mostrada.

**Características:**
- Inspector de Widgets
- Timeline de Performance
- Memory Profiler
- Network Inspector
- Logging

### Debug en VS Code

1. Abrir `main.dart`
2. F5 o Run → Start Debugging
3. Colocar breakpoints (F9)
4. Usar controles de debug:
   - Continue (F5)
   - Step Over (F10)
   - Step Into (F11)
   - Step Out (Shift+F11)

### Debug en Android Studio

1. Abrir proyecto
2. Seleccionar dispositivo
3. Run → Debug 'main.dart'
4. Usar breakpoints en editor

---

## 🏗️ Estructura de Desarrollo

### Branching Strategy

**Branches Principales:**
- `main` - Producción estable
- `develop` - Desarrollo activo
- `feature/*` - Nuevas características
- `bugfix/*` - Corrección de bugs
- `hotfix/*` - Parches urgentes

**Workflow:**
```bash
# Crear feature branch
git checkout develop
git pull origin develop
git checkout -b feature/nueva-funcionalidad

# Trabajar en feature
git add .
git commit -m "feat: agregar nueva funcionalidad"

# Merge a develop
git checkout develop
git merge feature/nueva-funcionalidad
git push origin develop
```

### Convenciones de Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nueva característica
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `style:` - Formateo, sin cambios en código
- `refactor:` - Refactorización
- `test:` - Agregar/modificar tests
- `chore:` - Mantenimiento, dependencias

**Ejemplos:**
```bash
git commit -m "feat: agregar detección de frenada brusca"
git commit -m "fix: corregir crash al iniciar sesión"
git commit -m "docs: actualizar README con instrucciones"
git commit -m "refactor: mejorar estructura de DashboardBloc"
```

---

## 🔧 Herramientas de Desarrollo

### Análisis de Código

**Ejecutar Análisis:**
```bash
flutter analyze
```

**Configurar Reglas:**

Ver `analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_final_fields
```

### Formateo de Código

**Formatear Archivo:**
```bash
dart format lib/main.dart
```

**Formatear Todo:**
```bash
dart format lib/
```

**En VS Code:** Guardar archivo formatea automáticamente (si está configurado)

### Generar Código

**Para Modelos con json_serializable:**
```bash
flutter pub run build_runner build
```

**Con Watch (auto-regenera):**
```bash
flutter pub run build_runner watch
```

---

## 📱 Build y Deployment

### Android APK

**Debug:**
```bash
flutter build apk --debug
```

**Release:**
```bash
flutter build apk --release
```

Salida: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

Salida: `build/app/outputs/bundle/release/app-release.aab`

### iOS IPA

```bash
flutter build ios --release
```

Luego usar Xcode para archivar y exportar.

---

## 🐛 Troubleshooting

### Error: "Gradle build failed"

**Solución:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "CocoaPods not installed"

**Solución:**
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Error: "License not accepted"

**Solución:**
```bash
flutter doctor --android-licenses
```

### Error: "Unable to locate Android SDK"

**Solución:**
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### Limpiar Proyecto Completo

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter run
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Docs](https://dart.dev/guides)
- [Firebase Docs](https://firebase.google.com/docs)
- [BLoC Library](https://bloclibrary.dev/)

### Comunidad

- [Flutter Discord](https://discord.gg/flutter)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### Cursos Recomendados

- [Flutter & Dart - The Complete Guide](https://www.udemy.com/course/learn-flutter-dart-to-build-ios-android-apps/)
- [BLoC Pattern Course](https://www.udemy.com/course/bloc-from-zero-to-hero/)

---

## ✅ Checklist de Configuración

Antes de comenzar a desarrollar:

- [ ] Flutter SDK instalado y verificado
- [ ] Android Studio/Xcode configurado
- [ ] VS Code con extensiones instaladas
- [ ] Git configurado
- [ ] Firebase CLI instalado
- [ ] Proyecto clonado
- [ ] Dependencias instaladas (`flutter pub get`)
- [ ] Firebase configurado (`flutterfire configure`)
- [ ] App ejecuta correctamente (`flutter run`)
- [ ] Tests pasan (`flutter test`)
- [ ] Análisis de código OK (`flutter analyze`)

---

**¡Entorno listo para desarrollo!** 🚀

Ahora puedes comenzar a contribuir al proyecto DriveGuard. Lee la [Guía de Contribución](CONTRIBUIR.md) para conocer el workflow de desarrollo.
