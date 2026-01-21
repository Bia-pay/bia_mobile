import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_flow_service.dart';
import '../widgets/auth_flow_monitor.dart';
import '../../app/socket/socket_provider.dart';

/// Test page to verify the auth flow works correctly
class AuthFlowTestPage extends ConsumerWidget {
  const AuthFlowTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authFlowService = ref.read(authFlowServiceProvider);
    final socketNotifier = ref.read(socketNotifierProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Flow Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthFlowMonitor(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authFlowService.completeAuthFlow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auth flow completed')),
                );
              },
              child: const Text('Complete Auth Flow'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                socketNotifier.connect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Socket connection initiated')),
                );
              },
              child: const Text('Connect Socket'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                socketNotifier.disconnect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Socket disconnected')),
                );
              },
              child: const Text('Disconnect Socket'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final isValid = await authFlowService.verifyAuthState();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isValid ? 'Auth state valid' : 'Auth state invalid'),
                    backgroundColor: isValid ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Verify Auth State'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await authFlowService.clearAuthFlow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auth flow cleared')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear Auth Flow'),
            ),
          ],
        ),
      ),
    );
  }
}