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
          // ── Background: Clean SaaS Fluid ───────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.backgroundMatte : AppTheme.backgroundLight,
            ),
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
                              color: Theme.of(context).cardTheme.color,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.dashboard_customize_rounded, size: 28, color: accent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.translate('app_title'),
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role == 'staff'
                                ? AppLocalizations.translate('sidebar_staff_portal')
                                : (role == 'guest' ? AppLocalizations.translate('sidebar_guest_portal') : AppLocalizations.translate('emergency_system')),
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                          ValueListenableBuilder<AppThemeType>(
                            valueListenable: AppTheme.themeNotifier,
                            builder: (context, currentType, _) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.palette_rounded, color: accent, size: 22),
                                    const SizedBox(width: 14),
                                    Text(
                                      AppLocalizations.translate('sidebar_theme'),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    DropdownButton<AppThemeType>(
                                      value: currentType,
                                      dropdownColor: Theme.of(context).cardTheme.color,
                                      underline: const SizedBox(),
                                      icon: Icon(Icons.arrow_drop_down_rounded, color: accent),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      onChanged: (AppThemeType? newTheme) {
                                        if (newTheme != null) {
                                          AppTheme.themeNotifier.value = newTheme;
                                        }
                                      },
                                      items: AppThemeType.values.map((theme) {
                                        return DropdownMenuItem<AppThemeType>(
                                          value: theme,
                                          child: Text(theme.title.toUpperCase()),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
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
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                    dropdownColor: Theme.of(context).cardTheme.color,
                                    underline: const SizedBox(),
                                    icon: Icon(Icons.arrow_drop_down_rounded, color: accent),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Theme.of(context).colorScheme.onSurface,
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
                        AppLocalizations.translate('emergency_response_system') ?? 'Emergency Response System',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.errorNeon.withValues(alpha: 0.3)),
        ),
        title: Text(
          AppLocalizations.translate('sidebar_logout_confirm_title'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          AppLocalizations.translate('sidebar_logout_confirm_body'),
          style: TextStyle(
            fontFamily: 'Inter',
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
            child: Text(
              'Yes, Logout',
              style: TextStyle(
                color: AppTheme.errorNeon,
                fontFamily: 'Plus Jakarta Sans',
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
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
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
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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

