import 'dart:async';
import 'dart:collection';
import '../models/detection_event.dart';
import '../models/event_severity.dart';

/// Agrega y gestiona eventos de detección, evitando duplicados y priorizando
class EventAggregator {
  final _aggregatedEventController = StreamController<DetectionEvent>.broadcast();
  final Queue<DetectionEvent> _recentEvents = Queue();
  final Map<String, DateTime> _lastEventByType = {};

  static const int maxRecentEvents = 50;
  static const int maxVisualAlertsPerMinute = 5;
  static const int maxAudioAlertsPerMinute = 1;

  int _visualAlertsInLastMinute = 0;
  int _audioAlertsInLastMinute = 0;
  DateTime? _lastMinuteReset;

  Stream<DetectionEvent> get eventStream => _aggregatedEventController.stream;

  /// Procesa un nuevo evento detectado
  void processEvent(DetectionEvent event) {
    // ignore: avoid_print
    print('[AGGREGATOR] 📥 Evento recibido: ${event.type.displayName} '
        '(severity=${event.severity.value}, confidence=${event.confidence.toStringAsFixed(2)})');

    // Deduplicación: verificar si es muy similar a un evento reciente
    if (_isDuplicate(event)) {
      // ignore: avoid_print
      print('[AGGREGATOR] 🔄 DUPLICADO - ignorado (muy reciente)');
      return;
    }

    // Enriquecer evento con contexto
    final enrichedEvent = _enrichEvent(event);

    // Verificar throttling
    if (!_shouldEmitEvent(enrichedEvent)) {
      // ignore: avoid_print
      print('[AGGREGATOR] 🚫 THROTTLED - límite de alertas alcanzado');
      return;
    }

    // Agregar a historial
    _addToHistory(enrichedEvent);

    // Emitir evento
    // ignore: avoid_print
    print('[AGGREGATOR] ✅ EMITIDO al Dashboard');
    _aggregatedEventController.add(enrichedEvent);

    // Actualizar última vez que se emitió este tipo
    _lastEventByType[enrichedEvent.type.value] = DateTime.now();
  }

  bool _isDuplicate(DetectionEvent event) {
    // Verificar si hay un evento del mismo tipo en los últimos 2 segundos
    final lastTime = _lastEventByType[event.type.value];
    if (lastTime != null) {
      final timeDiff = DateTime.now().difference(lastTime);
      if (timeDiff.inSeconds < 2) {
        return true; // Es un duplicado
      }
    }
    return false;
  }

  DetectionEvent _enrichEvent(DetectionEvent event) {
    // Aquí se puede agregar contexto adicional
    // Por ahora retornamos el evento original
    // En el futuro: agregar localización, hora del día, etc.
    return event;
  }

  bool _shouldEmitEvent(DetectionEvent event) {
    final now = DateTime.now();

    // Resetear contador cada minuto
    if (_lastMinuteReset == null || now.difference(_lastMinuteReset!).inMinutes >= 1) {
      _lastMinuteReset = now;
      _visualAlertsInLastMinute = 0;
      _audioAlertsInLastMinute = 0;
    }

    // Throttling de alertas visuales
    if (_visualAlertsInLastMinute >= maxVisualAlertsPerMinute) {
      // Solo permitir eventos CRITICAL
      if (event.severity != EventSeverity.critical) {
        return false;
      }
    }

    // Incrementar contadores
    _visualAlertsInLastMinute++;

    // Audio solo para severidad HIGH y CRITICAL
    if (event.severity >= EventSeverity.high) {
      if (_audioAlertsInLastMinute < maxAudioAlertsPerMinute) {
        _audioAlertsInLastMinute++;
      }
    }

    return true;
  }

  void _addToHistory(DetectionEvent event) {
    _recentEvents.add(event);

    // Limitar tamaño del historial
    while (_recentEvents.length > maxRecentEvents) {
      _recentEvents.removeFirst();
    }
  }

  /// Obtiene los eventos recientes
  List<DetectionEvent> getRecentEvents({int limit = 10}) {
    if (_recentEvents.length <= limit) {
      return List.from(_recentEvents);
    }
    return _recentEvents.toList().sublist(_recentEvents.length - limit);
  }

  /// Obtiene las estadísticas de eventos
  Map<String, int> getEventStatistics() {
    final stats = <String, int>{};
    for (final event in _recentEvents) {
      final key = event.type.value;
      stats[key] = (stats[key] ?? 0) + 1;
    }
    return stats;
  }

  /// Calcula el score de riesgo global de la sesión (0-100)
  double calculateGlobalRiskScore() {
    if (_recentEvents.isEmpty) return 0.0;

    // Eventos recientes (últimos 10)
    final recent = getRecentEvents(limit: 10);

    // Promedio de risk scores
    final avgRisk = recent.map((e) => e.getRiskScore()).reduce((a, b) => a + b) / recent.length;

    // Bonus por frecuencia
    final frequencyBonus = (recent.length / 10.0) * 20.0;

    return (avgRisk + frequencyBonus).clamp(0.0, 100.0);
  }

  void clearHistory() {
    _recentEvents.clear();
    _lastEventByType.clear();
  }

  void dispose() {
    _aggregatedEventController.close();
  }
}
