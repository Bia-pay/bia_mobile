import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/enhanced_pin_screen.dart';
import '../../dashboard/dashboard_repo/repo.dart';

class SetPin extends ConsumerWidget {
  const SetPin({super.key, this.title = "Set Payment PIN"});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PinInputScreen(
      title: title,
      subtitle: "Enter a new PIN",
      onComplete: (pin) async {
        final repo = ref.read(dashboardRepositoryProvider);

        final response = await repo.setPin({
          "pin": pin,
          "confirmPin": pin,
        });

        if (!context.mounted) return;

        if (response.responseSuccessful) {
          final box = Hive.box('authBox');
          await box.put('has_pin', true);

          if (!context.mounted) return;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.goNamed(RouteList.bottomNavBar);
            }
          });
        }
      },
    );
  }
}