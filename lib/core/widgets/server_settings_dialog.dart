import 'package:flutter/material.dart';
import '../../services/clinic_service.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final tempUrl = _controller.text.trim();
    await AppConfig.setBaseUrl(tempUrl);

    final service = ClinicService();
    final res = await service.getClinicInfo();

    setState(() {
      _isTesting = false;
      _isSuccess = res.success;
      _testResult = res.success
          ? 'Connected! Clinic: ${res.data?.clinicName}'
          : 'Failed: ${res.message}';
    });
  }

  void _save(String url) async {
    await AppConfig.setBaseUrl(url);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server API URL updated to: $url'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryLightBlue,
            child: Icon(Icons.dns_rounded, color: AppTheme.primaryBlue, size: 20),
          ),
          SizedBox(width: 12),
          Text('Server API Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the backend Laravel API base URL. On physical devices or Firebase Web, point to your local IP or Tunnel URL:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Base API URL',
                hintText: 'http://127.0.0.1:8000/api',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),

            // Connection Test Result
            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      size: 18,
                      color: _isSuccess ? AppTheme.accentGreen : AppTheme.dangerRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check, size: 16),
              label: Text(_isTesting ? 'Testing...' : 'Test Server Connection'),
            ),

            const SizedBox(height: 16),
            const Text('Presets / पूर्व निर्धारित पते:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_done, size: 16, color: AppTheme.accentGreen),
                  label: const Text('Live Tunnel (Active Now)'),
                  onPressed: () => _controller.text = AppConfig.livePublicUrl,
                ),
                ActionChip(
                  avatar: const Icon(Icons.cloud_queue, size: 16, color: AppTheme.primaryBlue),
                  label: const Text('Render (prakash-homeo.onrender.com)'),
                  onPressed: () => _controller.text = 'https://prakash-homeo-hall.onrender.com/api',
                ),
                ActionChip(
                  label: const Text('Localhost (127.0.0.1:8000)'),
                  onPressed: () => _controller.text = 'http://127.0.0.1:8000/api',
                ),
                ActionChip(
                  label: const Text('Android Emulator (10.0.2.2:8000)'),
                  onPressed: () => _controller.text = 'http://10.0.2.2:8000/api',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _save(_controller.text),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
