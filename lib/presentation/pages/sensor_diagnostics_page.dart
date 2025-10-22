import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/device_sensor_service.dart';
import '../../domain/entities/sensor_data.dart';
import '../../core/constants/app_constants.dart';

/// Pantalla de diagnóstico de sensores
/// Muestra valores en tiempo real y permite validar el funcionamiento
class SensorDiagnosticsPage extends StatefulWidget {
  const SensorDiagnosticsPage({super.key});

  @override
  State<SensorDiagnosticsPage> createState() => _SensorDiagnosticsPageState();
}

class _SensorDiagnosticsPageState extends State<SensorDiagnosticsPage> {
  final DeviceSensorService _sensorService = DeviceSensorService();
  StreamSubscription<SensorData>? _subscription;
  SensorData? _currentData;
  bool _isMonitoring = false;

  // Histórico de alertas
  final List<String> _alertHistory = [];

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    if (_isMonitoring) return;

    setState(() {
      _isMonitoring = true;
    });

    _sensorService.startMonitoring();
    _subscription = _sensorService.stream.listen((data) {
      setState(() {
        _currentData = data;
        _checkThresholds(data);
      });
    });
  }

  void _stopMonitoring() {
    if (!_isMonitoring) return;

    setState(() {
      _isMonitoring = false;
    });

    _subscription?.cancel();
    _sensorService.stopMonitoring();
  }

  void _checkThresholds(SensorData data) {
    if (data.isRecklessDriving) {
      _addAlert('⚠️ CONDUCCIÓN TEMERARIA detectada');
    }
    if (data.isCrashDetected) {
      _addAlert('🚨 IMPACTO DETECTADO');
    }
  }

  void _addAlert(String alert) {
    setState(() {
      _alertHistory.insert(0, '${DateTime.now().toString().substring(11, 19)} - $alert');
      if (_alertHistory.length > 10) {
        _alertHistory.removeRange(10, _alertHistory.length);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Sensores'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado del monitoreo
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Acelerómetro
            _buildSensorCard(
              title: 'Acelerómetro',
              icon: Icons.speed,
              color: Colors.blue,
              values: _currentData != null
                  ? {
                      'X': _currentData!.accelerationX,
                      'Y': _currentData!.accelerationY,
                      'Z': _currentData!.accelerationZ,
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            // Giroscopio
            _buildSensorCard(
              title: 'Giroscopio',
              icon: Icons.rotate_right,
              color: Colors.green,
              values: _currentData != null
                  ? {
                      'X': _currentData!.gyroscopeX,
                      'Y': _currentData!.gyroscopeY,
                      'Z': _currentData!.gyroscopeZ,
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            // Umbrales y detección
            _buildThresholdsCard(),
            const SizedBox(height: 16),

            // Historial de alertas
            _buildAlertHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado del Monitoreo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _isMonitoring ? Icons.check_circle : Icons.cancel,
                  color: _isMonitoring ? Colors.green : Colors.red,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isMonitoring ? null : _startMonitoring,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isMonitoring ? _stopMonitoring : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Detener'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, double>? values,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (values != null)
              ...values.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.value.toStringAsFixed(3),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              const Center(
                child: Text(
                  'Sin datos',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsCard() {
    final totalAccel = _currentData != null
        ? (_currentData!.accelerationX.abs() + _currentData!.accelerationY.abs()) / 2
        : 0.0;
    final totalGyro = _currentData != null
        ? (_currentData!.gyroscopeX.abs() +
                _currentData!.gyroscopeY.abs() +
                _currentData!.gyroscopeZ.abs()) /
            3
        : 0.0;

    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  'Umbrales de Detección',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildThresholdRow(
              'Aceleración Temeraria:',
              totalAccel,
              AppConstants.recklessAccelThreshold,
            ),
            _buildThresholdRow(
              'Giroscopio Temerario:',
              totalGyro,
              AppConstants.recklessGyroThreshold,
            ),
            _buildThresholdRow(
              'Umbral de Impacto:',
              _currentData != null
                  ? (_currentData!.accelerationX.abs() +
                          _currentData!.accelerationY.abs() +
                          _currentData!.accelerationZ.abs()) /
                      3
                  : 0.0,
              AppConstants.crashAccelThreshold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(String label, double current, double threshold) {
    final isExceeded = current > threshold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (current / (threshold * 2)).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? Colors.red : Colors.green,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${current.toStringAsFixed(2)} / ${threshold.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: isExceeded ? Colors.red : Colors.black87,
                  fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertHistoryCard() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  'Historial de Alertas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_alertHistory.isEmpty)
              const Center(
                child: Text(
                  'Sin alertas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._alertHistory.map((alert) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      alert,
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
