import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../../core/mocks/sensor_simulator.dart';
import '../../domain/entities/sensor_data.dart';
import 'dart:async';
import 'dart:math';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final SensorSimulator _sensorSimulator = SensorSimulator();
  Timer? _sessionTimer;
  late AnimationController _pulseController;
  late AnimationController _alertController;

  // Estados de monitoreo
  bool _isMonitoring = false;
  String _deviceStatus = 'DESCONECTADO';
  String _currentAlertType = 'NORMAL';
  double _riskScore = 0.0;
  Duration _sessionDuration = Duration.zero;

  // Datos de sensores
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 9.8;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // Historial de alertas
  final List<Map<String, dynamic>> _recentAlerts = [];

  // Estadísticas de sesión
  int _distractionCount = 0;
  int _recklessCount = 0;
  int _emergencyCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _alertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Simular conexión del dispositivo después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _deviceStatus = 'CONECTADO';
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSimulator.dispose();
    _sessionTimer?.cancel();
    _pulseController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;

      if (_isMonitoring) {
        _startSession();
        _sensorSimulator.startSimulation(SimulationMode.normal);
        _listenToSensorData();
      } else {
        _stopSession();
        _sensorSimulator.stopSimulation();
      }
    });
  }

  void _startSession() {
    _sessionDuration = Duration.zero;
    _distractionCount = 0;
    _recklessCount = 0;
    _emergencyCount = 0;
    _recentAlerts.clear();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionDuration = Duration(seconds: timer.tick);
      });

      // Simular eventos aleatorios
      if (Random().nextDouble() < 0.05) {
        _simulateRandomEvent();
      }
    });
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    setState(() {
      _currentAlertType = 'NORMAL';
      _riskScore = 0.0;
    });
  }

  void _listenToSensorData() {
    _sensorSimulator.stream.listen((sensorData) {
      if (mounted) {
        setState(() {
          _accelX = sensorData.accelerationX;
          _accelY = sensorData.accelerationY;
          _accelZ = sensorData.accelerationZ;
          _gyroX = sensorData.gyroscopeX;
          _gyroY = sensorData.gyroscopeY;
          _gyroZ = sensorData.gyroscopeZ;

          // Calcular score de riesgo
          _calculateRiskScore(sensorData);

          // Detectar patrones peligrosos
          if (sensorData.isRecklessDriving) {
            _triggerAlert('CONDUCCIÓN TEMERARIA', 'HIGH');
          } else if (sensorData.isCrashDetected) {
            _triggerAlert('IMPACTO DETECTADO', 'CRITICAL');
          }
        });
      }
    });
  }

  void _calculateRiskScore(SensorData data) {
    double score = 0.0;

    // Factor de aceleración
    double accelMagnitude = sqrt(
      pow(data.accelerationX, 2) +
      pow(data.accelerationY, 2) +
      pow((data.accelerationZ - 9.8).abs(), 2)
    );
    score += min(accelMagnitude * 10, 30);

    // Factor de rotación
    double gyroMagnitude = sqrt(
      pow(data.gyroscopeX, 2) +
      pow(data.gyroscopeY, 2) +
      pow(data.gyroscopeZ, 2)
    );
    score += min(gyroMagnitude / 2, 30);

    // Factor de historial reciente
    if (_recentAlerts.isNotEmpty) {
      score += min(_recentAlerts.length * 5, 40);
    }

    _riskScore = min(score, 100);
  }

  void _simulateRandomEvent() {
    final events = [
      {'type': 'DISTRACCIÓN', 'severity': 'MEDIUM'},
      {'type': 'MIRADA FUERA', 'severity': 'LOW'},
      {'type': 'USO DE CELULAR', 'severity': 'HIGH'},
      {'type': 'FRENADA BRUSCA', 'severity': 'MEDIUM'},
    ];

    final event = events[Random().nextInt(events.length)];
    _triggerAlert(event['type']!, event['severity']!);
  }

  void _triggerAlert(String type, String severity) {
    _alertController.forward().then((_) {
      _alertController.reverse();
    });

    setState(() {
      _currentAlertType = type;

      // Actualizar contadores
      if (type.contains('DISTRACCIÓN') || type.contains('CELULAR') || type.contains('MIRADA')) {
        _distractionCount++;
      } else if (type.contains('TEMERARIA') || type.contains('FRENADA')) {
        _recklessCount++;
      } else if (type.contains('IMPACTO') || severity == 'CRITICAL') {
        _emergencyCount++;
      }

      // Agregar al historial
      _recentAlerts.insert(0, {
        'type': type,
        'severity': severity,
        'time': DateTime.now(),
      });

      if (_recentAlerts.length > 5) {
        _recentAlerts.removeLast();
      }
    });
  }

  void _activateEmergency() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50],
        contentPadding: const EdgeInsets.all(20),
        title: Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 48),
            const SizedBox(height: 8),
            Text(
              'PROTOCOLO DE EMERGENCIA',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!, width: 1),
                ),
                child: Text(
                  'Se activará el protocolo de emergencia en 10 segundos',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones automáticas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEmergencyAction(Icons.contacts, 'Notificación a contactos de emergencia'),
                    const SizedBox(height: 8),
                    _buildEmergencyAction(Icons.location_on, 'Envío de ubicación actual'),
                    const SizedBox(height: 8),
                    _buildEmergencyAction(Icons.phone, 'Llamada automática al 911'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(
                value: 1.0,
                backgroundColor: Colors.red,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 8,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    _triggerAlert('EMERGENCIA ACTIVADA', 'CRITICAL');
  }

  Widget _buildEmergencyAction(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.red[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'LOW':
        return Colors.yellow[700]!;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.deepOrange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'DriveGuard Monitor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 2,
        actions: [
          // Solo indicador de estado del dispositivo
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _deviceStatus == 'CONECTADO'
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _deviceStatus == 'CONECTADO' ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_deviceStatus == 'CONECTADO' ? Colors.green : Colors.red)
                          .withValues(alpha: 0.7 + (_pulseController.value * 0.3)),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _deviceStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.car_rental,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'DriveGuard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Sistema de Monitoreo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a notificaciones
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a configuración
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.blue),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a estadísticas
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a historial
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.blue),
              title: const Text('Ayuda'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a ayuda
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Mostrar información de la app
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel de Control Principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isMonitoring
                    ? [Colors.green[700]!, Colors.green[500]!]
                    : [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMonitoring ? 'MONITOREANDO' : 'EN ESPERA',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(_sessionDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Botón de inicio/parada
                      GestureDetector(
                        onTap: _toggleMonitoring,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isMonitoring ? Icons.stop : Icons.play_arrow,
                            size: 40,
                            color: _isMonitoring ? Colors.red : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Indicador de Riesgo y Alerta Actual
            Row(
              children: [
                // Score de Riesgo
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Score de Riesgo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.analytics,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _riskScore.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getRiskColor(_riskScore),
                              ),
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _riskScore / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getRiskColor(_riskScore),
                          ),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Estado Actual
                Expanded(
                  child: AnimatedBuilder(
                    animation: _alertController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _currentAlertType == 'NORMAL'
                            ? Colors.green[50]
                            : Colors.orange[50]!.withValues(
                                alpha: 0.5 + (_alertController.value * 0.5)
                              ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentAlertType == 'NORMAL'
                              ? Colors.green
                              : Colors.orange,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Estado Actual',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  _currentAlertType == 'NORMAL'
                                    ? Icons.check_circle
                                    : Icons.warning,
                                  color: _currentAlertType == 'NORMAL'
                                    ? Colors.green
                                    : Colors.orange,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentAlertType,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentAlertType == 'NORMAL'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estadísticas de Sesión
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Distracciones',
                    value: _distractionCount,
                    icon: Icons.visibility_off,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Conducta Temeraria',
                    value: _recklessCount,
                    icon: Icons.speed,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Emergencias',
                    value: _emergencyCount,
                    icon: Icons.emergency,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Datos de Sensores en Tiempo Real
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sensores en Tiempo Real',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.sensors,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Acelerómetro (m/s²)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSensorValue('X', _accelX),
                            _buildSensorValue('Y', _accelY),
                            _buildSensorValue('Z', _accelZ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giroscopio (°/s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSensorValue('X', _gyroX),
                            _buildSensorValue('Y', _gyroY),
                            _buildSensorValue('Z', _gyroZ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Historial de Alertas Recientes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alertas Recientes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.history,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recentAlerts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay alertas recientes',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _recentAlerts.map((alert) {
                        final timeString = '${alert['time'].hour.toString().padLeft(2, '0')}:${alert['time'].minute.toString().padLeft(2, '0')}:${alert['time'].second.toString().padLeft(2, '0')}';
                        return _buildAlertItem(alert, timeString);
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de Emergencia
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _activateEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'ACTIVAR PROTOCOLO DE EMERGENCIA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValue(String axis, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$axis:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert, String timeString) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSeverityColor(alert['severity']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getSeverityColor(alert['severity']).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getSeverityColor(alert['severity']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['type'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Severidad: ${alert['severity']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSeverityColor(alert['severity']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}