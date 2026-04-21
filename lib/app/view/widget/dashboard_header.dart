import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../utils/colors.dart';

class HomeHeader extends StatelessWidget {
  final String? picture;
  final String fullname;
  final ThemeData theme;
  final Color primaryColor;
  final Color lightSecondaryText;
  final Color lightText;
  final String appLogoPng;
  final String bell;
  final String notificationRoute;
  final String profileRoute;

  const HomeHeader({
    super.key,
    required this.picture,
    required this.fullname,
    required this.theme,
    required this.primaryColor,
    required this.lightSecondaryText,
    required this.lightText,
    required this.appLogoPng,
    required this.bell,
    required this.notificationRoute,
    required this.profileRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 10.h,
      ),
      color: offWhiteBackground, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pushNamed(profileRoute),
                child: Container(
                  height: 42.r,
                  width: 42.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 1.5),
                  ),
                  child: ClipOval(
                    child: picture != null && picture!.isNotEmpty
                        ? Image.network(
                      picture!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Image.asset(appLogoPng),
                    )
                        : Image.asset(appLogoPng),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: lightSecondaryText,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(
                    width: 130.w,
                    child: Text(
                      fullname,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: lightText,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.pushNamed(notificationRoute),
            child: Container(
              height: 22.r,
              width: 22.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
              ),
              child: SvgPicture.asset(bell),
            ),
          ),
        ],
      ),
    );
  }
}