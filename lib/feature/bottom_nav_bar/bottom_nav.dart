import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/utils/image.dart';
import '../dashboard/pages/homepage.dart';
import '../dashboard/pages/send_money/scan_transfer/scanner_onboarding.dart';
import '../settings/presentation/account_settings.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomePage(),
      UProfile(),
      ScannerOnboarding(),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteBackground,
      body: _pages[_selectedIndex],

      bottomNavigationBar: RepaintBoundary(
        child: SizedBox(
          height: 85.h,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 85.h),
                painter: BNBCustomPainter(),
              ),

              // Floating center button
              Positioned(
                bottom: 40.h,
                child: GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: Container(
                    height: 70.h,
                    width: 70.w,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(18.w),
                    child: SvgPicture.asset(scanner),
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 85.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home, 0),
                      SizedBox(width: 80.w),
                      _buildNavItem(Icons.settings, 1),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        icon,
        size: 24.sp,
        color: isSelected ? primaryColor : kGray,
      ),
    );
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = whiteBackground
      ..style = PaintingStyle.fill;

    final path = Path();
    double arcWidth = 120;
    double arcRadius = 62;

    path.moveTo(0, 0);
    path.lineTo((size.width - arcWidth) / 2, 0);

    path.arcToPoint(
      Offset((size.width + arcWidth) / 2, 0),
      radius: Radius.circular(arcRadius),
      clockwise: true,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Removed shadow (causes jank)
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}