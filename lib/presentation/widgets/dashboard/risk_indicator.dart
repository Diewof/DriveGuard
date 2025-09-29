import 'package:flutter/material.dart';

class RiskIndicator extends StatelessWidget {
  final double riskScore;

  const RiskIndicator({
    super.key,
    required this.riskScore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTooltip(context),
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
                riskScore.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _getRiskColor(riskScore),
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
            value: riskScore / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getRiskColor(riskScore),
            ),
            minHeight: 6,
          ),
        ],
        ),
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.red;
  }

  void _showTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Score de Riesgo'),
          content: const Text(
            'El Score de Riesgo es una medición en tiempo real (0-100) que evalúa la seguridad de tu conducción basándose en:\n\n'
            '• Aceleración: Detecta frenadas y acelerones bruscos\n'
            '• Rotación: Identifica giros agresivos o maniobras peligrosas\n'
            '• Historial: Considera el patrón de alertas recientes\n\n'
            'Score menor a 30: Conducción segura\n'
            'Score 30-60: Riesgo moderado\n'
            'Score mayor a 60: Alto riesgo',
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