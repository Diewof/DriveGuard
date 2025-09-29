# Archivos de Audio para Alertas

Este directorio contiene los archivos de audio para las notificaciones de alerta del sistema DriveGuard.

## Archivos Requeridos

### Tonos de Alerta
- `medium_alert.mp3` - Tono para alertas de severidad MEDIA
- `high_alert.mp3` - Tono para alertas de severidad ALTA
- `critical_alert.mp3` - Tono para alertas de severidad CRÍTICA

### Características de Audio Recomendadas
- **Formato**: MP3
- **Duración**: 1-2 segundos
- **Volumen**: Normalizado
- **Frecuencia**: 440-880 Hz (fácil de escuchar mientras se conduce)
- **Tipo**: Tonos simples, no música

### Tonos Sugeridos por Severidad

#### MEDIA (medium_alert.mp3)
- Tono suave, una sola nota
- Frecuencia: ~440 Hz
- Duración: 1 segundo

#### ALTA (high_alert.mp3)
- Tono más pronunciado, dos notas ascendentes
- Frecuencia: 440-660 Hz
- Duración: 1.5 segundos

#### CRÍTICA (critical_alert.mp3)
- Tono urgente, múltiples notas rápidas
- Frecuencia: 660-880 Hz
- Duración: 2 segundos

## Notas de Implementación

1. Los archivos deben estar presentes para que el sistema de audio funcione correctamente
2. Se pueden generar usando herramientas como Audacity o grabar desde dispositivos
3. Para pruebas, se pueden usar tonos generados por software de síntesis
4. El volumen se controla desde la configuración de la aplicación