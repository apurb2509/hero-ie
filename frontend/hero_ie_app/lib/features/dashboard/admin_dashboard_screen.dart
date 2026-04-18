import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/localization/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _broadcastController = TextEditingController();
  final TextEditingController _layoutDescController = TextEditingController();
  List<dynamic> _zones = [];
  Timer? _pollingTimer;
  File? _layoutImage;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadHeatmap();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ingestTimer?.cancel();
    _broadcastController.dispose();
    _layoutDescController.dispose();
    super.dispose();
  }

  Future<void> _loadHeatmap() async {
    final zones = await ApiService.getHeatmap();
    if (mounted) setState(() => _zones = zones);
  }

  void _sendBroadcast() async {
    final msg = _broadcastController.text;
    if (msg.isEmpty) return;
    try {
      await ApiService.sendBroadcast(msg, 'Staff_Node');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent')));
        _broadcastController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to offline queue.')));
    }
  }

  Future<void> _uploadLayout() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading layout to AI...')));
      bool success = await ApiService.uploadAdminLayout(
        "Floorplan", 
        _layoutDescController.text, 
        File(file.path)
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layout applied to routing engine.'), backgroundColor: Colors.green));
        setState(() => _layoutImage = File(file.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed.'), backgroundColor: Colors.red));
      }
    }
  }

  Timer? _ingestTimer;
  bool _isLiveFeeding = false;
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  String? _currentSimId;
  int _simSeconds = 0;

  Future<void> _connectLiveCam() async {
    if (_isLiveFeeding) {
      _stopLiveFeed();
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    
    if (file != null) {
      setState(() {
        _isUploading = true;
        _simSeconds = 0;
      });

      // Step 1: Optimized One-Time Upload
      final simId = await ApiService.setupRiskSimulation(File(file.path));
      if (simId == null) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to setup simulation on server."), backgroundColor: Colors.red));
        }
        return;
      }
      _currentSimId = simId;

      // Initialize Video Player for UI feedback
      _videoController = VideoPlayerController.file(File(file.path));
      try {
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        await _videoController!.play();
      } catch (e) {
        print("❌ Video Player Init Error: $e");
      }

      setState(() {
        _isLiveFeeding = true;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('LIVE FEED READY: Poll requests optimized.'), 
        backgroundColor: AppTheme.warningNeon,
        duration: Duration(seconds: 3),
      ));

      // Immediate first ingestion (offset 0)
      await ApiService.processSimulationFrame(_currentSimId!, _simSeconds);

      // Step 2: LIGHTWEIGHT 5-second polling
      _ingestTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!mounted || !_isLiveFeeding) {
          timer.cancel();
          return;
        }
        _simSeconds += 5; // Track offset in video
        print("🤖 [AUTO-POLL] Requesting analysis for simulation frame at ${_simSeconds}s...");
        await ApiService.processSimulationFrame(_currentSimId!, _simSeconds);
      });
    }
  }

  void _stopLiveFeed() {
    _ingestTimer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    setState(() => _isLiveFeeding = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.translate('live_stopped')),
      backgroundColor: Colors.blueGrey,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.translate('admin_dashboard')),
            backgroundColor: AppTheme.errorNeon.withOpacity(0.2),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: ApiService.isConnected,
                builder: (context, connected, _) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: connected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: connected ? Colors.green : Colors.red),
                    ),
                    child: Center(
                      child: Text(
                        connected ? AppLocalizations.translate('status_connected') : AppLocalizations.translate('status_offline'),
                        style: TextStyle(color: connected ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceColor, foregroundColor: AppTheme.primaryNeon, padding: const EdgeInsets.symmetric(vertical: 20)),
                          icon: const Icon(Icons.map),
                          label: Text(AppLocalizations.translate('facility_layout')),
                          onPressed: () {
                             showDialog(context: context, builder: (c) => AlertDialog(
                               title: Text(AppLocalizations.translate('configure_layout')),
                               backgroundColor: AppTheme.backgroundMatte,
                               content: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   TextField(controller: _layoutDescController, decoration: InputDecoration(hintText: AppLocalizations.translate('layout_hint'))),
                                   const SizedBox(height: 16),
                                   ElevatedButton.icon(icon: const Icon(Icons.upload), label: Text(AppLocalizations.translate('upload_floorplan')), onPressed: _uploadLayout)
                                 ],
                               ),
                               actions: [TextButton(onPressed: ()=> Navigator.pop(c), child: Text(AppLocalizations.translate('close_btn')))],
                             ));
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiveFeeding ? AppTheme.warningNeon.withOpacity(0.3) : AppTheme.surfaceColor, 
                            foregroundColor: AppTheme.warningNeon, 
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: _isLiveFeeding ? const BorderSide(color: AppTheme.warningNeon, width: 2) : null,
                          ),
                          icon: Icon(_isLiveFeeding ? Icons.pause : Icons.videocam),
                          label: Text(_isLiveFeeding ? AppLocalizations.translate('live_polling') : AppLocalizations.translate('live_camera')),
                          onPressed: () {
                            if (_isLiveFeeding) {
                              _stopLiveFeed();
                            } else {
                              showDialog(context: context, builder: (c) => AlertDialog(
                                title: Text(AppLocalizations.translate('sim_dialog_title')),
                                backgroundColor: AppTheme.backgroundMatte,
                                content: Text(AppLocalizations.translate('sim_dialog_body')),
                                actions: [
                                  TextButton(onPressed: ()=> Navigator.pop(c), child: Text(AppLocalizations.translate('cancel_btn'))),
                                  ElevatedButton(onPressed: () { Navigator.pop(c); _connectLiveCam(); }, child: Text(AppLocalizations.translate('start_sim_btn')))
                                ],
                              ));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildLiveMonitor(),
                  const SizedBox(height: 24),
                  Card(
                    color: AppTheme.surfaceColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(AppLocalizations.translate('heatmap_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNeon)),
                          const SizedBox(height: 16),
                          _zones.isEmpty 
                          ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                          : Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: _zones.map((zone) {
                                int count = zone['count'] ?? 0;
                                String name = zone['name'] ?? 'Unknown';
                                Color statusColor = Colors.green;
                                if (count > 0 && count < 10) statusColor = AppTheme.warningNeon;
                                if (count >= 10) statusColor = AppTheme.errorNeon;
                                return _buildZoneStatus(name, count, statusColor);
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(AppLocalizations.translate('broadcast'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _broadcastController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.translate('broadcast_hint'),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: Text(AppLocalizations.translate('broadcast_alerts')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorNeon, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _sendBroadcast,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildLiveMonitor() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.backgroundMatte,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isLiveFeeding ? AppTheme.warningNeon : Colors.white12, width: 1.5),
        boxShadow: _isLiveFeeding ? [
          BoxShadow(color: AppTheme.warningNeon.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
        ] : [],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isUploading)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.warningNeon),
                const SizedBox(height: 16),
                Text(AppLocalizations.translate('preparing_sim'), style: const TextStyle(color: AppTheme.warningNeon, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            )
          else if (_isLiveFeeding && _videoController != null && _videoController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 48, color: Colors.white24),
                const SizedBox(height: 8),
                Text(AppLocalizations.translate('no_stream'), style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
              ],
            ),
          
          if (_isLiveFeeding && !_isUploading)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoneStatus(String zoneName, int occupants, Color statusColor) {
    return Column(
      children: [
        Icon(Icons.people, color: statusColor, size: 32),
        const SizedBox(height: 4),
        Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$occupants', style: TextStyle(color: statusColor, fontSize: 18)),
      ],
    );
  }
}

