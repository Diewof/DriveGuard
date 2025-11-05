import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/widgets/common_card.dart';

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Configuración de Notificaciones',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: AppSpacing.elevation2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
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

            const SizedBox(height: AppSpacing.md),

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
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
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

            const SizedBox(height: AppSpacing.md),

            // Información adicional
            _buildInfoCard(),

            const SizedBox(height: AppSpacing.xl),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  'Guardar Configuración',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
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
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textDisabled;
            }),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                valueFormatter(value),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']!),
                );
              }).toList(),
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              underline: const SizedBox.shrink(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: AppSpacing.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Información',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• Las notificaciones se activan solo para alertas de severidad MEDIA o superior\n'
            '• Existe un tiempo de enfriamiento de 30 segundos entre alertas del mismo tipo\n'
            '• El modo silencioso puede activarse temporalmente durante las pruebas\n'
            '• Los ajustes se guardan automáticamente en el dispositivo',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}