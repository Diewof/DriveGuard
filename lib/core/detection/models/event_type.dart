/// Tipos de eventos de conducción detectables
enum EventType {
  harshBraking('FRENADO_BRUSCO', 'Frenado Brusco'),
  aggressiveAcceleration('ACELERACION_AGRESIVA', 'Aceleración Agresiva'),
  sharpTurn('GIRO_CERRADO', 'Giro Cerrado'),
  weaving('ZIGZAGUEO', 'Zigzagueo'),
  roughRoad('CAMINO_IRREGULAR', 'Camino Irregular'),
  speedBump('LOMO_DE_TORO', 'Lomo de Toro');

  final String value;
  final String displayName;

  const EventType(this.value, this.displayName);

  static EventType fromValue(String value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EventType.harshBraking,
    );
  }
}
