import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'data/datasources/local/auth_local_datasource.dart';
import 'data/datasources/remote/firebase_auth_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/usecases/forgot_password_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/start_session_usecase.dart';
import 'domain/usecases/end_session_usecase.dart';
import 'domain/usecases/add_session_event_usecase.dart';
import 'domain/usecases/get_user_sessions_usecase.dart';
import 'domain/usecases/get_session_events_usecase.dart';
import 'domain/usecases/get_active_session_usecase.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/session/session_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(DriveGuardApp(sharedPreferences: sharedPreferences));
}

class DriveGuardApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const DriveGuardApp({
    super.key,
    required this.sharedPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            // Configurar dependencias de autenticación
            final remoteDataSource = FirebaseAuthDataSourceImpl();
            final localDataSource = AuthLocalDataSourceImpl(
              prefs: sharedPreferences,
            );
            final authRepository = AuthRepositoryImpl(
              remoteDataSource: remoteDataSource,
              localDataSource: localDataSource,
            );

            // Crear UseCases de autenticación
            final loginUseCase = LoginUseCase(authRepository);
            final registerUseCase = RegisterUseCase(authRepository);
            final logoutUseCase = LogoutUseCase(authRepository);
            final forgotPasswordUseCase = ForgotPasswordUseCase(authRepository);
            final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

            // Crear y configurar AuthBloc
            final authBloc = AuthBloc(
              loginUseCase: loginUseCase,
              registerUseCase: registerUseCase,
              logoutUseCase: logoutUseCase,
              forgotPasswordUseCase: forgotPasswordUseCase,
              getCurrentUserUseCase: getCurrentUserUseCase,
            );

            // Verificar estado inicial de autenticación
            authBloc.add(AuthCheckRequested());

            return authBloc;
          },
        ),
        BlocProvider(
          create: (context) {
            // Configurar dependencias de sesión
            final sessionRepository = SessionRepositoryImpl();

            // Crear UseCases de sesión
            final startSessionUseCase = StartSessionUseCase(sessionRepository);
            final endSessionUseCase = EndSessionUseCase(sessionRepository);
            final addSessionEventUseCase = AddSessionEventUseCase(sessionRepository);
            final getUserSessionsUseCase = GetUserSessionsUseCase(sessionRepository);
            final getSessionEventsUseCase = GetSessionEventsUseCase(sessionRepository);
            final getActiveSessionUseCase = GetActiveSessionUseCase(sessionRepository);

            // Crear y configurar SessionBloc
            return SessionBloc(
              startSessionUseCase: startSessionUseCase,
              endSessionUseCase: endSessionUseCase,
              addSessionEventUseCase: addSessionEventUseCase,
              getUserSessionsUseCase: getUserSessionsUseCase,
              getSessionEventsUseCase: getSessionEventsUseCase,
              getActiveSessionUseCase: getActiveSessionUseCase,
            );
          },
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
