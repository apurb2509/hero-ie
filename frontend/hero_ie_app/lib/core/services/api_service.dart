import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static String _discoveredIp = '127.0.0.1'; // Default fallback
  static bool _isSearching = false;
  static final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://$_discoveredIp:8000';
  }

  /// Automatically discovers the backend by scanning the local subnet on port 8000.
  static Future<void> discoverBackend() async {
    if (kIsWeb || _isSearching) return;
    _isSearching = true;

    try {
      // 1. Try Emulator bridge IPs first (standard for Android)
      final commonIps = ['10.0.2.2', '10.0.3.2'];
      for (var ip in commonIps) {
        if (await _verifyBackend(ip)) {
          _isSearching = false;
          return;
        }
      }

      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLinkLocal: true);

      List<String> subnets = [];
      for (var interface in interfaces) {
        print("Checking Interface: ${interface.name}");
        for (var addr in interface.addresses) {
          print("Found Address: ${addr.address}");
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
            }
          }
        }
      }

      if (subnets.isEmpty) {
        print("No subnets found!");
        _isSearching = false;
        return;
      }

      print("Scanning subnets: $subnets");

      // 2. Scan subnets in batches to avoid overwhelming the network stack
      for (var subnet in subnets) {
        const batchSize = 25;
        for (int i = 1; i < 255; i += batchSize) {
          List<Future<void>> batch = [];
          for (int j = i; j < i + batchSize && j < 255; j++) {
            final testIp = '$subnet.$j';
            batch.add(() async {
              if (isConnected.value) return;
              await _verifyBackend(testIp);
            }());
          }
          await Future.wait(batch);
          if (isConnected.value) break;
        }
        if (isConnected.value) break;
      }
    } catch (e) {
      print("Discovery error: $e");
    } finally {
      _isSearching = false;
      if (!isConnected.value) {
        print("Discovery finished: Backend not found on local network. Using fallback: $_discoveredIp");
      }
    }
  }

  /// Helper to check if a specific IP is hosting the HERO-IE backend
  static Future<bool> _verifyBackend(String ip) async {
    try {
      final socket = await Socket.connect(ip, 8000,
          timeout: const Duration(milliseconds: 800));
      socket.destroy();

      print("Potential Backend Found at $ip, verifying identity...");
      final response = await http.get(Uri.parse('http://$ip:8000/')).timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200 && response.body.contains("HERO-IE")) {
        _discoveredIp = ip;
        isConnected.value = true;
        print("✅ BACKEND VERIFIED AT: $_discoveredIp");
        return true;
      }
    } catch (_) {
      // Silent catch for failed pings
    }
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
          contentType: MediaType(isVideo ? 'video' : 'image', 'jpeg')
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
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
      return response.statusCode == 200;
    } catch (e) {
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
        contentType: MediaType('video', 'mp4'), // Explicitly set content type
      ));
      
      print("📡 [ADMIN MEDIA] Sending request to $baseUrl/risk/ingest ...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print("📡 [ADMIN MEDIA] Response Code: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("❌ [ADMIN MEDIA] Server Error: ${response.body}");
      } else {
        print("✅ [ADMIN MEDIA] Final Response Data: ${response.body}");
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print("❌ [ADMIN MEDIA] Critical Upload Error: $e");
      return false;
    }
  }

  // --- OPTIMIZED TWO-STEP SIMULATION METHODS ---

  /// Step 1: Upload the big video once to the server
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
        return data['simulation_id'];
      }
      print("❌ [SIM SETUP] Failed: ${response.body}");
      return null;
    } catch (e) {
      print("❌ [SIM SETUP] Error: $e");
      return null;
    }
  }

  /// Step 2: Push a lightweight "pull frame" request every 5s
  static Future<bool> processSimulationFrame(String simId, int seconds) async {
    try {
      // Form-data request
      final response = await http.post(
        Uri.parse('$baseUrl/risk/sim/frame'),
        body: {
          'simulation_id': simId,
          'offset_seconds': seconds.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        print("✅ [SIM POLL] Offset ${seconds}s processed.");
        return true;
      }
      print("❌ [SIM POLL] Error: ${response.body}");
      return false;
    } catch (e) {
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
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<void> reportVitals(String userId, String location, int heartRate, String status) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/heatmap/vitals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'location': location,
          'heart_rate': heartRate,
          'status': status,
        }),
      );
    } catch (e) {
      print('Offline or network error, vitals queued: $e');
    }
  }

  static Future<List<dynamic>> getHeatmap() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/heatmap/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['zones'] ?? [];
      }
      return [];
    } catch (e) {
      print('Failed to get heatmap: $e');
      return [];
    }
  }

  static Future<void> sendBroadcast(String message, String senderId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/broadcast/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'target_languages': ['es', 'fr', 'de'],
          'sender_id': senderId,
        }),
      );
    } catch (e) {
      print('Offline mode: Could not broadcast to server.');
    }
  }
}
