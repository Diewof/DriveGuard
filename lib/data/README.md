# Data Layer

Esta carpeta contiene la implementación de la capa de datos siguiendo Clean Architecture.

## Estructura

- **datasources/**: Fuentes de datos (APIs remotas y almacenamiento local)
  - **remote/**: Implementaciones de APIs y servicios web
  - **local/**: Base de datos local, SharedPreferences, archivos
- **models/**: Modelos de datos con serialización JSON
- **repositories/**: Implementaciones concretas de los repositorios del dominio