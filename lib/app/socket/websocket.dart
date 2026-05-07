import 'dart:convert';
import 'package:bia/app/socket/socket_provider.dart';
import 'package:bia/core/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import '../../feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../feature/dashboard/dashboardcontroller/notification_notifier.dart';
import '../../feature/dashboard/dashboardcontroller/provider.dart';

class AppSocketListener extends ConsumerStatefulWidget {
  final Widget child;
  const AppSocketListener({super.key, required this.child});

  @override
  ConsumerState<AppSocketListener> createState() => _AppSocketListenerState();
}

class _AppSocketListenerState extends ConsumerState<AppSocketListener> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _listenForFcmTokenRefresh(); // 👈 ADD THIS

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _checkAndConnect();
      });
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');
    String? token = authBox.get('token');
    
    if ((token == null || token.isEmpty) && userId.isNotEmpty) {
      const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
      token = await storage.read(key: 'access_token_$userId');
    }

    if (token == null || token.isEmpty) return;

    if (state == AppLifecycleState.resumed) {
      ref.read(socketNotifierProvider.notifier).connect();
    } else if (state == AppLifecycleState.paused) {
      ref.read(socketNotifierProvider.notifier).disconnect();
    }
  }
  void _listenForFcmTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("🔄 FCM Token refreshed: $newToken");

      final box = await Hive.openBox('authBox');
      await box.put('fcmToken', newToken);

      final socket = ref.read(socketProvider);
      if (socket != null && socket.connected) {
        final accessToken = box.get('token');
        socket.emit('registerFcmToken', {
          'accessToken': accessToken,
          'fcmToken': newToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
        print("📤 Sent refreshed FCM token to backend via socket");
      } else {
        print("⚠️ Socket not connected, will send later");
      }
    });
  }
  void _checkAndConnect() async {
    // Check if WebSocket is enabled
    if (!AppConstants.enableWebSocket) {
      print('⚠️ Socket.IO is disabled in app constants');
      return;
    }

    try {
      // Open box asynchronously to avoid blocking
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      String? token = authBox.get('token');
      
      if ((token == null || token.isEmpty) && userId.isNotEmpty) {
        const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
        token = await storage.read(key: 'access_token_$userId');
      }

      if (token != null && token.isNotEmpty) {
        final socketNotifier = ref.read(socketNotifierProvider.notifier);
        if (!socketNotifier.isConnected) {
          print('🔌 User is logged in (id: $userId), connecting Socket.IO...');
          socketNotifier.connect();
        }
      } else {
        print('⚠️ User not logged in, skipping Socket.IO connection');
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final socket = ref.watch(socketProvider);
    final socketState = ref.watch(socketNotifierProvider);

    // Set up Socket.IO event listeners when connected
    if (socket != null && socketState == SocketState.connected) {
      _setupSocketListeners(context, socket);
    }

    return widget.child;
  }

  void _setupSocketListeners(BuildContext context, socket) {
    // Listen to various Socket.IO events
    socket.on('deposit_success', (data) => _handleSocketEvent(context, {'event': 'deposit_success', ...data}));
    socket.on('deposit_completed', (data) => _handleSocketEvent(context, {'event': 'deposit_completed', ...data}));
    socket.on('deposit', (data) => _handleSocketEvent(context, {'event': 'deposit', ...data}));
    socket.on('transaction_success', (data) => _handleSocketEvent(context, {'event': 'transaction_success', ...data}));

    socket.on('transfer_received', (data) => _handleSocketEvent(context, {'event': 'transfer_received', ...data}));
    socket.on('credit_alert', (data) => _handleSocketEvent(context, {'event': 'credit_alert', ...data}));
    socket.on('credit', (data) => _handleSocketEvent(context, {'event': 'credit', ...data}));

    socket.on('balance_update', (data) => _handleSocketEvent(context, {'event': 'balance_update', ...data}));
    socket.on('balance', (data) => _handleSocketEvent(context, {'event': 'balance', ...data}));

    socket.on('transaction_update', (data) => _handleSocketEvent(context, {'event': 'transaction_update', ...data}));
    socket.on('notification', (data) => _handleSocketEvent(context, {'event': 'notification', ...data}));
  }

  Widget _buildConnectionIndicator(SocketState state) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case SocketState.connecting:
        color = Colors.orange;
        text = 'Connecting...';
        icon = Icons.sync;
        break;
      case SocketState.error:
        color = Colors.red;
        text = 'Connection Error';
        icon = Icons.error_outline;
        break;
      case SocketState.disconnected:
        color = Colors.grey;
        text = 'Disconnected';
        icon = Icons.cloud_off;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Material(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocketEvent(BuildContext context, Map<String, dynamic> json) {
    final event = json["event"] ?? json["type"] ?? json["action"];

    print("🎯 Handling Socket.IO event: $event");

    switch (event) {
      case "deposit_success":
      case "deposit_completed":
      case "deposit":
        _showDepositNotification(context, json);
        break;

      case "transaction_success":
        _showTransactionSuccessNotification(context, json);
        break;

      case "transfer_received":
      case "credit_alert":
      case "credit":
        _showTransferNotification(context, json);
        break;

      case "balance_update":
      case "balance":
        _handleBalanceUpdate(json);
        break;

      case "transaction_update":
        _handleTransactionUpdate(json);
        break;

      case "notification":
        _handleNotification(context, json);
        break;

      default:
        print("ℹ️ Unhandled Socket.IO event: $event");
        print("📄 Full message: $json");
    }
  }

  void _showDepositNotification(BuildContext context, Map<String, dynamic> data) {
    final amount = data['amount'] ?? data['data']?['amount'] ?? '0';

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Deposit of ₦$amount completed"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to transaction history
          },
        ),
      ),
    );
  }

  void _showTransferNotification(BuildContext context, Map<String, dynamic> data) {
    final amount = data['amount'] ?? data['data']?['amount'] ?? '0';
    final sender = data['sender'] ?? data['senderName'] ?? data['data']?['sender'] ?? 'Someone';

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("💰 You received ₦$amount from $sender"),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to transaction history
          },
        ),
      ),
    );
  }

  void _handleBalanceUpdate(Map<String, dynamic> data) {
    final balance = data['balance'] ?? data['data']?['balance'];
    print("💰 Balance updated: $balance");
    // Trigger balance refresh in dashboard if needed
  }

  void _handleTransactionUpdate(Map<String, dynamic> data) {
    print("💳 Transaction update: $data");
    // Handle transaction updates - refresh transaction list, etc.
  }

  void _handleNotification(BuildContext context, Map<String, dynamic> data) {
    final message = data['message'] ?? data['data']?['message'] ?? 'New notification';
    final title = data['title'] ?? data['data']?['title'] ?? 'Notification';

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  void _showTransactionSuccessNotification(BuildContext context, Map<String, dynamic> data) {
    final amount = data['amount'] ?? '0';
    final type = data['type'] ?? 'Transaction';

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $type of ₦$amount was successful!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}