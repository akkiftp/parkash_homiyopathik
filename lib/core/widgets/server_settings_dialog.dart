import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _controller;

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

  void _save(String url) async {
    await AppConfig.setBaseUrl(url);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server API URL updated to: $url'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns, color: Color(0xFF0284C7)),
          SizedBox(width: 8),
          Text('Backend API Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the Laravel REST API base URL. Changes apply immediately.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
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
            const SizedBox(height: 16),
            const Text('Quick Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Localhost (Web/Desktop)'),
                  onPressed: () => _controller.text = 'http://127.0.0.1:8000/api',
                ),
                ActionChip(
                  label: const Text('Android Emulator (10.0.2.2)'),
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
