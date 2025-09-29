import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String currentAlertType;
  final Animation<double> alertAnimation;

  const StatusIndicator({
    super.key,
    required this.currentAlertType,
    required this.alertAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: alertAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentAlertType == 'NORMAL'
              ? Colors.green[50]
              : Colors.orange[50]!.withValues(
                  alpha: 0.5 + (alertAnimation.value * 0.5)
                ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: currentAlertType == 'NORMAL'
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
                    currentAlertType == 'NORMAL'
                      ? Icons.check_circle
                      : Icons.warning,
                    color: currentAlertType == 'NORMAL'
                      ? Colors.green
                      : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currentAlertType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: currentAlertType == 'NORMAL'
                    ? Colors.green[700]
                    : Colors.orange[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}