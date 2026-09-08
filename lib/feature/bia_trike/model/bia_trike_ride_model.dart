class DriverInfo {
  final int id;
  final String name;
  final String phone;
  final double rating;
  final String trikeModel;
  final String plateNumber;
  final String? avatar;
  final int totalTrips;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.trikeModel,
    required this.plateNumber,
    this.avatar,
    this.totalTrips = 0,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Driver',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      trikeModel: json['trikeModel'] as String? ?? 'Bajaj RE 4S',
      plateNumber: json['plateNumber'] as String? ?? 'KMC-000-XX',
      avatar: json['avatar'] as String?,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'rating': rating,
        'trikeModel': trikeModel,
        'plateNumber': plateNumber,
        'avatar': avatar,
        'totalTrips': totalTrips,
      };
}

class DriverBid {
  final int id;
  final int rideId;
  final int driverId;
  final double bidAmount;
  final int etaMinutes;
  final double distanceKm;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'
  final DriverInfo driver;
  final DateTime createdAt;

  DriverBid({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.bidAmount,
    required this.etaMinutes,
    required this.distanceKm,
    required this.status,
    required this.driver,
    required this.createdAt,
  });

  factory DriverBid.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>? ?? {};
    return DriverBid(
      id: (json['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      rideId: (json['rideId'] as num?)?.toInt() ?? 0,
      driverId: (json['driverId'] as num?)?.toInt() ?? (driverJson['id'] as num?)?.toInt() ?? 0,
      bidAmount: (json['bidAmount'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 3,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.5,
      status: json['status'] as String? ?? 'PENDING',
      driver: DriverInfo.fromJson(driverJson),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'driverId': driverId,
        'bidAmount': bidAmount,
        'etaMinutes': etaMinutes,
        'distanceKm': distanceKm,
        'status': status,
        'driver': driver.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class RideEstimate {
  final String city;
  final String rideType; // 'STANDARD_KEKE', 'SHARED_KEKE', 'EXPRESS_CARGO'
  final double distanceKm;
  final int durationMins;
  final double baseFare;
  final double recommendedOffer;
  final double minAllowedOffer;
  final double maxAllowedOffer;
  final int discountPct;
  final double perKmRate;

  RideEstimate({
    required this.city,
    required this.rideType,
    required this.distanceKm,
    required this.durationMins,
    required this.baseFare,
    required this.recommendedOffer,
    required this.minAllowedOffer,
    required this.maxAllowedOffer,
    required this.discountPct,
    required this.perKmRate,
  });

  factory RideEstimate.fromJson(Map<String, dynamic> json) {
    return RideEstimate(
      city: json['city'] as String? ?? 'Kano',
      rideType: json['rideType'] as String? ?? 'STANDARD_KEKE',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 5.0,
      durationMins: (json['durationMins'] as num?)?.toInt() ?? 15,
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 1000.0,
      recommendedOffer: (json['recommendedOffer'] as num?)?.toDouble() ?? 1000.0,
      minAllowedOffer: (json['minAllowedOffer'] as num?)?.toDouble() ?? 500.0,
      maxAllowedOffer: (json['maxAllowedOffer'] as num?)?.toDouble() ?? 3000.0,
      discountPct: (json['discountPct'] as num?)?.toInt() ?? 0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'rideType': rideType,
        'distanceKm': distanceKm,
        'durationMins': durationMins,
        'baseFare': baseFare,
        'recommendedOffer': recommendedOffer,
        'minAllowedOffer': minAllowedOffer,
        'maxAllowedOffer': maxAllowedOffer,
        'discountPct': discountPct,
        'perKmRate': perKmRate,
      };
}

class BiaTrikeRideRequest {
  final int rideId;
  final String rideCode;
  final String status; // 'NEGOTIATING', 'ACCEPTED', 'ARRIVED', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED'
  final double passengerOfferFare;
  final double baseEstimatedFare;
  final String otpCode;
  final String pickupAddress;
  final String destinationAddress;
  final String city;
  final String rideType;
  final String paymentMethod; // 'WALLET', 'CASH'
  final DriverInfo? driver;
  final double? finalFare;
  final DateTime createdAt;

  BiaTrikeRideRequest({
    required this.rideId,
    required this.rideCode,
    required this.status,
    required this.passengerOfferFare,
    required this.baseEstimatedFare,
    required this.otpCode,
    required this.pickupAddress,
    required this.destinationAddress,
    this.city = 'Kano',
    this.rideType = 'STANDARD_KEKE',
    this.paymentMethod = 'WALLET',
    this.driver,
    this.finalFare,
    required this.createdAt,
  });

  factory BiaTrikeRideRequest.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;
    return BiaTrikeRideRequest(
      rideId: (json['rideId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      rideCode: json['rideCode'] as String? ?? 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      status: json['status'] as String? ?? 'NEGOTIATING',
      passengerOfferFare: (json['passengerOfferFare'] as num?)?.toDouble() ?? 800.0,
      baseEstimatedFare: (json['baseEstimatedFare'] as num?)?.toDouble() ?? 1000.0,
      otpCode: json['otpCode'] as String? ?? '1699',
      pickupAddress: json['pickupAddress'] as String? ?? 'Pickup Point',
      destinationAddress: json['destinationAddress'] as String? ?? 'Destination',
      city: json['city'] as String? ?? 'Kano',
      rideType: json['rideType'] as String? ?? 'STANDARD_KEKE',
      paymentMethod: json['paymentMethod'] as String? ?? 'WALLET',
      driver: driverJson != null ? DriverInfo.fromJson(driverJson) : null,
      finalFare: (json['finalFare'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rideId': rideId,
        'rideCode': rideCode,
        'status': status,
        'passengerOfferFare': passengerOfferFare,
        'baseEstimatedFare': baseEstimatedFare,
        'otpCode': otpCode,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'city': city,
        'rideType': rideType,
        'paymentMethod': paymentMethod,
        'driver': driver?.toJson(),
        'finalFare': finalFare,
        'createdAt': createdAt.toIso8601String(),
      };

  BiaTrikeRideRequest copyWith({
    int? rideId,
    String? rideCode,
    String? status,
    double? passengerOfferFare,
    double? baseEstimatedFare,
    String? otpCode,
    String? pickupAddress,
    String? destinationAddress,
    String? city,
    String? rideType,
    String? paymentMethod,
    DriverInfo? driver,
    double? finalFare,
    DateTime? createdAt,
  }) {
    return BiaTrikeRideRequest(
      rideId: rideId ?? this.rideId,
      rideCode: rideCode ?? this.rideCode,
      status: status ?? this.status,
      passengerOfferFare: passengerOfferFare ?? this.passengerOfferFare,
      baseEstimatedFare: baseEstimatedFare ?? this.baseEstimatedFare,
      otpCode: otpCode ?? this.otpCode,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      city: city ?? this.city,
      rideType: rideType ?? this.rideType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      driver: driver ?? this.driver,
      finalFare: finalFare ?? this.finalFare,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DigitalRiderPass {
  final String passCode;
  final String status; // 'VERIFYING', 'APPROVED', 'REJECTED', 'SUSPENDED'
  final String plateNumber;
  final String trikeModel;
  final String city;
  final double rating;
  final int totalTrips;
  final bool isOnline;
  final String qrPayload;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  DigitalRiderPass({
    required this.passCode,
    required this.status,
    required this.plateNumber,
    required this.trikeModel,
    required this.city,
    this.rating = 4.9,
    this.totalTrips = 0,
    this.isOnline = false,
    required this.qrPayload,
    this.verifiedAt,
    this.rejectionReason,
  });

  factory DigitalRiderPass.fromJson(Map<String, dynamic> json) {
    return DigitalRiderPass(
      passCode: json['passCode'] as String? ?? 'BIA-TRK-2026-6878',
      status: json['status'] as String? ?? 'VERIFYING',
      plateNumber: json['plateNumber'] as String? ?? 'KMC-482-XA',
      trikeModel: json['trikeModel'] as String? ?? 'Bajaj RE 4S (Yellow)',
      city: json['city'] as String? ?? 'Kano',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      qrPayload: json['qrPayload'] as String? ?? 'BIA-TRK-PASS:BIA-TRK-2026-6878',
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'passCode': passCode,
        'status': status,
        'plateNumber': plateNumber,
        'trikeModel': trikeModel,
        'city': city,
        'rating': rating,
        'totalTrips': totalTrips,
        'isOnline': isOnline,
        'qrPayload': qrPayload,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  DigitalRiderPass copyWith({
    String? passCode,
    String? status,
    String? plateNumber,
    String? trikeModel,
    String? city,
    double? rating,
    int? totalTrips,
    bool? isOnline,
    String? qrPayload,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return DigitalRiderPass(
      passCode: passCode ?? this.passCode,
      status: status ?? this.status,
      plateNumber: plateNumber ?? this.plateNumber,
      trikeModel: trikeModel ?? this.trikeModel,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      isOnline: isOnline ?? this.isOnline,
      qrPayload: qrPayload ?? this.qrPayload,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
