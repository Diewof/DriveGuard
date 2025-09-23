# Sistema de Autenticación DriveGuard

Este documento describe la implementación completa del sistema de autenticación para la aplicación DriveGuard.

## Arquitectura Implementada

El sistema sigue **Clean Architecture** con las siguientes capas:

### 📁 Estructura de Carpetas

```
lib/
├── core/
│   ├── errors/
│   │   └── auth_failures.dart              # Tipos de errores de autenticación
│   ├── utils/
│   │   └── validators.dart                 # Validadores de formularios
│   └── routing/
│       └── app_router.dart                 # Configuración de rutas
│
├── domain/
│   ├── entities/
│   │   ├── user.dart                       # Entidad Usuario
│   │   └── auth_result.dart                # Resultado de autenticación
│   ├── repositories/
│   │   └── auth_repository.dart            # Contrato del repositorio
│   └── usecases/
│       ├── login_usecase.dart              # Caso de uso: Login
│       ├── register_usecase.dart           # Caso de uso: Registro
│       ├── logout_usecase.dart             # Caso de uso: Logout
│       ├── forgot_password_usecase.dart    # Caso de uso: Recuperar contraseña
│       └── get_current_user_usecase.dart   # Caso de uso: Usuario actual
│
├── data/
│   ├── models/
│   │   ├── user_model.dart                 # Modelo de Usuario (Firebase)
│   │   └── auth_result_model.dart          # Modelo de resultado
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── firebase_auth_datasource.dart  # Fuente de datos Firebase
│   │   └── local/
│   │       └── auth_local_datasource.dart     # Fuente de datos local
│   └── repositories/
│       └── auth_repository_impl.dart       # Implementación del repositorio
│
└── presentation/
    ├── blocs/
    │   └── auth/
    │       ├── auth_bloc.dart              # BLoC de autenticación
    │       ├── auth_event.dart             # Eventos de autenticación
    │       └── auth_state.dart             # Estados de autenticación
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart             # Página de inicio de sesión
    │   │   ├── register_page.dart          # Página de registro
    │   │   └── forgot_password_page.dart   # Página de recuperar contraseña
    │   ├── splash_page.dart                # Página de splash (modificada)
    │   └── dashboard_page.dart             # Dashboard principal
    └── widgets/
        └── auth/
            ├── auth_text_field.dart        # Campo de texto personalizado
            └── auth_button.dart            # Botón personalizado
```

## 🚀 Características Implementadas

### ✅ Funcionalidades de Autenticación

1. **Inicio de Sesión**
   - Validación de email y contraseña
   - Remember me functionality
   - Manejo de errores específicos de Firebase
   - Navegación automática después del login

2. **Registro de Usuario**
   - Validación de formulario completo
   - Confirmación de contraseña
   - Creación automática de perfil en Firestore
   - Términos y condiciones

3. **Recuperación de Contraseña**
   - Envío de email de recuperación
   - Feedback visual del proceso
   - Opción de reenvío

4. **Gestión de Sesión**
   - Auto-login para usuarios autenticados
   - Logout con limpieza de datos
   - Persistencia de sesión con SharedPreferences

5. **Navegación Inteligente**
   - Splash screen con verificación de autenticación
   - Navegación basada en estado de auth
   - Router configurado con go_router

### 🔧 Componentes Técnicos

- **State Management**: BLoC Pattern
- **Navigation**: go_router
- **Local Storage**: SharedPreferences
- **Backend**: Firebase Auth + Firestore
- **Error Handling**: Either pattern con dartz
- **Form Validation**: Validadores personalizados

## 📱 Páginas Implementadas

### 1. Splash Page (`/splash`)
- Verifica estado de autenticación al inicio
- Navega automáticamente a login o dashboard
- Indicadores de loading con contexto

### 2. Login Page (`/login`)
- Formulario de email/contraseña
- Checkbox "Recordarme"
- Links a registro y recuperación de contraseña
- Validación en tiempo real

### 3. Register Page (`/register`)
- Formulario completo de registro
- Validación de contraseña y confirmación
- Términos y condiciones
- Navegación a login después del registro

### 4. Forgot Password Page
- Envío de email de recuperación
- Feedback visual del estado
- Opción de reenvío

### 5. Dashboard Page (`/dashboard`)
- Panel principal post-autenticación
- Información del usuario
- Opción de logout
- Cards de funcionalidades futuras

## 🔒 Seguridad y Validaciones

### Validadores Implementados
- **Email**: Formato válido con regex
- **Contraseña**: Mínimo 6 caracteres
- **Nombre**: Mínimo 2 caracteres
- **Confirmación**: Coincidencia de contraseñas

### Manejo de Errores
- Errores específicos de Firebase Auth
- Mensajes localizados en español
- Feedback visual con SnackBars
- Estados de loading apropiados

## 🛠️ Configuración y Uso

### Dependencias Agregadas
```yaml
dependencies:
  dartz: ^0.10.1  # Either pattern para manejo de errores
```

### Firebase Configuration
El proyecto usa las configuraciones de Firebase ya establecidas:
- **Project ID**: `driveguard-prototipo`
- **Collections**: `users`, `driving_sessions`, `alerts`, `sensor_data`

### Uso del Sistema

1. **Inicialización**: La app verifica automáticamente el estado de autenticación
2. **Login**: Usuario ingresa credenciales → Sistema valida → Navega a dashboard
3. **Registro**: Usuario se registra → Crea perfil en Firestore → Auto-login
4. **Logout**: Limpia datos locales → Navega a login

## 🧪 Testing

Se implementaron tests unitarios para los validadores:
- Validación de email
- Validación de contraseña
- Validación de nombre
- Confirmación de contraseña

Para ejecutar tests:
```bash
flutter test
```

## 🔄 Estados de la Aplicación

### AuthStatus
- `unknown`: Estado inicial, verificando autenticación
- `loading`: Procesando operación de auth
- `authenticated`: Usuario autenticado
- `unauthenticated`: Usuario no autenticado

### Flujo de Navegación
```
Splash → (Check Auth) → Login/Dashboard
Login → (Success) → Dashboard
Register → (Success) → Dashboard
Dashboard → (Logout) → Login
```

## 📋 Próximos Pasos

Para continuar el desarrollo:

1. **Email Verification**: Implementar verificación de email
2. **Social Login**: Agregar Google/Apple Sign-In
3. **Profile Management**: Página de perfil de usuario
4. **Password Change**: Cambio de contraseña desde la app
5. **Two-Factor Auth**: Implementar 2FA
6. **Session Management**: Manejo avanzado de sesiones

## 🎨 UI/UX Features

- Diseño consistente con el tema azul de DriveGuard
- Campos de formulario con validación visual
- Indicadores de loading durante operaciones async
- Mensajes de error y éxito claros
- Navegación fluida entre pantallas
- Splash screen con branding corporativo

---

El sistema de autenticación está **completamente funcional** y listo para ser usado en la aplicación DriveGuard. Todas las pantallas y funcionalidades están implementadas siguiendo las mejores prácticas de Flutter y Clean Architecture.