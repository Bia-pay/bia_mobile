import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../model/bia_trike_model.dart';

class BiaTrikeNotifier extends StateNotifier<AsyncValue<BiaTrikeRiderApplication?>> {
  BiaTrikeNotifier() : super(const AsyncValue.data(null)) {
    loadExistingApplication();
  }

  Future<void> loadExistingApplication() async {
    state = const AsyncValue.loading();
    try {
      final box = await Hive.openBox('appBox');
      final rawData = box.get('bia_trike_rider_app');
      if (rawData != null && rawData is Map) {
        final app = BiaTrikeRiderApplication.fromJson(
            Map<String, dynamic>.from(rawData));
        state = AsyncValue.data(app);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> submitApplication(BiaTrikeRiderApplication application) async {
    state = const AsyncValue.loading();
    try {
      // Simulate network request delay
      await Future.delayed(const Duration(milliseconds: 1200));

      final box = await Hive.openBox('appBox');
      await box.put('bia_trike_rider_app', application.toJson());

      state = AsyncValue.data(application);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> clearApplication() async {
    final box = await Hive.openBox('appBox');
    await box.delete('bia_trike_rider_app');
    state = const AsyncValue.data(null);
  }
}

final biaTrikeProvider = StateNotifierProvider<BiaTrikeNotifier,
    AsyncValue<BiaTrikeRiderApplication?>>((ref) {
  return BiaTrikeNotifier();
});
