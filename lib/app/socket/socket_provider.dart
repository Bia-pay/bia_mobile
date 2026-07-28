import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../feature/dashboard/dashboardcontroller/notification_notifier.dart';
import '../../feature/dashboard/dashboardcontroller/provider.dart';
import '../../feature/dashboard/model/services_status_model.dart';
import '../../feature/support/controller/support_controller.dart';
import '../../feature/auth/interceptor/interceptor.dart';
import '../utils/colors.dart';
import '../utils/widgets/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import '../../core/utils/app_logger.dart';

// Socket connection state
enum SocketState { idle, connecting, connected, disconnected, error }

class SocketNotifier extends StateNotifier<SocketState> {
  IO.Socket? _socket;
  String? _token;
  String? fcmToken;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final Ref _ref;
  Timer? _debounceTimer;

  SocketNotifier(this._ref) : super(SocketState.idle);

  IO.Socket? get socket => _socket;
  bool get isConnected => state == SocketState.connected && _socket?.connected == true;

  Future<void> connect() async {
    // Cancel any pending reconnect
    _reconnectTimer?.cancel();

    try {
      // Get user info from Hive and check the fresh token
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      
      // Try Hive first (legacy)
      String? freshToken = authBox.get('token');
      
      // Fallback to SecureStorage (New flow)
      if (freshToken == null || freshToken.isEmpty) {
        const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
        freshToken = await storage.read(key: 'access_token_$userId');
      }

      if (freshToken == null || freshToken.isEmpty) {
        AppLogger.debug('⚠️ No access token found. Socket.IO cannot connect');
        state = SocketState.idle;
        return;
      }

      // If the token has changed, we must disconnect the old socket and establish a new one
      final bool tokenChanged = _token != freshToken;

      if (!tokenChanged && (state == SocketState.connecting || (state == SocketState.connected && _socket?.connected == true))) {
        AppLogger.debug('⚠️ Socket already ${state.name} with same token');
        return;
      }

      // If token changed and we are already active, disconnect first to reconnect with new credentials
      if (tokenChanged && _socket != null) {
        AppLogger.debug('🔄 Access token changed. Forcing Socket.IO disconnect & reconnect...');
        await _disconnect();
      }

      _token = freshToken;
      this.fcmToken = authBox.get('fcmToken');

      state = SocketState.connecting;
      AppLogger.debug('🔌 Attempting Socket.IO connection...');

      if (this.fcmToken == null || this.fcmToken!.isEmpty) {
        AppLogger.debug('⚠️ No FCM token found. Socket.IO will connect but registration might fail');
      }

      // Build Socket.IO URL - Use wsUrl if available, else baseUrl
      String socketUrl = AppConstants.wsUrl.isNotEmpty ? AppConstants.wsUrl : AppConstants.baseUrl;

      // Remove trailing slash if present
      if (socketUrl.endsWith('/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 1);
      }

      AppLogger.debug('🔌 Connecting to Socket server...');

      // Disconnect existing socket if any
      await _disconnect();

      // Create Socket.IO connection with authentication
      _socket = IO.io(socketUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) 
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000) 
          .enableForceNew()
          .setExtraHeaders({
            'Authorization': 'Bearer $_token',
            'x-fcm-token': fcmToken ?? '',
          })
          .setAuth({
            'token': _token,
            'fcmToken': fcmToken ?? '',
          })
          .setQuery({
            'token': _token,
            'fcmToken': fcmToken ?? '',
          })
          .build());

      _setupSocketListeners();

      // Connect the socket
      _socket!.connect();

    } catch (e) {
      AppLogger.debug('❌ Socket.IO connection failed: $e');
      state = SocketState.error;
      _handleDisconnection();
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection successful
    _socket!.onConnect((data) {
      AppLogger.debug('✅ Socket.IO connected successfully');
      state = SocketState.connected;
      _reconnectAttempts = 0;

      // Get userId for more robust registration
      final authBox = Hive.box('authBox');
      final userId = authBox.get('userId', defaultValue: '');

      // Send registration after connection with ACK callback
      final payload = {
        'accessToken': _token,
        'fcmToken': fcmToken,
        'userId': userId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      };
      _socket!.emitWithAck('registerFcmToken', payload, ack: (ackData) {
        AppLogger.debug('🎉 registerFcmToken ACK received from server');
      });
    });

    // Connection error
    _socket!.onConnectError((error) {
      AppLogger.debug('❌ Socket.IO connection error');
      state = SocketState.error;
      _handleDisconnection();
    });

    // Raw connect response (catches all data on first connect)
    _socket!.on('connect', (data) {
      AppLogger.debug('📨 Raw connect event received');
    });

    // Ping / pong for latency debugging
    _socket!.on('ping', (_) => AppLogger.debug('🏓 Ping sent to server'));
    _socket!.on('pong', (latency) => AppLogger.debug('🏓 Pong received, latency: ${latency}ms'));

    // Disconnection
    _socket!.onDisconnect((reason) {
      AppLogger.debug('🔌 Socket.IO disconnected: $reason');
      state = SocketState.disconnected;

      // Handle different disconnect reasons
      switch (reason) {
        case 'io client disconnect':
          AppLogger.debug('📱 Manual disconnect - not reconnecting');
          break;
        case 'transport close':
          AppLogger.debug('🚫 Transport closed - will attempt reconnection');
          _handleDisconnection();
          break;
        case 'transport error':
          AppLogger.debug('❌ Transport error - will attempt reconnection');
          _handleDisconnection();
          break;
        case 'ping timeout':
          AppLogger.debug('⏰ Ping timeout - will attempt reconnection');
          _handleDisconnection();
          break;
        default:
          AppLogger.debug('🔄 Unexpected disconnect ($reason) - will attempt reconnection');
          _handleDisconnection();
          break;
      }
    });

    // Authentication response
    _socket!.on('authenticated', (data) {
      AppLogger.debug('====== SOCKET AUTHENTICATED ======');
    });

    // Authentication error
    _socket!.on('auth_error', (error) {
      AppLogger.error('SOCKET AUTH ERROR: $error');
      state = SocketState.error;
    });

    // Generic message handler
    _socket!.on('message', (data) {
      AppLogger.debug('📥 Socket.IO message received');
    });

    // Transaction updates
    _socket!.on('transaction_update', (data) {
      AppLogger.debug('====== TRANSACTION UPDATE RECEIVED ======');
      _refetchAllData();
    });

    // Transaction success (specific event requested by user)
    _socket!.on('transaction_success', (data) {
      AppLogger.debug('🎯 Transaction success event received, refetching all data...');
      _refetchAllData();
    });

    // Balance updates
    _socket!.on('balance_update', (data) {
      AppLogger.debug('====== BALANCE UPDATE RECEIVED ======');
      _ref.read(dashboardControllerProvider.notifier).loadWalletBalance();
    });

    // Dynamic wallet update (wallet:update:userId)
    final userId = _ref.read(userIdProvider);
    if (userId.isNotEmpty) {
      _socket!.on('wallet:update:$userId', (data) {
        AppLogger.debug('💳 Wallet update received for user $userId');
        _ref.read(dashboardControllerProvider.notifier).loadWalletBalance();
        _refetchAllData(); // Refresh history too as balance changed
      });
    }

    // Notification updates
    _socket!.on('notification', (data) {
      AppLogger.debug('====== NOTIFICATION RECEIVED ======');
    });

    // Support notifications
    _socket!.on('user_support_notification', (data) {
      AppLogger.debug('====== USER SUPPORT NOTIFICATION ======');
      try {
        _ref.read(supportTicketsProvider.notifier).fetchTickets();
      } catch (_) {}

      final int ticketId = data is Map ? (data['ticketId'] as num?)?.toInt() ?? 0 : 0;
      final activeTicketId = _ref.read(activeTicketIdProvider);

      if (activeTicketId == ticketId) {
        // User is currently looking at this ticket's chat screen!
        // We do NOT want to show the sliding toast alert.
        // BUT we DO want to ensure the message gets appended to the active chat thread.
        try {
          if (data is Map && data.containsKey('message') && data['message'] is Map) {
            final messageMap = Map<String, dynamic>.from(data['message'] as Map);
            _ref.read(ticketDetailsProvider(ticketId).notifier).handleIncomingMessage(messageMap);
          }
        } catch (e, stackTrace) {
          AppLogger.error('Error updating active ticket details from notification', e, stackTrace);
        }
        return;
      }

      final msg = data != null && data['message'] != null
          ? data['message']['message'] ?? 'New reply to your ticket'
          : 'New reply to your ticket';

      final context = navigatorKey.currentContext;
      if (context != null) {
        ToastHelper.showToast(
          context: context,
          message: "Support: $msg",
          icon: Icons.support_agent_rounded,
          iconColor: primaryColor,
          position: ToastPosition.top,
        );
      }
    });

    // Real-time support messages inside active ticket chat room
    _socket!.on('new_support_message', (data) {
      AppLogger.debug('====== NEW SUPPORT MESSAGE ======');
      try {
        if (data is Map) {
          final Map<String, dynamic> messageMap = (data.containsKey('message') && data['message'] is Map)
              ? Map<String, dynamic>.from(data['message'] as Map)
              : Map<String, dynamic>.from(data);
          
          final ticketId = (messageMap['ticketId'] as num?)?.toInt();
          final activeTicketId = _ref.read(activeTicketIdProvider);
          if (ticketId != null && activeTicketId == ticketId) {
            _ref.read(ticketDetailsProvider(ticketId).notifier).handleIncomingMessage(messageMap);
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error handling new_support_message socket event', e, stackTrace);
      }
    });

    // Real-time support ticket resolution event
    _socket!.on('ticket_resolved', (data) {
      AppLogger.debug('====== TICKET RESOLVED ======');
      try {
        final ticketId = data is Map ? (data['id'] as num?)?.toInt() : null;
        final activeTicketId = _ref.read(activeTicketIdProvider);
        if (ticketId != null && activeTicketId == ticketId) {
          _ref.read(ticketDetailsProvider(ticketId).notifier).handleTicketResolved(data);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error handling ticket_resolved socket event', e, stackTrace);
      }
    });

    // Service status updates
    _socket!.on('service_status_changed', (data) {
      AppLogger.debug('📡 Socket.IO service_status_changed event received');
      try {
        if (data != null) {
          final updatedStatus = ServicesStatus.fromJson(Map<String, dynamic>.from(data as Map));
          _ref.read(servicesStatusProvider.notifier).updateStatus(updatedStatus);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Error parsing service_status_changed socket data', e, stackTrace);
      }
    });

    // Catch-all for any other events
    _socket!.onAny((event, data) {
      AppLogger.debug('📡 [ANY EVENT] Event: "$event"');
    });

    // Reconnection attempt
    _socket!.onReconnectAttempt((attemptNumber) {
      AppLogger.debug('🔄 Socket.IO reconnection attempt: $attemptNumber');
    });

    // Reconnection successful
    _socket!.onReconnect((attemptNumber) {
      AppLogger.debug('✅ Socket.IO reconnected after $attemptNumber attempts');
      state = SocketState.connected;
      _reconnectAttempts = 0;
    });

    // Reconnection error
    _socket!.onReconnectError((error) {
      AppLogger.error('Socket.IO reconnection error', error);
    });

    // Reconnection failed
    _socket!.onReconnectFailed((_) {
      AppLogger.error('Socket.IO reconnection failed');
      state = SocketState.error;
    });
  }

  void _handleDisconnection() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.error('Max reconnection attempts reached. Stopping reconnection.');
      state = SocketState.error;
      return;
    }

    _reconnectAttempts++;

    // Exponential backoff: 5s, 10s, 15s, 20s, 25s
    final delay = Duration(seconds: 5 * _reconnectAttempts);

    AppLogger.debug('🔄 Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && state != SocketState.connected) {
        AppLogger.debug('🔄 Reconnecting... (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
        connect();
      }
    });
  }

  Future<void> _disconnect() async {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    } catch (e, stackTrace) {
      AppLogger.error('Error disconnecting socket', e, stackTrace);
    }
  }

  void disconnect() {
    AppLogger.debug('Manually disconnecting Socket.IO');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _disconnect();
    state = SocketState.disconnected;
  }

  void reconnect() {
    AppLogger.debug('🔄 Manual reconnection requested');
    _reconnectAttempts = 0;
    _shouldReconnect = true;
    connect();
  }

  // Send message through socket
  void emit(String event, dynamic data) {
    if (_socket?.connected == true) {
      _socket!.emit(event, data);
      AppLogger.debug('📤 Sent event: $event');
    } else {
      AppLogger.debug('⚠️ Cannot send $event - socket not connected');
    }
  }

  // Listen to specific events
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // Remove event listener
  void off(String event) {
    _socket?.off(event);
  }

  void _refetchAllData() {
    // Debounce to prevent multiple refreshes within a short window
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      try {
        // 1. Refetch Balance
        _ref.read(dashboardControllerProvider.notifier).loadWalletBalance();

        // 2. Refetch Transactions
        final userId = _ref.read(userIdProvider);
        if (userId.isNotEmpty) {
          _ref.read(recentTransactionsProvider(userId).notifier).refresh();
          _ref.read(allTransactionsProvider(userId).notifier).refresh();
        }

        // 3. Refetch Notifications
        _ref.read(notificationNotifierProvider.notifier).refresh();
        
        AppLogger.debug('All data refetched successfully via Socket event (debounced)');
      } catch (e, stackTrace) {
        AppLogger.error('Error refetching data', e, stackTrace);
      }
    });
  }

  @override
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _debounceTimer?.cancel();
    _disconnect();
    super.dispose();
  }
}

// Provider for socket state
final socketNotifierProvider = StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier(ref);
});

// Provider for the Socket.IO instance
final socketProvider = Provider<IO.Socket?>((ref) {
  final notifier = ref.watch(socketNotifierProvider.notifier);
  return notifier.socket;
});