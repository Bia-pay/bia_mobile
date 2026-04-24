import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard_repo/repo.dart';
import '../model/notification_model.dart';
import '../model/pagination_model.dart';
import 'unread_count_notifier.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool isLoadMore;
  final String? error;
  final Pagination? pagination;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.isLoadMore = false,
    this.error,
    this.pagination,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? isLoadMore,
    String? error,
    Pagination? pagination,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      error: error,
      pagination: pagination ?? this.pagination,
    );
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return NotificationNotifier(repository, ref);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final DashboardRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref)
      : super(NotificationState(notifications: [])) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await _repository.fetchNotifications(page: 1);

    if (response.responseBody != null) {
      state = state.copyWith(
        notifications: response.responseBody!.notifications,
        pagination: response.responseBody!.pagination,
        isLoading: false,
      );
      // Also refresh unread count
      _ref.read(unreadCountProvider.notifier).fetchCount();
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.responseMessage,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadMore || state.pagination == null) return;
    if (state.pagination!.page >= state.pagination!.totalPages) return;

    state = state.copyWith(isLoadMore: true);
    final nextPage = state.pagination!.page + 1;
    final response = await _repository.fetchNotifications(page: nextPage);

    if (response.responseBody != null) {
      state = state.copyWith(
        notifications: [...state.notifications, ...response.responseBody!.notifications],
        pagination: response.responseBody!.pagination,
        isLoadMore: false,
      );
    } else {
      state = state.copyWith(isLoadMore: false);
    }
  }

  Future<void> markAsRead(int id) async {
    // Optimistic update
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !state.notifications[index].isRead) {
      final updatedList = [...state.notifications];
      updatedList[index] = updatedList[index].copyWith(isRead: true);
      state = state.copyWith(notifications: updatedList);
      
      // Update unread count locally
      _ref.read(unreadCountProvider.notifier).decrement();

      // Backend update
      await _repository.markAsRead(id.toString());
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updatedList);
    
    // Reset unread count locally
    _ref.read(unreadCountProvider.notifier).reset();

    // Backend update
    await _repository.markAllAsRead();
  }
}
