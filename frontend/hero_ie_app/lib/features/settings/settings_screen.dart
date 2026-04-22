import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _canEditName = true;
  String _nameCooldownMessage = '';
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();

  Future<void> _loadSettings() async {
    final user = AuthService.currentUser;
    if (user == null) {
      context.go('/');
      return;
    }
    
    _contactController.text = user.email ?? user.phone ?? 'Unknown Contact';
    
    try {
      // First, initialize from basic auth metadata
      _nameController.text = user.userMetadata?['full_name'] ?? '';

      // Fetch from settings table
      final settings = await AuthService.getUserSettings().timeout(const Duration(seconds: 5));
      if (settings != null) {
        _nameController.text = settings['full_name'] ?? _nameController.text;
        _dobController.text = settings['dob'] ?? '';
        _address1Controller.text = settings['address_line1'] ?? '';
        _address2Controller.text = settings['address_line2'] ?? '';
        _pincodeController.text = settings['pincode'] ?? '';
        _heightController.text = settings['height'] ?? '';
        _bloodGroupController.text = settings['blood_group'] ?? '';
        
        // Calculate 7-day cooldown
        if (settings['last_name_update'] != null) {
          final lastUpdate = DateTime.tryParse(settings['last_name_update'].toString());
          if (lastUpdate != null) {
            final difference = DateTime.now().difference(lastUpdate);
            if (difference.inDays < 7) {
              _canEditName = false;
              _nameCooldownMessage = '${7 - difference.inDays} days left until name change is allowed.';
            }
          }
        }
      }
    } catch (e) {
      print("Settings load error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final data = {
      'full_name': _nameController.text,
      'contact_info': _contactController.text,
      'dob': _dobController.text,
      'address_line1': _address1Controller.text,
      'address_line2': _address2Controller.text,
      'pincode': _pincodeController.text,
      'height': _heightController.text,
      'blood_group': _bloodGroupController.text,
    };
    
    final success = await AuthService.upsertUserSettings(data);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
      if (success) {
        // Reload to update cooldown UI if name was changed
        _loadSettings();
      }
    }
    
    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _dobController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _pincodeController.dispose();
    _heightController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    Color iconColor = isLight ? AppTheme.lightTheme.colorScheme.primary : AppTheme.primaryNeon;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: iconColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  
                  // Read Only Contact
                  TextFormField(
                    controller: _contactController,
                    readOnly: true,
                    style: TextStyle(color: isLight ? Colors.grey.shade600 : Colors.white54),
                    decoration: AppTheme.inputDecoration('Registered Contact (Read-Only)', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.contact_mail, color: isLight ? Colors.grey : Colors.white30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field (Logic restricted)
                  TextFormField(
                    controller: _nameController,
                    readOnly: !_canEditName,
                    style: TextStyle(color: !_canEditName ? (isLight ? Colors.grey.shade500 : Colors.white54) : null),
                    decoration: AppTheme.inputDecoration('Full Name', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.badge, color: !_canEditName ? (isLight ? Colors.grey : Colors.white30) : iconColor),
                      helperText: !_canEditName ? _nameCooldownMessage : 'You can only change your name once every 7 days.',
                      helperStyle: TextStyle(color: !_canEditName ? AppTheme.warningNeon : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Other Fields
                  TextFormField(
                    controller: _dobController,
                    decoration: AppTheme.inputDecoration('Date of Birth (YYYY-MM-DD)', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.calendar_today, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _bloodGroupController,
                    decoration: AppTheme.inputDecoration('Blood Group', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.bloodtype, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _heightController,
                    decoration: AppTheme.inputDecoration('Height (e.g. 175 cm)', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.height, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _address1Controller,
                    decoration: AppTheme.inputDecoration('Address Line 1', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.home, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _address2Controller,
                    decoration: AppTheme.inputDecoration('Address Line 2 (Optional)', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.home_work, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration('Pincode / Zip Code', focusColor: iconColor, isLightMode: isLight).copyWith(
                      prefixIcon: Icon(Icons.pin_drop, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: iconColor,
                      foregroundColor: isLight ? Colors.white : AppTheme.backgroundMatte,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
}
