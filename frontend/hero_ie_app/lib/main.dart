import 'dart:ui';
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
import 'core/localization/app_localizations.dart';

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


// Global Router to prevent state loss on rebuilds
final GoRouter _router = GoRouter(
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

class HeroIEApp extends StatelessWidget {
  const HeroIEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<AppThemeType>(
          valueListenable: AppTheme.themeNotifier,
          builder: (context, currentMode, _) {
            return MaterialApp.router(
              title: 'HERO-IE',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.generateTheme(currentMode),
              routerConfig: _router,
              builder: (context, child) {
                return ThemeTransitionOverlay(
                  themeType: currentMode,
                  child: child!,
                );
              },
            );
          }
        );
      }
    );
  }
}

class ThemeTransitionOverlay extends StatefulWidget {
  final Widget child;
  final AppThemeType themeType;
  const ThemeTransitionOverlay({super.key, required this.child, required this.themeType});

  @override
  State<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends State<ThemeTransitionOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    // A quick, snappy 500ms duration for the colour splash
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ThemeTransitionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeType != widget.themeType) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              // Opacity peaks at 0.5 (middle of animation) and drops back to 0
              final op = (1.0 - (val - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Positioned.fill(
                // IgnorePointer ensures clicks pass through during animation
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15 * op, sigmaY: 15 * op),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accent(context).withValues(alpha: 0.25 * op),
                            AppTheme.accent(context).withValues(alpha: 0.05 * op),
                            Colors.transparent,
                          ],
                          radius: 0.8 + (val * 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

