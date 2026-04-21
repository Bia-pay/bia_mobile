
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/easy_loading_config.dart';
import 'image.dart';

import 'colors.dart';

class CustomLoader extends ConsumerWidget {
  final Color? color;
  final double? size;
  const CustomLoader({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: PulsingLogoIndicator(
        logoPath: appLogoPng,
        size: size ?? 40, // Balanced size for inline placeholders
        pulseColor: color,
      ),
    );
  }
}
