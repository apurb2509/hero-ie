import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService {
  static final _strategy = Strategy.P2P_CLUSTER; // Supports mesh-like topology via cluster
  static String? currentEndpointId;

  /// Requests necessary permissions for Nearby Connections (Android 13+ support)
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.nearbyWifiDevices,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<void> startAdvertising(String userName) async {
    if (kIsWeb) {
      print("Mesh networking (Nearby) is skipped on Web.");
      return;
    }

    if (!await requestPermissions()) {
      print("Permissions not granted for Nearby Connections.");
      return;
    }

    try {
      bool a = await Nearby().startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) async {
          // Accept connection automatically for mesh purposes
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (String endId, Payload payload) {
              if (payload.type == PayloadType.BYTES) {
                String str = String.fromCharCodes(payload.bytes!);
                print("Received mesh payload: $str");
                // TODO: implement relay logic and notify UI
              }
            },
            onPayloadTransferUpdate: (String endId, PayloadTransferUpdate update) {
              // Handle update
            },
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            currentEndpointId = id;
            print("Connected to mesh node: $id");
          }
        },
        onDisconnected: (String id) {
          print("Disconnected from: $id");
        },
      );
      print("Advertising started: $a");
    } catch (e) {
      print("Error advertising: $e");
    }
  }

  static Future<void> startDiscovery(String userName) async {
    if (kIsWeb) return;

    if (!await requestPermissions()) {
      print("Permissions not granted for Nearby Connections.");
      return;
    }

    try {
      bool a = await Nearby().startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (String id, String name, String serviceId) async {
          // Found a node! Let's request connection
          await Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) async {
              await Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (String endId, Payload payload) {
                   if (payload.type == PayloadType.BYTES) {
                    String str = String.fromCharCodes(payload.bytes!);
                    print("Received mesh payload: $str");
                   }
                },
                onPayloadTransferUpdate: (String endId, PayloadTransferUpdate update) {},
              );
            },
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                currentEndpointId = id;
                print("Connected to mesh node: $id");
              }
            },
            onDisconnected: (id) {},
          );
        },
        onEndpointLost: (String? id) {
          print("Lost endpoint: $id");
        },
      );
      print("Discovery started: $a");
    } catch (e) {
      print("Error discovering: $e");
    }
  }

  static Future<void> broadcastMessage(Map<String, dynamic> data) async {
    if (kIsWeb || currentEndpointId == null) return;
    Nearby().sendBytesPayload(
        currentEndpointId!,
        Uint8List.fromList(jsonEncode(data).codeUnits));
  }
}
