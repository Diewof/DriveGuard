# 📚 Documentación DriveGuard

Bienvenido a la documentación completa del proyecto **DriveGuard** - Sistema Inteligente de Prevención y Respuesta ante Crisis de Conducción.

---

## 🗂️ Organización de la Documentación

La documentación está organizada en las siguientes categorías:

### [📁 01. General](01-general/)
Información general sobre el proyecto.
- [README.md](01-general/README.md) - Visión general, objetivos y alcance del proyecto
- [INDICE.md](01-general/INDICE.md) - Índice completo de toda la documentación

### [📁 02. Arquitectura](02-arquitectura/)
Documentación técnica de la arquitectura del sistema.
- [ARQUITECTURA_Y_COMPONENTES.md](02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md) - Clean Architecture + BLoC Pattern
- [FLUJO_DE_DATOS.md](02-arquitectura/FLUJO_DE_DATOS.md) - Diagramas y flujos de datos completos

### [📁 03. Hardware](03-hardware/)
Integración con dispositivos IoT.
- [ESP32_INTEGRATION_GUIDE.md](03-hardware/ESP32_INTEGRATION_GUIDE.md) - Guía completa de integración ESP32-CAM
- [ESP32_EXAMPLE_REQUEST.md](03-hardware/ESP32_EXAMPLE_REQUEST.md) - Ejemplos de código y requests

### [📁 04. API e Integración](04-api-integracion/)
Documentación de APIs y servicios.
- [API_SERVIDOR_HTTP.md](04-api-integracion/API_SERVIDOR_HTTP.md) - Documentación del servidor HTTP embebido

### [📁 05. Guías de Usuario](05-guias-usuario/)
Manuales para usuarios finales.
- [INSTALACION.md](05-guias-usuario/INSTALACION.md) - Guía de instalación paso a paso
- [FAQ.md](05-guias-usuario/FAQ.md) - Preguntas frecuentes y solución de problemas

### [📁 06. Desarrollo](06-desarrollo/)
Guías para desarrolladores.
- [SETUP_DESARROLLO.md](06-desarrollo/SETUP_DESARROLLO.md) - Configuración del entorno de desarrollo

### [📁 07. Testing](07-testing/)
Estrategias y guías de testing.
- Documentación de pruebas unitarias, widgets e integración (próximamente)

### [📁 08. Seguridad](08-seguridad/)
Políticas de seguridad y privacidad.
- Documentación de seguridad y manejo de datos (próximamente)

---

## 🚀 Inicio Rápido

### Para Usuarios

¿Primera vez usando DriveGuard?

1. 📖 Lee el [README](01-general/README.md) para entender qué es DriveGuard
2. 📱 Sigue la [Guía de Instalación](05-guias-usuario/INSTALACION.md)
3. ❓ Consulta las [FAQ](05-guias-usuario/FAQ.md) si tienes dudas

### Para Desarrolladores

¿Quieres contribuir al proyecto?

1. 🏗️ Revisa la [Arquitectura](02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md)
2. 💻 Configura tu [Entorno de Desarrollo](06-desarrollo/SETUP_DESARROLLO.md)
3. 🔄 Lee el [Flujo de Datos](02-arquitectura/FLUJO_DE_DATOS.md)

### Para Integración de Hardware

¿Tienes un ESP32-CAM?

1. 🔧 Sigue la [Guía de Integración ESP32](03-hardware/ESP32_INTEGRATION_GUIDE.md)
2. 📡 Consulta la [Documentación del API](04-api-integracion/API_SERVIDOR_HTTP.md)
3. 💡 Revisa los [Ejemplos de Código](03-hardware/ESP32_EXAMPLE_REQUEST.md)

---

## 📖 Recursos Clave

### Documentos Principales

| Documento | Descripción | Audiencia |
|-----------|-------------|-----------|
| [README General](01-general/README.md) | Visión general del proyecto | Todos |
| [Arquitectura](02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md) | Estructura técnica completa | Desarrolladores |
| [Instalación](05-guias-usuario/INSTALACION.md) | Cómo instalar la app | Usuarios |
| [FAQ](05-guias-usuario/FAQ.md) | Preguntas frecuentes | Usuarios |
| [Setup Desarrollo](06-desarrollo/SETUP_DESARROLLO.md) | Configurar entorno dev | Desarrolladores |
| [API HTTP](04-api-integracion/API_SERVIDOR_HTTP.md) | Documentación del servidor | Desarrolladores/Hardware |
| [ESP32 Integration](03-hardware/ESP32_INTEGRATION_GUIDE.md) | Integración hardware | Makers/IoT |

---

## 🎯 ¿Qué es DriveGuard?

DriveGuard es un **sistema híbrido** que integra sensores, inteligencia artificial y una aplicación móvil para monitorear en tiempo real el estado físico y de atención del conductor, con el fin de prevenir accidentes de tránsito.

### Características Principales

- 📊 **Monitoreo en Tiempo Real** - Sensores de aceleración y rotación
- 🚨 **Alertas Multimodales** - Sonido, vibración y visuales
- 🎥 **Integración ESP32-CAM** - Análisis de video (opcional)
- 📱 **App Multiplataforma** - Android e iOS
- ☁️ **Cloud Sync** - Firebase para historial y estadísticas
- 🧠 **Detección Inteligente** - Algoritmos de detección de patrones

### Tecnologías

- **Frontend:** Flutter 3.16.0+, Dart, BLoC Pattern
- **Backend:** Firebase (Auth, Firestore, Functions)
- **Hardware:** ESP32-CAM, MPU-6050
- **Arquitectura:** Clean Architecture, SOLID

---

## 📊 Estructura del Proyecto

```
DriveGuard/
├── documentacion/              # Esta carpeta
│   ├── 01-general/            # Docs generales
│   ├── 02-arquitectura/       # Arquitectura técnica
│   ├── 03-hardware/           # Integración IoT
│   ├── 04-api-integracion/    # APIs y servicios
│   ├── 05-guias-usuario/      # Manuales de usuario
│   ├── 06-desarrollo/         # Guías de desarrollo
│   ├── 07-testing/            # Testing
│   └── 08-seguridad/          # Seguridad
│
├── lib/                        # Código fuente Flutter
│   ├── core/                  # Componentes centrales
│   ├── data/                  # Capa de datos
│   ├── domain/                # Capa de dominio
│   └── presentation/          # Capa de presentación
│
├── android/                    # Proyecto Android
├── ios/                        # Proyecto iOS
├── functions/                  # Cloud Functions
├── test/                       # Tests
└── assets/                     # Recursos (sonidos, imágenes)
```

---

## 🔄 Flujo de Desarrollo

### Ciclo de Vida de una Funcionalidad

```
1. Planificación
   └─> Revisar [Arquitectura](02-arquitectura/ARQUITECTURA_Y_COMPONENTES.md)

2. Desarrollo
   ├─> Configurar [Entorno](06-desarrollo/SETUP_DESARROLLO.md)
   ├─> Implementar siguiendo Clean Architecture
   └─> Documentar cambios

3. Testing
   ├─> Unit tests
   ├─> Widget tests
   └─> Integration tests

4. Documentación
   └─> Actualizar docs relevantes

5. Deployment
   └─> Build y distribución
```

---

## 📝 Convenciones de Documentación

### Formato

- **Markdown** para todos los documentos
- **Diagramas ASCII** para estructuras
- **Bloques de código** con sintaxis highlighting
- **Enlaces internos** entre documentos

### Estructura de Documentos

Cada documento debe incluir:
1. **Título y Descripción**
2. **Tabla de Contenidos** (si es largo)
3. **Contenido Principal**
4. **Ejemplos de Código** (si aplica)
5. **Referencias y Enlaces**

### Actualización

Al modificar el código, actualiza:
1. Documentación técnica si cambia arquitectura
2. README si cambian características principales
3. FAQ si se resuelven problemas comunes
4. Guías de usuario si cambia la UI/UX

---

## 🤝 Contribuir a la Documentación

¿Encontraste un error o quieres mejorar la documentación?

1. **Fork** del repositorio
2. **Crear branch:** `git checkout -b docs/mejora-instalacion`
3. **Editar** documentos en Markdown
4. **Commit:** `git commit -m "docs: mejorar guía de instalación"`
5. **Push:** `git push origin docs/mejora-instalacion`
6. **Pull Request** con descripción detallada

### Estilo de Escritura

- ✅ **Claro y conciso**
- ✅ **Ejemplos prácticos**
- ✅ **Screenshots cuando sea útil**
- ✅ **Código bien formateado**
- ✅ **Enlaces a recursos externos**

---

## 📞 Soporte y Contacto

### ¿Necesitas Ayuda?

1. **Busca en la documentación** (usa el índice arriba)
2. **Consulta las [FAQ](05-guias-usuario/FAQ.md)**
3. **Abre un Issue** en GitHub
4. **Contacta al equipo** (ver README principal)

### Reportar Problemas

**Issues de Documentación:**
- Errores de formato
- Enlaces rotos
- Información desactualizada
- Ejemplos que no funcionan

**Issues de Código:**
- Ver guía de contribución en [06-desarrollo/](06-desarrollo/)

---

## 🗺️ Roadmap de Documentación

### ✅ Completado

- [x] README general
- [x] Arquitectura y componentes
- [x] Flujo de datos
- [x] Guía de instalación
- [x] FAQ
- [x] Setup de desarrollo
- [x] Integración ESP32-CAM
- [x] API del servidor HTTP

### 🚧 En Progreso

- [ ] Manual de usuario completo
- [ ] Guía de contribución
- [ ] Estándares de código
- [ ] Guía de testing

### 📋 Planeado

- [ ] Configuración de Firebase
- [ ] Cloud Functions
- [ ] Políticas de seguridad
- [ ] Guía de deployment
- [ ] Changelog detallado
- [ ] Roadmap del proyecto
- [ ] Diagramas de flujo visuales
- [ ] Videos tutoriales

---

## 📄 Licencia

DriveGuard es un proyecto de código abierto. Ver LICENSE en el repositorio principal.

---

## 🌟 Agradecimientos

Gracias a todos los contribuyentes que han ayudado a mejorar esta documentación.

---

**Última actualización:** Octubre 2025
**Versión de la documentación:** 1.0.0
**Compatible con DriveGuard:** v1.0.0+

---

<div align="center">

📚 **[Volver al Índice](01-general/INDICE.md)** 📚

</div>
