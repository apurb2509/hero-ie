import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../localization/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = AppTheme.accent(context);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // ── Background: hex-mesh ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0xFF0D0A00), Color(0xFF1A1200)]
                    : const [Color(0xFFFFF9F0), Color(0xFFFFF3E0)],
              ),
            ),
          ),
          CustomPaint(
            painter: _DrawerHexPainter(isDark: isDark),
            child: const SizedBox.expand(),
          ),
          // Radial glow at drawer header
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          ValueListenableBuilder<String>(
            valueListenable: AppLocalizations.currentLocale,
            builder: (context, locale, _) {
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.12),
                              border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(Icons.shield_rounded, size: 28, color: accent),
                          ),
                          const SizedBox(height: 16),
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: isDark
                                  ? [AppTheme.primaryNeon, const Color(0xFFFFCC80)]
                                  : [AppTheme.primaryLight, const Color(0xFFE59A2A)],
                            ).createShader(b),
                            child: Text(
                              role == 'unauthenticated'
                                  ? AppLocalizations.translate('app_title')
                                  : (role == 'staff'
                                      ? AppLocalizations.translate('sidebar_staff_portal')
                                      : AppLocalizations.translate('sidebar_guest_portal')),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role == 'staff'
                                ? 'Admin Panel'
                                : (role == 'guest' ? 'Guest Portal' : 'Emergency System'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              letterSpacing: 1.4,
                              color: isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: accent.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),

                    // ── Items ────────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        children: [
                          // Profile
                          if (role != 'unauthenticated') ...[
                            _DrawerItem(
                              icon: Icons.person_rounded,
                              label: AppLocalizations.translate('sidebar_profile_settings'),
                              accent: accent,
                              isDark: isDark,
                              onTap: () {
                                context.pop();
                                context.push('/settings');
                              },
                            ),
                            _DrawerDivider(isDark: isDark),
                          ],

                          // Theme toggle
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: AppTheme.themeNotifier,
                            builder: (context, currentMode, _) {
                              final dark = currentMode == ThemeMode.dark;
                              return _DrawerToggle(
                                icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                label: AppLocalizations.translate('sidebar_dark_mode'),
                                accent: accent,
                                isDark: isDark,
                                value: dark,
                                onChanged: (v) {
                                  AppTheme.themeNotifier.value =
                                      v ? ThemeMode.dark : ThemeMode.light;
                                },
                              );
                            },
                          ),
                          _DrawerDivider(isDark: isDark),

                          // Language
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.language_rounded, color: accent, size: 22),
                                const SizedBox(width: 14),
                                Text(
                                  AppLocalizations.translate('sidebar_language'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                                  ),
                                  child: DropdownButton<String>(
                                    value: locale,
                                    dropdownColor: isDark ? AppTheme.surfaceColor : Colors.white,
                                    underline: const SizedBox(),
                                    icon: Icon(Icons.arrow_drop_down_rounded, color: accent),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 14,
                                    ),
                                    onChanged: (v) {
                                      if (v != null) AppLocalizations.currentLocale.value = v;
                                    },
                                    items: const [
                                      DropdownMenuItem(value: 'en', child: Text('English')),
                                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                                      DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                                      DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Logout
                          if (role != 'unauthenticated') ...[
                            _DrawerDivider(isDark: isDark),
                            _DrawerItem(
                              icon: Icons.logout_rounded,
                              label: AppLocalizations.translate('sidebar_logout'),
                              accent: AppTheme.errorNeon,
                              isDark: isDark,
                              onTap: () => _confirmLogout(context, isDark),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Bottom label ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Text(
                        'HERO-IE  ·  v1.0.0',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.errorNeon.withValues(alpha: 0.3)),
        ),
        title: Text(
          AppLocalizations.translate('sidebar_logout_confirm_title'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          AppLocalizations.translate('sidebar_logout_confirm_body'),
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dContext).pop(),
            child: Text(
              AppLocalizations.translate('sidebar_no'),
              style: const TextStyle(color: Colors.grey, fontFamily: 'Outfit'),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dContext).pop();
              await AuthService.signOut();
              if (context.mounted) context.go('/');
            },
            child: const Text(
              'Yes, Logout',
              style: TextStyle(
                color: AppTheme.errorNeon,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWER ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _pressing
              ? widget.accent.withValues(alpha: 0.10)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.accent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.isDark ? Colors.white24 : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWER TOGGLE
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DrawerToggle({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerDivider extends StatelessWidget {
  final bool isDark;
  const _DrawerDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DRAWER HEX PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DrawerHexPainter extends CustomPainter {
  final bool isDark;
  _DrawerHexPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark ? AppTheme.primaryNeon : AppTheme.primaryLight;
    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.08 : 0.22)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    const double sqrt3  = 1.7320508;
    const double hexSize = 34.0;
    const double w      = hexSize * 2;
    const double h      = hexSize * sqrt3;

    for (double row = -1; row < (size.height / h) + 2; row++) {
      for (double col = -1; col < (size.width / (w * 0.75)) + 2; col++) {
        final bool isOdd = col.toInt() % 2 == 1;
        final cx = col * (w * 0.75);
        final cy = row * h + (isOdd ? h / 2 : 0);
        _hex(canvas, cx, cy, hexSize * 0.85, paint);
      }
    }
  }

  void _hex(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(a);
      final y = cy + r * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawerHexPainter old) => old.isDark != isDark;
}
