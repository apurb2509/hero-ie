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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late String _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
      }
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOTP() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final success = await AuthService.sendOTP(_phoneController.text);
    if (success) {
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final success = await AuthService.verifyOTP(
      phoneNumber: _phoneController.text,
      otp: _otpController.text,
      role: _currentRole,
      fullName: _nameController.text,
      password: _passwordController.text,
      userId: AuthService.currentUser?.id, 
    );

    if (success) {
      if (mounted) {
        context.go(_currentRole == 'staff' ? '/admin-dashboard' : '/user-dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification Failed. Please try again.')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
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
                margin: const EdgeInsets.symmetric(vertical: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 48, color: AppTheme.primaryNeon),
                    const SizedBox(height: 16),
                    Text(
                      'Verification',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryNeon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete verification to continue as ${_currentRole.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    
                    if (!_phoneMode) ...[
                      _buildGoogleButton(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white10)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12)),
                          ),
                          const Expanded(child: Divider(color: Colors.white10)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildPhoneToggle(),
                    ] else if (!_otpSent) ...[
                      _buildPhoneInput(),
                    ] else ...[
                      _buildOTPInput(),
                    ],
              
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(color: AppTheme.primaryNeon),
                      ),
                    
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        if (_phoneMode && !_otpSent) {
                          setState(() => _phoneMode = false);
                        } else {
                          context.pop();
                        }
                      },
                      child: Text(_phoneMode && !_otpSent ? 'Back to Options' : 'Cancel', 
                        style: const TextStyle(color: Colors.white30)),
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

  Widget _buildGoogleButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Image.network(
        'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
        height: 24,
      ),
      label: const Text('Continue with Google'),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
    );
  }

  Widget _buildPhoneToggle() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: AppTheme.primaryNeon),
        foregroundColor: AppTheme.primaryNeon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.phone_android),
      label: const Text('Verify via Phone OTP'),
      onPressed: () => setState(() => _phoneMode = true),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: AppTheme.inputDecoration('Full Name').copyWith(
            prefixIcon: const Icon(Icons.person, color: AppTheme.primaryNeon),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.phone,
          decoration: AppTheme.inputDecoration('Phone Number').copyWith(
            prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryNeon),
            hintText: '+1234567890',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.white),
          obscureText: true,
          decoration: AppTheme.inputDecoration('Create Password').copyWith(
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryNeon),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
          onPressed: _isLoading ? null : _handleSendOTP,
          child: const Text('Send Verification Code'),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: AppTheme.inputDecoration('6-Digit OTP').copyWith(
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
          ),
          onPressed: _isLoading ? null : _handleVerifyOTP,
          child: const Text('Verify & Finish'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _otpSent = false),
          child: const Text('Change Number', style: TextStyle(color: AppTheme.primaryNeon)),
        ),
      ],
    );
  }
}
