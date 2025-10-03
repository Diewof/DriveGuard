import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/settings/notification_settings_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/history/history_page.dart';
import '../../presentation/pages/history/session_events_page.dart';
import '../../domain/entities/driving_session.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppConstants.dashboardRoute,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppConstants.notificationSettingsRoute,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/history/session-events',
        name: 'session-events',
        builder: (context, state) {
          final session = state.extra as DrivingSession;
          return SessionEventsPage(session: session);
        },
      ),
    ],
  );
}