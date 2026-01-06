import 'package:bia/app/socket/socket_provider.dart';
import 'package:bia/app/socket/connection_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Debug widget to test WebSocket connection
/// Add this to your dashboard or settings page to test the connection
class SocketDebugWidget extends ConsumerWidget {
  const SocketDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketNotifierProvider);
    final socketNotifier = ref.read(socketNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Socket.IO Debug',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Connection Status
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                _buildStatusChip(socketState),
              ],
            ),
            const SizedBox(height: 12),
            
            // Token Info
            FutureBuilder<String>(
              future: _getToken(),
              builder: (context, snapshot) {
                final token = snapshot.data ?? '';
                return Text(
                  'Token: ${token.isEmpty ? "Not logged in" : "${token.substring(0, 20)}..."}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: socketState == SocketState.connected
                      ? null
                      : () => socketNotifier.connect(),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: socketState == SocketState.connected
                      ? () => socketNotifier.disconnect()
                      : null,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => socketNotifier.reconnect(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testSendMessage(socketNotifier),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Test Ping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _runConnectionTests(context),
                  icon: const Icon(Icons.network_check, size: 18),
                  label: const Text('Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Check console logs for detailed connection info',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SocketState state) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case SocketState.idle:
        color = Colors.grey;
        text = 'Idle';
        icon = Icons.circle;
        break;
      case SocketState.connecting:
        color = Colors.orange;
        text = 'Connecting';
        icon = Icons.sync;
        break;
      case SocketState.connected:
        color = Colors.green;
        text = 'Connected';
        icon = Icons.check_circle;
        break;
      case SocketState.disconnected:
        color = Colors.grey;
        text = 'Disconnected';
        icon = Icons.cancel;
        break;
      case SocketState.error:
        color = Colors.red;
        text = 'Error';
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Future<String> _getToken() async {
    try {
      final authBox = Hive.box('authBox');
      return authBox.get('token', defaultValue: '');
    } catch (e) {
      return '';
    }
  }

  void _testSendMessage(SocketNotifier notifier) {
    try {
      if (notifier.isConnected) {
        notifier.emit('ping', {
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('📤 Test ping sent via Socket.IO');
      } else {
        print('❌ Socket.IO not connected');
      }
    } catch (e) {
      print('❌ Error sending test message: $e');
    }
  }

  void _runConnectionTests(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Running connection tests...'),
          ],
        ),
      ),
    );

    try {
      final token = await _getToken();
      final results = await ConnectionTest.runAllTests(token: token.isNotEmpty ? token : null);
      final recommendations = ConnectionTest.getRecommendations(results);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Test Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...results.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.error,
                          color: entry.value ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: entry.value ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(rec, style: const TextStyle(fontSize: 12)),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test failed: $e')),
        );
      }
    }
  }
}
