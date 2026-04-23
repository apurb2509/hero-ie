import 'dart:math';
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

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

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
    _rotateController.dispose();
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

                      // Theme toggle
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _GlassIconButton(
                          icon: isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          isDark: isDark,
                          onPressed: () {
                            AppTheme.themeNotifier.value =
                                isDark ? ThemeMode.light : ThemeMode.dark;
                          },
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
  //  BACKGROUND
  // ------------------------------------------------------------------ //
  Widget _buildBackground(bool isDark) {
    return Stack(
      children: [
        // Base color
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D0A00),
                      Color(0xFF1A1200),
                      Color(0xFF0D0A00),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF9F0),
                      Color(0xFFFFF3E0),
                      Color(0xFFFFFBF0),
                    ],
                  ),
          ),
        ),

        // Hex mesh pattern
        AnimatedBuilder(
          animation: _rotateController,
          builder: (_, __) => CustomPaint(
            painter: HexMeshPainter(
              progress: _rotateController.value,
              isDark: isDark,
            ),
            child: const SizedBox.expand(),
          ),
        ),

        // Radial glow — top centre
        Positioned(
          top: -80,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              height: 380,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFFFB347).withValues(alpha: 0.18 * _pulseAnim.value),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFC97B1A).withValues(alpha: 0.12 * _pulseAnim.value),
                          Colors.transparent,
                        ],
                  radius: 0.65,
                ),
              ),
            ),
          ),
        ),

        // Radial glow — bottom centre
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFFFCC80).withValues(alpha: 0.10 * _pulseAnim.value),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFE59A2A).withValues(alpha: 0.08 * _pulseAnim.value),
                          Colors.transparent,
                        ],
                  radius: 0.55,
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
    final accent = isDark ? const Color(0xFFFFB347) : const Color(0xFFC97B1A);
    final accentSoft = isDark ? const Color(0xFFFFCC80) : const Color(0xFFE59A2A);

    return Column(
      children: [
        const SizedBox(height: 72),

        // ---- HERO ICON ----
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Center(
                    child: Icon(
                      Icons.shield_rounded,
                      size: 64,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ---- APP TITLE ----
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [const Color(0xFFFFB347), const Color(0xFFFFCC80)]
                : [const Color(0xFFC97B1A), const Color(0xFFE59A2A)],
          ).createShader(bounds),
          child: Text(
            AppLocalizations.translate('app_title'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ---- TAGLINE ----
        Text(
          'Hospitality Emergency Response and Orchestration\nIntegrated Ecosystem',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            letterSpacing: 1.2,
            height: 1.6,
            color: isDark
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.35),
          ),
        ),

        const Spacer(),

        // ---- ROLE SELECTION CARD ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.65),
                  border: Border.all(
                    color: isDark
                        ? accent.withValues(alpha: 0.25)
                        : const Color(0xFFC97B1A).withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.translate('role_selection'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        letterSpacing: 1.2,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.45),
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
          ),
        ),

        const SizedBox(height: 32),

        // ---- BOTTOM LABEL ----
        Text(
          'SECURE · ENCRYPTED · OFFLINE-READY',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            letterSpacing: 2.2,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
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
    final accent = isDark ? const Color(0xFFFFB347) : const Color(0xFFC97B1A);

    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1.0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.7),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.8),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.15),
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
                              color: accent.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Icon(Icons.lock_person_rounded,
                                size: 40, color: accent),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Sign In to Continue',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Verified access is required for emergency\nsafety and coordination.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.45),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: isDark
                                    ? const Color(0xFF0D0A00)
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () {
                                setState(() => _showAuthRestriction = false);
                                context.push('/auth?role=$_targetRole');
                              },
                              child: const Text('SIGN IN'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                setState(() => _showAuthRestriction = false),
                            child: Text(
                              'Go Back',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: isDark
                                    ? Colors.white30
                                    : Colors.black38,
                                fontSize: 13,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.5),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon,
                size: 22,
                color: isDark
                    ? const Color(0xFFFFB347)
                    : const Color(0xFFC97B1A)),
            onPressed: onPressed,
          ),
        ),
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
          borderRadius: BorderRadius.circular(14),
          gradient: widget.isPrimary
              ? LinearGradient(
                  colors: [
                    widget.accent.withValues(alpha: _hovering ? 1.0 : 0.9),
                    widget.accent.withValues(alpha: _hovering ? 0.75 : 0.65),
                  ],
                )
              : null,
          color: widget.isPrimary
              ? null
              : widget.isDark
                  ? Colors.white.withValues(alpha: _hovering ? 0.08 : 0.04)
                  : Colors.black.withValues(alpha: _hovering ? 0.06 : 0.03),
          border: Border.all(
            color: widget.accent.withValues(alpha: widget.isPrimary ? 0 : 0.5),
            width: 1,
          ),
          boxShadow: widget.isPrimary
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: _hovering ? 0.45 : 0.25),
                    blurRadius: _hovering ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: widget.isPrimary
                  ? (widget.isDark ? const Color(0xFF0D0A00) : Colors.white)
                  : widget.accent,
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: widget.isPrimary
                    ? (widget.isDark ? const Color(0xFF0D0A00) : Colors.white)
                    : widget.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== //
//  HEX MESH PAINTER
// ====================================================================== //
class HexMeshPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  HexMeshPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final accentColor = isDark
        ? const Color(0xFFFFB347)
        : const Color(0xFFC97B1A);

    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.08 : 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.22 : 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.35 : 0.40)
      ..style = PaintingStyle.fill;

    const double sqrt3 = 1.7320508;
    const double hexSize = 38.0;
    const double w = hexSize * 2;
    const double h = hexSize * sqrt3;

    // Subtle slow drift
    final double offsetX = (size.width * 0.04) * sin(progress * 2 * pi);
    final double offsetY = (size.height * 0.02) * cos(progress * 2 * pi);

    for (double row = -1; row < (size.height / h) + 2; row++) {
      for (double col = -1; col < (size.width / (w * 0.75)) + 2; col++) {
        final bool isOdd = col.toInt() % 2 == 1;
        final double cx = col * (w * 0.75) + offsetX;
        final double cy = row * h + (isOdd ? h / 2 : 0) + offsetY;

        // Distance from centre — fade glowing hexes near centre
        final double distFromCenter = sqrt(
          pow(cx - size.width / 2, 2) + pow(cy - size.height * 0.38, 2),
        );

        final bool isGlow = distFromCenter < size.width * 0.35;
        _drawHexagon(canvas, cx, cy, hexSize * 0.88,
            isGlow ? glowPaint : linePaint);

        // Draw vertex dots
        for (int i = 0; i < 6; i++) {
          final double angle = (pi / 3) * i - pi / 6;
          final double vx = cx + hexSize * 0.88 * cos(angle);
          final double vy = cy + hexSize * 0.88 * sin(angle);
          canvas.drawCircle(Offset(vx, vy), isGlow ? 1.8 : 1.0, dotPaint);
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (pi / 3) * i - pi / 6;
      final double x = cx + r * cos(angle);
      final double y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexMeshPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
