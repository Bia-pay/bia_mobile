import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard_repo/repo.dart';

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return UnreadCountNotifier(repository);
});

class UnreadCountNotifier extends StateNotifier<int> {
  final DashboardRepository _repository;
  Timer? _timer;

  UnreadCountNotifier(this._repository) : super(0) {
    fetchCount();
    // Refresh every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => fetchCount());
  }

  Future<void> fetchCount() async {
    try {
      final response = await _repository.fetchUnreadCount();
      if (response['responseSuccessful'] == true) {
        state = response['responseBody']?['unreadCount'] ?? 0;
      }
    } catch (_) {}
  }

  void decrement() {
    if (state > 0) state--;
  }

  void reset() {
    state = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
