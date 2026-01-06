import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/utils/widgets/enhanced_pin_screen.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class ChangePaymentPin extends ConsumerWidget {
  const ChangePaymentPin({super.key, this.title = "Change Payment Pin"});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedPinScreen(
      title: title,
      subtitle: "Enter OLD PIN",
      type: PinScreenType.verify,
      fieldType: InputFieldType.pin,
      onPinComplete: (oldPin) {
        context.pushNamed(
          RouteList.setTransactionPin,
          extra: {'oldPin': oldPin},
        );
      },
    );
  }
}

class NewPaymentPin extends ConsumerWidget {
  final String oldPin;
  const NewPaymentPin({super.key, required this.oldPin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedPinScreen(
      title: "Set New PIN",
      subtitle: "Enter a new PIN",
      type: PinScreenType.set,
      fieldType: InputFieldType.pin,
      onPinConfirmed: (newPin) async {
        // Validate old PIN is different from new PIN
        if (oldPin == newPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("New PIN must be different from old PIN"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Call the API to change PIN
        final controller = ref.read(dashboardControllerProvider.notifier);
        
        final response = await controller.changePin(
          context,
          oldPin,
          newPin,
          newPin, // confirmPin same as newPin since ReusablePinScreen handles confirmation
        );

        if (response != null && response.responseSuccessful ) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ PIN changed successfully"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to home
          context.goNamed(RouteList.bottomNavBar);
        }
      },
    );
  }
}