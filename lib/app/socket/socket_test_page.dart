import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_debug_widget.dart';

/// Standalone test page for WebSocket debugging
/// Navigate to this page to test WebSocket connection
class SocketTestPage extends ConsumerWidget {
  const SocketTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SocketDebugWidget(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction(
                        '1',
                        'Make sure you are logged in',
                      ),
                      _buildInstruction(
                        '2',
                        'Click "Connect" to establish WebSocket connection',
                      ),
                      _buildInstruction(
                        '3',
                        'Status should change to "Connected" if successful',
                      ),
                      _buildInstruction(
                        '4',
                        'Click "Test Ping" to send a test message',
                      ),
                      _buildInstruction(
                        '5',
                        'Check console logs for detailed connection info',
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Expected WebSocket URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const SelectableText(
                        'wss://biabackend.onrender.com/ws?token=YOUR_TOKEN',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Common Issues:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildIssue(
                        '❌ "No token found"',
                        'You need to login first',
                      ),
                      _buildIssue(
                        '❌ "Connection Error"',
                        'Backend WebSocket endpoint may not be available',
                      ),
                      _buildIssue(
                        '⚠️ "Connecting..." stuck',
                        'Backend may not support WebSocket on /ws endpoint',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildIssue(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
