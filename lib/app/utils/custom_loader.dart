
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Center(
      child: PulsingLogoIndicator(
        logoPath: appLogoPng,
        size: size ?? (isTablet ? 42.0 : 40.0),
        pulseColor: color,
      ),
    );
  }
}
