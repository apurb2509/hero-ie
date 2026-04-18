import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/landing_screen.dart';
import 'features/dashboard/user_dashboard_screen.dart';
import 'features/dashboard/admin_dashboard_screen.dart';

import 'core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure firebase gets initialized later when configuring completely
  // await Firebase.initializeApp(); 
  
  // Discover backend automatically
  await ApiService.discoverBackend();
  
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
      ],
    );

    return MaterialApp.router(
      title: 'HERO-IE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
