class BiaTrikeRiderApplication {
  final String fullName;
  final String phoneNumber;
  final String cityOfOperation;
  final String trikeModel;
  final String plateNumber;
  final String licenseOrNinNumber;
  final DateTime submittedAt;
  final String status; // 'PENDING_VERIFICATION', 'APPROVED', 'REJECTED'

  BiaTrikeRiderApplication({
    required this.fullName,
    required this.phoneNumber,
    required this.cityOfOperation,
    required this.trikeModel,
    required this.plateNumber,
    required this.licenseOrNinNumber,
    required this.submittedAt,
    this.status = 'PENDING_VERIFICATION',
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'cityOfOperation': cityOfOperation,
        'trikeModel': trikeModel,
        'plateNumber': plateNumber,
        'licenseOrNinNumber': licenseOrNinNumber,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status,
      };

  factory BiaTrikeRiderApplication.fromJson(Map<String, dynamic> json) {
    return BiaTrikeRiderApplication(
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      cityOfOperation: json['cityOfOperation'] ?? '',
      trikeModel: json['trikeModel'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      licenseOrNinNumber: json['licenseOrNinNumber'] ?? '',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      status: json['status'] ?? 'PENDING_VERIFICATION',
    );
  }
}
