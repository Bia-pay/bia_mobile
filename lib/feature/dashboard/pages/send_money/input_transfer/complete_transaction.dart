import 'package:bia/app/utils/widgets/pin_field.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

class CompleteTransactionBottomSheet extends ConsumerStatefulWidget {
  final String amount;
  final String recipientName;
  final String recipientAccount;

  const CompleteTransactionBottomSheet({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
  });

  @override
  ConsumerState<CompleteTransactionBottomSheet> createState() =>
      _CompleteTransactionBottomSheetState();
}

class _CompleteTransactionBottomSheetState
    extends ConsumerState<CompleteTransactionBottomSheet> {
  final TextEditingController pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool _hasBiometric = false;
  bool _isAuthenticating = false;
  bool _biometricEnabled = false;
  bool _saveAsBeneficiary = false;
  bool _showPasswordField = false;

  String? savedPin;
  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  Future<void> _initializeSettings() async {
    final settingsBox = await Hive.openBox("settingsBox");

    bool hasFingerprint = false;
    try {
      // First check if the device supports any biometrics at all
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      // Then specifically check for fingerprint if available
      final availableBiometrics = await auth.getAvailableBiometrics();

      hasFingerprint =
          (canCheck && isSupported) &&
          (availableBiometrics.contains(BiometricType.fingerprint) ||
              availableBiometrics.isNotEmpty);

      debugPrint("🧠 canCheckBiometrics: $canCheck");
      debugPrint("🧠 isDeviceSupported: $isSupported");
      debugPrint("🧠 availableBiometrics: $availableBiometrics");
      debugPrint("✅ hasFingerprint final: $hasFingerprint");
    } catch (e) {
      debugPrint("⚠️ Biometric detection failed: $e");
    }

    final biometricEnabled = settingsBox.get(
      "biometric_enabled",
      defaultValue: false,
    );
    final savedPiin = settingsBox.get("saved_pin");
    debugPrint(savedPiin);
    setState(() {
      _hasBiometric = hasFingerprint;
      _biometricEnabled = biometricEnabled;
      savedPin = savedPiin;
    });

    // ✅ Logic flow
    if (!hasFingerprint) {
      debugPrint("🚫 No fingerprint hardware detected. Showing pin only.");
      setState(() => _showPasswordField = true);
      return;
    }

    if (hasFingerprint && biometricEnabled) {
      debugPrint("🔐 Fingerprint transfer enabled. Launching biometric...");
      Future.delayed(const Duration(milliseconds: 400), _authenticate);
    } else {
      debugPrint(
        "🧾 Fingerprint available but not enabled. Showing pin field.",
      );
      setState(() => _showPasswordField = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);

      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to transfer',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        setState(() => _showPasswordField = true);
        return;
      }

      const narration = 'Transfer';

      // ✅ Use SAVED PIN for biometric transfers
      final pin = savedPin;

      if (pin == null || pin.isEmpty) {
        _showError("No saved PIN found. Please use PIN instead.");
        setState(() => _showPasswordField = true);
        return;
      }

      final cleanAmount =
          double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0.0;

      const double fee = 10.00;
      final total = cleanAmount + fee;

      final authController = ref.read(dashboardControllerProvider.notifier);

      await authController.sendMoney(
        context,
        widget.recipientAccount, // ACCOUNT
        total.toStringAsFixed(2), // AMOUNT
        narration, // NARRATION
        pin, // PIN (savedPin)
        save: _saveAsBeneficiary,
      );

      final authBox = await Hive.openBox("authBox");
      final token = authBox.get("token");

      if (token != null && token.isNotEmpty && mounted) {
        Navigator.pushNamed(
          context,
          RouteList.successScreen,
          arguments: {
            "type": "transfer", // ✅ must be here
            "amount": total.toStringAsFixed(2),
            "recipientName": widget.recipientName,
            "recipientAccount": widget.recipientAccount,
          },
        );
      } else {
        _showError("Something went wrong. Please try again.");
      }
    } catch (e) {
      debugPrint("⚠️ Biometric error: $e");
      setState(() => _showPasswordField = true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final amount =
        double.tryParse(widget.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;
    const double fee = 10.00;
    final total = amount + fee;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SingleChildScrollView(
        reverse: true, // scrolls to bottom when keyboard appears
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SvgPicture.asset(cancelSvg, height: 10.h),
              ),
            ),
            Text(
              'Are you sure?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryColor,
                fontSize: 27.sp,
              ),
            ),
            Text(
              'Please confirm your transfer details.',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall,
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: keyAColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    widget.recipientName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.recipientAccount,
                    style: textTheme.bodySmall?.copyWith(
                      color: lightSecondaryText,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    '${Constants.nairaCurrencySymbol}${total.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(color: checkboxBorderColor),
                  _buildRow('Amount', amount, lightSecondaryText, textTheme),
                  _buildRow('Fee', fee, lightSecondaryText, textTheme),
                ],
              ),
            ),
            SizedBox(height: 5.h),
            _buildBeneficiaryToggle(primaryColor, textTheme),
            SizedBox(height: 10.h),

            if (_hasBiometric && _biometricEnabled && !_showPasswordField)
              Column(
                children: [
                  GestureDetector(
                    onTap: _isAuthenticating ? null : _authenticate,
                    child: SvgPicture.asset(
                      fingerPrint,
                      height: 100.h,
                      colorFilter: ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  TextButton(
                    onPressed: () => setState(() => _showPasswordField = true),
                    child: Text(
                      'Use Pin Instead',
                      // style: theme.textTheme.bodyMedium?.copyWith(color: primaryColor),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: 250.w,
                    child: AppPinCodeField(
                      controller: pinController,
                      length: 4,
                      // 👇 Added custom styling
                      fillColor: keyAColor,
                      inactiveColor: keyAColor,
                      activeColor: primaryColor,
                      selectedColor: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      buttonName: 'Send Money',
                      buttonColor: primaryColor,
                      buttonTextColor: Colors.white,
                      onPressed: () async {
                        final authController = ref.read(
                          dashboardControllerProvider.notifier,
                        );

                        // Call sendMoney and get response
                        final response = await authController.sendMoney(
                          context,
                          widget.recipientAccount,
                          total.toStringAsFixed(2),
                          'Transfer',
                          pinController.text,
                          save: _saveAsBeneficiary,
                        );

                        // ✅ Check if the transfer was successful
                        if (response != null && response.responseSuccessful) {
                          Navigator.pushNamed(
                            context,
                            RouteList.successScreen,
                            arguments: {
                              "type": "transfer",
                              "amount": total.toStringAsFixed(2),
                              "recipientName": widget.recipientName,
                              "recipientAccount": widget.recipientAccount,
                            },
                          );
                        } else {
                          // ❌ Show error if PIN is wrong or transfer failed
                          final msg =
                              response?.responseMessage ??
                              "Transfer failed. Check your PIN.";
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value,
    dynamic themeContext,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: lightSecondaryText),
        ),
        Text(
          '${Constants.nairaCurrencySymbol}${value.toStringAsFixed(2)}',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBeneficiaryToggle(dynamic themeContext, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: 8.w),
            Text(
              'Save as Beneficiary',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: lightText,
              ),
            ),
          ],
        ),
        Transform.scale(
          scale: 0.45,
          child: Switch(
            value: _saveAsBeneficiary,
            onChanged: (bool value) {
              setState(() {
                _saveAsBeneficiary = value;
              });
            },
            activeThumbColor: primaryColor,
          ),
        ),
      ],
    );
  }
}
