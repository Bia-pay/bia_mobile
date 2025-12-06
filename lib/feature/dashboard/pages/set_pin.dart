import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/utils/colors.dart';
import '../../../app/utils/widgets/pin_field.dart';

class SetPin extends ConsumerStatefulWidget {
  const SetPin({super.key, this.title = "Set Payment PIN"});
  final String title;

  @override
  ConsumerState<SetPin> createState() => _SetPinState();
}

class _SetPinState extends ConsumerState<SetPin> {
  int _selectedIndex = -1;
  bool showMinWarning = false;

  final TextEditingController pinController = TextEditingController();

  // Track steps
  bool isConfirm = false;
  String firstPin = '';

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }
  void addDigit(String value) {
    if (!mounted) return;
    setState(() {
      if (pinController.text.length < 4) pinController.text += value;
      _checkMinLimit();
    });
  }

  void removeDigit() {
    if (!mounted) return;
    setState(() {
      if (pinController.text.isNotEmpty) {
        pinController.text = pinController.text.substring(0, pinController.text.length - 1);
      }
      _checkMinLimit();
    });
  }

  void _goToNextStep() {
    if (!mounted) return;

    if (pinController.text.length != 4) {
      setState(() => showMinWarning = true);
      return;
    }

    if (!isConfirm) {
      firstPin = pinController.text;
      pinController.clear();
      setState(() {
        isConfirm = true;
        showMinWarning = false;
      });
    } else {
      if (pinController.text == firstPin) {
        print("PIN set successfully: ${pinController.text}");
        if (mounted) Navigator.pop(context); // Safe navigation
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PINs do not match. Try again!")),
        );
        pinController.clear();
      }
    }
  }

  void _checkMinLimit() {
    showMinWarning = pinController.text.length < 4 && pinController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          isConfirm ? "Confirm Payment PIN" : widget.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          children: [
            SizedBox(height: 65.h),
            Text(
              isConfirm ? "Enter PIN again to confirm" : "Enter a new PIN",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: AppPinCodeField(
                controller: pinController,
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
                child: Text(
                  "PIN must be 4 digits",
                  style: theme.textTheme.bodySmall?.copyWith(color: errorColor),
                ),
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
                      else if (key == "ok") _goToNextStep();
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
                          : Text(
                        key,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: _selectedIndex == index ? primaryColor : lightText,
                          fontWeight: FontWeight.w500,
                          fontSize: 24.sp,
                        ),
                      ),
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