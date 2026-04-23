import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'package:go_router/go_router.dart';

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
          // ── Hex-mesh background (same as landing) ──────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF080D08), Color(0xFF1A1200), Color(0xFF080D08)]
                    : const [Color(0xFFFFF9F0), Color(0xFFFFF3E0), Color(0xFFFFFBF0)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => CustomPaint(
              painter: _AuthHexPainter(progress: _bgController.value, isDark: isDark),
              child: const SizedBox.expand(),
            ),
          ),
          // Radial glow behind card — auth accent colour
          Center(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    radius: 0.5,
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
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.72),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.12),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
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
                                color: accent.withValues(alpha: 0.12),
                                border: Border.all(color: accent.withValues(alpha: 0.45)),
                              ),
                              child: Icon(
                                _phoneMode
                                    ? Icons.phone_android_rounded
                                    : (_emailMode
                                        ? Icons.email_rounded
                                        : Icons.shield_rounded),
                                size: 32,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: isDark
                                    ? [accent, accent.withValues(alpha: 0.7)]
                                    : [accent, accent],
                              ).createShader(b),
                              child: Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? 'Register to HERO-IE system'
                                  : 'Sign in to continue',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.4),
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
                                label: 'Continue with Email',
                                icon: Icons.email_rounded,
                                accent: accent,
                                isDark: isDark,
                                onTap: () => setState(() => _emailMode = true),
                              ),
                              const SizedBox(height: 10),
                              _ChannelButton(
                                label: 'Continue with Phone',
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
                                    'Back',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isDark ? Colors.white30 : Colors.black38,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _toggleMode,
                                  child: Text(
                                    _isSignUp ? 'Have account? Log In' : 'New? Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
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
              fontFamily: 'Outfit',
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
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        icon: Image.network(
          'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
          height: 22,
        ),
        label: const Text('Continue with Google'),
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
              foregroundColor: isDark ? AppTheme.backgroundMatte : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.8,
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
            fontFamily: 'Outfit',
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
                fontFamily: 'Outfit',
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
        fontFamily: 'Outfit',
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white38 : Colors.black38,
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
          borderRadius: BorderRadius.circular(14),
          color: widget.isDark
              ? widget.accent.withValues(alpha: _pressing ? 0.12 : 0.06)
              : widget.accent.withValues(alpha: _pressing ? 0.1 : 0.05),
          border: Border.all(
            color: widget.accent.withValues(alpha: _pressing ? 0.55 : 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: widget.accent, size: 20),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BACKGROUND HEX PAINTER (same algorithm as landing)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthHexPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AuthHexPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Use auth accent colour tint for the hex mesh
    final meshColor = isDark
        ? const Color(0xFFFFB347)
        : const Color(0xFFE59A2A); 

    final linePaint = Paint()
      ..color = meshColor.withValues(alpha: isDark ? 0.08 : 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = meshColor.withValues(alpha: isDark ? 0.25 : 0.35)
      ..style = PaintingStyle.fill;

    const double sqrt3  = 1.7320508;
    const double hexSize = 40.0;
    const double w      = hexSize * 2;
    const double h      = hexSize * sqrt3;

    final double ox = (size.width * 0.03) * sin(progress * 2 * pi);
    final double oy = (size.height * 0.02) * cos(progress * 2 * pi);

    for (double row = -1; row < (size.height / h) + 2; row++) {
      for (double col = -1; col < (size.width / (w * 0.75)) + 2; col++) {
        final bool isOdd = col.toInt() % 2 == 1;
        final double cx = col * (w * 0.75) + ox;
        final double cy = row * h + (isOdd ? h / 2 : 0) + oy;

        _drawHexagon(canvas, cx, cy, hexSize * 0.85, linePaint);

        for (int i = 0; i < 6; i++) {
          final angle = (pi / 3) * i - pi / 6;
          canvas.drawCircle(
            Offset(cx + hexSize * 0.85 * cos(angle), cy + hexSize * 0.85 * sin(angle)),
            1.0,
            dotPaint,
          );
        }
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
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
  bool shouldRepaint(covariant _AuthHexPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
