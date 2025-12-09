// ----------------------- CUSTOM APP BAR HELPER -------------------------
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../colors.dart';
import '../image.dart';

class ArrowBackIcon extends StatelessWidget {
  const ArrowBackIcon({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ Access current theme

    return Container(
      decoration: BoxDecoration(color: Colors.transparent),
      padding: EdgeInsets.all(17),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: SvgPicture.asset(
              theme.brightness == Brightness.light
                  ? arrowBackIcon
                  : arrowBackIconWhite,
              width: 25.w,
            ),
          ),
          SizedBox(width: 55.w),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.light
                  ? darkBackground
                  : lightBackground,

              fontWeight: FontWeight.w400,
              fontSize: 16.spMin,
            ),
          ),
        ],
      ),
    );
  }
}
