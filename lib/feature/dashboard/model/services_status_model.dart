class ServicesStatus {
  final bool airtime;
  final bool data;
  final bool utility;
  final bool qr;

  const ServicesStatus({
    required this.airtime,
    required this.data,
    required this.utility,
    required this.qr,
  });

  factory ServicesStatus.fromJson(Map<String, dynamic> json) {
    return ServicesStatus(
      airtime: json['airtime'] ?? true,
      data: json['data'] ?? true,
      utility: json['utility'] ?? true,
      qr: json['qr'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airtime': airtime,
      'data': data,
      'utility': utility,
      'qr': qr,
    };
  }

  ServicesStatus copyWith({
    bool? airtime,
    bool? data,
    bool? utility,
    bool? qr,
  }) {
    return ServicesStatus(
      airtime: airtime ?? this.airtime,
      data: data ?? this.data,
      utility: utility ?? this.utility,
      qr: qr ?? this.qr,
    );
  }

  @override
  String toString() {
    return 'ServicesStatus(airtime: $airtime, data: $data, utility: $utility, qr: $qr)';
  }
}
