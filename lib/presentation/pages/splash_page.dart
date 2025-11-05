import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_typography.dart';
import '../../core/utils/app_spacing.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashTimer();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSplashTimer() async {
    // Mínimo 2 segundos de splash
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    final authState = context.read<AuthBloc>().state;

    if (authState.isAuthenticated) {
      context.go('/dashboard');
    } else if (authState.isUnauthenticated) {
      context.go('/login');
    }
    // Si es unknown o loading, esperamos a que se resuelva
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Solo navegamos después de que el timer del splash termine
        if (state.status != AuthStatus.unknown && state.status != AuthStatus.loading) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final route = state.isAuthenticated ? '/dashboard' : '/login';
              if (context.mounted) {
                context.go(route);
              }
            }
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo con gradiente
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            spreadRadius: 0,
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shield_outlined,
                              size: 80,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // Nombre de la app
                    Text(
                      AppConstants.appName,
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        letterSpacing: 1.2,
                      ),
                    ),

                    SizedBox(height: AppSpacing.sm),

                    // Subtítulo
                    Text(
                      'Sistema de Monitoreo Inteligente\nde Conducción',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    // Loading indicator
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            SizedBox(
                              width: AppSpacing.iconLarge,
                              height: AppSpacing.iconLarge,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              _getLoadingText(state),
                              style: AppTypography.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLoadingText(AuthState state) {
    switch (state.status) {
      case AuthStatus.loading:
        return 'Verificando sesión...';
      case AuthStatus.authenticated:
        return 'Bienvenido de vuelta';
      case AuthStatus.unauthenticated:
        return 'Cargando...';
      default:
        return 'Iniciando...';
    }
  }
}