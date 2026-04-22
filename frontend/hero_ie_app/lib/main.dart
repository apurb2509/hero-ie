import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_service.dart';
import 'features/onboarding/landing_screen.dart';
import 'features/dashboard/user_dashboard_screen.dart';
import 'features/dashboard/admin_dashboard_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bjatkogzmdzhwbsuhlii.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqYXRrb2d6bWR6aHdic3VobGlpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjQ0OTg1MiwiZXhwIjoyMDkyMDI1ODUyfQ.3DLoBeLSD96WVwlDzWhlOm5bVfeN_eBQvBiHQwKDqww',
  );

  // Discover backend automatically
  await ApiService.discoverBackend();

  // Pre-load avatar from local storage into the global notifier
  await AuthService.initAvatarNotifier();

  runApp(const HeroIEApp());
}


class HeroIEApp extends StatelessWidget {
  const HeroIEApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/user-dashboard',
          builder: (context, state) => const UserDashboardScreen(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'] ?? 'guest';
            return AuthScreen(initialRole: role);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          title: 'HERO-IE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          routerConfig: router,
        );
      }
    );
  }
}
