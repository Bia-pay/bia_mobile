class VerifyAccountResponseBody {
  final String fullname;

  VerifyAccountResponseBody({required this.fullname});

  factory VerifyAccountResponseBody.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return VerifyAccountResponseBody(fullname: '');
    }
    return VerifyAccountResponseBody(fullname: json['fullname'] ?? '');
  }

  Map<String, dynamic> toJson() => {'fullname': fullname};
}