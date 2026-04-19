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
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Send OTP Error: $e");
      return false;
    }
  }

  static Future<bool> verifyOTP({
    required String phoneNumber,
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
          'phone_number': phoneNumber,
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
