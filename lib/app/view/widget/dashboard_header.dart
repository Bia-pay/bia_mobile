import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../feature/dashboard/dashboardcontroller/unread_count_notifier.dart';

import '../../utils/colors.dart';
import '../../utils/image.dart';

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
  final String helpRoute;

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
    required this.helpRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: isTablet
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
          : EdgeInsets.symmetric(
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
                  height: isTablet ? 44 : 42.r,
                  width: isTablet ? 44 : 42.r,
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
                          Image.network(getDiceBearAvatar(fullname)),
                    )
                        : Image.network(getDiceBearAvatar(fullname)),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12 : 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: lightSecondaryText,
                      fontSize: isTablet ? 13 : 11.sp,
                    ),
                  ),
                  Text(
                    fullname,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: lightText,
                      fontSize: isTablet ? 16 : 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pushNamed(helpRoute),
                child: Container(
                  height: isTablet ? 24 : 22.r,
                  width: isTablet ? 24 : 22.r,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: lightText,
                    size: isTablet ? 24 : 22.r,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 18 : 14.w),
              GestureDetector(
                onTap: () => context.pushNamed(notificationRoute),
                child: Consumer(
                  builder: (context, ref, _) {
                    final unreadCount = ref.watch(unreadCountProvider);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: isTablet ? 24 : 22.r,
                          width: isTablet ? 24 : 22.r,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: SvgPicture.asset(bell),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -5,
                            right: -5,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 3 : 4.r),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: isTablet ? 18 : 16.r,
                                minHeight: isTablet ? 18 : 16.r,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 9 : 8.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}