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

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  bool _showAuthRestriction = false;
  String _targetRole = 'guest';
  bool _showLoader = true;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showLoader = false);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRoleSelection(String role) async {
    final verified = await AuthService.isVerified();
    if (!verified) {
      setState(() {
        _targetRole = role;
        _showAuthRestriction = true;
      });
      return;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        if (_showLoader) {
          return _buildStartupLoader(isDark);
        }

        return Scaffold(
          drawer: const AppDrawer(role: 'unauthenticated'),
          body: Stack(
            children: [
              // === BACKGROUND ===
              _buildBackground(isDark),

              // === MAIN CONTENT ===
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Stack(
                    children: [
                      // Hamburger menu
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Builder(
                          builder: (ctx) => _GlassIconButton(
                            icon: Icons.menu_rounded,
                            isDark: isDark,
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                      ),

                      // Theme dropdown
                      Positioned(
                        top: 12,
                        right: 12,
                        child: ValueListenableBuilder<AppThemeType>(
                          valueListenable: AppTheme.themeNotifier,
                          builder: (context, currentType, _) {
                            return PopupMenuButton<AppThemeType>(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.palette_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
                                    const SizedBox(width: 6),
                                    Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
                                  ],
                                ),
                              ),
                              color: isDark ? AppTheme.surfaceColor : Colors.white,
                              onSelected: (AppThemeType newTheme) {
                                AppTheme.themeNotifier.value = newTheme;
                              },
                              itemBuilder: (BuildContext context) {
                                return AppThemeType.values.map((theme) {
                                  return PopupMenuItem<AppThemeType>(
                                    value: theme,
                                    child: Text(
                                      theme.title.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Space Grotesk',
                                        color: currentType == theme ? AppTheme.accent(context) : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: currentType == theme ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                            );
                          }
                        ),
                      ),

                      // Central content
                      _buildCentralContent(isDark),
                    ],
                  ),
                ),
              ),

              // === AUTH RESTRICTION OVERLAY ===
              if (_showAuthRestriction) _buildAuthOverlay(isDark),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ //
  //  STARTUP LOADER
  // ------------------------------------------------------------------ //
  Widget _buildStartupLoader(bool isDark) {
    final accent = AppTheme.accent(context);
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundMatte : AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.security_rounded, size: 64, color: accent),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: accent, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'INITIALIZING SECURE MESH...',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ //
  //  BACKGROUND
  // ------------------------------------------------------------------ //
  Widget _buildBackground(bool isDark) {
    final accent = AppTheme.accent(context);
    final accentSoft = AppTheme.accentSoft(context);
    
    return Stack(
      children: [
        // Base color
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.backgroundMatte : AppTheme.backgroundLight,
          ),
        ),

        // Radar Sweep / Sonar Animation
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => CustomPaint(
            painter: _RadarPainter(
              progress: _pulseAnim.value,
              color: accent,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Deep central glow masking the center of the radar
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: isDark ? 0.08 * _pulseAnim.value : 0.04 * _pulseAnim.value),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  //  CENTRAL CONTENT
  // ------------------------------------------------------------------ //
  Widget _buildCentralContent(bool isDark) {
    final accent = AppTheme.accent(context);
    final accentSoft = AppTheme.accentSoft(context);

    return Column(
      children: [
        const SizedBox(height: 80),

        // ---- GLOWING HERO SHIELD ICON ----
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.surfaceColor.withValues(alpha: 0.5) : Colors.white,
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              if (isDark) BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner glowing core
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3 * _pulseAnim.value),
                        blurRadius: 15,
                        spreadRadius: 5 * _pulseAnim.value,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.security_rounded,
                size: 42,
                color: isDark ? Colors.white : accent,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ---- APP TITLE (WORDMARK) ----
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HERO',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '-IE',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 38,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: accent,
                shadows: [
                  Shadow(color: accent.withValues(alpha: 0.5), blurRadius: 10),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ---- TAGLINE ----
        Text(
          AppLocalizations.translate('app_tagline'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: isDark
                ? const Color(0xFFA1A1AA)
                : const Color(0xFF71717A),
          ),
        ),

        const Spacer(),

        // ---- ROLE SELECTION CARD ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? const Color(0xFF18181B)
                  : Colors.white,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE4E4E7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.translate('role_selection'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? const Color(0xFFA1A1AA)
                        : const Color(0xFF71717A),
                  ),
                ),
                    const SizedBox(height: 20),

                    // Guest Button
                    _RoleButton(
                      label: AppLocalizations.translate('connect_guest'),
                      icon: Icons.person_rounded,
                      isPrimary: true,
                      isDark: isDark,
                      accent: accent,
                      onPressed: () => _handleRoleSelection('guest'),
                    ),

                    const SizedBox(height: 12),

                    // Staff Button
                    _RoleButton(
                      label: AppLocalizations.translate('connect_staff'),
                      icon: Icons.admin_panel_settings_rounded,
                      isPrimary: false,
                      isDark: isDark,
                      accent: accentSoft,
                      onPressed: () => _handleRoleSelection('staff'),
                    ),
                  ],
                ),
              ),
            ),

        const SizedBox(height: 32),

        // ---- BOTTOM LABEL ----
        Text(
          'SECURE · ENCRYPTED · OFFLINE-READY',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: isDark
                ? const Color(0xFF52525B)
                : const Color(0xFFA1A1AA),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  //  AUTH OVERLAY
  // ------------------------------------------------------------------ //
  Widget _buildAuthOverlay(bool isDark) {
    final accent = AppTheme.accent(context);

    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1.0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.7),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: isDark
                        ? const Color(0xFF18181B)
                        : Colors.white,
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                          border: Border.all(
                              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7), 
                              width: 1.5),
                        ),
                        child: Icon(Icons.lock_person_rounded,
                            size: 40, color: accent),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.translate('sign_in_to_continue'),
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Verified access is required for emergency\nsafety and coordination.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            elevation: isDark ? 8 : 0,
                            shadowColor: accent.withValues(alpha: 0.4),
                          ),
                          onPressed: () {
                            setState(() => _showAuthRestriction = false);
                            context.push('/auth?role=$_targetRole');
                          },
                          child: Text(AppLocalizations.translate('sign_in_to_continue').toUpperCase()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showAuthRestriction = false),
                        child: Text(
                          AppLocalizations.translate('back_btn'),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================== //
//  GLASS ICON BUTTON
// ====================================================================== //
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? const Color(0xFF18181B)
            : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF27272A)
              : const Color(0xFFE4E4E7),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      ),
    );
  }
}

// ====================================================================== //
//  ROLE BUTTON
// ====================================================================== //
class _RoleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDark;
  final Color accent;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDark,
    required this.accent,
    required this.onPressed,
  });

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovering = true),
      onTapUp: (_) {
        setState(() => _hovering = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isPrimary
              ? widget.accent.withValues(alpha: _hovering ? 0.9 : 1.0)
              : (widget.isDark
                  ? const Color(0xFF27272A).withValues(alpha: _hovering ? 0.8 : 0.5)
                  : const Color(0xFFF4F4F5).withValues(alpha: _hovering ? 0.8 : 1.0)),
          border: Border.all(
            color: widget.isPrimary
                ? Colors.transparent
                : (widget.isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: widget.isPrimary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.isPrimary
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== //
//  RADAR SWEEP BACKGROUND PAINTER
// ====================================================================== //
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.4);
    final maxRadius = size.height * 0.6;

    // Draw 4 expanding rings
    for (int i = 0; i < 4; i++) {
        double r = ((progress + (i * 0.25)) % 1.0) * maxRadius;
        // Fade out as it expands
        final alphaMultiplier = 1.0 - (r / maxRadius);
        paint.color = color.withValues(alpha: 0.25 * alphaMultiplier);
        canvas.drawCircle(center, r, paint);
    }
    
    // Draw crosshairs
    final chPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), chPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), chPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.progress != progress || old.color != color;
}

