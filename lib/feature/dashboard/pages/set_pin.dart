import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/utils/widgets/enhanced_pin_screen.dart';
import '../dashboard_repo/repo.dart';

class SetPin extends ConsumerWidget {
  const SetPin({super.key, this.title = "Set Payment PIN"});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedPinScreen(
      title: title,
      subtitle: "Enter a new PIN",
      type: PinScreenType.set,
      fieldType: InputFieldType.pin,
      onPinConfirmed: (pin) async {
          final repo = ref.read(dashboardRepositoryProvider);

          final body = {
            "pin": pin,
            "confirmPin": pin, // REQUIRED by backend
          };

          final response = await repo.setPin(body);

          if (response.responseSuccessful) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.responseMessage)),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.responseMessage)),
            );
          }
        }
    );
  }
}