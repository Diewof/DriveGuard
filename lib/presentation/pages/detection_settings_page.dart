import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/detection_config_service.dart';
import '../blocs/dashboard/dashboard_bloc.dart';

class DetectionSettingsPage extends StatefulWidget {
  const DetectionSettingsPage({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Configuración de Detección'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfiguration,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Título principal
          const Text(
            '🎛️ Sensibilidad de Detección',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajusta qué tan sensible es el sistema para detectar eventos de conducción',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

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

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Configuración de Gimbal
          const Text(
            '📱 Configuración de Hardware',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildGimbalSwitch(),

          const SizedBox(height: 24),

          // Información adicional
          _buildInfoCard(),

          const SizedBox(height: 24),

          // Botón de guardado
          ElevatedButton.icon(
            onPressed: _saveConfiguration,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Configuración'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
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

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? color.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                activeColor: color,
              ),
              const SizedBox(width: 12),

              // Icono
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.black87,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RECOMENDADO',
                              style: TextStyle(
                                fontSize: 10,
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: _useGimbal,
        onChanged: (value) {
          setState(() {
            _useGimbal = value;
          });
        },
        title: const Text(
          'Usar con Gimbal/Estabilizador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Activa esta opción si el teléfono está montado en un estabilizador. '
          'Esto ajusta los umbrales de detección para compensar la estabilización.',
          style: TextStyle(fontSize: 13),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _useGimbal ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.phone_android,
            color: _useGimbal ? Colors.blue : Colors.grey,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Información',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Modo Leve',
              'Menos alertas. Ideal para conductores experimentados en carreteras buenas.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Modo Moderado',
              'Balance perfecto. Recomendado para la mayoría de usuarios.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Modo Estricto',
              'Máxima detección. Ideal para aprendizaje o entrenamiento.',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Gimbal',
              'Optimiza la detección cuando usas un estabilizador de teléfono.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
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
