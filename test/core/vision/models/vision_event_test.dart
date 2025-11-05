import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard_app/core/vision/models/vision_event.dart';
import 'package:driveguard_app/core/detection/models/event_type.dart';
import 'package:driveguard_app/core/detection/models/event_severity.dart';

void main() {
  group('VisionEvent', () {
    late VisionEvent testEvent;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testEvent = VisionEvent(
        type: EventType.distraction,
        severity: EventSeverity.high,
        timestamp: testTimestamp,
        confidence: 0.85,
        metadata: {'headYaw': 45.0},
      );
    });

    group('Constructor', () {
      test('debe crear evento con todos los campos requeridos', () {
        expect(testEvent.type, equals(EventType.distraction));
        expect(testEvent.severity, equals(EventSeverity.high));
        expect(testEvent.timestamp, equals(testTimestamp));
        expect(testEvent.confidence, equals(0.85));
        expect(testEvent.metadata, equals({'headYaw': 45.0}));
      });

      test('debe crear evento con metadata vacío por defecto', () {
        final event = VisionEvent(
          type: EventType.inattention,
          severity: EventSeverity.medium,
          timestamp: testTimestamp,
          confidence: 0.7,
        );
        expect(event.metadata, isEmpty);
      });
    });

    group('isHighConfidence', () {
      test('debe retornar true para confianza >= 0.7', () {
        final highConfEvent = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.low,
          timestamp: testTimestamp,
          confidence: 0.75,
        );
        expect(highConfEvent.isHighConfidence, isTrue);
      });

      test('debe retornar false para confianza < 0.7', () {
        final lowConfEvent = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.low,
          timestamp: testTimestamp,
          confidence: 0.65,
        );
        expect(lowConfEvent.isHighConfidence, isFalse);
      });
    });

    group('isCritical', () {
      test('debe retornar true para severidad crítica', () {
        final criticalEvent = VisionEvent(
          type: EventType.handsOff,
          severity: EventSeverity.critical,
          timestamp: testTimestamp,
          confidence: 0.9,
        );
        expect(criticalEvent.isCritical, isTrue);
      });

      test('debe retornar false para otras severidades', () {
        expect(testEvent.isCritical, isFalse);
      });
    });

    group('requiresImmediateAlert', () {
      test('debe retornar true para alta severidad y alta confianza', () {
        final alertEvent = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.8,
        );
        expect(alertEvent.requiresImmediateAlert, isTrue);
      });

      test('debe retornar false para baja confianza aunque alta severidad', () {
        final lowConfEvent = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.5,
        );
        expect(lowConfEvent.requiresImmediateAlert, isFalse);
      });

      test('debe retornar false para baja severidad aunque alta confianza', () {
        final lowSevEvent = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.low,
          timestamp: testTimestamp,
          confidence: 0.9,
        );
        expect(lowSevEvent.requiresImmediateAlert, isFalse);
      });
    });

    group('copyWith', () {
      test('debe crear copia con campos modificados', () {
        final copied = testEvent.copyWith(
          confidence: 0.95,
          severity: EventSeverity.critical,
        );
        expect(copied.confidence, equals(0.95));
        expect(copied.severity, equals(EventSeverity.critical));
        expect(copied.type, equals(testEvent.type));
        expect(copied.timestamp, equals(testEvent.timestamp));
      });

      test('debe mantener valores originales si no se modifican', () {
        final copied = testEvent.copyWith();
        expect(copied.type, equals(testEvent.type));
        expect(copied.severity, equals(testEvent.severity));
        expect(copied.confidence, equals(testEvent.confidence));
      });
    });

    group('toJson', () {
      test('debe serializar correctamente a JSON', () {
        final json = testEvent.toJson();
        expect(json['type'], equals('DISTRACCION'));
        expect(json['severity'], equals('HIGH'));
        expect(json['confidence'], equals(0.85));
        expect(json['metadata'], equals({'headYaw': 45.0}));
      });
    });

    group('fromJson', () {
      test('debe deserializar correctamente desde JSON', () {
        final json = {
          'type': 'DESATENCION',
          'severity': 'MEDIUM',
          'timestamp': testTimestamp.toIso8601String(),
          'confidence': 0.7,
          'metadata': const {'headPitch': -25.0},
        };

        final event = VisionEvent.fromJson(json);
        expect(event.type, equals(EventType.inattention));
        expect(event.severity, equals(EventSeverity.medium));
        expect(event.confidence, equals(0.7));
        expect(event.metadata, equals({'headPitch': -25.0}));
      });

      test('debe manejar metadata vacío en JSON', () {
        final json = {
          'type': 'DISTRACCION',
          'severity': 'LOW',
          'timestamp': testTimestamp.toIso8601String(),
          'confidence': 0.6,
        };

        final event = VisionEvent.fromJson(json);
        expect(event.metadata, isEmpty);
      });
    });

    group('Equatable', () {
      test('debe comparar igualdad correctamente', () {
        final event1 = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.85,
          metadata: {'test': 1},
        );

        final event2 = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.85,
          metadata: {'test': 1},
        );

        expect(event1, equals(event2));
      });

      test('debe detectar diferencia correctamente', () {
        final event1 = VisionEvent(
          type: EventType.distraction,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.85,
        );

        final event2 = VisionEvent(
          type: EventType.inattention,
          severity: EventSeverity.high,
          timestamp: testTimestamp,
          confidence: 0.85,
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('toString', () {
      test('debe generar string descriptivo', () {
        final str = testEvent.toString();
        expect(str, contains('VisionEvent'));
        expect(str, contains('Distracción'));
        expect(str, contains('85.0%'));
      });
    });
  });
}
