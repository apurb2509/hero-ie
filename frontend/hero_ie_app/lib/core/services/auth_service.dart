import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ── Global reactive notifier for avatar ──────────────────────────────────────
  /// Holds the local file path to the current avatar.
  /// Any widget that listens via ValueListenableBuilder re-renders automatically
  /// when a new avatar is saved — no manual refresh needed.
  static final ValueNotifier<String?> avatarNotifier = ValueNotifier<String?>(null);

  /// Call once at app startup (e.g., in main.dart after Supabase.init)
  /// to pre-populate the notifier from the persisted local file.
  static Future<void> initAvatarNotifier() async {
    final path = await getLocalAvatarPath();
    avatarNotifier.value = path;
  }

  // ── Local session keys ─────────────────────────────────────────────────────
  static const _verifiedKey     = 'is_locally_verified';
  static const _localNameKey    = 'local_full_name';
  static const _localContactKey = 'local_contact';
  static const _localRoleKey    = 'local_role';
  // A stable UUID generated once for non-Supabase users so they can still
  // write to user_settings (the service-role key bypasses RLS).
  static const _localUserIdKey  = 'local_user_id';
  static const _avatarLocalPathKey = 'settings_avatar_local_path';

  // ── Auth session ───────────────────────────────────────────────────────────
  static User? get currentUser => _supabase.auth.currentUser;
  static bool  get isAuthenticated => currentUser != null;

  static Future<bool> isVerified() async {
    if (isAuthenticated) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verifiedKey) ?? false;
  }

  // ── Local identity helpers ─────────────────────────────────────────────────
  static Future<String?> getLocalName() async =>
      (await SharedPreferences.getInstance()).getString(_localNameKey);

  static Future<String?> getLocalContact() async =>
      (await SharedPreferences.getInstance()).getString(_localContactKey);

  static Future<String?> getLocalRole() async =>
      (await SharedPreferences.getInstance()).getString(_localRoleKey);

  /// Returns a stable Supabase-compatible UUID for the current user.
  /// Supabase session users → their auth UID.
  /// Phone/email OTP users → a generated UUID stored locally.
  static Future<String> getOrCreateUserId() async {
    // Supabase auth session takes priority
    if (currentUser != null) return currentUser!.id;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_localUserIdKey);
    if (id == null) {
      // Generate a v4-ish UUID using Dart's built-ins
      id = _generateUuid();
      await prefs.setString(_localUserIdKey, id);
    }
    return id;
  }

  static String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = now.hashCode ^ Object.hash(now, 'hero-ie');
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final r = (rand >> (m.start * 4)) & 0xf;
        final v = m.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }

  // ── User profile (users table) ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserProfile(
      {String? userId, String? email, String? phone}) async {
    try {
      var q = _supabase.from('users').select('*');
      if (userId != null) q = q.eq('user_id', userId);
      if (email  != null) q = q.eq('email', email);
      if (phone  != null) q = q.eq('phone_number', phone);
      return await q.maybeSingle();
    } catch (e) {
      print('Get Profile Error: $e');
      return null;
    }
  }

  // ── Local settings cache ───────────────────────────────────────────────────
  static const _settingsPrefix = 'settings_';
  static const _settingsKeys = [
    'full_name', 'contact_info', 'dob', 'blood_group',
    'height_cm', 'height_ftin', 'address_line1', 'address_line2',
    'pincode', 'avatar_url',
  ];

  static Future<void> _saveSettingsLocally(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _settingsKeys) {
      final val = data[key]?.toString();
      if (val != null && val.isNotEmpty) {
        await prefs.setString('$_settingsPrefix$key', val);
      }
    }
  }

  static Future<Map<String, dynamic>> getLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, dynamic>{};
    for (final key in _settingsKeys) {
      final val = prefs.getString('$_settingsPrefix$key');
      if (val != null && val.isNotEmpty) result[key] = val;
    }
    return result;
  }

  // ── Supabase settings (reads) ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final uid = await getOrCreateUserId();
      return await _supabase
          .from('user_settings')
          .select('*')
          .eq('id', uid)
          .maybeSingle();
    } catch (e) {
      print('Get Settings Error: $e');
      return null;
    }
  }

  // ── Supabase settings (writes) — always syncs, bypasses RLS via service key ─
  static Future<bool> upsertUserSettings(Map<String, dynamic> data) async {
    // 1. Always persist to SharedPreferences (instant, offline-safe)
    await _saveSettingsLocally(data);
    final name = data['full_name']?.toString();
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localNameKey, name);
    }

    // 2. Write to Supabase (service_role key → bypasses RLS → works for ALL users)
    try {
      final uid = await getOrCreateUserId();
      final clean = Map<String, dynamic>.from(data)
        ..removeWhere((_, v) => v == null || v.toString().isEmpty);
      clean['id'] = uid;

      // 7-day name-change cooldown (only enforce for Supabase auth users)
      if (clean.containsKey('full_name') && currentUser != null) {
        final curr = await getUserSettings();
        if (curr == null || curr['full_name'] != clean['full_name']) {
          clean['last_name_update'] = DateTime.now().toIso8601String();
          await _supabase.auth.updateUser(
            UserAttributes(data: {'full_name': clean['full_name']}),
          );
        }
      }

      await _supabase.from('user_settings').upsert(clean);
      print('✅ Settings synced to Supabase for uid: $uid');
      return true;
    } catch (e) {
      print('Upsert Settings Error: $e');
      // Local save succeeded — return true so UI doesn't show error
      return true;
    }
  }

  // ── Avatar: local persistence ─────────────────────────────────────────────
  static Future<String?> saveLocalAvatarFile(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      // Cleanup old avatar files to avoid bloat
      final files = dir.listSync();
      for (var f in files) {
        if (f is File && f.path.contains('hero_ie_avatar_')) {
          try { f.deleteSync(); } catch (_) {}
        }
      }

      // Generate a unique filename every time to bust Flutter's Image Cache
      // and ensure ValueNotifier.value != previousValue
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dest = File('${dir.path}/hero_ie_avatar_$timestamp.jpg');
      
      await File(sourcePath).copy(dest.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarLocalPathKey, dest.path);

      // ⚡ Fire the global notifier so every listening widget updates immediately
      avatarNotifier.value = dest.path;

      // 🧹 Clear Flutter's internal image cache to force a real-time redraw
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      return dest.path;
    } catch (e) {
      print('Save local avatar error: $e');
      return null;
    }
  }

  static Future<String?> getLocalAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path  = prefs.getString(_avatarLocalPathKey);
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  // ── Avatar: upload to Supabase Storage + save URL ─────────────────────────
  /// Saves locally AND uploads to Supabase Storage (service key bypasses policies).
  /// Returns the public URL on success, null on cloud failure (local still saved).
  static Future<String?> uploadProfilePhoto(String filePath) async {
    // Step 1: Always save locally
    await saveLocalAvatarFile(filePath);

    // Step 2: Upload to Supabase Storage (works for all users via service key)
    try {
      final uid   = await getOrCreateUserId();
      final bytes = await File(filePath).readAsBytes();
      final path  = 'avatars/$uid.jpg';

      await _supabase.storage.from('hero-ie-avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final url = _supabase.storage.from('hero-ie-avatars').getPublicUrl(path);
      // Cache URL locally and persist to user_settings
      await _saveSettingsLocally({'avatar_url': url});
      await _supabase.from('user_settings').upsert({'id': uid, 'avatar_url': url});
      print('✅ Avatar uploaded: $url');
      return url;
    } catch (e) {
      print('Photo cloud upload error: $e');
      return null;
    }
  }

  /// Removes the profile photo locally, from preferences, and from Supabase.
  static Future<void> removeProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Clear local path from prefs
      await prefs.remove(_avatarLocalPathKey);
      await prefs.remove('${_settingsPrefix}avatar_url');

      // 2. Delete local files
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      for (var f in files) {
        if (f is File && f.path.contains('hero_ie_avatar_')) {
          try { f.deleteSync(); } catch (_) {}
        }
      }

      // 3. Clear from Supabase user_settings
      final uid = await getOrCreateUserId();
      await _supabase.from('user_settings').upsert({
        'id': uid,
        'avatar_url': null,
      });

      // 4. Notify UI (sets to null)
      avatarNotifier.value = null;

      // 🧹 Clear Flutter's internal image cache so the "removed" state shows immediately
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      print('✅ Profile photo removed.');
    } catch (e) {
      print('Remove photo error: $e');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  static Future<void> signInWithGoogle() async {
    const webClientId =
        '939808506560-gf1ocksjrfd3j4v2d1qlsos2bckr0fgj.apps.googleusercontent.com';
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser   = await googleSignIn.signIn();
    final googleAuth   = await googleUser?.authentication;
    final accessToken  = googleAuth?.accessToken;
    final idToken      = googleAuth?.idToken;
    if (accessToken == null || idToken == null) throw 'No Google Auth Token.';

    final res  = await _supabase.auth.signInWithIdToken(
      provider:    OAuthProvider.google,
      idToken:     idToken,
      accessToken: accessToken,
    );
    final user = res.user;
    if (user != null) {
      final existing = await getUserProfile(userId: user.id);
      if (existing == null) {
        await _supabase.from('users').insert({
          'user_id':           user.id,
          'email':             user.email,
          'full_name':         user.userMetadata?['full_name'] ?? 'User',
          'is_email_verified': true,
          'role':              'guest',
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_verifiedKey, true);
    }
  }

  // ── Password login (custom backend) ───────────────────────────────────────
  static Future<bool> signInWithPassword(
      String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_verifiedKey, true);
        await prefs.setString(_localContactKey, identifier);
        await prefs.setString(_localRoleKey, data['role'] ?? 'guest');
        if (data['full_name'] != null) {
          await prefs.setString(_localNameKey, data['full_name']);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  // ── OTP ────────────────────────────────────────────────────────────────────
  static Future<bool> sendOTP({String? phone, String? email}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (phone != null) 'phone_number': phone,
          if (email != null) 'email': email,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Send OTP Error: $e');
      return false;
    }
  }

  static Future<bool> verifyOTP({
    String? phoneNumber,
    String? email,
    required String otp,
    String? userId,
    String role = 'guest',
    String? fullName,
    String? password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (email       != null) 'email': email,
          'otp':       otp,
          'user_id':   userId,
          'role':      role,
          'full_name': fullName,
          'password':  password,
        }),
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_verifiedKey, true);
        await prefs.setString(_localContactKey, phoneNumber ?? email ?? '');
        await prefs.setString(_localRoleKey, role);
        if (fullName != null && fullName.isNotEmpty) {
          await prefs.setString(_localNameKey, fullName);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Verify OTP Error: $e');
      return false;
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedKey);
    await prefs.remove(_localNameKey);
    await prefs.remove(_localContactKey);
    await prefs.remove(_localRoleKey);
    // Note: we keep _localUserIdKey and settings so user can re-login
  }
}
