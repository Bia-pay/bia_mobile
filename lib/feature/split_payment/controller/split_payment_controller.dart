import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import '../../../app/socket/socket_provider.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../../../core/easy_loading_config.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../model/split_models.dart';
import '../repository/split_payment_repository.dart';

// ── CREATOR SETUP NOTIFIER ───────────────────────────────────────────────────
class SplitCreatorNotifier
    extends StateNotifier<AsyncValue<CreateSplitResponse?>> {
  final SplitPaymentRepository _repo;

  SplitCreatorNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<CreateSplitResponse?> createSplit({
    required BuildContext context,
    String? title,
    String? description,
    DateTime? expiresAt,
    required List<ParticipantPayload> participants,
  }) async {
    if (participants.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Please add at least one participant.",
        icon: Icons.info_outline,
        iconColor: errorColor,
        position: ToastPosition.top,
      );
      return null;
    }

    state = const AsyncValue.loading();
    try {
      LoadingHelper.show('Generating QR...');

      final req = CreateSplitRequest(
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        description: description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        expiresAt: expiresAt?.toUtc().toIso8601String(),
        participants: participants,
      );

      final response = await _repo.createSplit(req);
      LoadingHelper.dismiss();

      if (response != null) {
        state = AsyncValue.data(response);
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Split request created successfully.",
            icon: Icons.check_circle_outline_rounded,
            iconColor: primaryGreenColor,
            position: ToastPosition.top,
          );
        }
        return response;
      } else {
        state = AsyncValue.error('Failed to create split', StackTrace.current);
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Failed to create split request.",
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        }
        return null;
      }
    } catch (e, st) {
      LoadingHelper.dismiss();
      state = AsyncValue.error(e, st);
      if (context.mounted) {
        ToastHelper.showToast(
          context: context,
          message: "An error occurred: $e",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final splitCreatorProvider =
    StateNotifierProvider<
      SplitCreatorNotifier,
      AsyncValue<CreateSplitResponse?>
    >((ref) {
      final repo = ref.watch(splitPaymentRepositoryProvider);
      return SplitCreatorNotifier(repo);
    });

// ── PARTICIPANT SCAN NOTIFIER ────────────────────────────────────────────────
class ScanSplitNotifier extends StateNotifier<AsyncValue<ScanSplitResponse?>> {
  final SplitPaymentRepository _repo;
  final Ref _ref;

  ScanSplitNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<ScanSplitResponse?> loadScanDetails({
    required BuildContext context,
    required String splitId,
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      final details = await _repo.scanSplit(splitId, token);
      if (details != null) {
        state = AsyncValue.data(details);
        return details;
      } else {
        state = AsyncValue.error(
          'Scan failed or not a participant',
          StackTrace.current,
        );
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message:
                "Unable to retrieve split details. You may not be a participant.",
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        }
        return null;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<PaySplitResponse?> paySplit({
    required BuildContext context,
    required String splitId,
    required String pin,
  }) async {
    try {
      LoadingHelper.show('Processing Payment...');
      final response = await _repo.paySplit(splitId, pin);
      LoadingHelper.dismiss();

      if (response != null) {
        _ref.read(dashboardControllerProvider.notifier).loadWalletBalance();
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message:
                "Payment of ₦${response.amountPaid} processed successfully.",
            icon: Icons.check_circle_outline_rounded,
            iconColor: primaryGreenColor,
            position: ToastPosition.top,
          );
        }
        return response;
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Payment failed. Please verify your PIN and try again.",
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        }
        return null;
      }
    } catch (e) {
      LoadingHelper.dismiss();
      if (context.mounted) {
        ToastHelper.showToast(
          context: context,
          message: "Error processing payment: $e",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
          position: ToastPosition.top,
        );
      }
      return null;
    }
  }
}

final scanSplitProvider =
    StateNotifierProvider<ScanSplitNotifier, AsyncValue<ScanSplitResponse?>>((
      ref,
    ) {
      final repo = ref.watch(splitPaymentRepositoryProvider);
      return ScanSplitNotifier(repo, ref);
    });

// ── CREATOR DETAILS & DASHBOARD NOTIFIER ──────────────────────────────────────
class SplitDetailsNotifier
    extends StateNotifier<AsyncValue<SplitDetailsResponse?>> {
  final SplitPaymentRepository _repo;
  final String _splitId;
  final Ref _ref;

  SplitDetailsNotifier(this._repo, this._splitId, this._ref)
    : super(const AsyncValue.loading()) {
    fetchDetails();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    final socket = _ref.read(socketProvider);
    if (socket != null) {
      debugPrint(
        '🔌 SplitDetailsNotifier: Listening to split progress events for $_splitId',
      );
      socket.on('split_progress_update', _onSocketProgressUpdate);
    }
  }

  void _onSocketProgressUpdate(dynamic data) {
    if (data == null) return;
    try {
      if (data is Map && data['splitId']?.toString() == _splitId) {
        debugPrint(
          '📡 SplitDetailsNotifier: Received real-time progress update for $_splitId',
        );
        fetchDetails();
      }
    } catch (e) {
      debugPrint('❌ Error handling split_progress_update socket event: $e');
    }
  }

  Future<void> fetchDetails() async {
    try {
      final details = await _repo.getSplitDetails(_splitId);
      if (details != null) {
        state = AsyncValue.data(details);
      } else {
        state = AsyncValue.error(
          'Failed to load split details',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendReminders(BuildContext context) async {
    try {
      LoadingHelper.show('Sending reminders...');
      final success = await _repo.sendReminders(_splitId);
      LoadingHelper.dismiss();

      if (success) {
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Reminders successfully sent to pending participants.",
            icon: Icons.check_circle_outline_rounded,
            iconColor: primaryGreenColor,
            position: ToastPosition.top,
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Failed to send reminders.",
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        }
        return false;
      }
    } catch (e) {
      LoadingHelper.dismiss();
      return false;
    }
  }

  Future<bool> cancelSplit(BuildContext context) async {
    try {
      LoadingHelper.show('Cancelling split bill...');
      final success = await _repo.cancelSplit(_splitId);
      LoadingHelper.dismiss();

      if (success) {
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message: "Split bill cancelled successfully.",
            icon: Icons.check_circle_outline_rounded,
            iconColor: primaryGreenColor,
            position: ToastPosition.top,
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ToastHelper.showToast(
            context: context,
            message:
                "Failed to cancel split bill. It may already have collections.",
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            position: ToastPosition.top,
          );
        }
        return false;
      }
    } catch (e) {
      LoadingHelper.dismiss();
      return false;
    }
  }

  @override
  void dispose() {
    final socket = _ref.read(socketProvider);
    if (socket != null) {
      debugPrint(
        '🔌 SplitDetailsNotifier: Disposing progress event listener for $_splitId',
      );
      socket.off('split_progress_update', _onSocketProgressUpdate);
    }
    super.dispose();
  }
}

final splitDetailsProvider =
    StateNotifierProvider.family<
      SplitDetailsNotifier,
      AsyncValue<SplitDetailsResponse?>,
      String
    >((ref, splitId) {
      final repo = ref.watch(splitPaymentRepositoryProvider);
      return SplitDetailsNotifier(repo, splitId, ref);
    });
