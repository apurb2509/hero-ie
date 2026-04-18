import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/nearby_service.dart';

import '../../core/localization/app_localizations.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundMatte, Color(0xFF0F2027)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Language Toggle in Top Right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                      ),
                      child: DropdownButton<String>(
                        value: locale,
                        dropdownColor: AppTheme.surfaceColor,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.language, color: AppTheme.primaryNeon, size: 18),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            AppLocalizations.currentLocale.value = newValue;
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('EN', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'hi', child: Text('HI', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'mr', child: Text('MR', style: TextStyle(color: Colors.white, fontSize: 13))),
                          DropdownMenuItem(value: 'bn', child: Text('BN', style: TextStyle(color: Colors.white, fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_moon, size: 100, color: AppTheme.primaryNeon),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.translate('app_title'),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              letterSpacing: 2,
                              color: AppTheme.primaryNeon,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.translate('app_tagline'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          // The "Check-in to Protect" QR Onboarding Simulation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppLocalizations.translate('role_selection'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person),
                                    label: Text(AppLocalizations.translate('connect_guest')),
                                    onPressed: () async {
                                      // Initialize Nearby connections as User
                                      await NearbyService.startDiscovery('Guest_Node');
                                      if (context.mounted) {
                                        context.go('/user-dashboard');
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryNeon,
                                      side: const BorderSide(color: AppTheme.primaryNeon),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    icon: const Icon(Icons.admin_panel_settings),
                                    label: Text(AppLocalizations.translate('connect_staff')),
                                    onPressed: () async {
                                      // Initialize Nearby connections as Admin/Proxy
                                      await NearbyService.startAdvertising('Staff_Node');
                                      if (context.mounted) {
                                        context.go('/admin-dashboard');
                                      }
                                    },
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
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
