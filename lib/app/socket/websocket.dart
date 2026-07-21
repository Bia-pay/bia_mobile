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
import 'package:go_router/go_router.dart';
import '../../app/utils/router/route_constant.dart';
import '../../core/utils/app_logger.dart';

class AppSocketListener extends ConsumerStatefulWidget {
  final Widget child;
  const AppSocketListener({super.key, required this.child});

  @override
  ConsumerState<AppSocketListener> createState() => _AppSocketListenerState();
}

class _AppSocketListenerState extends ConsumerState<AppSocketListener> with WidgetsBindingObserver {

  bool _isFcmListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Defer socket connection by 1s so Hive boxes finish opening in background
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _checkAndConnect();
      });

      // Retry FCM setup until Firebase is ready (runs in background, no blocking)
      _setupFcmWhenReady();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Polls until Firebase is initialized, then registers the FCM token refresh listener.
  /// This is safe to call before Firebase.initializeApp() completes.
  Future<void> _setupFcmWhenReady() async {
    if (_isFcmListening) return;
    // Wait until Firebase is initialized (checks every 500ms, max 30 retries = 15s)
    for (int i = 0; i < 30; i++) {
      if (!mounted) return;
      try {
        // This throws if Firebase isn't initialized yet
        FirebaseMessaging.instance; // probes the instance
        _listenForFcmTokenRefresh();
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    debugPrint('⚠️ Firebase not ready after 15s — FCM token refresh skipped.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Guard: Hive may not be initialized yet on very early lifecycle events.
    // Use SecureStorage (always available) as primary token source.
    String token = '';
    String userId = '';

    try {
      if (Hive.isBoxOpen('authBox')) {
        final authBox = Hive.box('authBox');
        userId = authBox.get('userId', defaultValue: '');
        token = authBox.get('token', defaultValue: '');
      }
    } catch (_) {}

    // Fall back to FlutterSecureStorage if Hive token is missing
    if (token.isEmpty && userId.isNotEmpty) {
      const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true));
      token = await storage.read(key: 'access_token_$userId') ?? '';
    }

    if (token.isEmpty) return;
    if (!mounted) return; // widget may have been disposed during the await

    if (state == AppLifecycleState.resumed) {
      ref.read(socketNotifierProvider.notifier).connect();
      ref.read(servicesStatusProvider.notifier).loadStatus();
    } else if (state == AppLifecycleState.paused) {
      ref.read(socketNotifierProvider.notifier).disconnect();
    }
  }
  void _listenForFcmTokenRefresh() {
    if (_isFcmListening) return;
    _isFcmListening = true;
    AppLogger.debug('🔥 Registering FCM token refresh listener.');
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      AppLogger.debug("🔄 FCM Token refreshed");

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
        AppLogger.debug("📤 Sent refreshed FCM token to backend via socket");
      } else {
        AppLogger.debug("⚠️ Socket not connected, will send later");
      }
    });
  }
  void _checkAndConnect() async {
    // Check if WebSocket is enabled
    if (!AppConstants.enableWebSocket) {
      AppLogger.debug('⚠️ Socket.IO is disabled in app constants');
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
          AppLogger.debug('🔌 Connecting Socket.IO...');
          socketNotifier.connect();
        }
      } else {
        AppLogger.debug('⚠️ User not logged in, skipping Socket.IO connection');
      }
    } catch (e) {
      AppLogger.debug('❌ Error checking auth status: $e');
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
    
    socket.on('qr_payment_request', (data) => _handleSocketEvent(context, {'event': 'qr_payment_request', ...data}));
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

    AppLogger.debug("🎯 Handling Socket.IO event: $event");

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

      case "qr_payment_request":
        _showQrPaymentRequestNotification(context, json);
        break;

      default:
        AppLogger.debug("ℹ️ Unhandled Socket.IO event: $event");
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
    AppLogger.debug("💰 Balance update received");
    // Trigger balance refresh in dashboard if needed
  }

  void _handleTransactionUpdate(Map<String, dynamic> data) {
    AppLogger.debug("💳 Transaction update received");
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

  void _showQrPaymentRequestNotification(BuildContext context, Map<String, dynamic> data) {
    final amountStr = data['amount']?.toString() ?? data['data']?['amount']?.toString() ?? '0';
    final amount = double.tryParse(amountStr) ?? 0.0;
    final senderName = data['senderName'] ?? data['data']?['senderName'] ?? 'Someone';
    final requestId = data['requestId'] ?? data['data']?['requestId'] ?? '';

    if (!mounted || requestId.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📲 QR Request: $senderName is requesting ₦$amountStr"),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 15),
        action: SnackBarAction(
          label: 'Authorize',
          textColor: Colors.white,
          onPressed: () {
            context.pushNamed(RouteList.qrAuthorizeScreen, extra: {
              'requestId': requestId,
              'amount': amount,
              'senderName': senderName,
            });
          },
        ),
      ),
    );
  }
}