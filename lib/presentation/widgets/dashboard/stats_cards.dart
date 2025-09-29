import 'package:flutter/material.dart';

class StatsCards extends StatelessWidget {
  final int distractionCount;
  final int recklessCount;
  final int emergencyCount;

  const StatsCards({
    super.key,
    required this.distractionCount,
    required this.recklessCount,
    required this.emergencyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Distracciones',
            value: distractionCount,
            icon: Icons.visibility_off,
            color: Colors.yellow,
            onTap: () => _showDistractionTooltip(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Conducta Temeraria',
            value: recklessCount,
            icon: Icons.speed,
            color: Colors.orange,
            onTap: () => _showRecklessTooltip(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Emergencias',
            value: emergencyCount,
            icon: Icons.emergency,
            color: Colors.red,
            onTap: () => _showEmergencyTooltip(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  void _showDistractionTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Distracciones'),
          content: const Text(
            'Las distracciones detectadas incluyen:\n\n'
            '• Uso del teléfono móvil mientras conduces\n'
            '• Miradas prolongadas fuera de la carretera\n'
            '• Patrones de conducción errática que sugieren distracción\n\n'
            'Este contador muestra el número total de distracciones detectadas durante la sesión actual de monitoreo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showRecklessTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conducta Temeraria'),
          content: const Text(
            'La conducta temeraria se identifica por:\n\n'
            '• Aceleraciones bruscas o excesivas\n'
            '• Frenadas súbitas y agresivas\n'
            '• Giros bruscos o maniobras peligrosas\n'
            '• Cambios repentinos de velocidad\n\n'
            'Este contador registra episodios de conducción que pueden comprometer tu seguridad y la de otros.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergencias'),
          content: const Text(
            'Las emergencias detectadas incluyen:\n\n'
            '• Posibles impactos o colisiones\n'
            '• Frenadas de emergencia extremas\n'
            '• Movimientos bruscos que sugieren accidentes\n'
            '• Situaciones de riesgo crítico\n\n'
            'Cuando se detecta una emergencia, se activa automáticamente el protocolo de respuesta de emergencia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}