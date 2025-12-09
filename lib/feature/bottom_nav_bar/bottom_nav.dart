import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/utils/image.dart';
import '../dashboard/pages/homepage.dart';
import '../dashboard/pages/send_money/scan_transfer/scanner_onboarding.dart';
import '../settings/presentation/account_settings.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const UProfile(),
    const ScannerOnboarding(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      backgroundColor: whiteBackground, // using colors.dart
      bottomNavigationBar: SizedBox(
        height: 80.h,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 80.h),
              painter: BNBCustomPainter(),
            ),

            // Floating Center Button
            Positioned(
              bottom: 25,
              child: GestureDetector(
                onTap: () => _onItemTapped(2),
                child: Container(
                  height: 90.h,
                  width: 90.w,
                  decoration: const BoxDecoration(
                    color: primaryColor, // colors.dart
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all( 35),
                    child: SvgPicture.asset(scanner),
                  ),
                ),
              ),
            ),

            // Nav Items Row
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 80.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 0),
                     SizedBox(width: 60.w),
                    _buildNavItem(Icons.settings, 1),
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
      child: Icon(
        icon,
        color: isSelected ? primaryColor : kGray, // colors.dart
      ),
    );
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = whiteBackground // colors.dart
      ..style = PaintingStyle.fill;

    final path = Path();
    double arcWidth = 120;
    double arcRadius = 62;

    path.moveTo(0, 0);
    path.lineTo((size.width - arcWidth) / 2, -10);

    path.arcToPoint(
      Offset((size.width + arcWidth) / 2, -10),
      radius: Radius.circular(arcRadius),
      clockwise: true,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      "Wallet Screen",
      style: TextStyle(fontSize: 24, color: lightText), // colors.dart
    ),
  );
}