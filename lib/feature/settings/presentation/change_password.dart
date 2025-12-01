import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:hive/hive.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/custom_button.dart';
import '../../../app/utils/widgets/custom_appbar.dart';
import '../../auth/authcontroller/authcontroller.dart';
import '../../auth/data/api_constant.dart';

class Change2FA extends ConsumerStatefulWidget {
  const Change2FA({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _Change2FAState();
}

class _Change2FAState extends ConsumerState<Change2FA> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final authState = ref.watch(authControllerProvider.notifier);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? lightBackground
          : darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArrowBackIcon(
              name: 'Two-Factor Authentication',
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 18.w),
                child: Column(
                  children: [
                    Text(
                      "Choose a code you can remember but others can't guess.",
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: theme.brightness == Brightness.light
                            ? darkBackground
                            : lightBackground,
                        fontSize: 15.spMin,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _pinController,
                      obscureText: true, // hide PIN
                      animationType: AnimationType.none,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        inactiveColor:
                        Colors.grey[200], // 🔹 Border color when inactive
                        selectedColor:
                        Colors.grey[200], // 🔹 Border color when selected
                        activeColor:
                        Colors.grey[300], // 🔹 Border color when active
                        borderWidth: 0.5.w, // 🔹 Thickness of border
                        activeFillColor: Colors.transparent,
                        selectedFillColor: Colors.transparent,
                        inactiveFillColor: Colors.transparent,
                      ),
                      enableActiveFill:
                      false, // 🔹 keeps it just border, no background fill
                      onCompleted: (value) {
                        print("PIN is $value");
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 18.w),
              child: Column(
                children: [
                  CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: theme.brightness == Brightness.light
                        ? darkBackground
                        : darkBackground,
                    buttonName: 'Continue',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmChange2FA(
                            previousPin: _pinController.text,
                          ),
                        ),
                      );
                      // print(_pinController.text);
                      // print(widget.privateKeys);
                      // authState.signIn(
                      //   context,
                      //   widget.privateKeys,
                      //   _pinController.text,
                      // );
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmChange2FA extends ConsumerStatefulWidget {
  const ConfirmChange2FA({super.key, required this.previousPin});

  final String previousPin;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfirmChange2FAState();
}

class _ConfirmChange2FAState extends ConsumerState<ConfirmChange2FA> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // Future<void> changeTwoFactorPin(String pin, String confirmPin) async {
  //   final url = Uri.parse(ApiConstant.BASE_URL + ApiConstant.SET_PIN);
  //
  //   // 🔹 Retrieve access token from Hive
  //   final box = Hive.box("authBox");
  //   final token = box.get("accessToken");
  //
  //   // 🔹 Headers (Authorization + JSON type)
  //   final headers = {
  //     "Content-Type": "application/json",
  //     "Accept": "application/json",
  //     if (token != null) "Authorization": "Bearer $token",
  //   };
  //
  //   // 🔹 Request body
  //   final body = jsonEncode({"pin": pin, "confirmPin": confirmPin});
  //
  //   try {
  //     final response = await http.patch(url, headers: headers, body: body);
  //     final data = jsonDecode(response.body);
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final jsonResponse = jsonDecode(response.body);
  //       // print("✅ Two-factor PIN set successfully: $jsonResponse");
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (context) => TwoFactoradded()),
  //       );
  //     } else {
  //       // 🔹 Directly grab message from response
  //       final errorMessage =
  //           data['responseMessage'] ??
  //               data['message'] ??
  //               data['error'] ??
  //               response.body;
  //
  //       ToastHelper.showToast(
  //         context: context,
  //         message: errorMessage,
  //         icon: Icons.error_outline,
  //         iconColor: Colors.red,
  //         position: ToastPosition.top,
  //       );
  //
  //       print("❌ Failed: ${response.statusCode} - ${response.body}");
  //       print("❌ body: ${body}");
  //     }
  //   } catch (e) {
  //     ToastHelper.showToast(
  //       context: context,
  //       message: "⚠️ $e",
  //       icon: Icons.error_outline,
  //       iconColor: Colors.red,
  //       position: ToastPosition.top,
  //     );
  //     print("⚠️ Error: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider.notifier);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? lightBackground
          : darkBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArrowBackIcon(
              name: 'Two-Factor Authentication',
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 18.w),
                child: Column(
                  children: [
                    Text(
                      "Confirm your code",
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: theme.brightness == Brightness.light
                            ? darkBackground
                            : lightBackground,
                        fontSize: 15.spMin,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _pinController,
                      obscureText: true, // hide PIN
                      animationType: AnimationType.none,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        inactiveColor:
                        Colors.grey[200], // 🔹 Border color when inactive
                        selectedColor:
                        Colors.grey[200], // 🔹 Border color when selected
                        activeColor:
                        Colors.grey[300], // 🔹 Border color when active
                        borderWidth: 0.5.w, // 🔹 Thickness of border
                        activeFillColor: Colors.transparent,
                        selectedFillColor: Colors.transparent,
                        inactiveFillColor: Colors.transparent,
                      ),
                      enableActiveFill:
                      false, // 🔹 keeps it just border, no background fill
                      onCompleted: (value) {
                        print("PIN is $value");
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 18.w),
              child: Column(
                children: [
                  CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: theme.brightness == Brightness.light
                        ? darkBackground
                        : darkBackground,
                    buttonName: 'Continue',
                    onPressed: () {
                      // authState.signIn(
                      //   context,
                      //   widget.privateKeys,
                      //   _pinController.text,
                      // );

                      // changeTwoFactorPin(
                      //   widget.previousPin,
                      //   _pinController.text,
                      // );
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}