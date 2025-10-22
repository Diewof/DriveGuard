import 'dart:collection';
import '../models/sensor_reading.dart';
import '../models/detection_event.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';

/// Estado del detector en la máquina de estados
enum DetectionState {
  idle,       // Sin evento detectado
  potential,  // Condiciones iniciales cumplidas
  confirmed,  // Evento confirmado en progreso
  cooldown    // Período de espera post-evento
}

/// Resultado de procesamiento de una lectura
class DetectionResult {
  final DetectionEvent? event;
  final DetectionState state;

  const DetectionResult({
    this.event,
    required this.state,
  });
}

/// Clase abstracta base para todos los detectores
abstract class BaseDetector {
  final String detectorName;
  final EventType eventType;

  // Buffer circular para análisis temporal
  final Queue<SensorReading> _buffer = Queue();
  final int maxBufferSize;

  // Estado interno del detector
  DetectionState _state = DetectionState.idle;
  DateTime? _eventStartTime;
  DateTime? _cooldownEndTime;
  SensorReading? _baselineReading;

  // Lecturas capturadas durante el evento
  final List<SensorReading> _eventReadings = [];

  // BETA: Tolerancia para condiciones perdidas en potential
  int _missedConditionsCount = 0;
  static const int _maxMissedConditions = 10; // Permitir 10 fallos consecutivos (era 3, ahora MÁS tolerante)

  BaseDetector({
    required this.detectorName,
    required this.eventType,
    this.maxBufferSize = 100,
  });

  /// Métodos abstractos que cada detector debe implementar

  /// Verifica si las condiciones para el evento se cumplen
  bool checkConditions(SensorReading current, SensorStatistics stats);

  /// Calcula el nivel de confianza del evento detectado (0.0 - 1.0)
  double calculateConfidence(List<SensorReading> eventReadings);

  /// Calcula la severidad del evento
  EventSeverity calculateSeverity(List<SensorReading> eventReadings);

  /// Extrae metadata específica del evento
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings);

  /// Extrae valores pico del evento
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings);

  /// Duración del período de cooldown
  Duration get cooldownDuration;

  /// Duración mínima del evento
  Duration get minEventDuration;

  /// Duración máxima del evento
  Duration get maxEventDuration;

  /// Confianza mínima requerida para reportar el evento
  double get minConfidence;

  /// Procesa una nueva lectura y retorna resultado de detección
  DetectionResult? process(SensorReading reading, SensorStatistics stats) {
    // Agregar al buffer
    _buffer.add(reading);
    if (_buffer.length > maxBufferSize) {
      _buffer.removeFirst();
    }

    // Verificar si estamos en cooldown
    if (_state == DetectionState.cooldown) {
      if (DateTime.now().isAfter(_cooldownEndTime!)) {
        _state = DetectionState.idle;
        _eventReadings.clear();
      } else {
        return DetectionResult(state: _state);
      }
    }

    // Ejecutar máquina de estados
    switch (_state) {
      case DetectionState.idle:
        return _handleIdleState(reading, stats);

      case DetectionState.potential:
        return _handlePotentialState(reading, stats);

      case DetectionState.confirmed:
        return _handleConfirmedState(reading, stats);

      case DetectionState.cooldown:
        return DetectionResult(state: _state);
    }
  }

  DetectionResult _handleIdleState(SensorReading reading, SensorStatistics stats) {
    if (checkConditions(reading, stats)) {
      // ignore: avoid_print
      print('[$detectorName] 🟡 POTENTIAL: Condiciones iniciales cumplidas');
      _state = DetectionState.potential;
      _eventStartTime = reading.timestamp;
      _baselineReading = reading;
      _eventReadings.clear();
      _eventReadings.add(reading);
      _missedConditionsCount = 0; // Reset contador
      return DetectionResult(state: _state);
    }
    return DetectionResult(state: _state);
  }

  DetectionResult _handlePotentialState(SensorReading reading, SensorStatistics stats) {
    _eventReadings.add(reading);

    if (checkConditions(reading, stats)) {
      // Condiciones cumplidas, resetear contador de fallos
      _missedConditionsCount = 0;

      // Verificar si cumple duración mínima
      final duration = reading.timestamp.difference(_eventStartTime!);
      if (duration >= minEventDuration) {
        // ignore: avoid_print
        print('[$detectorName] 🟢 CONFIRMED: Duración mínima alcanzada (${duration.inMilliseconds}ms)');
        _state = DetectionState.confirmed;
      }
      return DetectionResult(state: _state);
    } else {
      // BETA: Tolerancia a condiciones perdidas temporalmente
      _missedConditionsCount++;

      // Solo cancelar si se superan los fallos consecutivos permitidos
      if (_missedConditionsCount >= _maxMissedConditions) {
        // ignore: avoid_print
        print('[$detectorName] ⚪ IDLE: Condiciones perdidas en potential ($_missedConditionsCount fallos consecutivos)');
        _state = DetectionState.idle;
        _eventReadings.clear();
        _missedConditionsCount = 0;
        return DetectionResult(state: _state);
      } else {
        // ignore: avoid_print
        print('[$detectorName] 🟡 POTENTIAL: Condición perdida ($_missedConditionsCount/$_maxMissedConditions) - Tolerando...');
        return DetectionResult(state: _state);
      }
    }
  }

  DetectionResult _handleConfirmedState(SensorReading reading, SensorStatistics stats) {
    _eventReadings.add(reading);

    final duration = reading.timestamp.difference(_eventStartTime!);

    // Verificar si el evento ha terminado o excedió duración máxima
    if (!checkConditions(reading, stats) || duration > maxEventDuration) {
      // Generar evento de detección
      final event = _createDetectionEvent(duration);

      // Entrar en cooldown
      _state = DetectionState.cooldown;
      _cooldownEndTime = DateTime.now().add(cooldownDuration);

      return DetectionResult(
        event: event,
        state: _state,
      );
    }

    return DetectionResult(state: _state);
  }

  DetectionEvent? _createDetectionEvent(Duration duration) {
    final confidence = calculateConfidence(_eventReadings);

    // ignore: avoid_print
    print('[$detectorName] 📊 Evento finalizado: confidence=$confidence, '
        'minRequired=$minConfidence, readings=${_eventReadings.length}');

    // Solo reportar si cumple confianza mínima
    if (confidence < minConfidence) {
      // ignore: avoid_print
      print('[$detectorName] ❌ RECHAZADO: Confianza insuficiente ($confidence < $minConfidence)');
      return null;
    }

    final severity = calculateSeverity(_eventReadings);
    final peakValues = extractPeakValues(_eventReadings);
    final metadata = extractMetadata(_eventReadings);

    // ignore: avoid_print
    print('[$detectorName] ✅ EVENTO CREADO: severity=$severity, confidence=$confidence');

    return DetectionEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      type: eventType,
      severity: severity,
      timestamp: _eventStartTime!,
      duration: duration,
      peakValues: peakValues,
      confidence: confidence,
      metadata: metadata,
      readings: List.from(_eventReadings),
    );
  }

  /// Reinicia el estado del detector
  void reset() {
    _state = DetectionState.idle;
    _eventStartTime = null;
    _cooldownEndTime = null;
    _baselineReading = null;
    _eventReadings.clear();
    _missedConditionsCount = 0;
  }

  /// Limpia el buffer
  void clearBuffer() {
    _buffer.clear();
  }

  /// Getters de estado
  DetectionState get currentState => _state;
  List<SensorReading> get recentReadings => List.from(_buffer);
  SensorReading? get baseline => _baselineReading;
}
