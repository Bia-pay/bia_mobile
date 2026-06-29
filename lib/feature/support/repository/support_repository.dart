import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../model/support_ticket_model.dart';

final supportRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SupportRepository(apiClient);
});

class SupportRepository {
  final ApiClient _apiClient;

  SupportRepository(this._apiClient);

  Future<List<SupportTicket>> getTickets() async {
    try {
      final response = await _apiClient.getData(ApiConstant.SUPPORT_TICKETS);
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['responseSuccessful'] == true) {
        final List list = jsonResponse['responseBody'] ?? [];
        return list.map((e) => SupportTicket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<SupportTicket?> getTicketDetails(int ticketId) async {
    try {
      final response = await _apiClient.getData(ApiConstant.SUPPORT_TICKET_DETAILS(ticketId));
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true && jsonResponse['responseBody'] != null) {
        return SupportTicket.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SupportMessage?> sendMessage(int ticketId, String message) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.SEND_SUPPORT_MESSAGE(ticketId),
        {'message': message},
      );
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true && jsonResponse['responseBody'] != null) {
        return SupportMessage.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SupportTicket?> createTicket(String subject, String description) async {
    try {
      final response = await _apiClient.postData(
        ApiConstant.SUPPORT_TICKETS,
        {
          'subject': subject,
          'description': description,
        },
      );
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['responseSuccessful'] == true && jsonResponse['responseBody'] != null) {
        return SupportTicket.fromJson(jsonResponse['responseBody']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
