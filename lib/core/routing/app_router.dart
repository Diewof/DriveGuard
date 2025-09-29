import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/settings/notification_settings_page.dart';

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
        path: AppConstants.notificationSettingsRoute,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
    ],
  );
}