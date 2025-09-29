# Archivos de Voz para Alertas

Este directorio contiene los archivos de audio con mensajes de voz para las notificaciones del sistema DriveGuard.

## Archivos Requeridos

### Mensajes de Voz en Español
- `distraction_warning_es.mp3` - "Atención detectada fuera del camino. Mantén la vista en la carretera."
- `reckless_warning_es.mp3` - "Conducción temeraria detectada. Reduce la velocidad y conduce con precaución."
- `impact_warning_es.mp3` - "Impacto detectado, activando protocolo de emergencia. Verificando estado del conductor."
- `phone_warning_es.mp3` - "Uso de celular detectado mientras conduces. Guarda el dispositivo de manera segura."
- `look_away_warning_es.mp3` - "Mirada desviada detectada. Mantén los ojos en el camino."
- `harsh_braking_warning_es.mp3` - "Frenada brusca detectada. Mantén distancia de seguridad con otros vehículos."

## Textos Completos para Grabación

### 1. Distracción (distraction_warning_es.mp3)
**Texto**: "Atención detectada fuera del camino. Mantén la vista en la carretera."
**Duración**: 3-4 segundos
**Tono**: Firme pero no alarmante

### 2. Conducción Temeraria (reckless_warning_es.mp3)
**Texto**: "Conducción temeraria detectada. Reduce la velocidad y conduce con precaución."
**Duración**: 4-5 segundos
**Tono**: Serio y autoritario

### 3. Impacto (impact_warning_es.mp3)
**Texto**: "Impacto detectado, activando protocolo de emergencia. Verificando estado del conductor."
**Duración**: 5-6 segundos
**Tono**: Urgente pero claro

### 4. Uso de Celular (phone_warning_es.mp3)
**Texto**: "Uso de celular detectado mientras conduces. Guarda el dispositivo de manera segura."
**Duración**: 4-5 segundos
**Tono**: Firme y directo

### 5. Mirada Desviada (look_away_warning_es.mp3)
**Texto**: "Mirada desviada detectada. Mantén los ojos en el camino."
**Duración**: 3-4 segundos
**Tono**: Recordatorio amable pero firme

### 6. Frenada Brusca (harsh_braking_warning_es.mp3)
**Texto**: "Frenada brusca detectada. Mantén distancia de seguridad con otros vehículos."
**Duración**: 4-5 segundos
**Tono**: Instructivo y calmado

## Características de Audio Recomendadas

### Especificaciones Técnicas
- **Formato**: MP3
- **Calidad**: 128 kbps mínimo
- **Frecuencia de muestreo**: 44.1 kHz
- **Canal**: Mono (para reducir tamaño)
- **Volumen**: Normalizado a -6dB

### Características de Voz
- **Idioma**: Español neutro
- **Género**: Preferiblemente femenino (estudios muestran mejor atención)
- **Velocidad**: Moderada, clara y comprensible
- **Tono**: Profesional, autoritativo pero no agresivo
- **Pronunciación**: Clara, sin acentos regionales marcados

## Opciones de Implementación

### Opción 1: Grabación con Voz Humana
- Contratar locutor profesional
- Grabar en estudio para calidad óptima
- Costo: Alto, pero máxima calidad

### Opción 2: Síntesis de Voz (TTS)
- Usar flutter_tts para generar en tiempo real
- Configurar voz femenina en español
- Costo: Bajo, implementación inmediata

### Opción 3: Servicios de Voz AI
- Google Text-to-Speech
- Amazon Polly
- Azure Cognitive Services
- Costo: Medio, alta calidad

## Implementación Actual

Por defecto, el sistema usa flutter_tts para generar los mensajes en tiempo real. Los archivos MP3 se usarán como respaldo si están disponibles, pero no son obligatorios para el funcionamiento básico.

## Testing

Para probar los mensajes de voz:
1. Colocar archivos MP3 en este directorio
2. Usar el botón "Probar" en la configuración de notificaciones
3. Verificar claridad y volumen en diferentes condiciones de ruido
4. Ajustar volumen desde la configuración de la app