import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants.dart';

// Socket connection state
enum SocketState { idle, connecting, connected, disconnected, error }

class SocketNotifier extends StateNotifier<SocketState> {
  IO.Socket? _socket;
  String? _token;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  SocketNotifier() : super(SocketState.idle);

  IO.Socket? get socket => _socket;
  bool get isConnected => state == SocketState.connected && _socket?.connected == true;

  Future<void> connect() async {
    // Cancel any pending reconnect
    _reconnectTimer?.cancel();

    // Don't connect if already connecting or connected
    if (state == SocketState.connecting || (state == SocketState.connected && _socket?.connected == true)) {
      print('⚠️ Socket already ${state.name}');
      return;
    }

    try {
      state = SocketState.connecting;
      print('🔌 Attempting Socket.IO connection...');

      // Get user token from Hive
      final authBox = Hive.box('authBox');
      _token = authBox.get('token', defaultValue: '');

      if (_token == null || _token!.isEmpty) {
        print('⚠️ No token found, Socket.IO cannot connect');
        state = SocketState.idle;
        return;
      }

      // Build Socket.IO URL
      String socketUrl = AppConstants.baseUrl;
      
      // Remove trailing slash if present
      if (socketUrl.endsWith('/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 1);
      }

      print('🔌 Connecting to: $socketUrl');
      print('🔑 Using token: ${_token!.substring(0, 20)}...');

      // Disconnect existing socket if any
      await _disconnect();

      // Create Socket.IO connection with authentication
      _socket = IO.io(socketUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Allow fallback to polling
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(3000)
          .setReconnectionDelayMax(10000)
          .setTimeout(30000) // Increased timeout
          .enableForceNew() // Force new connection
          .setExtraHeaders({
            'Authorization': 'Bearer $_token',
          })
          .setAuth({
            'token': _token,
          })
          .build());

      _setupSocketListeners();
      
      // Connect the socket
      _socket!.connect();

    } catch (e, stackTrace) {
      print('❌ Socket.IO connection failed: $e');
      print('Stack trace: $stackTrace');
      state = SocketState.error;
      _handleDisconnection();
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection successful
    _socket!.onConnect((_) {
      print('✅ Socket.IO connected successfully');
      state = SocketState.connected;
      _reconnectAttempts = 0;
      
      // Send authentication after connection
      _socket!.emit('authenticate', {'token': _token});
    });

    // Connection error
    _socket!.onConnectError((error) {
      print('❌ Socket.IO connection error: $error');
      state = SocketState.error;
      _handleDisconnection();
    });

    // Disconnection
    _socket!.onDisconnect((reason) {
      print('🔌 Socket.IO disconnected: $reason');
      state = SocketState.disconnected;
      
      // Handle different disconnect reasons
      switch (reason) {
        case 'io client disconnect':
          print('📱 Manual disconnect - not reconnecting');
          break;
        case 'transport close':
          print('🚫 Transport closed - will attempt reconnection');
          _handleDisconnection();
          break;
        case 'transport error':
          print('❌ Transport error - will attempt reconnection');
          _handleDisconnection();
          break;
        case 'ping timeout':
          print('⏰ Ping timeout - will attempt reconnection');
          _handleDisconnection();
          break;
        default:
          print('🔄 Unexpected disconnect ($reason) - will attempt reconnection');
          _handleDisconnection();
          break;
      }
    });

    // Authentication response
    _socket!.on('authenticated', (data) {
      print('🔐 Socket.IO authenticated: $data');
    });

    // Authentication error
    _socket!.on('auth_error', (error) {
      print('❌ Socket.IO authentication error: $error');
      state = SocketState.error;
    });

    // Generic message handler
    _socket!.on('message', (data) {
      print('📥 Socket.IO message: $data');
    });

    // Transaction updates
    _socket!.on('transaction_update', (data) {
      print('💰 Transaction update: $data');
      // Handle transaction updates here
    });

    // Balance updates
    _socket!.on('balance_update', (data) {
      print('💳 Balance update: $data');
      // Handle balance updates here
    });

    // Notification updates
    _socket!.on('notification', (data) {
      print('🔔 Notification: $data');
      // Handle notifications here
    });

    // Reconnection attempt
    _socket!.onReconnectAttempt((attemptNumber) {
      print('🔄 Socket.IO reconnection attempt: $attemptNumber');
    });

    // Reconnection successful
    _socket!.onReconnect((attemptNumber) {
      print('✅ Socket.IO reconnected after $attemptNumber attempts');
      state = SocketState.connected;
      _reconnectAttempts = 0;
    });

    // Reconnection error
    _socket!.onReconnectError((error) {
      print('❌ Socket.IO reconnection error: $error');
    });

    // Reconnection failed
    _socket!.onReconnectFailed((_) {
      print('❌ Socket.IO reconnection failed');
      state = SocketState.error;
    });
  }

  void _handleDisconnection() {
    if (!_shouldReconnect) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached. Stopping reconnection.');
      print('💡 Tip: Check if backend Socket.IO server is running');
      state = SocketState.error;
      return;
    }

    _reconnectAttempts++;
    
    // Exponential backoff: 5s, 10s, 15s, 20s, 25s
    final delay = Duration(seconds: 5 * _reconnectAttempts);
    
    print('🔄 Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && state != SocketState.connected) {
        print('🔄 Reconnecting... (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
        connect();
      }
    });
  }

  Future<void> _disconnect() async {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    } catch (e) {
      print('⚠️ Error disconnecting socket: $e');
    }
  }

  void disconnect() {
    print('🔌 Manually disconnecting Socket.IO');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _disconnect();
    state = SocketState.disconnected;
  }

  void reconnect() {
    print('🔄 Manual reconnection requested');
    _reconnectAttempts = 0;
    _shouldReconnect = true;
    connect();
  }

  // Send message through socket
  void emit(String event, dynamic data) {
    if (_socket?.connected == true) {
      _socket!.emit(event, data);
      print('📤 Sent $event: $data');
    } else {
      print('⚠️ Cannot send $event - socket not connected');
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

  @override
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _disconnect();
    super.dispose();
  }
}

// Provider for socket state
final socketNotifierProvider = StateNotifierProvider<SocketNotifier, SocketState>((ref) {
  return SocketNotifier();
});

// Provider for the Socket.IO instance
final socketProvider = Provider<IO.Socket?>((ref) {
  final notifier = ref.watch(socketNotifierProvider.notifier);
  return notifier.socket;
});