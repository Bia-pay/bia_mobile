import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final qrOnboardingProvider = StateNotifierProvider<QrOnboardingNotifier, bool>((ref) {
  return QrOnboardingNotifier();
});

class QrOnboardingNotifier extends StateNotifier<bool> {
  QrOnboardingNotifier() : super(_getInitialState());

  static bool _getInitialState() {
    return Hive.box('appBox').get('qr_onboarding_completed', defaultValue: false);
  }

  Future<void> completeOnboarding() async {
    await Hive.box('appBox').put('qr_onboarding_completed', true);
    state = true;
  }

  void setOnboardingCompleted(bool completed) {
    Hive.box('appBox').put('qr_onboarding_completed', completed);
    state = completed;
  }
}
