import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../utils/colors.dart';

class HomeHeader extends StatelessWidget {
  final bool isSmallScreen;
  final String? picture;
  final String fullname;
  final ThemeData theme;
  final Color primaryColor;
  final Color lightSecondaryText;
  final Color lightText;
  final String appLogoPng;
  final String bell;
  final String notificationRoute;

  const HomeHeader({
    super.key,
    required this.isSmallScreen,
    required this.picture,
    required this.fullname,
    required this.theme,
    required this.primaryColor,
    required this.lightSecondaryText,
    required this.lightText,
    required this.appLogoPng,
    required this.bell,
    required this.notificationRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      color: offWhiteBackground, // keeps it solid when scrolling
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: isSmallScreen ? 38.r : 45.r,
                width: isSmallScreen ? 38.r : 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor),
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
              SizedBox(width: isSmallScreen ? 8.w : 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: lightSecondaryText,
                      fontSize: isSmallScreen ? 10.sp : 12.sp,
                    ),
                  ),
                  SizedBox(
                    width: 120.w,
                    child: Text(
                      fullname,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: lightText,
                        fontSize: isSmallScreen ? 11.sp : 13.sp,
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
              height: isSmallScreen ? 18.h : 25.h,
              width: isSmallScreen ? 18.h : 25.h,
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