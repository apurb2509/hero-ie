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

class _AuthScreenState extends State<AuthScreen> {
  bool _otpSent = false;
  bool _phoneMode = false;
  bool _emailMode = false;
  bool _isSignUp = true; // Toggle between Login and Sign-up

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController(); // Handles Email or Phone
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  late String _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _otpSent = false;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuthAction() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // Sign-up requires OTP first
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
        // Login directly with password
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final success = await AuthService.verifyOTP(
      phoneNumber: _phoneMode ? _identifierController.text : null,
      email: _emailMode ? _identifierController.text : null,
      otp: _otpController.text,
      role: _currentRole,
      fullName: _nameController.text,
      password: _passwordController.text,
    );

    if (success) {
      if (mounted) {
        context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification Failed')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    
    // Use darker variants for light theme, else use the bright neons
    Color accentColor = isLight ? Theme.of(context).colorScheme.primary : AppTheme.primaryNeon;
    if (_isSignUp) {
      // For sign up, if light mode, use a slightly darker purple
      accentColor = isLight ? Colors.deepPurpleAccent : AppTheme.secondaryNeon;
    }
    
    String title = _isSignUp ? 'Sign Up' : 'Log In';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Theme.of(context).brightness == Brightness.light ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.5)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_phoneMode ? Icons.phone_android : (_emailMode ? Icons.email : Icons.security), 
                        size: 48, color: accentColor),
                    const SizedBox(height: 16),
                    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    
                    if (!_phoneMode && !_emailMode) ...[
                      _buildGoogleButton(),
                      const SizedBox(height: 16),
                      _buildChannelToggle('Email', Icons.email, () => setState(() => _emailMode = true), accentColor),
                      const SizedBox(height: 16),
                      _buildChannelToggle('Phone', Icons.phone, () => setState(() => _phoneMode = true), accentColor),
                    ] else if (!_otpSent) ...[
                      _buildCredentialInput(accentColor, context),
                    ] else ...[
                      _buildOTPInput(accentColor, context),
                    ],

                    if (_isLoading) Padding(padding: const EdgeInsets.only(top: 24), child: CircularProgressIndicator(color: accentColor)),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() { _phoneMode = false; _emailMode = false; _otpSent = false; }),
                          child: Text('Back', style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white30)),
                        ),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(_isSignUp ? 'Already have an account? Log In' : 'New? Sign up', style: TextStyle(color: accentColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialInput(Color accentColor, BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      children: [
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
            enableInteractiveSelection: true,
            decoration: AppTheme.inputDecoration('Full Name', focusColor: accentColor, isLightMode: isLight).copyWith(prefixIcon: Icon(Icons.person, color: accentColor)),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _identifierController,
          style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
          keyboardType: _emailMode ? TextInputType.emailAddress : TextInputType.phone,
          enableInteractiveSelection: true,
          decoration: AppTheme.inputDecoration(_emailMode ? 'Email Address' : 'Phone Number', focusColor: accentColor, isLightMode: isLight).copyWith(
            prefixIcon: Icon(_emailMode ? Icons.email : Icons.phone, color: accentColor),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
          obscureText: _obscurePassword,
          enableInteractiveSelection: true,
          decoration: AppTheme.inputDecoration(_isSignUp ? 'Create password' : 'Password', focusColor: accentColor, isLightMode: isLight).copyWith(
            prefixIcon: Icon(Icons.lock_outline, color: accentColor),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: isLight ? Colors.black54 : Colors.white54),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: isLight ? Colors.white : AppTheme.backgroundMatte,
            minimumSize: const Size(double.infinity, 54)
          ),
          onPressed: _isLoading ? null : _handleAuthAction,
          child: Text(_isSignUp ? 'Verify & Continue' : 'Log In'),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: Image.network('https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png', height: 24),
      label: const Text('Continue with Google'),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
    );
  }

  Widget _buildChannelToggle(String label, IconData icon, VoidCallback onTap, Color accentColor) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54), 
        side: BorderSide(color: accentColor), 
        foregroundColor: accentColor, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildOTPInput(Color accentColor, BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      children: [
        Text('Verify your ${_emailMode ? "Email" : "Phone"}', style: TextStyle(color: isLight ? Colors.black54 : Colors.white70)),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: AppTheme.inputDecoration('6-Digit OTP', focusColor: accentColor, isLightMode: isLight).copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: isLight ? Colors.white : AppTheme.backgroundMatte,
            minimumSize: const Size(double.infinity, 54)
          ),
          onPressed: _isLoading ? null : _handleVerifyOTP,
          child: const Text('Verify & Finish'),
        ),
      ],
    );
  }
}
