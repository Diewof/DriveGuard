import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/utils/app_typography.dart';
import '../../core/widgets/common_card.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': '¿Cómo inicio una sesión de monitoreo?',
      'answer': 'En el dashboard principal, presiona el botón "INICIAR MONITOREO". El sistema comenzará a detectar comportamientos de conducción usando los sensores del dispositivo.',
    },
    {
      'question': '¿Qué sensores utiliza DriveGuard?',
      'answer': 'DriveGuard utiliza el acelerómetro y giroscopio de tu dispositivo para detectar frenados bruscos, aceleraciones agresivas, giros cerrados y baches en el camino.',
    },
    {
      'question': '¿Cómo funcionan las alertas?',
      'answer': 'El sistema emite alertas visuales, sonoras y de vibración cuando detecta comportamientos de riesgo. La severidad varía según la intensidad del evento detectado: Bajo, Medio, Alto o Crítico.',
    },
    {
      'question': '¿Qué es el ESP32-CAM y cómo lo configuro?',
      'answer': 'El ESP32-CAM es una cámara opcional que detecta distracciones visuales (uso de celular, mirada desviada). Conéctalo a la misma red WiFi y configúralo desde "Detectar y Calibrar Cam" en el menú.',
    },
    {
      'question': '¿Puedo personalizar las notificaciones?',
      'answer': 'Sí, ve a "Notificaciones" en el menú lateral para ajustar el volumen de alertas, activar/desactivar vibración y cambiar la duración de las tarjetas de alerta.',
    },
    {
      'question': '¿Dónde veo mi historial de conducción?',
      'answer': 'Accede a "Historial" desde el menú lateral para ver todas tus sesiones anteriores, con detalles de eventos detectados y estadísticas.',
    },
    {
      'question': '¿Qué significa el puntaje de riesgo?',
      'answer': 'Es una métrica que va de 0-100 que refleja el nivel de riesgo de tu conducción actual. Más eventos detectados = mayor puntaje. Intenta mantenerlo bajo.',
    },
    {
      'question': '¿Cómo calibro los sensores?',
      'answer': 'Los sensores se calibran automáticamente. Si notas detecciones incorrectas, puedes ajustar los umbrales en "Detección" del menú lateral.',
    },
    {
      'question': '¿Qué es el protocolo de emergencia?',
      'answer': 'El botón rojo de emergencia activa una alerta crítica. Úsalo solo en situaciones de emergencia real mientras conduces.',
    },
    {
      'question': '¿El app consume mucha batería?',
      'answer': 'El monitoreo continuo de sensores consume batería. Se recomienda mantener el dispositivo conectado al cargador del vehículo durante sesiones largas.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Soporte',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: AppSpacing.elevation2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickGuideSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildFaqSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido a DriveGuard!',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tu asistente de conducción segura',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'DriveGuard es un sistema de monitoreo inteligente que te ayuda a mejorar tu conducción mediante alertas en tiempo real.',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGuideSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Guía Rápida de Uso',
                style: AppTypography.h4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideStep(
            number: 1,
            title: 'Monta tu dispositivo',
            description: 'Coloca tu teléfono en un soporte seguro en el tablero o parabrisas.',
            icon: Icons.phone_android,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideStep(
            number: 2,
            title: 'Inicia el monitoreo',
            description: 'Presiona "INICIAR MONITOREO" en el dashboard principal antes de conducir.',
            icon: Icons.play_circle_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideStep(
            number: 3,
            title: 'Conduce normalmente',
            description: 'El sistema detectará automáticamente comportamientos de riesgo y te alertará.',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideStep(
            number: 4,
            title: 'Detén al finalizar',
            description: 'Al terminar tu viaje, presiona "DETENER MONITOREO" para guardar la sesión.',
            icon: Icons.stop_circle_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGuideStep(
            number: 5,
            title: 'Revisa tu historial',
            description: 'Consulta tus estadísticas y mejora tu conducción en la sección "Historial".',
            icon: Icons.analytics_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: AppColors.info,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Preguntas Frecuentes',
                style: AppTypography.h4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              final isExpanded = _expandedFaqIndex == index;

              return Container(
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: isExpanded
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedFaqIndex = isExpanded ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['question']!,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isExpanded
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isExpanded
                                    ? AppColors.primary
                                    : AppColors.textDisabled,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: AppColors.divider,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              faq['answer']!,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.contact_support,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '¿Necesitas más ayuda?',
                style: AppTypography.h4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Si no encuentras respuesta a tu pregunta, contáctanos:',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'soporte@driveguard.app',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildContactItem(
            icon: Icons.bug_report_outlined,
            label: 'Reportar problema',
            value: 'Toca aquí para reportar un error',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'DriveGuard está en fase BETA. Tu feedback es muy valioso.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
