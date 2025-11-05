# Configuración de Claude Code - DriveGuard

Esta carpeta contiene la configuración de Claude Code para el proyecto DriveGuard.

## Archivos de Configuración

### `settings.local.json`
Permisos y configuraciones locales del proyecto.

### Archivos de Memoria (Memory Files)

Claude Code lee automáticamente los siguientes archivos:

1. **`../CLAUDE.MD`** (raíz del proyecto)
   - Directrices de desarrollo
   - Principios de Clean Code (DRY, KISS, YAGNI)
   - Estándares de código
   - Filosofía de desarrollo para BETA
   - Testing y documentación
   - Comandos útiles

## Cómo Funciona la Memoria

Claude Code carga automáticamente `CLAUDE.MD` al inicio de cada sesión. No necesitas hacer nada especial - simplemente mantén el archivo actualizado con las mejores prácticas del proyecto.

### Actualizar Directrices

Si necesitas actualizar las directrices de desarrollo:

1. Edita `../CLAUDE.MD`
2. Los cambios se aplican en la siguiente sesión de Claude Code
3. Commit los cambios para compartir con el equipo

## Verificar que Claude Sigue las Directrices

Para verificar que Claude está siguiendo las directrices, simplemente pregúntale:
- "¿Cuáles son las reglas de desarrollo de este proyecto?"
- "¿Qué principios debo seguir al programar aquí?"
- "¿Está este proyecto en modo BETA?"

Claude debería responder con información del archivo CLAUDE.MD.

## Recursos Adicionales

- [Documentación de Memory Files](https://docs.claude.com/en/docs/claude-code/memory.md)
- [Settings de Claude Code](https://docs.claude.com/en/docs/claude-code/settings.md)
