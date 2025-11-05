/// Sistema de espaciado DriveGuard
///
/// Grid system de 8px para espaciado consistente y modular
/// Todos los espaciados siguen múltiplos de 8px
class AppSpacing {
  // ========== ESPACIADO BASE (múltiplos de 8px) ==========
  static const double xs = 4.0;   // Extra pequeño (0.5x)
  static const double sm = 8.0;   // Pequeño (1x)
  static const double md = 16.0;  // Mediano (2x)
  static const double lg = 24.0;  // Grande (3x)
  static const double xl = 32.0;  // Extra grande (4x)
  static const double xxl = 48.0; // Extra extra grande (6x)

  // ========== PADDING DE CONTENEDORES ==========
  /// Padding pequeño para elementos compactos
  static const double paddingSmall = 12.0;

  /// Padding estándar para tarjetas y contenedores
  static const double paddingCard = 16.0;

  /// Padding grande para secciones principales
  static const double paddingSection = 20.0;

  /// Padding de página (márgenes laterales)
  static const double paddingPage = 16.0;

  // ========== RADIOS DE BORDE ==========
  /// Radio pequeño (badges, chips)
  static const double radiusSmall = 8.0;

  /// Radio estándar (tarjetas, botones)
  static const double radiusMedium = 12.0;

  /// Radio grande (elementos destacados)
  static const double radiusLarge = 16.0;

  /// Radio extra grande (modales, overlays)
  static const double radiusXLarge = 20.0;

  /// Radio circular (botones circulares)
  static const double radiusCircular = 999.0;

  // ========== ELEVACIONES (sombras) ==========
  /// Elevación nivel 1 - elementos sutiles
  static const double elevation1 = 2.0;

  /// Elevación nivel 2 - tarjetas estándar
  static const double elevation2 = 4.0;

  /// Elevación nivel 3 - elementos flotantes
  static const double elevation3 = 6.0;

  /// Elevación nivel 4 - modales y overlays
  static const double elevation4 = 8.0;

  /// Elevación nivel 5 - elementos máxima prioridad
  static const double elevation5 = 12.0;

  // ========== TAMAÑOS DE ICONOS ==========
  /// Icono extra pequeño
  static const double iconXSmall = 16.0;

  /// Icono pequeño
  static const double iconSmall = 20.0;

  /// Icono mediano (estándar)
  static const double iconMedium = 24.0;

  /// Icono grande
  static const double iconLarge = 32.0;

  /// Icono extra grande
  static const double iconXLarge = 48.0;

  // ========== ANCHOS DE BORDE ==========
  /// Borde fino
  static const double borderThin = 1.0;

  /// Borde mediano
  static const double borderMedium = 2.0;

  /// Borde grueso
  static const double borderThick = 3.0;

  // ========== ALTURA DE COMPONENTES ==========
  /// Altura de botón pequeño
  static const double buttonHeightSmall = 36.0;

  /// Altura de botón estándar
  static const double buttonHeightMedium = 48.0;

  /// Altura de botón grande
  static const double buttonHeightLarge = 56.0;

  /// Altura de campo de texto
  static const double inputHeight = 48.0;

  /// Altura de AppBar
  static const double appBarHeight = 56.0;

  // ========== ANCHOS DE COMPONENTES ==========
  /// Ancho mínimo de botón
  static const double buttonMinWidth = 100.0;

  /// Ancho de badge/chip
  static const double badgeWidth = 80.0;

  // ========== OPACIDADES ==========
  /// Opacidad para elementos deshabilitados
  static const double opacityDisabled = 0.38;

  /// Opacidad para overlays
  static const double opacityOverlay = 0.4;

  /// Opacidad para fondos semitransparentes
  static const double opacityBackground = 0.1;

  /// Opacidad para hover
  static const double opacityHover = 0.08;

  // ========== DURACIONES DE ANIMACIÓN ==========
  /// Duración rápida (microinteracciones)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Duración estándar
  static const Duration durationMedium = Duration(milliseconds: 250);

  /// Duración lenta (transiciones complejas)
  static const Duration durationSlow = Duration(milliseconds: 350);

  /// Duración para alertas
  static const Duration durationAlert = Duration(milliseconds: 500);
}
