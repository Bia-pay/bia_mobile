import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../model/bia_trike_model.dart';
import '../model/bia_trike_ride_model.dart';
import '../service/bia_trike_api_service.dart';
import '../service/bia_trike_socket_service.dart';

class BiaTrikeState {
  final BiaTrikeRideRequest? activeRide;
  final DigitalRiderPass? riderPass;
  final BiaTrikeRiderApplication? riderApp;
  final List<DriverBid> bids;
  final double currentOffer;
  final double minOffer;
  final double maxOffer;
  final String selectedRideType; // 'STANDARD_KEKE', 'SHARED_KEKE', 'EXPRESS_CARGO'
  final String paymentMethod; // 'WALLET', 'CASH'
  final String dialect; // 'english', 'hausa', 'pidgin'
  final bool isSearching;
  final bool isLoading;
  final String? errorMessage;

  BiaTrikeState({
    this.activeRide,
    this.riderPass,
    this.riderApp,
    this.bids = const [],
    this.currentOffer = 1000.0,
    this.minOffer = 400.0,
    this.maxOffer = 5000.0,
    this.selectedRideType = 'STANDARD_KEKE',
    this.paymentMethod = 'WALLET',
    this.dialect = 'english',
    this.isSearching = false,
    this.isLoading = false,
    this.errorMessage,
  });

  BiaTrikeState copyWith({
    BiaTrikeRideRequest? activeRide,
    bool clearActiveRide = false,
    DigitalRiderPass? riderPass,
    bool clearRiderPass = false,
    BiaTrikeRiderApplication? riderApp,
    bool clearRiderApp = false,
    List<DriverBid>? bids,
    double? currentOffer,
    double? minOffer,
    double? maxOffer,
    String? selectedRideType,
    String? paymentMethod,
    String? dialect,
    bool? isSearching,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BiaTrikeState(
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
      riderPass: clearRiderPass ? null : (riderPass ?? this.riderPass),
      riderApp: clearRiderApp ? null : (riderApp ?? this.riderApp),
      bids: bids ?? this.bids,
      currentOffer: currentOffer ?? this.currentOffer,
      minOffer: minOffer ?? this.minOffer,
      maxOffer: maxOffer ?? this.maxOffer,
      selectedRideType: selectedRideType ?? this.selectedRideType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dialect: dialect ?? this.dialect,
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BiaTrikeNotifier extends StateNotifier<BiaTrikeState> {
  final BiaTrikeApiService _apiService;
  final BiaTrikeSocketService _socketService = BiaTrikeSocketService();

  BiaTrikeNotifier(this._apiService) : super(BiaTrikeState()) {
    _initController();
  }

  Future<void> _initController() async {
    _loadSavedPreferences();
    _setupSocketListeners();
    await checkActiveRideAndPass();
  }

  void _loadSavedPreferences() {
    try {
      if (Hive.isBoxOpen('authBox')) {
        final box = Hive.box('authBox');
        final savedDialect = box.get('bia_trike_language', defaultValue: 'english') as String;
        state = state.copyWith(dialect: savedDialect);
      }
    } catch (_) {}
  }

  void setDialect(String dialect) {
    state = state.copyWith(dialect: dialect);
    try {
      if (Hive.isBoxOpen('authBox')) {
        Hive.box('authBox').put('bia_trike_language', dialect);
      }
    } catch (_) {}
  }

  void _setupSocketListeners() {
    _socketService.onBidReceived = (newBid) {
      final existingIndex = state.bids.indexWhere((b) => b.id == newBid.id);
      List<DriverBid> updatedList;
      if (existingIndex != -1) {
        updatedList = List.from(state.bids)..[existingIndex] = newBid;
      } else {
        updatedList = [newBid, ...state.bids];
      }
      state = state.copyWith(bids: updatedList);
    };

    _socketService.onOfferUpdated = (fare) {
      state = state.copyWith(currentOffer: fare);
    };

    _socketService.onBidAccepted = (acceptedReq) {
      state = state.copyWith(
        activeRide: acceptedReq,
        isSearching: false,
      );
    };

    _socketService.onStatusChanged = (newStatus, timestamp) {
      if (state.activeRide != null) {
        final updated = state.activeRide!.copyWith(status: newStatus);
        state = state.copyWith(activeRide: updated);
      }
    };
  }

  Future<void> checkActiveRideAndPass() async {
    state = state.copyWith(isLoading: true);

    final activeReq = await _apiService.getActiveRide();
    final pass = await _apiService.getDigitalRiderPass();

    if (activeReq != null) {
      state = state.copyWith(
        activeRide: activeReq,
        currentOffer: activeReq.passengerOfferFare,
        selectedRideType: activeReq.rideType,
        isSearching: activeReq.status == 'NEGOTIATING',
      );

      _socketService.joinRideRoom(activeReq.rideId, activeReq.passengerOfferFare);
    }

    if (pass != null) {
      state = state.copyWith(riderPass: pass);
    }

    state = state.copyWith(isLoading: false);
  }

  void selectRideType(String rideType) {
    double fare = 1000.0;
    if (rideType == 'SHARED_KEKE') {
      fare = 650.0; // 35% fare discount
    } else if (rideType == 'EXPRESS_CARGO') {
      fare = 1400.0;
    }
    state = state.copyWith(
      selectedRideType: rideType,
      currentOffer: fare,
      minOffer: (fare * 0.6).clamp(300.0, 5000.0),
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void adjustOffer(double delta) {
    final nextOffer = (state.currentOffer + delta).clamp(state.minOffer, state.maxOffer);
    state = state.copyWith(currentOffer: nextOffer);

    if (state.activeRide != null && state.isSearching) {
      _apiService.adjustOfferFare(state.activeRide!.rideId, nextOffer);
      _socketService.updatePassengerOffer(nextOffer);
    }
  }

  Future<bool> createRideRequest({
    required String pickupAddress,
    required String destinationAddress,
    required String city,
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final req = await _apiService.createRideRequest(
        pickupAddress: pickupAddress,
        pickupLat: pickupLat ?? 11.9964,
        pickupLng: pickupLng ?? 8.5167,
        destinationAddress: destinationAddress,
        destLat: destLat ?? 12.0022,
        destLng: destLng ?? 8.5920,
        city: city,
        rideType: state.selectedRideType,
        passengerOfferFare: state.currentOffer,
        paymentMethod: state.paymentMethod,
      );

      state = state.copyWith(
        activeRide: req,
        bids: [],
        isSearching: true,
        isLoading: false,
      );

      _socketService.joinRideRoom(req.rideId, req.passengerOfferFare);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create ride request: $e',
      );
      return false;
    }
  }

  Future<bool> acceptBid(DriverBid bid) async {
    if (state.activeRide == null) return false;

    state = state.copyWith(isLoading: true);

    final accepted = await _apiService.acceptBid(state.activeRide!.rideId, bid.id);

    if (accepted != null) {
      state = state.copyWith(
        activeRide: accepted,
        isSearching: false,
        isLoading: false,
      );
      return true;
    } else {
      // Local fallback lock
      final updatedReq = state.activeRide!.copyWith(
        status: 'ACCEPTED',
        driver: bid.driver,
        finalFare: bid.bidAmount,
      );
      state = state.copyWith(
        activeRide: updatedReq,
        isSearching: false,
        isLoading: false,
      );
      return true;
    }
  }

  Future<bool> cancelActiveRide({String? reason}) async {
    if (state.activeRide == null) return false;

    state = state.copyWith(isLoading: true);

    final rideId = state.activeRide!.rideId;
    await _apiService.cancelRide(rideId, cancelReason: reason);
    _socketService.leaveRideRoom(rideId);

    state = state.copyWith(
      clearActiveRide: true,
      bids: [],
      isSearching: false,
      isLoading: false,
    );
    return true;
  }

  Future<bool> submitRiderOnboarding({
    required String fullName,
    required String phoneNumber,
    required String city,
    required String trikeModel,
    required String plateNumber,
    required String licenseOrNin,
  }) async {
    state = state.copyWith(isLoading: true);

    final pass = await _apiService.submitRiderOnboarding(
      city: city,
      trikeModel: trikeModel,
      plateNumber: plateNumber,
      licenseOrNin: licenseOrNin,
    );

    // Save legacy app model as well for Hive sync
    final app = BiaTrikeRiderApplication(
      fullName: fullName,
      phoneNumber: phoneNumber,
      cityOfOperation: city,
      trikeModel: trikeModel,
      plateNumber: plateNumber,
      licenseOrNinNumber: licenseOrNin,
      submittedAt: DateTime.now(),
      status: pass?.status ?? 'VERIFYING',
    );

    try {
      final box = await Hive.openBox('appBox');
      await box.put('bia_trike_rider_app', app.toJson());
    } catch (_) {}

    state = state.copyWith(
      riderPass: pass,
      riderApp: app,
      isLoading: false,
    );
    return pass != null;
  }

  Future<void> toggleRiderOnlineStatus(bool isOnline) async {
    if (state.riderPass == null) return;

    final updatedPass = state.riderPass!.copyWith(isOnline: isOnline);
    state = state.copyWith(riderPass: updatedPass);

    await _apiService.updateRiderOnlineStatus(isOnline: isOnline);
  }

  Future<bool> advanceRideStatus(String newStatus, {String? otpCode}) async {
    if (state.activeRide == null) return false;

    if (newStatus == 'IN_TRANSIT' && (otpCode == null || otpCode != state.activeRide!.otpCode)) {
      state = state.copyWith(errorMessage: 'Invalid 4-digit trip OTP PIN.');
      return false;
    }

    final success = await _apiService.advanceRideStatus(
      state.activeRide!.rideId,
      newStatus,
      otpCode: otpCode,
    );

    if (success) {
      final updated = state.activeRide!.copyWith(status: newStatus);
      state = state.copyWith(activeRide: updated, clearError: true);
    }
    return success;
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}

// Unified Riverpod Provider
final biaTrikeStateNotifierProvider =
    StateNotifierProvider<BiaTrikeNotifier, BiaTrikeState>((ref) {
  final apiService = ref.watch(biaTrikeApiServiceProvider);
  return BiaTrikeNotifier(apiService);
});

// Backward compatibility alias for legacy widgets
final biaTrikeProvider = biaTrikeStateNotifierProvider;
