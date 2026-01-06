import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/widgets/pin_field.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class ChangePaymentPin extends ConsumerStatefulWidget {
  const ChangePaymentPin({super.key, this.title = "Change Payment Pin"});
  final String title;

  @override
  ConsumerState<ChangePaymentPin> createState() => _ChangePaymentPinState();
}

class _ChangePaymentPinState extends ConsumerState<ChangePaymentPin> {
  int _selectedIndex = -1;
  bool showMinWarning = false;

  final TextEditingController oldPin = TextEditingController();

  @override
  void dispose() {
    oldPin.dispose();
    super.dispose();
  }

  void addDigit(String value) {
    setState(() {
      if (oldPin.text.length < 4) oldPin.text += value;
      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      if (oldPin.text.isNotEmpty) {
        oldPin.text = oldPin.text.substring(0, oldPin.text.length - 1);
      }
      _checkMinLimit();
    });
  }

  void _checkMinLimit() {
    showMinWarning = oldPin.text.length < 4 && oldPin.text.isNotEmpty;
  }

  void _goToNewPinPage() {
    if (oldPin.text.length != 4) {
      setState(() => showMinWarning = true);
      return;
    }
    context.pushNamed(
      RouteList.setTransactionPin,
      extra: {'oldPin': oldPin.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          children: [
            SizedBox(height: 65.h),
            Text('Enter OLD PIN', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: AppPinCodeField(
                controller: oldPin,
                length: 4,
                fillColor: offWhiteBackground,
                inactiveColor: keyAColor,
                activeColor: primaryColor,
                selectedColor: primaryColor,
              ),
            ),
            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text("PIN must be 4 digits", style: theme.textTheme.bodySmall?.copyWith(color: errorColor)),
              ),
            SizedBox(height: 120.h),

            /// Keypad
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 35.w,
                  mainAxisExtent: 70.h,
                ),
                itemBuilder: (context, index) {
                  List<String> keys = ["1","2","3","4","5","6","7","8","9","x","0","ok"];
                  String key = keys[index];
                  Color keyColor = keyAColor;
                  Color textColor = lightSecondaryText;

                  if (key == "x") { keyColor = primaryColor.withOpacity(0.1); textColor = primaryColor; }
                  else if (key == "ok") { keyColor = primaryColor; textColor = whiteBackground; }

                  return InkWell(
                    borderRadius: BorderRadius.circular(50.r),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (key == "x") removeDigit();
                      else if (key == "ok") _goToNewPinPage();
                      else addDigit(key);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == index ? Colors.white : keyColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedIndex == index ? primaryColor : Colors.transparent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: key == "x"
                          ? SvgPicture.asset('assets/svg/cancel.svg', height: 20.h, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn))
                          : key == "ok"
                          ? Icon(Icons.arrow_forward, color: _selectedIndex == index ? primaryColor : textColor, size: 24.sp)
                          : Text(key, style: theme.textTheme.headlineSmall?.copyWith(color: _selectedIndex == index ? primaryColor : lightText, fontWeight: FontWeight.w500, fontSize: 24.sp)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class NewPaymentPin extends ConsumerStatefulWidget {
  final String oldPin;
  const NewPaymentPin({super.key, required this.oldPin});

  @override
  ConsumerState<NewPaymentPin> createState() => _NewPaymentPinState();
}

class _NewPaymentPinState extends ConsumerState<NewPaymentPin> {
  int _selectedIndex = -1;
  bool showMinWarning = false;

  final TextEditingController newPin = TextEditingController();
  final TextEditingController confirmPin = TextEditingController();
  late TextEditingController activeController;

  @override
  void initState() {
    super.initState();
    activeController = newPin;
  }

  @override
  void dispose() {
    newPin.dispose();
    confirmPin.dispose();
    // Don't dispose activeController as it's just a reference to newPin or confirmPin
    super.dispose();
  }

  void addDigit(String value) {
    setState(() {
      if (activeController.text.length < 4) activeController.text += value;
      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      if (activeController.text.isNotEmpty) activeController.text = activeController.text.substring(0, activeController.text.length - 1);
      _checkMinLimit();
    });
  }

  void _checkMinLimit() {
    showMinWarning = (newPin.text.length < 4 || confirmPin.text.length < 4) && newPin.text.isNotEmpty && confirmPin.text.isNotEmpty;
  }

  Future<void> _confirmNewPin() async {
    if (newPin.text.length != 4 || confirmPin.text.length != 4) {
      setState(() => showMinWarning = true);
      return;
    }
    if (newPin.text != confirmPin.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New PIN and Confirm PIN do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate old PIN is different from new PIN
    if (widget.oldPin == newPin.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New PIN must be different from old PIN"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = ref.read(dashboardControllerProvider.notifier);

    final response = await controller.changePin(
      context,
      widget.oldPin,
      newPin.text,
      confirmPin.text,
    );

    if (response != null && response.responseSuccessful && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ PIN changed successfully"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to home
      context.goNamed(RouteList.bottomNavBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text("Set New PIN", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            _buildPinField("Enter NEW PIN", newPin),
            SizedBox(height: 20.h),
            _buildPinField("Confirm NEW PIN", confirmPin),
            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text("PIN must be 4 digits", style: theme.textTheme.bodySmall?.copyWith(color: errorColor)),
              ),
            SizedBox(height: 20.h),

            /// Keypad
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 35.w,
                  mainAxisExtent: 70.h,
                ),
                itemBuilder: (context, index) {
                  List<String> keys = ["1","2","3","4","5","6","7","8","9","x","0","ok"];
                  String key = keys[index];
                  Color keyColor = keyAColor;
                  Color textColor = lightSecondaryText;

                  if (key == "x") { keyColor = primaryColor.withOpacity(0.1); textColor = primaryColor; }
                  else if (key == "ok") { keyColor = primaryColor; textColor = whiteBackground; }

                  return InkWell(
                    borderRadius: BorderRadius.circular(50.r),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (key == "x") removeDigit();
                      else if (key == "ok") _confirmNewPin();
                      else addDigit(key);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == index ? Colors.white : keyColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedIndex == index ? primaryColor : Colors.transparent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: key == "x"
                          ? SvgPicture.asset('assets/svg/cancel.svg', height: 20.h, colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn))
                          : key == "ok"
                          ? Icon(Icons.arrow_forward, color: _selectedIndex == index ? primaryColor : textColor, size: 24.sp)
                          : Text(key, style: theme.textTheme.headlineSmall?.copyWith(color: _selectedIndex == index ? primaryColor : lightText, fontWeight: FontWeight.w500, fontSize: 24.sp)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(String label, TextEditingController controller) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () {
            setState(() {
              activeController = controller;
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: AppPinCodeField(
              controller: controller,
              length: 4,
              fillColor: offWhiteBackground,
              inactiveColor: keyAColor,
              activeColor: primaryColor,
              selectedColor: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
