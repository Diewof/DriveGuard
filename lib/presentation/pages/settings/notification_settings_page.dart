import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  late NotificationSettings _settings;

  // Controllers para valores editables
  double _volume = 0.8;
  String _selectedLanguage = 'es';
  String _selectedDrivingMode = 'ciudad';
  double _sensitivity = 0.7;
  bool _visualEnabled = true;
  bool _audioEnabled = true;
  bool _hapticEnabled = true;
  int _alertCardDuration = 5;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    _settings = _notificationService.settings;
    setState(() {
      _volume = _settings.volume;
      _selectedLanguage = _settings.language;
      _selectedDrivingMode = _settings.drivingMode;
      _sensitivity = _settings.sensitivity;
      _visualEnabled = _settings.visualEnabled;
      _audioEnabled = _settings.audioEnabled;
      _hapticEnabled = _settings.hapticEnabled;
      _alertCardDuration = _settings.alertCardDuration;
    });
  }

  void _saveSettings() {
    final newSettings = NotificationSettings(
      visualEnabled: _visualEnabled,
      audioEnabled: _audioEnabled,
      hapticEnabled: _hapticEnabled,
      volume: _volume,
      language: _selectedLanguage,
      drivingMode: _selectedDrivingMode,
      sensitivity: _sensitivity,
      alertCardDuration: _alertCardDuration,
    );

    _notificationService.updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Configuración de Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipos de Notificación
            _buildSectionCard(
              title: 'Tipos de Notificación',
              icon: Icons.notifications_active,
              children: [
                _buildToggleItem(
                  title: 'Notificaciones Visuales',
                  subtitle: 'Mostrar overlays en pantalla',
                  value: _visualEnabled,
                  onChanged: (value) => setState(() => _visualEnabled = value),
                  icon: Icons.visibility,
                ),
                _buildToggleItem(
                  title: 'Notificaciones Auditivas',
                  subtitle: 'Reproducir sonidos y mensajes de voz',
                  value: _audioEnabled,
                  onChanged: (value) => setState(() => _audioEnabled = value),
                  icon: Icons.volume_up,
                ),
                _buildToggleItem(
                  title: 'Notificaciones Hápticas',
                  subtitle: 'Vibración del dispositivo',
                  value: _hapticEnabled,
                  onChanged: (value) => setState(() => _hapticEnabled = value),
                  icon: Icons.vibration,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Configuración de Audio
            if (_audioEnabled) ...[
              _buildSectionCard(
                title: 'Configuración de Audio',
                icon: Icons.audiotrack,
                children: [
                  _buildSliderItem(
                    title: 'Volumen de Alertas',
                    subtitle: 'Nivel de volumen para tonos y mensajes',
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) => setState(() => _volume = value),
                    icon: Icons.volume_up,
                    valueFormatter: (value) => '${(value * 100).round()}%',
                  ),
                  _buildDropdownItem(
                    title: 'Idioma de Mensajes',
                    subtitle: 'Idioma para mensajes de voz',
                    value: _selectedLanguage,
                    items: const [
                      {'value': 'es', 'label': 'Español'},
                      {'value': 'en', 'label': 'English'},
                    ],
                    onChanged: (value) => setState(() => _selectedLanguage = value!),
                    icon: Icons.language,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Configuración Visual
            if (_visualEnabled) ...[
              _buildSectionCard(
                title: 'Configuración Visual',
                icon: Icons.visibility,
                children: [
                  _buildSliderItem(
                    title: 'Duración de Tarjetas de Alerta',
                    subtitle: 'Tiempo que permanecen visibles las alertas',
                    value: _alertCardDuration.toDouble(),
                    min: 2.0,
                    max: 15.0,
                    divisions: 13,
                    onChanged: (value) => setState(() => _alertCardDuration = value.round()),
                    icon: Icons.timer,
                    valueFormatter: (value) => '${value.round()} segundos',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Configuración de Conducción
            _buildSectionCard(
              title: 'Modo de Conducción',
              icon: Icons.drive_eta,
              children: [
                _buildDropdownItem(
                  title: 'Tipo de Vía',
                  subtitle: 'Ajusta la sensibilidad según el entorno',
                  value: _selectedDrivingMode,
                  items: const [
                    {'value': 'ciudad', 'label': 'Ciudad'},
                    {'value': 'carretera', 'label': 'Carretera'},
                    {'value': 'nocturno', 'label': 'Nocturno'},
                  ],
                  onChanged: (value) => setState(() => _selectedDrivingMode = value!),
                  icon: Icons.map,
                ),
                _buildSliderItem(
                  title: 'Sensibilidad de Alertas',
                  subtitle: 'Ajusta qué tan sensible es la detección',
                  value: _sensitivity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) => setState(() => _sensitivity = value),
                  icon: Icons.tune,
                  valueFormatter: (value) {
                    if (value <= 0.3) return 'Baja';
                    if (value <= 0.6) return 'Media';
                    if (value <= 0.8) return 'Alta';
                    return 'Muy Alta';
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información adicional
            _buildInfoCard(),

            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'Guardar Configuración',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
            children: [
              Icon(icon, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.blue[700],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required IconData icon,
    required String Function(double) valueFormatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                valueFormatter(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: Colors.blue[700],
              inactiveColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
            underline: Container(
              height: 1,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Información',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Las notificaciones se activan solo para alertas de severidad MEDIA o superior\n'
            '• Existe un tiempo de enfriamiento de 30 segundos entre alertas del mismo tipo\n'
            '• El modo silencioso puede activarse temporalmente durante las pruebas\n'
            '• Los ajustes se guardan automáticamente en el dispositivo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}