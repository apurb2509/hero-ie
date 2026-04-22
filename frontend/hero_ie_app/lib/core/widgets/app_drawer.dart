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
    bool isLight = Theme.of(context).brightness == Brightness.light;
    Color iconColor = isLight ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon;

    return Drawer(
      backgroundColor: isLight ? AppTheme.backgroundLight : AppTheme.backgroundMatte,
      child: ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.currentLocale,
        builder: (context, locale, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : AppTheme.surfaceColor,
                  border: Border(bottom: BorderSide(color: iconColor.withOpacity(0.5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.shield_moon, size: 48, color: iconColor),
                    const SizedBox(height: 12),
                    Text(
                      role == 'unauthenticated' ? AppLocalizations.translate('app_title') : (role == 'staff' ? AppLocalizations.translate('sidebar_staff_portal') : AppLocalizations.translate('sidebar_guest_portal')),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings
              if (role != 'unauthenticated') ...[
                ListTile(
                  leading: Icon(Icons.person, color: iconColor),
                  title: Text(AppLocalizations.translate('sidebar_profile_settings'), style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
                  onTap: () {
                    context.pop(); // Close drawer
                    context.push('/settings');
                  },
                ),
                const Divider(color: Colors.grey),
              ],

              // Theme Toggle
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.themeNotifier,
                builder: (context, currentMode, _) {
                  bool isDark = currentMode == ThemeMode.dark;
                  return SwitchListTile(
                    activeColor: iconColor,
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: iconColor),
                    title: Text(AppLocalizations.translate('sidebar_dark_mode'), style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
                    value: isDark,
                    onChanged: (value) {
                      AppTheme.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                    },
                  );
                }
              ),

              const Divider(color: Colors.grey),
              
              // Language Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.language, color: iconColor),
                    const SizedBox(width: 16),
                    Text(AppLocalizations.translate('sidebar_language'), style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isLight ? Colors.white : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: iconColor.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: locale,
                        dropdownColor: isLight ? Colors.white : AppTheme.surfaceColor,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: iconColor),
                        style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            AppLocalizations.currentLocale.value = newValue;
                          }
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
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.errorNeon),
                  title: Text(AppLocalizations.translate('sidebar_logout'), style: const TextStyle(color: AppTheme.errorNeon, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext dContext) {
                        return AlertDialog(
                          backgroundColor: isLight ? Colors.white : AppTheme.backgroundMatte,
                          title: Text(AppLocalizations.translate('sidebar_logout_confirm_title'), style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
                          content: Text(AppLocalizations.translate('sidebar_logout_confirm_body'), style: TextStyle(color: isLight ? Colors.black87 : Colors.white)),
                          actions: [
                            TextButton(
                              child: Text(AppLocalizations.translate('sidebar_no'), style: const TextStyle(color: Colors.grey)),
                              onPressed: () {
                                Navigator.of(dContext).pop(); // Dismiss
                              },
                            ),
                            TextButton(
                              child: Text(AppLocalizations.translate('sidebar_yes'), style: const TextStyle(color: AppTheme.errorNeon)),
                              onPressed: () async {
                                Navigator.of(dContext).pop(); // Dismiss dialog
                                await AuthService.signOut();
                                if (context.mounted) {
                                  context.go('/');
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          );
        }
      ),
    );
  }
}
