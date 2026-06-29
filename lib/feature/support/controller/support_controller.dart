import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import '../../../core/easy_loading_config.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../../../app/utils/colors.dart';
import '../../../app/socket/socket_provider.dart';
import '../model/support_ticket_model.dart';
import '../repository/support_repository.dart';

// Provider to track the active ticket ID user is currently viewing in chat screen
final activeTicketIdProvider = StateProvider<int?>((ref) => null);

// ── SUPPORT TICKETS CONTROLLER ───────────────────────────────────────────────

class SupportTicketsNotifier extends StateNotifier<AsyncValue<List<SupportTicket>>> {
  final SupportRepository _repo;

  SupportTicketsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    try {
      final list = await _repo.getTickets();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createTicket(BuildContext context, String subject, String description) async {
    if (subject.trim().isEmpty || description.trim().isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Subject and Description cannot be empty.",
        icon: Icons.info,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return false;
    }

    try {
      LoadingHelper.show('Creating ticket...');
      final newTicket = await _repo.createTicket(subject.trim(), description.trim());
      LoadingHelper.dismiss();

      if (newTicket != null) {
        // Refresh ticket list
        final currentList = state.value ?? [];
        state = AsyncValue.data([newTicket, ...currentList]);
        
        ToastHelper.showToast(
          context: context,
          message: "Support ticket created successfully.",
          icon: Icons.check_circle_outline_rounded,
          iconColor: primaryGreenColor,
          position: ToastPosition.top,
        );
        return true;
      } else {
        ToastHelper.showToast(
          context: context,
          message: "Failed to create support ticket.",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
        return false;
      }
    } catch (e) {
      LoadingHelper.dismiss();
      ToastHelper.showToast(
        context: context,
        message: "An error occurred. Please try again.",
        icon: Icons.error_outline_rounded,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return false;
    }
  }
}

final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, AsyncValue<List<SupportTicket>>>((ref) {
  final repo = ref.watch(supportRepositoryProvider);
  return SupportTicketsNotifier(repo);
});

// ── TICKET DETAILS CONTROLLER ────────────────────────────────────────────────

class TicketDetailsNotifier extends StateNotifier<AsyncValue<SupportTicket?>> {
  final SupportRepository _repo;
  final int _ticketId;
  final Ref _ref;

  TicketDetailsNotifier(this._repo, this._ticketId, this._ref) : super(const AsyncValue.loading()) {
    fetchDetails();
    _joinTicketRoom();
  }

  void _joinTicketRoom() {
    Future.microtask(() {
      _ref.read(activeTicketIdProvider.notifier).state = _ticketId;
    });

    final socket = _ref.read(socketProvider);
    if (socket != null) {
      print('🔌 TicketDetailsNotifier: Joining room for ticket $_ticketId');
      socket.emit('joinTicket', {'ticketId': _ticketId});
    }
  }

  void handleIncomingMessage(dynamic messageData) {
    if (messageData == null) return;
    try {
      final msg = SupportMessage.fromJson(messageData);
      if (msg.ticketId == _ticketId) {
        final currentTicket = state.value;
        if (currentTicket != null) {
          // Check for duplicate messages
          if (currentTicket.messages.any((m) => m.id == msg.id)) return;
          
          final updatedMessages = [...currentTicket.messages, msg];
          state = AsyncValue.data(
            SupportTicket(
              id: currentTicket.id,
              userId: currentTicket.userId,
              subject: currentTicket.subject,
              description: currentTicket.description,
              status: currentTicket.status,
              aiEscalated: currentTicket.aiEscalated,
              resolution: currentTicket.resolution,
              createdAt: currentTicket.createdAt,
              updatedAt: currentTicket.updatedAt,
              messages: updatedMessages,
            ),
          );
        }
      }
    } catch (e) {
      print('Error parsing socket support message: $e');
    }
  }

  void handleTicketResolved(dynamic resolvedData) {
    if (resolvedData == null) return;
    try {
      final currentTicket = state.value;
      if (currentTicket != null) {
        state = AsyncValue.data(
          SupportTicket(
            id: currentTicket.id,
            userId: currentTicket.userId,
            subject: currentTicket.subject,
            description: currentTicket.description,
            status: 'resolved',
            aiEscalated: currentTicket.aiEscalated,
            resolution: resolvedData is Map ? resolvedData['resolution']?.toString() : null,
            createdAt: currentTicket.createdAt,
            updatedAt: currentTicket.updatedAt,
            messages: currentTicket.messages,
          ),
        );
      }
    } catch (e) {
      print('Error parsing ticket resolved event: $e');
    }
  }

  Future<void> fetchDetails() async {
    try {
      final ticket = await _repo.getTicketDetails(_ticketId);
      state = AsyncValue.data(ticket);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendMessage(BuildContext context, String messageText) async {
    if (messageText.trim().isEmpty) return false;

    try {
      final newMsg = await _repo.sendMessage(_ticketId, messageText.trim());
      
      if (newMsg != null) {
        final currentTicket = state.value;
        if (currentTicket != null) {
          // If the message is already added via Socket.io event, don't duplicate
          if (currentTicket.messages.any((m) => m.id == newMsg.id)) return true;

          final updatedMessages = [...currentTicket.messages, newMsg];
          state = AsyncValue.data(
            SupportTicket(
              id: currentTicket.id,
              userId: currentTicket.userId,
              subject: currentTicket.subject,
              description: currentTicket.description,
              status: currentTicket.status,
              aiEscalated: currentTicket.aiEscalated,
              resolution: currentTicket.resolution,
              createdAt: currentTicket.createdAt,
              updatedAt: currentTicket.updatedAt,
              messages: updatedMessages,
            ),
          );
        }
        return true;
      } else {
        ToastHelper.showToast(
          context: context,
          message: "Failed to send message.",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
        return false;
      }
    } catch (e) {
      ToastHelper.showToast(
        context: context,
        message: "Failed to send message. Please try again.",
        icon: Icons.error_outline_rounded,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return false;
    }
  }

  @override
  void dispose() {
    final socket = _ref.read(socketProvider);
    if (socket != null) {
      print('🔌 TicketDetailsNotifier: Leaving room for ticket $_ticketId');
      socket.emit('leaveTicket', {'ticketId': _ticketId});
    }
    if (_ref.read(activeTicketIdProvider) == _ticketId) {
      _ref.read(activeTicketIdProvider.notifier).state = null;
    }
    super.dispose();
  }
}

final ticketDetailsProvider =
    StateNotifierProvider.family<TicketDetailsNotifier, AsyncValue<SupportTicket?>, int>((ref, ticketId) {
  final repo = ref.watch(supportRepositoryProvider);
  return TicketDetailsNotifier(repo, ticketId, ref);
});
