/// Tipos de eventos de conducción detectables
enum EventType {
  // Eventos basados en sensores IMU
  harshBraking('FRENADO_BRUSCO', 'Frenado Brusco'),
  aggressiveAcceleration('ACELERACION_AGRESIVA', 'Aceleración Agresiva'),
  sharpTurn('GIRO_CERRADO', 'Giro Cerrado'),
  weaving('ZIGZAGUEO', 'Zigzagueo'),
  roughRoad('CAMINO_IRREGULAR', 'Camino Irregular'),
  speedBump('LOMO_DE_TORO', 'Lomo de Toro'),

  // Eventos basados en visión por computadora (ESP32-CAM)
  distraction('DISTRACCION', 'Distracción (Teléfono)'),
  inattention('DESATENCION', 'Desatención Visual'),
  handsOff('MANOS_FUERA', 'Manos Fuera del Volante'),
  noFaceDetected('SIN_ROSTRO', 'Sin Rostro Detectado');

  final String value;
  final String displayName;

  const EventType(this.value, this.displayName);

  static EventType fromValue(String value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EventType.harshBraking,
    );
  }

  /// Indica si el evento es basado en análisis de visión
  bool get isVisionBased {
    return this == EventType.distraction ||
        this == EventType.inattention ||
        this == EventType.handsOff ||
        this == EventType.noFaceDetected;
  }

  /// Indica si el evento es basado en sensores IMU
  bool get isIMUBased {
    return this == EventType.harshBraking ||
        this == EventType.aggressiveAcceleration ||
        this == EventType.sharpTurn ||
        this == EventType.weaving ||
        this == EventType.roughRoad ||
        this == EventType.speedBump;
  }

  /// Indica si el evento es híbrido (visión + IMU)
  ///
  /// El evento handsOff requiere tanto detección visual (manos fuera del volante)
  /// como confirmación de sensores IMU (vehículo en movimiento)
  bool get isHybrid {
    return this == EventType.handsOff;
  }

  /// Obtiene la descripción detallada del evento
  String get description {
    switch (this) {
      // Eventos IMU
      case EventType.harshBraking:
        return 'El conductor frenó bruscamente';
      case EventType.aggressiveAcceleration:
        return 'El conductor aceleró agresivamente';
      case EventType.sharpTurn:
        return 'El conductor realizó un giro brusco';
      case EventType.weaving:
        return 'El vehículo zigzagueó entre carriles';
      case EventType.roughRoad:
        return 'El vehículo pasó por un camino irregular';
      case EventType.speedBump:
        return 'El vehículo pasó por un reductor de velocidad';

      // Eventos de visión
      case EventType.distraction:
        return 'El conductor está usando el teléfono móvil';
      case EventType.inattention:
        return 'El conductor no está mirando la carretera';
      case EventType.handsOff:
        return 'El conductor no tiene las manos en el volante';
      case EventType.noFaceDetected:
        return 'No se detecta el rostro del conductor';
    }
  }

  /// Obtiene un icono recomendado para el evento (emoji o nombre de icono)
  String get icon {
    switch (this) {
      case EventType.harshBraking:
        return '🛑';
      case EventType.aggressiveAcceleration:
        return '⚡';
      case EventType.sharpTurn:
        return '↪️';
      case EventType.weaving:
        return '〰️';
      case EventType.roughRoad:
        return '🛣️';
      case EventType.speedBump:
        return '⚠️';
      case EventType.distraction:
        return '📱';
      case EventType.inattention:
        return '👁️';
      case EventType.handsOff:
        return '🖐️';
      case EventType.noFaceDetected:
        return '👤';
    }
  }
}
