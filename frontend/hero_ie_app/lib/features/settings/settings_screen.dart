import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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

  // ── Avatar ──────────────────────────────────────────
  /// Cropped local file chosen this session (not yet saved)
  File? _pendingAvatarFile;

  /// Permanent local path saved from a previous session
  String? _localAvatarPath;

  /// Remote URL (from Supabase) from a previous session
  String? _remoteAvatarUrl;

  // ── Blood group ─────────────────────────────────────
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  String? _selectedBloodGroup;

  // ── DOB ─────────────────────────────────────────────
  DateTime? _selectedDob;
  final TextEditingController _dobDisplayController = TextEditingController();

  // ── Height ──────────────────────────────────────────
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFtController = TextEditingController();
  final TextEditingController _heightInController = TextEditingController();
  bool _heightLock = false;

  // ── Other fields ────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // ──────────────────────────────────────────────────────
  // Height conversion
  // ──────────────────────────────────────────────────────
  void _cmChanged() {
    if (_heightLock) return;
    final cm = double.tryParse(_heightCmController.text.trim());
    if (cm == null || cm <= 0) return;
    _heightLock = true;
    final totalIn = cm / 2.54;
    _heightFtController.text = (totalIn ~/ 12).toString();
    _heightInController.text = (totalIn % 12).round().toString();
    _heightLock = false;
  }

  void _ftInChanged() {
    if (_heightLock) return;
    final ft = double.tryParse(_heightFtController.text.trim()) ?? 0;
    final inches = double.tryParse(_heightInController.text.trim()) ?? 0;
    if (ft == 0 && inches == 0) return;
    _heightLock = true;
    _heightCmController.text =
        ((ft * 12 + inches) * 2.54).roundToDouble().toStringAsFixed(0);
    _heightLock = false;
  }

  // ──────────────────────────────────────────────────────
  // DOB helpers
  // ──────────────────────────────────────────────────────
  String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  void _applyDob(DateTime? d) {
    _selectedDob = d;
    _dobDisplayController.text = d != null ? _formatDob(d) : '';
  }

  // ──────────────────────────────────────────────────────
  // Apply settings map to UI
  // ──────────────────────────────────────────────────────
  void _applySettings(Map<String, dynamic> s) {
    if ((s['full_name'] ?? '').toString().isNotEmpty) {
      _nameController.text = s['full_name'];
    }
    if ((s['contact_info'] ?? '').toString().isNotEmpty) {
      _contactController.text = s['contact_info'];
    }
    final dobStr = s['dob']?.toString();
    _applyDob(dobStr != null ? DateTime.tryParse(dobStr) : null);

    final bg = s['blood_group']?.toString();
    _selectedBloodGroup = _bloodGroups.contains(bg) ? bg : null;

    final cm = s['height_cm']?.toString() ?? '';
    if (cm.isNotEmpty) {
      _heightCmController.text = cm;
      _cmChanged();
    }
    _address1Controller.text = s['address_line1'] ?? '';
    _address2Controller.text = s['address_line2'] ?? '';
    _pincodeController.text = s['pincode'] ?? '';

    // Avatar URL (remote)
    final url = s['avatar_url']?.toString();
    if (url != null && url.isNotEmpty) _remoteAvatarUrl = url;
  }

  // ──────────────────────────────────────────────────────
  // Load (instant from cache, optional Supabase enrich)
  // ──────────────────────────────────────────────────────
  Future<void> _loadSettings() async {
    // 1. Auth session basics
    final localName = await AuthService.getLocalName();
    final localContact = await AuthService.getLocalContact();
    final supaUser = AuthService.currentUser;

    _nameController.text =
        localName ?? supaUser?.userMetadata?['full_name'] ?? '';
    _contactController.text =
        localContact ?? supaUser?.email ?? supaUser?.phone ?? '';

    // 2. All locally-cached profile fields (instant)
    final local = await AuthService.getLocalSettings();
    if (local.isNotEmpty) _applySettings(local);

    // 3. Local avatar file (persisted across sessions)
    final localAvatarPath = await AuthService.getLocalAvatarPath();
    if (localAvatarPath != null) _localAvatarPath = localAvatarPath;

    // Show form immediately
    if (mounted) setState(() => _isLoading = false);

    // 4. Background Supabase enrich (Supabase-session users only)
    if (supaUser == null) return;
    try {
      final s = await AuthService.getUserSettings()
          .timeout(const Duration(seconds: 8));
      if (s == null || !mounted) return;
      setState(() {
        _applySettings(s);
        final lastUpdate =
            DateTime.tryParse(s['last_name_update']?.toString() ?? '');
        if (lastUpdate != null) {
          final diff = DateTime.now().difference(lastUpdate);
          if (diff.inDays < 7) {
            _canEditName = false;
            _nameCooldownMessage =
                '${7 - diff.inDays} days left until name change is allowed.';
          }
        }
      });
    } on TimeoutException {
      debugPrint('Settings Supabase fetch timed out.');
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  // ──────────────────────────────────────────────────────
  // Save
  // ──────────────────────────────────────────────────────
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final dob = _selectedDob?.toIso8601String().split('T').first;
    final bloodGroup = _selectedBloodGroup;
    final heightCm = _heightCmController.text.trim();
    final heightFt = _heightFtController.text.trim();
    final heightIn = _heightInController.text.trim();
    final addr1 = _address1Controller.text.trim();
    final addr2 = _address2Controller.text.trim();
    final pincode = _pincodeController.text.trim();

    setState(() => _isSaving = true);

    // Upload avatar if a new one was chosen
    String? newAvatarUrl = _remoteAvatarUrl;
    if (_pendingAvatarFile != null) {
      final uploaded =
          await AuthService.uploadProfilePhoto(_pendingAvatarFile!.path);
      // uploadProfilePhoto always saves locally; cloud URL returned if session exists
      if (uploaded != null) newAvatarUrl = uploaded;
      // Refresh local path
      _localAvatarPath = await AuthService.getLocalAvatarPath();
    }

    final data = <String, dynamic>{
      'full_name': name,
      'contact_info': contact,
      if (dob != null) 'dob': dob,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (heightCm.isNotEmpty) 'height_cm': heightCm,
      if (heightFt.isNotEmpty || heightIn.isNotEmpty)
        'height_ftin': '${heightFt}ft ${heightIn}in',
      if (addr1.isNotEmpty) 'address_line1': addr1,
      if (addr2.isNotEmpty) 'address_line2': addr2,
      if (pincode.isNotEmpty) 'pincode': pincode,
      if (newAvatarUrl != null && newAvatarUrl.isNotEmpty)
        'avatar_url': newAvatarUrl,
    };

    final success = await AuthService.upsertUserSettings(data);

    if (!mounted) return;

    // Restore snapshots so fields never flash empty after rebuild
    _nameController.text = name;
    _contactController.text = contact;
    _applyDob(_selectedDob);
    _heightCmController.text = heightCm;
    _heightFtController.text = heightFt;
    _heightInController.text = heightIn;
    _address1Controller.text = addr1;
    _address2Controller.text = addr2;
    _pincodeController.text = pincode;

    setState(() {
      _isSaving = false;
      if (newAvatarUrl != null) _remoteAvatarUrl = newAvatarUrl;
      _pendingAvatarFile = null; // clear pending — avatar is now committed
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Profile saved!'
            : '❌ Save failed. Please retry.'),
        backgroundColor:
            success ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Photo pick → crop
  // ──────────────────────────────────────────────────────
  Future<void> _pickAndCrop(ImageSource source) async {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primary = isLight
        ? AppTheme.lightTheme.colorScheme.primary
        : AppTheme.primaryNeon;

    // Step 1: Pick from gallery / camera
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    // Step 2: Try to open native crop tool. If it fails for ANY reason
    // (missing UCropActivity, user cancelled, Android version issue),
    // we fall back gracefully to the original picked image.
    File imageToUse = File(picked.path);

    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: primary,
            toolbarWidgetColor: Colors.white,
            statusBarColor: primary,
            activeControlsWidgetColor: primary,
            cropStyle: CropStyle.circle,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            showCropGrid: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      if (cropped != null) {
        imageToUse = File(cropped.path);
      }
      // If cropped == null the user cancelled — keep imageToUse as original
    } catch (e) {
      debugPrint('Crop tool error (using original image): $e');
      // imageToUse stays as the original picked file
    }

    if (!mounted) return;

    // Step 3: Immediately upload to Supabase + update notifier.
    // avatarNotifier.value fires inside saveLocalAvatarFile → AppBarAvatar refreshes instantly.
    setState(() => _pendingAvatarFile = imageToUse); // show preview right away

    // Show uploading indicator briefly on the avatar
    final url = await AuthService.uploadProfilePhoto(imageToUse.path);
    if (url != null) {
      // Cloud URL saved — also persist into the settings cache
      await AuthService.upsertUserSettings({'avatar_url': url});
    }
    // Local path is already set in notifier by uploadProfilePhoto → AppBar updated ✅
  }

  // ──────────────────────────────────────────────────────
  // Full-screen photo viewer
  // ──────────────────────────────────────────────────────
  void _viewPhoto() {
    // Resolve current avatar image using the reactive source of truth
    final notifiedPath = AuthService.avatarNotifier.value;
    
    ImageProvider? img;
    if (_pendingAvatarFile != null) {
      img = FileImage(_pendingAvatarFile!);
    } else if (notifiedPath != null && File(notifiedPath).existsSync()) {
      img = FileImage(File(notifiedPath));
    } else if (_remoteAvatarUrl != null && _remoteAvatarUrl!.isNotEmpty) {
      img = NetworkImage(_remoteAvatarUrl!);
    }
    
    if (img == null) return; // nothing to show

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Dismisses on tap outside
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.4,
                  backgroundImage: img,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color ?? (isLight ? Colors.white : AppTheme.surfaceColor),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // View Photo — only if there is an avatar already
            if (_pendingAvatarFile != null ||
                _localAvatarPath != null ||
                _remoteAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.image_search_rounded),
                title: const Text('View Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _viewPhoto();
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(ImageSource.gallery);
              },
            ),
            if (_pendingAvatarFile != null ||
                _localAvatarPath != null ||
                _remoteAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // 1. Clear local session states immediately for "sudden" UI effect
                  setState(() {
                    _pendingAvatarFile = null;
                    _remoteAvatarUrl = null;
                    _localAvatarPath = null;
                  });
                  // 2. Persist removal in cloud & local prefs (this fires the global notifier)
                  await AuthService.removeProfilePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Date picker
  // ──────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (ctx, child) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isLight
                ? ColorScheme.light(
                    primary: Theme.of(ctx).colorScheme.primary)
                : ColorScheme.dark(primary: AppTheme.primaryNeon),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) setState(() => _applyDob(picked));
  }

  // ──────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _heightCmController.addListener(_cmChanged);
    _heightFtController.addListener(_ftInChanged);
    _heightInController.addListener(_ftInChanged);

    // Sync local state when the global avatar changes (updates or removals)
    AuthService.avatarNotifier.addListener(_onAvatarChanged);

    _loadSettings();
  }

  void _onAvatarChanged() {
    if (mounted) {
      setState(() {
        _localAvatarPath = AuthService.avatarNotifier.value;
        // If the notified path is null (removal) or changes, 
        // we must clear the stale remote URL fallback so it doesn't show old data.
        _remoteAvatarUrl = null; 
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _dobDisplayController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _pincodeController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    AuthService.avatarNotifier.removeListener(_onAvatarChanged);
    super.dispose();
  }

  // ──────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primary = isLight
        ? AppTheme.lightTheme.colorScheme.primary
        : AppTheme.primaryNeon;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dimColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    InputDecoration dec(String label, {IconData? icon}) =>
        AppTheme.inputDecoration(label,
                focusColor: primary, isLightMode: isLight)
            .copyWith(
          prefixIcon: icon != null ? Icon(icon, color: primary) : null,
        );


    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Avatar (reactive to notifier) ────────
                    ValueListenableBuilder<String?>(
                      valueListenable: AuthService.avatarNotifier,
                      builder: (_, notifiedPath, __) {
                        // RE-RESOLVE PRIORITY: 
                        // 1. Pending crop file (User pick)
                        // 2. Notified Path (Committed local file)
                        // 3. Remote URL (ONLY as a fallback for initial load if no local file exists)
                        ImageProvider? img;
                        if (_pendingAvatarFile != null) {
                          img = FileImage(_pendingAvatarFile!);
                        } else if (notifiedPath != null &&
                            File(notifiedPath).existsSync()) {
                          img = FileImage(File(notifiedPath));
                        } else if (_remoteAvatarUrl != null &&
                            _remoteAvatarUrl!.isNotEmpty &&
                            notifiedPath == null) {
                          // Only fallback to remote URL if we don't have a local path committed yet
                          img = NetworkImage(_remoteAvatarUrl!);
                        }

                        return Column(
                          children: [
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: _showPhotoOptions,
                                    child: CircleAvatar(
                                      key: ValueKey(
                                        _pendingAvatarFile?.path ??
                                            notifiedPath ??
                                            _remoteAvatarUrl ??
                                            'no-avatar',
                                      ),
                                      radius: 56,
                                      backgroundColor:
                                          primary.withOpacity(0.15),
                                      backgroundImage: img,
                                      child: img == null
                                          ? Icon(Icons.person,
                                              size: 56, color: primary)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: _showPhotoOptions,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: primary,
                                        child: const Icon(Icons.camera_alt,
                                            size: 17, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notifiedPath != null
                                  ? 'Photo saved ✓'
                                  : 'Tap photo to change',
                              style: TextStyle(
                                color: notifiedPath != null ? primary : dimColor,
                                fontSize: 12,
                                fontStyle: notifiedPath != null
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),


                    // ── Contact (read-only) ──────────────────
                    TextFormField(
                      controller: _contactController,
                      readOnly: true,
                      style: TextStyle(color: dimColor),
                      decoration: dec('Registered Contact (Read-Only)')
                          .copyWith(
                              prefixIcon: Icon(Icons.contact_mail,
                                  color: dimColor)),
                    ),
                    const SizedBox(height: 16),

                    // ── Full Name ────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      readOnly: !_canEditName,
                      style: TextStyle(
                          color: !_canEditName ? dimColor : textColor),
                      decoration: dec('Full Name').copyWith(
                        prefixIcon: Icon(Icons.badge,
                            color: !_canEditName ? dimColor : primary),
                        helperText: !_canEditName
                            ? _nameCooldownMessage
                            : 'Name can only be changed every 7 days.',
                        helperStyle: TextStyle(
                            color: !_canEditName
                                ? AppTheme.warningNeon
                                : Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Date of Birth ────────────────────────
                    GestureDetector(
                      onTap: _pickDob,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dobDisplayController,
                          readOnly: true,
                          style: TextStyle(color: textColor),
                          decoration:
                              dec('Date of Birth', icon: Icons.cake)
                                  .copyWith(
                            suffixIcon: Icon(Icons.calendar_month,
                                color: primary),
                            hintText: 'Tap to select',
                            hintStyle: TextStyle(color: dimColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Blood Group ──────────────────────────
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      dropdownColor:
                          isLight ? Colors.white : AppTheme.surfaceColor,
                      decoration:
                          dec('Blood Group', icon: Icons.bloodtype),
                      style: TextStyle(color: textColor, fontSize: 16),
                      icon: Icon(Icons.arrow_drop_down, color: primary),
                      hint: Text('Select blood group',
                          style: TextStyle(color: dimColor)),
                      items: _bloodGroups
                          .map((bg) => DropdownMenuItem(
                                value: bg,
                                child: Text(bg,
                                    style: TextStyle(color: textColor)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBloodGroup = v),
                    ),
                    const SizedBox(height: 20),

                    // ── Height ───────────────────────────────
                    _label('Height', primary),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _heightCmController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(color: textColor),
                            decoration: dec('cm', icon: Icons.height),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 18),
                          child: Text('or',
                              style: TextStyle(
                                  color: dimColor, fontSize: 13)),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _heightFtController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: dec('ft'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _heightInController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: dec('in'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Address ──────────────────────────────
                    TextFormField(
                      controller: _address1Controller,
                      style: TextStyle(color: textColor),
                      decoration:
                          dec('Address Line 1', icon: Icons.home),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _address2Controller,
                      style: TextStyle(color: textColor),
                      decoration: dec('Address Line 2 (Optional)',
                          icon: Icons.home_work),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: dec('Pincode / Zip Code',
                          icon: Icons.pin_drop),
                    ),
                    const SizedBox(height: 32),

                    // ── Save ─────────────────────────────────
                    ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(
                          _isSaving ? 'Saving...' : 'Save Profile'),
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primary,
                        foregroundColor: isLight
                            ? Colors.white
                            : AppTheme.backgroundMatte,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text, Color color) => Row(children: [
        Icon(Icons.height, color: color, size: 16),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]);
}
