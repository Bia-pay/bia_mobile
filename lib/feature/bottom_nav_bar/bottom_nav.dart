import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../app/utils/router/route_constant.dart';
import '../../app/utils/image.dart';
import '../dashboard/pages/homepage.dart';
import '../dashboard/pages/send_money/scan_transfer/scanner.dart';
import '../dashboard/pages/send_money/scan_transfer/scanner_onboarding.dart';
import '../dashboard/dashboardcontroller/qr_onboarding_provider.dart';
import '../dashboard/dashboardcontroller/provider.dart';
import '../settings/presentation/account_settings.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinStatus();
    });
  }

  void _checkPinStatus() {
    final box = Hive.box('authBox');
    final hasPin = box.get('has_pin', defaultValue: false);
    if (hasPin != true) {
      if (mounted) {
        context.go(RouteList.setTransactionPin);
      }
    }
  }

  List<Widget> _getPages(bool qrCompleted) => [
    const HomePage(),
    const Center(child: Text("Location")), // Placeholder
    qrCompleted ? const QrScannerScreen() : const ScannerOnboarding(),
    const Center(child: Text("Analytics")), // Placeholder
    const UProfile(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final qrCompleted = ref.watch(qrOnboardingProvider);
    final servicesStatus = ref.watch(servicesStatusProvider);
    final isQrEnabled = servicesStatus.qr;
    final pages = _getPages(qrCompleted);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: pages[_selectedIndex],
      extendBody: true,
      floatingActionButton: GestureDetector(
        onTap: () {
          if (!isQrEnabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('QR Code payments are temporarily disabled for maintenance.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange.shade800,
              ),
            );
          } else {
            _onItemTapped(2);
          }
        },
        child: Opacity(
          opacity: isQrEnabled ? 1.0 : 0.4,
          child: Container(
            height: 80.h,
            width: 80.h,
            decoration: BoxDecoration(
              color: isQrEnabled ? primaryColor : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isQrEnabled ? primaryColor : Colors.grey).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.w),
            child: SvgPicture.asset(
              scanner,
              height: 12.h,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: const _CustomFABLocation(),
      bottomNavigationBar: SizedBox(
        height: 120.h,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 120.h),
              painter: BNBCustomPainter(),
            ),

            // Navigation Items
            Positioned(
              bottom: 5.h,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 75.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, 0),
                   // _buildNavItem(Icons.location_on_outlined, 1),
                    SizedBox(width: 15.w), // Spacer for center button
                   // _buildNavItem(Icons.bar_chart_outlined, 3),
                    _buildNavItem(Icons.grid_view_rounded, 4),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28.sp,
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.7),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              height: 4.h,
              width: 4.w,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomFABLocation extends FloatingActionButtonLocation {
  const _CustomFABLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 20.h - scaffoldGeometry.floatingActionButtonSize.height;
    return Offset(fabX, fabY);
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Config for the bump
    final double bumpWidth = 110.r;
    final double bumpHeight = 45.r;
    final double centerX = size.width / 2;
    
    path.moveTo(0, bumpHeight); // Start below the bump height
    
    // Left flat part
    path.lineTo(centerX - bumpWidth, bumpHeight);
    
    // Smooth transition to the bump
    path.quadraticBezierTo(
      centerX - (bumpWidth / 2), bumpHeight, 
      centerX - (bumpWidth / 3), bumpHeight / 2
    );
    
    // Peak of the bump
    path.quadraticBezierTo(
      centerX, -10, // Peak above the top
      centerX + (bumpWidth / 3), bumpHeight / 2
    );
    
    // Smooth transition down
    path.quadraticBezierTo(
      centerX + (bumpWidth / 2), bumpHeight, 
      centerX + bumpWidth, bumpHeight
    );
    
    // Right flat part
    path.lineTo(size.width, bumpHeight);
    
    // Complete the box
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    canvas.drawShadow(path.shift(const Offset(0, -2)), Colors.black.withOpacity(0.5), 10, true);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}