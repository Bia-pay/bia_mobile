class QrCodeResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final QrCodeBody? responseBody;

  QrCodeResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    this.responseBody,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      responseSuccessful: json['responseSuccessful'] ?? false,
      responseMessage: json['responseMessage'] ?? '',
      responseBody: json['responseBody'] != null
          ? QrCodeBody.fromJson(json['responseBody'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseSuccessful': responseSuccessful,
      'responseMessage': responseMessage,
      'responseBody': responseBody?.toJson(),
    };
  }
}

class QrCodeBody {
  final String? url;

  QrCodeBody({this.url});

  factory QrCodeBody.fromJson(Map<String, dynamic> json) {
    return QrCodeBody(
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}