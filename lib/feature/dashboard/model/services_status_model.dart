class ServicesStatus {
  final bool airtime;
  final bool data;
  final bool cable;
  final bool electricity;
  final bool utility;
  final bool edu;
  final bool qr;
  final bool splitPayment;
  final bool biaTrike;
  final bool withdrawal;

  const ServicesStatus({
    required this.airtime,
    required this.data,
    required this.cable,
    required this.electricity,
    required this.utility,
    required this.edu,
    required this.qr,
    required this.splitPayment,
    required this.biaTrike,
    required this.withdrawal,
  });

  factory ServicesStatus.fromJson(Map<String, dynamic> json) {
    final cableVal = json['cable'] ?? json['utility'] ?? true;
    final electricityVal = json['electricity'] ?? json['utility'] ?? true;
    final utilityVal = json['utility'] ?? (cableVal && electricityVal);

    return ServicesStatus(
      airtime: json['airtime'] ?? true,
      data: json['data'] ?? true,
      cable: cableVal,
      electricity: electricityVal,
      utility: utilityVal,
      edu: json['edu'] ?? true,
      qr: json['qr'] ?? true,
      splitPayment: json['split_payment'] ?? json['splitPayment'] ?? true,
      biaTrike: json['bia_trike'] ?? json['biaTrike'] ?? true,
      withdrawal: json['withdrawal'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airtime': airtime,
      'data': data,
      'cable': cable,
      'electricity': electricity,
      'utility': utility,
      'edu': edu,
      'qr': qr,
      'split_payment': splitPayment,
      'bia_trike': biaTrike,
      'withdrawal': withdrawal,
    };
  }

  ServicesStatus copyWith({
    bool? airtime,
    bool? data,
    bool? cable,
    bool? electricity,
    bool? utility,
    bool? edu,
    bool? qr,
    bool? splitPayment,
    bool? biaTrike,
    bool? withdrawal,
  }) {
    return ServicesStatus(
      airtime: airtime ?? this.airtime,
      data: data ?? this.data,
      cable: cable ?? this.cable,
      electricity: electricity ?? this.electricity,
      utility: utility ?? this.utility,
      edu: edu ?? this.edu,
      qr: qr ?? this.qr,
      splitPayment: splitPayment ?? this.splitPayment,
      biaTrike: biaTrike ?? this.biaTrike,
      withdrawal: withdrawal ?? this.withdrawal,
    );
  }

  @override
  String toString() {
    return 'ServicesStatus(airtime: $airtime, data: $data, cable: $cable, electricity: $electricity, utility: $utility, edu: $edu, qr: $qr, splitPayment: $splitPayment, biaTrike: $biaTrike, withdrawal: $withdrawal)';
  }
}

