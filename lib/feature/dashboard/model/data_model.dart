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
    double parsedAmount = 0.0;
    final amtVal = json['variation_amount'] ?? json['amount'];
    if (amtVal != null) {
      if (amtVal is num) {
        parsedAmount = amtVal.toDouble();
      } else if (amtVal is String) {
        parsedAmount = double.tryParse(amtVal.replaceAll(',', '').trim()) ?? 0.0;
      }
    }

    return DataPlanModel(
      name: json['name'] ?? '',
      amount: parsedAmount.toInt(),
      serviceId: json['serviceID'] ?? '',
      variationCode: json['variation_code'],
    );
  }
}