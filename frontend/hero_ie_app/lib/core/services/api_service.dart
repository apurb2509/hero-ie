import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ✅ Use Render backend URL (with dart-define support)
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://hero-ie-backend.onrender.com', // 🔥 CHANGE THIS
  );

  static bool _isSearching = false;
  static final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  static String get baseUrl {
    return _backendUrl;
  }

  // ❌ Disabled local discovery (not needed for production)
  static Future<void> discoverBackend() async {
    return;
  }

  static Future<bool> _verifyBackend(String ip) async {
    return false;
  }

  // --- MEDIA UPLOAD METHODS ---

  static Future<bool> uploadSOSMedia(String text, File? file, bool isVideo) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/risk/ingest'));
      if (text.isNotEmpty) request.fields['details'] = text;

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(isVideo ? 'video' : 'image', 'jpeg'),
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        isConnected.value = true;
        return true;
      }
      return false;
    } catch (e) {
      isConnected.value = false;
      print("SOS Upload Error: $e");
      return false;
    }
  }

  static Future<bool> uploadAdminLayout(String name, String description, File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/layout'));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        isConnected.value = true;
        return true;
      }
      return false;
    } catch (e) {
      isConnected.value = false;
      print("Layout Upload Error: $e");
      return false;
    }
  }

  static Future<bool> uploadAdminRiskVideo(File file) async {
    try {
      print("🚀 [ADMIN MEDIA] Preparing to send video to AI: ${file.path}");
      print("📂 [ADMIN MEDIA] File size: ${await file.length()} bytes");

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/risk/ingest'));

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('video', 'mp4'),
      ));

      print("📡 [ADMIN MEDIA] Sending request to $baseUrl/risk/ingest ...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 [ADMIN MEDIA] Response Code: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("❌ [ADMIN MEDIA] Server Error: ${response.body}");
        return false;
      } else {
        print("✅ [ADMIN MEDIA] Final Response Data: ${response.body}");
        isConnected.value = true;
        return true;
      }
    } catch (e) {
      isConnected.value = false;
      print("❌ [ADMIN MEDIA] Critical Upload Error: $e");
      return false;
    }
  }

  // --- SIMULATION METHODS ---

  static Future<String?> setupRiskSimulation(File file) async {
    try {
      print("🚀 [SIM SETUP] Uploading simulation source: ${file.path}");
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/risk/sim/setup'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ [SIM SETUP] Ready! ID: ${data['simulation_id']}");
        isConnected.value = true;
        return data['simulation_id'];
      }
      print("❌ [SIM SETUP] Failed: ${response.body}");
      return null;
    } catch (e) {
      isConnected.value = false;
      print("❌ [SIM SETUP] Error: $e");
      return null;
    }
  }

  static Future<bool> processSimulationFrame(String simId, int seconds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/risk/sim/frame'),
        body: {
          'simulation_id': simId,
          'offset_seconds': seconds.toString(),
        },
      );

      if (response.statusCode == 200) {
        print("✅ [SIM POLL] Offset ${seconds}s processed.");
        isConnected.value = true;
        return true;
      }
      print("❌ [SIM POLL] Error: ${response.body}");
      return false;
    } catch (e) {
      isConnected.value = false;
      print("❌ [SIM POLL] Network Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> getEvacuationRoute(String location, String destination) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/evacuation/route'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_location': location,
          'destination': destination,
        }),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      isConnected.value = false;
      throw Exception('Network error: $e');
    }
  }

  static Future<void> reportVitals(String userId, String location, int heartRate, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/heatmap/vitals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'location': location,
          'heart_rate': heartRate,
          'status': status,
        }),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
      }
    } catch (e) {
      isConnected.value = false;
      print('Offline or network error, vitals queued: $e');
    }
  }

  static Future<List<dynamic>> getHeatmap() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/heatmap/'));
      if (response.statusCode == 200) {
        isConnected.value = true;
        final data = jsonDecode(response.body);
        return data['zones'] ?? [];
      }
      return [];
    } catch (e) {
      isConnected.value = false;
      print('Failed to get heatmap: $e');
      return [];
    }
  }

  static Future<void> sendBroadcast(String message, String senderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/broadcast/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'target_languages': ['es', 'fr', 'de'],
          'sender_id': senderId,
        }),
      );
      if (response.statusCode == 200) {
        isConnected.value = true;
      }
    } catch (e) {
      isConnected.value = false;
      print('Offline mode: Could not broadcast to server.');
    }
  }
}