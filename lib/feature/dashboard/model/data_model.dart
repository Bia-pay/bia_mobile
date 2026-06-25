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
    final rawAmount = json['variation_amount'] ?? json['amount'] ?? 0;
    int amountVal = 0;
    if (rawAmount is int) {
      amountVal = rawAmount;
    } else if (rawAmount is double) {
      amountVal = rawAmount.toInt();
    } else if (rawAmount is String) {
      amountVal = double.tryParse(rawAmount.replaceAll(',', '').replaceAll('₦', '').replaceAll('N', '').trim())?.toInt() ?? 0;
    }

    return DataPlanModel(
      name: json['name'] ?? '',
      amount: amountVal,
      serviceId: json['serviceID'] ?? '',
      variationCode: json['variation_code'], // Map from API response
    );
  }
}