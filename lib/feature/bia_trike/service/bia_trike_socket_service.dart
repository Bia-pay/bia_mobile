import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../model/bia_trike_ride_model.dart';

class BiaTrikeSocketService {
  socket_io.Socket? _socket;
  final String serverUrl = 'https://api.bia.com.ng';

  Function(DriverBid)? onBidReceived;
  Function(double)? onOfferUpdated;
  Function(BiaTrikeRideRequest)? onBidAccepted;
  Function(String status, DateTime timestamp)? onStatusChanged;

  Timer? _simulationTimer;
  int _activeRideId = 0;
  double _currentOfferFare = 0.0;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void initializeSocket(String token) {
    try {
      _socket = socket_io.io(
        serverUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint("🛺 Connected to Bia Trike Gateway Socket");
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint("⚠️ Disconnected from Bia Trike Gateway Socket");
      });

      _socket?.on('trike:bid:received', (data) {
        if (data != null && onBidReceived != null) {
          final bid = DriverBid.fromJson(Map<String, dynamic>.from(data));
          onBidReceived!(bid);
        }
      });

      _socket?.on('trike:offer:updated', (data) {
        if (data != null && onOfferUpdated != null) {
          final fare = (data['passengerOfferFare'] as num?)?.toDouble() ?? 0.0;
          onOfferUpdated!(fare);
        }
      });

      _socket?.on('trike:bid:accepted', (data) {
        if (data != null && onBidAccepted != null) {
          final req = BiaTrikeRideRequest.fromJson(Map<String, dynamic>.from(data));
          onBidAccepted!(req);
        }
      });

      _socket?.on('trike:ride:status_changed', (data) {
        if (data != null && onStatusChanged != null) {
          final status = data['status'] as String? ?? 'IN_TRANSIT';
          final tsStr = data['updatedAt'] as String?;
          final ts = tsStr != null ? DateTime.tryParse(tsStr) ?? DateTime.now() : DateTime.now();
          onStatusChanged!(status, ts);
        }
      });
    } catch (e) {
      debugPrint("⚠️ Socket init error: $e");
    }
  }

  void joinRideRoom(int rideId, double initialOffer) {
    _activeRideId = rideId;
    _currentOfferFare = initialOffer;

    if (_socket != null && _socket!.connected) {
      _socket?.emit('trike:ride:join', {'rideId': rideId});
    } else {
      debugPrint("ℹ️ Socket offline — starting fallback driver bidding simulator");
    }

    _startDriverBiddingSimulator();
  }

  void leaveRideRoom(int rideId) {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_socket != null && _socket!.connected) {
      _socket?.emit('trike:ride:leave', {'rideId': rideId});
    }
  }

  void updatePassengerOffer(double newFare) {
    _currentOfferFare = newFare;

    if (onOfferUpdated != null) {
      onOfferUpdated!(newFare);
    }

    // If simulating offline, produce immediate counter-bids tailored to updated price
    if (_simulationTimer != null && _simulationTimer!.isActive) {
      _generateSimulatedCounterBid(newFare);
    }
  }

  // Real-Time Simulator for demo/testing when socket server is unreachable
  void _startDriverBiddingSimulator() {
    _simulationTimer?.cancel();

    // 1st simulated bid after 2.5 seconds (Driver accepts exact offer or +50)
    _simulationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (_activeRideId == 0) return;
      final bid1 = DriverBid(
        id: 101,
        rideId: _activeRideId,
        driverId: 8,
        bidAmount: _currentOfferFare,
        etaMinutes: 2,
        distanceKm: 0.4,
        status: 'PENDING',
        driver: DriverInfo(
          id: 8,
          name: 'Aliyu Bello',
          phone: '+2348031234501',
          rating: 4.9,
          trikeModel: 'Bajaj RE 4S Yellow',
          plateNumber: 'KMC-482-XA',
          totalTrips: 1240,
        ),
        createdAt: DateTime.now(),
      );
      if (onBidReceived != null) onBidReceived!(bid1);
    });

    // 2nd simulated counter-bid after 5.5 seconds
    Timer(const Duration(milliseconds: 5500), () {
      if (_activeRideId == 0) return;
      final bid2 = DriverBid(
        id: 102,
        rideId: _activeRideId,
        driverId: 11,
        bidAmount: _currentOfferFare + 100.0,
        etaMinutes: 4,
        distanceKm: 0.8,
        status: 'PENDING',
        driver: DriverInfo(
          id: 11,
          name: 'Musa Ibrahim',
          phone: '+2348169876542',
          rating: 4.8,
          trikeModel: 'TVS King Deluxe Blue',
          plateNumber: 'TRK-912-KN',
          totalTrips: 890,
        ),
        createdAt: DateTime.now(),
      );
      if (onBidReceived != null) onBidReceived!(bid2);
    });
  }

  void _generateSimulatedCounterBid(double currentPrice) {
    Timer(const Duration(milliseconds: 1200), () {
      if (_activeRideId == 0) return;
      final bid3 = DriverBid(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        rideId: _activeRideId,
        driverId: 19,
        bidAmount: currentPrice,
        etaMinutes: 1,
        distanceKm: 0.2,
        status: 'PENDING',
        driver: DriverInfo(
          id: 19,
          name: 'Kabiru Sani (Speedy)',
          phone: '+2348029988771',
          rating: 5.0,
          trikeModel: 'Bia EV Eco Trike Green',
          plateNumber: 'KAN-551-ZZ',
          totalTrips: 410,
        ),
        createdAt: DateTime.now(),
      );
      if (onBidReceived != null) onBidReceived!(bid3);
    });
  }

  void dispose() {
    _simulationTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
  }
}
