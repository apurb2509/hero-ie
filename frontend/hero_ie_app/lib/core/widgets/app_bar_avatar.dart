import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Circular avatar in the AppBar.
/// Subscribes to [AuthService.avatarNotifier] — updates in real-time whenever
/// a new photo is saved anywhere in the app.
class AppBarAvatar extends StatefulWidget {
  const AppBarAvatar({super.key});

  @override
  State<AppBarAvatar> createState() => _AppBarAvatarState();
}

class _AppBarAvatarState extends State<AppBarAvatar> {
  String _name    = '';
  String _contact = '';
  String? _remoteUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name    = await AuthService.getLocalName();
    final contact = await AuthService.getLocalContact();
    final settings = await AuthService.getLocalSettings();
    final supa    = AuthService.currentUser;

    if (!mounted) return;
    setState(() {
      _name      = name    ?? supa?.userMetadata?['full_name'] ?? 'User';
      _contact   = contact ?? supa?.email ?? supa?.phone ?? '';
      _remoteUrl = settings['avatar_url']?.toString();
    });
  }

  /// Priority: Local path from notifier > Remote URL fallback > Default Icon
  Widget _buildAvatar(String? localPath, double radius, {Color? tint}) {
    ImageProvider? img;
    if (localPath != null && File(localPath).existsSync()) {
      img = FileImage(File(localPath));
    } else if (_remoteUrl != null && _remoteUrl!.isNotEmpty) {
      img = NetworkImage(_remoteUrl!);
    }

    if (img != null) {
      return ClipOval(
        child: Image(
          image: img,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Key with localPath forces a full redraw when the photo changes
          key: ValueKey(localPath ?? _remoteUrl ?? 'avatar'),
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius, color: tint),
        ),
      );
    }

    return Icon(Icons.person, size: radius, color: tint);
  }

  void _showProfileCard(BuildContext ctx, String? localPath) {
    // Re-load user info before showing card to ensure name/contact are latest too
    _loadUserInfo();

    final isLight  = Theme.of(ctx).brightness == Brightness.light;
    final primary  = isLight ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon;
    final bg       = isLight ? Colors.white : AppTheme.surfaceColor;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final dimColor  = isLight ? Colors.black54 : Colors.white70;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 48,
                backgroundColor: primary.withOpacity(0.15),
                child: _buildAvatar(localPath, 48, tint: primary),
              ),
              const SizedBox(height: 16),
              Text(
                _name.isNotEmpty ? _name : 'User',
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (_contact.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _contact.contains('@') ? Icons.email_outlined : Icons.phone_outlined,
                      size: 16, color: primary,
                    ),
                    const SizedBox(width: 6),
                    Text(_contact, style: TextStyle(color: dimColor, fontSize: 14)),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primary = isLight ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon;

    return ValueListenableBuilder<String?>(
      valueListenable: AuthService.avatarNotifier,
      builder: (ctx, localPath, _) {
        return GestureDetector(
          onTap: () => _showProfileCard(ctx, localPath),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: primary.withOpacity(0.2),
              // Use explicit Image widget with ClipOval to force real-time redraw
              child: _buildAvatar(localPath, 17, tint: primary),
            ),
          ),
        );
      },
    );
  }
}
