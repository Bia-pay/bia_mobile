
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'colors.dart';

class CustomLoader extends ConsumerWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
        widthFactor: 0.4,
        child: SizedBox(
          height: 40.h,
          width: 80.w,

          child: LoadingAnimationWidget.beat(
            color: lightBackground,
            size: 29.spMin,
          ),
        ));
  }
}
