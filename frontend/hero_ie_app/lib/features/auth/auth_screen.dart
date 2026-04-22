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
    String title = _isSignUp ? 'Sign Up' : 'Log In';
    Color accentColor = _isSignUp ? AppTheme.secondaryNeon : AppTheme.primaryNeon;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.8),
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
                      _buildCredentialInput(accentColor),
                    ] else ...[
                      _buildOTPInput(accentColor),
                    ],

                    if (_isLoading) Padding(padding: const EdgeInsets.only(top: 24), child: CircularProgressIndicator(color: accentColor)),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() { _phoneMode = false; _emailMode = false; _otpSent = false; }),
                          child: const Text('Back', style: TextStyle(color: Colors.white30)),
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

  Widget _buildCredentialInput(Color accentColor) {
    return Column(
      children: [
        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: AppTheme.inputDecoration('Full Name', focusColor: accentColor).copyWith(prefixIcon: Icon(Icons.person, color: accentColor)),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _identifierController,
          style: const TextStyle(color: Colors.white),
          keyboardType: _emailMode ? TextInputType.emailAddress : TextInputType.phone,
          decoration: AppTheme.inputDecoration(_emailMode ? 'Email Address' : 'Phone Number', focusColor: accentColor).copyWith(
            prefixIcon: Icon(_emailMode ? Icons.email : Icons.phone, color: accentColor),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          obscureText: true,
          decoration: AppTheme.inputDecoration(_isSignUp ? 'Create password' : 'Password', focusColor: accentColor).copyWith(
            prefixIcon: Icon(Icons.lock_outline, color: accentColor),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: AppTheme.backgroundMatte,
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

  Widget _buildOTPInput(Color accentColor) {
    return Column(
      children: [
        Text('Verify your ${_emailMode ? "Email" : "Phone"}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: AppTheme.inputDecoration('6-Digit OTP', focusColor: accentColor).copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: AppTheme.backgroundMatte,
            minimumSize: const Size(double.infinity, 54)
          ),
          onPressed: _isLoading ? null : _handleVerifyOTP,
          child: const Text('Verify & Finish'),
        ),
      ],
    );
  }
}
