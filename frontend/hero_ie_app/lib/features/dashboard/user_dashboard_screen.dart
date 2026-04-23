import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_bar_avatar.dart';
import 'package:go_router/go_router.dart';
import 'sos_form_widget.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _safePathKey = 'no_emergency';
  List<String> _path = [];

  void _getSafePath() async {
    try {
      final response = await ApiService.getEvacuationRoute('Room 204', 'Main Exit');
      setState(() {
        _path = List<String>.from(response['path']);
        _safePathKey = 'safe_path_calculated';
      });
    } catch (e) {
       setState(() {
        _safePathKey = 'connectivity_error';
      });
    }
  }

  void _triggerOneTapSOS() {
    ApiService.reportVitals('Guest_Node', 'Room 204', 120, 'Distress');
     setState(() {
        _safePathKey = 'sos_activated_msg';
     });
     _getSafePath();
  }

  void _handleRichSOS(String text, File? media, bool isVideo) async {
    if (media != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.translate('uploading_ai'))));
      bool success = await ApiService.uploadSOSMedia(text, media, isVideo);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.translate('ai_analysis_received')), backgroundColor: const Color(0xFFFFB347)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.translate('upload_failed')), backgroundColor: Colors.orange));
      }
    }
    _triggerOneTapSOS();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.translate('guest_dashboard')),
            // Removed logout icon; now in Drawer
            actions: [
              // Connection Status Indicator
              ValueListenableBuilder<bool>(
                valueListenable: ApiService.isConnected,
                builder: (context, connected, _) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: connected
                          ? const Color(0xFFFFB347).withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: connected ? const Color(0xFFFFB347) : Colors.red),
                    ),
                    child: Center(
                      child: Text(
                        connected ? AppLocalizations.translate('status_connected') : AppLocalizations.translate('status_offline'),
                        style: TextStyle(color: connected ? const Color(0xFFFFB347) : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(width: 8),
              // User profile avatar — tap to see name + contact
              const AppBarAvatar(),
            ],
          ),
          drawer: const AppDrawer(role: 'guest'),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Safe Path Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _path.isNotEmpty ? AppTheme.warningNeon : Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    ),
                    child: Column(
                      children: [
                         Icon(
                          _path.isNotEmpty ? Icons.directions_run : Icons.check_circle_outline, 
                          color: _path.isNotEmpty ? AppTheme.warningNeon : Theme.of(context).colorScheme.primary, 
                          size: 48
                        ),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.translate(_safePathKey), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        if (_path.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(AppLocalizations.translate('safe_path'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _path.map((node) => Chip(
                              label: Text(node),
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            )).toList(),
                          )
                        ]
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // NEW: Rich Media SOS Chat Form
                  SOSFormWidget(onSubmit: _handleRichSOS),
                  
                  const SizedBox(height: 32),
                  
                  // RETAINED: Quick One-Tap SOS
                  SizedBox(
                    height: 80,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorNeon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded, size: 32),
                      label: Text(AppLocalizations.translate('sos_button'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      onPressed: _triggerOneTapSOS,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
