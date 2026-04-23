import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';

class SOSFormWidget extends StatefulWidget {
  final Function(String text, File? mediaFile, bool isVideo) onSubmit;

  const SOSFormWidget({super.key, required this.onSubmit});

  @override
  State<SOSFormWidget> createState() => _SOSFormWidgetState();
}

class _SOSFormWidgetState extends State<SOSFormWidget> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  bool _isVideo = false;

  Future<void> _pickMedia(bool isVideo) async {
    final XFile? file = isVideo 
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
        
    if (file != null) {
      setState(() {
        _selectedMedia = File(file.path);
        _isVideo = isVideo;
      });
    }
  }

  void _submit() {
    if (_textController.text.isEmpty && _selectedMedia == null) return;
    widget.onSubmit(_textController.text, _selectedMedia, _isVideo);
    setState(() {
      _textController.clear();
      _selectedMedia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.currentLocale,
      builder: (context, locale, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.translate('sos_chat'), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 18)),
              const SizedBox(height: 16),
              if (_selectedMedia != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(_isVideo ? Icons.videocam : Icons.image, color: Colors.white54, size: 40),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _selectedMedia = null),
                        ),
                      )
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.translate('describe_emergency'),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.camera_alt), color: Theme.of(context).colorScheme.primary, onPressed: () => _pickMedia(false)),
                  IconButton(icon: const Icon(Icons.videocam), color: Theme.of(context).colorScheme.primary, onPressed: () => _pickMedia(true)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(AppLocalizations.translate('send_sos')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorNeon, foregroundColor: Colors.white),
                  onPressed: _submit,
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
