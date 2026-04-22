import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _verifiedKey = 'is_locally_verified';

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<bool> isVerified() async {
    if (isAuthenticated) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verifiedKey) ?? false;
  }

  static Future<Map<String, dynamic>?> getUserProfile({String? userId, String? email, String? phone}) async {
    try {
      var query = _supabase.from('users').select('*');
      if (userId != null) query = query.eq('user_id', userId);
      if (email != null) query = query.eq('email', email);
      if (phone != null) query = query.eq('phone_number', phone);
      
      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      print("Get Profile Error: $e");
      return null;
    }
  }

  // --- Settings specific endpoints ---
  static Future<Map<String, dynamic>?> getUserSettings() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _supabase.from('user_settings').select('*').eq('id', user.id).maybeSingle();
    } catch (e) {
      print("Get Settings Error: $e");
      return null;
    }
  }

  static Future<bool> upsertUserSettings(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      data['id'] = user.id; // ensure ID is correct
      // If full_name is being updated, we also update last_name_update
      final currentSettings = await getUserSettings();
      if (currentSettings != null && currentSettings['full_name'] != data['full_name']) {
        data['last_name_update'] = DateTime.now().toIso8601String();
        // Also update auth.users metadata to match for consistency
         await _supabase.auth.updateUser(
           UserAttributes(data: {'full_name': data['full_name']})
         );
      }
      
      await _supabase.from('user_settings').upsert(data);
      return true;
    } catch (e) {
      print("Upsert Settings Error: $e");
      return false;
    }
  }
  // ------------------------------------

  static Future<void> signInWithGoogle() async {
    // 1. Configure the Google Sign-In request
    const String webClientId = '939808506560-gf1ocksjrfd3j4v2d1qlsos2bckr0fgj.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    // 2. Trigger the native Google Account Picker
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken == null || idToken == null) {
      throw 'No Google Auth Token found.';
    }

    // 3. Hand off the token to Supabase
    final AuthResponse res = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = res.user;
    if (user != null) {
      // 4. Sync profile automatically to avoid redundant prompts
      final existing = await getUserProfile(userId: user.id);
      if (existing == null) {
        // Create initial profile from Google data
        await _supabase.from('users').insert({
          'user_id': user.id,
          'email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'is_email_verified': true,
          'role': 'guest'
        });
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_verifiedKey, true);
    }
  }

  static Future<bool> signInWithPassword(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_verifiedKey, true);
        return true;
      }
      return false;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

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
      print("Send OTP Error: $e");
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
          if (email != null) 'email': email,
          'otp': otp,
          'user_id': userId,
          'role': role,
          'full_name': fullName,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_verifiedKey, true);
        return true;
      }
      return false;
    } catch (e) {
      print("Verify OTP Error: $e");
      return false;
    }
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verifiedKey);
  }
}
