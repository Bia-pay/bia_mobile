import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'socket_provider.dart';

class SocketTestWidget extends ConsumerWidget {
  const SocketTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketNotifierProvider);
    final socketNotifier = ref.read(socketNotifierProvider.notifier);
    final socket = ref.watch(socketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(socketState),
                          color: _getStatusColor(socketState),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          socketState.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(socketState),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (socket?.connected == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Socket ID: ${socket?.id ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Connection Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: socketState == SocketState.connecting 
                                ? null 
                                : () => socketNotifier.connect(),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Connect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: socketState == SocketState.disconnected 
                                ? null 
                                : () => socketNotifier.disconnect(),
                            icon: const Icon(Icons.stop),
                            label: const Text('Disconnect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => socketNotifier.reconnect(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Messages
            if (socket?.connected == true) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Messages',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            socketNotifier.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Send Ping'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            socketNotifier.emit('test_message', {
                              'message': 'Hello from Flutter!',
                              'timestamp': DateTime.now().toIso8601String(),
                            });
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Send Test Message'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Auth Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _getTokenInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final token = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Token: ${token.isNotEmpty ? '${token.substring(0, 20)}...' : 'No token'}'),
                              Text('Length: ${token.length} characters'),
                              Text('Valid: ${token.isNotEmpty ? 'Yes' : 'No'}'),
                            ],
                          );
                        }
                        return const Text('Loading token info...');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getTokenInfo() async {
    try {
      final authBox = Hive.box('authBox');
      return authBox.get('token', defaultValue: '');
    } catch (e) {
      return '';
    }
  }

  IconData _getStatusIcon(SocketState state) {
    switch (state) {
      case SocketState.idle:
        return Icons.radio_button_unchecked;
      case SocketState.connecting:
        return Icons.sync;
      case SocketState.connected:
        return Icons.check_circle;
      case SocketState.disconnected:
        return Icons.cancel;
      case SocketState.error:
        return Icons.error;
    }
  }

  Color _getStatusColor(SocketState state) {
    switch (state) {
      case SocketState.idle:
        return Colors.grey;
      case SocketState.connecting:
        return Colors.orange;
      case SocketState.connected:
        return Colors.green;
      case SocketState.disconnected:
        return Colors.grey;
      case SocketState.error:
        return Colors.red;
    }
  }
}