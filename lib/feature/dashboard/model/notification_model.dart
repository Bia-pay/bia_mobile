import 'dart:convert';
import 'pagination_model.dart';

class NotificationResponse {
  final bool responseSuccessful;
  final String responseMessage;
  final NotificationData? responseBody;

  NotificationResponse({
    required this.responseSuccessful,
    required this.responseMessage,
    this.responseBody,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) => NotificationResponse(
        responseSuccessful: json["responseSuccessful"] ?? false,
        responseMessage: json["responseMessage"] ?? "",
        responseBody: json["responseBody"] == null ? null : NotificationData.fromJson(json["responseBody"]),
      );
}

class NotificationData {
  final List<NotificationItem> notifications;
  final Pagination? pagination;

  NotificationData({
    required this.notifications,
    this.pagination,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) => NotificationData(
        notifications: json["notifications"] == null
            ? []
            : List<NotificationItem>.from(json["notifications"].map((x) => NotificationItem.fromJson(x))),
        pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]),
      );
}

class NotificationItem {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json["id"] ?? 0,
        userId: json["userId"] ?? 0,
        title: json["title"] ?? "",
        message: json["message"] ?? "",
        isRead: json["isRead"] ?? false,
        createdAt: json["createdAt"] == null ? DateTime.now() : DateTime.parse(json["createdAt"]),
      );

  NotificationItem copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        message: message ?? this.message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}
