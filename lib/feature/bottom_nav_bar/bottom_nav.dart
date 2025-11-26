import 'package:bia/core/__core.dart';
import 'package:bia/core/constraint.dart';
import 'package:flutter/material.dart';

import '../dashboard/pages/homepage.dart';
import '../dashboard/send_money/scan_transfer/scanner_onboarding.dart';
import '../settings/account_settings.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});
  static const String routeName = '/bottomNavBar';

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
    const HomePage(),      // Screen 1
    const UProfile(),   // Screen 2
    const ScannerOnboarding(), // Screen 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex], // ✅ THIS DISPLAYS CURRENT SCREEN
      backgroundColor: Colors.grey[100],

      // Your custom navbar
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 80),
              painter: BNBCustomPainter(),
            ),

            // Floating Center Button
            Positioned(
              bottom: 25,
              child: GestureDetector(
                onTap: () => _onItemTapped(2), // Navigate to index 2
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: context.themeContext.kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: padR(context,all: 35),
                    child: RSvg('assets/svg/scan.svg'),
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
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home, 0),
                    const SizedBox(width: 60), // gap f
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
        color: isSelected ? context.themeContext.kPrimary : context.themeContext.checkboxBorderColor,
      ),
    );
  }
}

class BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    double arcWidth = 120;
    double arcRadius = 62;

    path.moveTo(0,0);
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
  Widget build(BuildContext context) =>
      const Center(child: Text("Wallet Screen", style: TextStyle(fontSize: 24)));
}


