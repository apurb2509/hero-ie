import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  final String initialRole;
  const AuthScreen({super.key, required this.initialRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _otpSent     = false;
  bool _phoneMode   = false;
  bool _emailMode   = false;
  bool _isSignUp    = true;

  final TextEditingController _nameController       = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _otpController        = TextEditingController();
  final TextEditingController _passwordController   = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;
  late String _currentRole;

  late AnimationController _bgController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() {
        _isSignUp = !_isSignUp;
        _otpSent  = false;
      });

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
      }
    } catch (e) {
      _snack('Google Sign-In Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthAction() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final success = await AuthService.sendOTP(
          phone: _phoneMode ? _identifierController.text : null,
          email: _emailMode ? _identifierController.text : null,
        );
        if (success) {
          setState(() => _otpSent = true);
        } else {
          throw 'Failed to send OTP';
        }
      } else {
        final success = await AuthService.signInWithPassword(
          _identifierController.text,
          _passwordController.text,
        );
        if (success) {
          if (mounted) context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
        } else {
          throw 'Invalid ID or Password';
        }
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final success = await AuthService.verifyOTP(
      phoneNumber: _phoneMode ? _identifierController.text : null,
      email:       _emailMode ? _identifierController.text : null,
      otp:         _otpController.text,
      role:        _currentRole,
      fullName:    _nameController.text,
      password:    _passwordController.text,
    );
    if (success) {
      if (mounted) context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
    } else {
      _snack('Verification Failed');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final accent   = AppTheme.authAccent(context);   // amber-gold or indigo

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Clean Fluid SaaS Background ──────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.backgroundMatte : AppTheme.backgroundLight,
            ),
          ),
          
          // Subtle radial glow
          Center(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentSoft(context).withValues(alpha: isDark ? 0.05 : 0.03),
                      Colors.transparent,
                    ],
                    radius: 0.6,
                  ),
                ),
              ),
            ),
          ),

          // ── Frosted card ────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: AppTheme.surfaceColor.withValues(alpha: 0.7),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.backgroundMatte,
                                border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: Icon(
                                _phoneMode
                                    ? Icons.phone_android_rounded
                                    : (_emailMode
                                        ? Icons.email_rounded
                                        : Icons.dashboard_customize_rounded),
                                size: 32,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              _isSignUp ? 'Create Account' : 'Welcome Back',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? 'Register to HERO-IE system'
                                  : AppLocalizations.translate('sign_in_to_continue'),
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Content
                            if (!_phoneMode && !_emailMode) ...[
                              _buildGoogleButton(isDark, accent),
                              const SizedBox(height: 14),
                              _buildDivider(isDark),
                              const SizedBox(height: 14),
                              _ChannelButton(
                                label: AppLocalizations.translate('continue_with_email'),
                                icon: Icons.email_rounded,
                                accent: accent,
                                isDark: isDark,
                                onTap: () => setState(() => _emailMode = true),
                              ),
                              const SizedBox(height: 10),
                              _ChannelButton(
                                label: AppLocalizations.translate('continue_with_phone'),
                                icon: Icons.phone_rounded,
                                accent: accent,
                                isDark: isDark,
                                onTap: () => setState(() => _phoneMode = true),
                              ),
                            ] else if (!_otpSent) ...[
                              _buildCredentialInput(accent, isDark),
                            ] else ...[
                              _buildOTPInput(accent, isDark),
                            ],

                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                              ),

                            const SizedBox(height: 20),
                            // Bottom row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => setState(() {
                                    _phoneMode = false;
                                    _emailMode = false;
                                    _otpSent   = false;
                                  }),
                                  child: Text(
                                    AppLocalizations.translate('back_btn'),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: isDark ? Colors.white30 : Colors.black38,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _toggleMode,
                                  child: Text(
                                    _isSignUp ? AppLocalizations.translate('have_account_login') : AppLocalizations.translate('new_sign_up'),
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w600,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              letterSpacing: 1.5,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
      ],
    );
  }

  Widget _buildGoogleButton(bool isDark, Color accent) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF09090B),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E4E7)),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        icon: Image.network(
          'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
          height: 22,
        ),
        label: Text(AppLocalizations.translate('continue_with_google')),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
      ),
    );
  }

  Widget _buildCredentialInput(Color accent, bool isDark) {
    return Column(
      children: [
        if (_isSignUp) ...[
          _AuthField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
        ],
        _AuthField(
          controller: _identifierController,
          label: _emailMode ? 'Email Address' : 'Phone Number',
          icon: _emailMode ? Icons.email_rounded : Icons.phone_rounded,
          accent: accent,
          isDark: isDark,
          keyboardType: _emailMode ? TextInputType.emailAddress : TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _passwordController,
          label: _isSignUp ? 'Create Password' : 'Password',
          icon: Icons.lock_rounded,
          accent: accent,
          isDark: isDark,
          obscure: _obscurePassword,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: _isLoading ? null : _handleAuthAction,
            child: Text(_isSignUp ? 'Verify & Continue' : 'Log In'),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput(Color accent, bool isDark) {
    return Column(
      children: [
        Text(
          'Enter the 6-digit code sent to your ${_emailMode ? "email" : "phone"}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 26,
            letterSpacing: 10,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isDark
                ? accent.withValues(alpha: 0.06)
                : accent.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: isDark ? AppTheme.backgroundMatte : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
            onPressed: _isLoading ? null : _handleVerifyOTP,
            child: const Text('Verify & Finish'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AUTH FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enableInteractiveSelection: true,
      style: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: accent, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: isDark
            ? accent.withValues(alpha: 0.06)
            : accent.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHANNEL BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ChannelButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _ChannelButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ChannelButton> createState() => _ChannelButtonState();
}

class _ChannelButtonState extends State<_ChannelButton> {
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isDark
              ? const Color(0xFF27272A).withValues(alpha: _pressing ? 0.8 : 0.4)
              : const Color(0xFFF4F4F5).withValues(alpha: _pressing ? 0.8 : 0.4),
          border: Border.all(
            color: widget.isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Theme.of(context).colorScheme.onSurface, size: 18),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


