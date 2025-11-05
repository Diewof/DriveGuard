import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/detection_config_service.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/utils/app_typography.dart';
import '../../core/widgets/common_card.dart';

class DetectionSettingsPage extends StatefulWidget {
  const DetectionSettingsPage({super.key});

  @override
  State<DetectionSettingsPage> createState() => _DetectionSettingsPageState();
}

class _DetectionSettingsPageState extends State<DetectionSettingsPage> {
  late DetectionConfigService _configService;
  SensitivityMode _selectedMode = SensitivityMode.normal;
  bool _useGimbal = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    _configService = await DetectionConfigService.getInstance();
    setState(() {
      _selectedMode = _configService.config.mode;
      _useGimbal = _configService.config.useGimbal;
      _isLoading = false;
    });
  }

  Future<void> _saveConfiguration() async {
    await _configService.setConfig(_selectedMode, _useGimbal);

    if (mounted) {
      // Notificar al DashboardBloc que la configuración ha cambiado
      try {
        context.read<DashboardBloc>().add(DashboardConfigurationChanged());
      } catch (e) {
        // Si el DashboardBloc no está disponible (usuario no está en el dashboard)
        // simplemente ignoramos el error
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Detección'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Configuración de Detección',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Título principal
          Text(
            'Sensibilidad de Detección',
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ajusta qué tan sensible es el sistema para detectar eventos de conducción',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Modos de sensibilidad
          _buildModeCard(
            mode: SensitivityMode.relaxed,
            icon: Icons.sentiment_satisfied,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            mode: SensitivityMode.normal,
            icon: Icons.balance,
            color: Colors.blue,
            recommended: true,
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            mode: SensitivityMode.strict,
            icon: Icons.security,
            color: Colors.orange,
          ),

          const SizedBox(height: AppSpacing.xl),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Configuración de Gimbal
          Text(
            'Configuración de Hardware',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _buildGimbalSwitch(),

          const SizedBox(height: AppSpacing.lg),

          // Información adicional
          _buildInfoCard(),

          const SizedBox(height: AppSpacing.xl),

          // Botón de guardado
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saveConfiguration,
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
    );
  }

  Widget _buildModeCard({
    required SensitivityMode mode,
    required IconData icon,
    required Color color,
    bool recommended = false,
  }) {
    final isSelected = _selectedMode == mode;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isSelected ? color : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              // Radio button
              Radio<SensitivityMode>(
                value: mode,
                groupValue: _selectedMode,
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                },
                fillColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? color
                      : AppColors.textSecondary;
                }),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Icono
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName.toUpperCase(),
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : AppColors.textPrimary,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              'RECOMENDADO',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGimbalSwitch() {
    return CommonCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _useGimbal
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.textDisabled.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              Icons.phone_android_outlined,
              color: _useGimbal ? AppColors.primary : AppColors.textDisabled,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usar con Gimbal/Estabilizador',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activa esta opción si el teléfono está montado en un estabilizador. '
                  'Esto ajusta los umbrales de detección para compensar la estabilización.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useGimbal,
            onChanged: (value) {
              setState(() {
                _useGimbal = value;
              });
            },
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
          _buildInfoItem(
            'Modo Leve',
            'Menos alertas. Ideal para conductores experimentados en carreteras buenas.',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoItem(
            'Modo Moderado',
            'Balance perfecto. Recomendado para la mayoría de usuarios.',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoItem(
            'Modo Estricto',
            'Máxima detección. Ideal para aprendizaje o entrenamiento.',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildInfoItem(
            'Gimbal',
            'Optimiza la detección cuando usas un estabilizador de teléfono.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: AppTypography.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
