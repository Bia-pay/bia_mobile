class DataPlanModel {
  final String name;
  final int amount;
  final String serviceId;
  final String? variationCode; // Add this field

  DataPlanModel({
    required this.name,
    required this.amount,
    required this.serviceId,
    this.variationCode,
  });

  factory DataPlanModel.fromJson(Map<String, dynamic> json) {
    return DataPlanModel(
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      serviceId: json['serviceID'] ?? '',
      variationCode: json['variation_code'], // Map from API response
    );
  }
}