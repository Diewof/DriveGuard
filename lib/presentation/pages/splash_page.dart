import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startSplashTimer();
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
              if (state.isAuthenticated) {
                context.go('/dashboard');
              } else {
                context.go('/login');
              }
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.blue[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.drive_eta,
                  color: Colors.blue[900],
                  size: 60,
                ),
              ),

              const SizedBox(height: 32),

              // Nombre de la app
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // Subtítulo
              const Text(
                'Sistema de Monitoreo Inteligente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'de Conducción',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 60),

              // Loading indicator
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getLoadingText(state),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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