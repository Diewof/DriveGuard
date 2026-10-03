# DriveGuard 

## Dispositivo Inteligente de Prevención y Respuesta ante Crisis de Conducción

Un sistema híbrido que integra sensores, inteligencia artificial y una aplicación móvil para monitorear en tiempo real el estado físico y de atención del conductor, con el fin de prevenir accidentes de tránsito ocasionados por distracción o alteraciones físicas.

---

##  Descripción del Proyecto

DriveGuard aborda la seguridad vial mediante tecnologías **IoT e Inteligencia Artificial**, enfocándose en reducir los riesgos derivados del uso del celular, la fatiga y la distracción al volante. Está enmarcado en la ingeniería de software y hardware embebido, con aplicaciones directas en movilidad inteligente y transporte seguro.

### Características Principales

-  **Monitoreo en Tiempo Real** - Sensores de aceleración, rotación y cámara
-  **Alertas Multimodales** - Sonido, vibración y notificaciones visuales
-  **Integración ESP32-CAM** - Captura y análisis de video
- **App Multiplataforma** - Flutter para Android e iOS
-  **Sincronización Cloud** - Firebase para historial y estadísticas
-  **Detección Inteligente** - Algoritmos de IA para patrones peligrosos

---

##  Objetivos

### Objetivo General

Desarrollar un dispositivo portátil y autónomo que detecte distracciones o condiciones físicas adversas del conductor, alertando y respondiendo automáticamente en situaciones de riesgo para proteger la vida de los ocupantes y terceros.

### Objetivos Específicos

1. **Hardware:** Diseñar e implementar sensores de movimiento, acelerómetros y cámara para registrar datos fisiológicos y comportamentales
2. **IA:** Desarrollar algoritmos en la nube para analizar señales multimodales y detectar riesgos en tiempo real
3. **App Móvil:** Crear aplicación para monitoreo remoto, notificaciones y activación de protocolos de emergencia
4. **Alertas:** Implementar sistema de alertas inteligentes (sonido, vibración, notificaciones)
5. **Emergencias:** Incorporar módulo de respuesta autónoma conectado a servicios de emergencia
6. **Validación:** Probar el sistema mediante pruebas controladas, evaluando precisión, efectividad y confiabilidad

---

## Alcance

### Implementado 

- [x] App móvil Flutter multiplataforma
- [x] Sistema de autenticación (Firebase Auth)
- [x] Dashboard con monitoreo en tiempo real
- [x] Simulador de sensores (acelerómetro, giroscopio)
- [x] Sistema de alertas multimodales (audio, vibración, visual)
- [x] Gestión de sesiones de conducción
- [x] Historial de eventos en Firestore
- [x] Integración ESP32-CAM con servidor HTTP embebido
- [x] Cálculo de risk score en tiempo real
- [x] Panel de debug para ESP32-CAM

### En Desarrollo 

- [ ] Algoritmos de IA para detección de objetos (YOLO/MobileNet)
- [ ] Procesamiento de frames de cámara con IA
- [ ] Detección de fatiga (análisis de parpadeo)
- [ ] Integración con servicios de emergencia

### Planeado 📋

- [ ] App Web para visualización de estadísticas
- [ ] Modo offline con sincronización posterior
- [ ] Soporte para múltiples ESP32-CAM
- [ ] Exportar sesiones a PDF/CSV

---

##  Tecnologías

### Frontend (App Móvil)

- **Flutter** 3.16.0+
- **Dart** 3.0+
- **BLoC Pattern** (flutter_bloc)
- **GoRouter** para navegación
- **Audioplayers** para alertas de audio
- **Vibration** para feedback háptico

### Backend

- **Firebase Authentication** - Login/Registro
- **Cloud Firestore** - Base de datos NoSQL
- **Cloud Functions** - Node.js + Express (próximamente)

### Hardware

- **ESP32-CAM** - Captura de video
- **Servidor HTTP** (Shelf) - Comunicación ESP32 ↔ App

### Arquitectura

- **Clean Architecture** - Separación de capas
- **SOLID Principles** - Código mantenible
- **Repository Pattern** - Abstracción de datos
- **BLoC Pattern** - Gestión de estado reactivo

---

##  Documentación

Toda la documentación del proyecto está organizada en la carpeta [`documentacion/`](documentacion/):

### Documentos Principales

| Documento | Descripción |
|-----------|-------------|
| [ Índice General](documentacion/01-general/INDICE.md) | Índice completo de toda la documentación |
| [ Arquitectura](documentacion/02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md) | Clean Architecture + BLoC detallado |
| [ Flujo de Datos](documentacion/02-arquitectura/FLUJO_DE_DATOS.md) | Diagramas completos de flujos |
| [ ESP32 Integration](documentacion/03-hardware/ESP32_INTEGRATION_GUIDE.md) | Guía de integración ESP32-CAM |
| [ API HTTP](documentacion/04-api-integracion/API_SERVIDOR_HTTP.md) | Documentación del servidor embebido |
| [ Instalación](documentacion/05-guias-usuario/INSTALACION.md) | Guía de instalación paso a paso |
| [ FAQ](documentacion/05-guias-usuario/FAQ.md) | Preguntas frecuentes |
| [ Setup Dev](documentacion/06-desarrollo/SETUP_DESARROLLO.md) | Configurar entorno de desarrollo |

### Categorías

- **[01-general/](documentacion/01-general/)** - Información general del proyecto
- **[02-arquitectura/](documentacion/02-arquitectura/)** - Arquitectura técnica completa
- **[03-hardware/](documentacion/03-hardware/)** - Integración IoT y ESP32-CAM
- **[04-api-integracion/](documentacion/04-api-integracion/)** - APIs y servicios
- **[05-guias-usuario/](documentacion/05-guias-usuario/)** - Manuales de usuario
- **[06-desarrollo/](documentacion/06-desarrollo/)** - Guías de desarrollo
- **[07-testing/](documentacion/07-testing/)** - Testing (próximamente)
- **[08-seguridad/](documentacion/08-seguridad/)** - Seguridad (próximamente)

---

##  Inicio Rápido

### Prerrequisitos

- Flutter SDK 3.16.0+
- Android Studio o Xcode
- Firebase CLI
- Cuenta de Firebase

### Instalación

```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/driveguard.git
cd driveguard

# Instalar dependencias
flutter pub get

# Configurar Firebase
flutterfire configure

# Ejecutar app
flutter run
```

Para instrucciones detalladas, ver [Guía de Instalación](documentacion/05-guias-usuario/INSTALACION.md).

---

##  Uso de la Aplicación

### 1. Registro e Inicio de Sesión

- Crear cuenta con email y contraseña
- Iniciar sesión para acceder al dashboard

### 2. Iniciar Monitoreo

- Dashboard → Presionar "Iniciar Monitoreo"
- El sistema comenzará a simular sensores
- Se generarán alertas según patrones detectados

### 3. Visualizar Historial

- Menú lateral → Historial
- Ver sesiones anteriores
- Tap en sesión para ver eventos detallados

### 4. Configurar Notificaciones

- Menú lateral → Configuración de Notificaciones
- Ajustar volumen, vibración, tipos de alerta

### 5. Integración ESP32-CAM (Opcional)

- Menú lateral → ESP32-CAM Debug
- Presionar "Iniciar Servidor"
- Configurar ESP32 con la IP mostrada

Ver [Manual de Usuario](documentacion/05-guias-usuario/MANUAL_USUARIO.md) para más detalles.

---

##  Estructura del Proyecto

```
DriveGuard/
├── android/                # Proyecto Android
├── ios/                    # Proyecto iOS
├── lib/
│   ├── core/              # Componentes centrales
│   │   ├── constants/     # Constantes de la app
│   │   ├── services/      # Servicios globales
│   │   ├── utils/         # Utilidades
│   │   └── mocks/         # Simuladores
│   ├── data/              # Capa de datos
│   │   ├── datasources/   # Fuentes de datos
│   │   ├── models/        # Modelos de datos
│   │   └── repositories/  # Implementaciones
│   ├── domain/            # Capa de dominio
│   │   ├── entities/      # Entidades de negocio
│   │   ├── repositories/  # Interfaces
│   │   └── usecases/      # Casos de uso
│   └── presentation/      # Capa de presentación
│       ├── blocs/         # Gestores de estado
│       ├── pages/         # Páginas de la app
│       └── widgets/       # Widgets reutilizables
├── documentacion/         #  Documentación completa
├── functions/             # Cloud Functions (Node.js)
├── test/                  # Tests
└── assets/               # Recursos (audio, imágenes)
```

Ver [Arquitectura](documentacion/02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md) para más detalles.

---

## Testing

```bash
# Todos los tests
flutter test

# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Con cobertura
flutter test --coverage
```

---

## Contribuir

¡Las contribuciones son bienvenidas!

1. Fork del repositorio
2. Crear branch: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m "feat: agregar nueva funcionalidad"`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abrir Pull Request

Ver [Guía de Desarrollo](documentacion/06-desarrollo/SETUP_DESARROLLO.md) para más detalles.

---

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo LICENSE para más detalles.

---



## Agradecimientos

- Flutter Team por el increíble framework
- Firebase por los servicios cloud
- Comunidad de código abierto

---



<div align="center">

**DriveGuard** - Conducción Segura con Tecnología Inteligente 

</div>
