/// Niveles de severidad de eventos detectados
enum EventSeverity {
  low('LOW', 'Bajo', 1),
  medium('MEDIUM', 'Medio', 2),
  high('HIGH', 'Alto', 3),
  critical('CRITICAL', 'Crítico', 4);

  final String value;
  final String displayName;
  final int priority;

  const EventSeverity(this.value, this.displayName, this.priority);

  static EventSeverity fromValue(String value) {
    return EventSeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => EventSeverity.medium,
    );
  }

  bool operator >(EventSeverity other) => priority > other.priority;
  bool operator <(EventSeverity other) => priority < other.priority;
  bool operator >=(EventSeverity other) => priority >= other.priority;
  bool operator <=(EventSeverity other) => priority <= other.priority;
}
