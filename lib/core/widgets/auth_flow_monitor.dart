import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../app/socket/socket_provider.dart';

/// Widget to monitor the auth flow status - useful for debugging
class AuthFlowMonitor extends ConsumerWidget {
  const AuthFlowMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socketState = ref.watch(socketNotifierProvider);
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Auth Flow Status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          FutureBuilder<Map<String, String?>>(
            future: _getAuthStatus(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Loading...');
              }
              
              final data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow('Access Token', data['accessToken']),
                  _buildStatusRow('FCM Token', data['fcmToken']),
                  _buildStatusRow('Socket State', socketState.name),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String? value) {
    final hasValue = value != null && value.isNotEmpty;
    return Row(
      children: [
        Icon(
          hasValue ? Icons.check_circle : Icons.cancel,
          color: hasValue ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text('$label: '),
        Text(
          hasValue ? '${value.substring(0, 10)}...' : 'Missing',
          style: TextStyle(
            color: hasValue ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<Map<String, String?>> _getAuthStatus() async {
    try {
      final authBox = await Hive.openBox('authBox');
      return {
        'accessToken': authBox.get('token'),
        'fcmToken': authBox.get('fcmToken'),
      };
    } catch (e) {
      return {
        'accessToken': null,
        'fcmToken': null,
      };
    }
  }
}