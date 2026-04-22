import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/nearby_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_drawer.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _showAuthRestriction = false;
  String _targetRole = 'guest';

  void _handleRoleSelection(String role) async {
    final verified = await AuthService.isVerified();
    if (!verified) {
      setState(() {
        _targetRole = role;
        _showAuthRestriction = true;
      });
      return;
    }

    // Already authenticated, proceed
    if (role == 'guest') {
      await NearbyService.startDiscovery('Guest_Node');
      if (mounted) context.go('/user-dashboard');
    } else {
      await NearbyService.startAdvertising('Staff_Node');
      if (mounted) context.go('/admin-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return Scaffold(
          drawer: const AppDrawer(role: 'unauthenticated'),
          body: Stack(
            children: [
              // Sleek Pattern Background
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPatternPainter(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ),
                ),
              ),
              
              SafeArea(
                child: Stack(
                  children: [
                    // Menu Button in Top Left
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Builder(
                        builder: (ctx) => IconButton(
                          icon: Icon(Icons.menu, color: Theme.of(context).brightness == Brightness.light ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon, size: 30),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                    ),
                    
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_moon, size: 100, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.translate('app_title'),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                letterSpacing: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.translate('app_tagline'),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            // Role Selection
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.light ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.5) : AppTheme.primaryNeon.withOpacity(0.5)
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    AppLocalizations.translate('role_selection'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.person),
                                      label: Text(AppLocalizations.translate('connect_guest')),
                                      onPressed: () => _handleRoleSelection('guest'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.admin_panel_settings),
                                      label: Text(AppLocalizations.translate('connect_staff')),
                                      onPressed: () => _handleRoleSelection('staff'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    
                    // Blurred Restriction Overlay
                    if (_showAuthRestriction)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Theme.of(context).brightness == Brightness.light ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                              child: Center(
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.light ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.5) : AppTheme.primaryNeon.withOpacity(0.5)
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_person, size: 64, color: Theme.of(context).brightness == Brightness.light ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Please Sign In to Continue',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Verified access is required to ensure emergency safety and coordination.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() => _showAuthRestriction = false);
                                          context.push('/auth?role=$_targetRole');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                        ),
                                        child: const Text('SIGN IN'),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(() => _showAuthRestriction = false),
                                        child: Text('Back', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white30)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
    );
  }
}

// Minimal Dotted Grid Painter
class GridPatternPainter extends CustomPainter {
  final Color color;

  GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double spacing = 30.0;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
