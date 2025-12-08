import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/utils/colors.dart';
import '../../dashboardcontroller/dashboardcontroller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isProcessing = false;
  bool _scanLocked = false;

  bool isVerified = false;
  String? verifiedName;
  String? verifiedAccount;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  void _goToAmountPage(BuildContext context) async {
    if (verifiedName == null || verifiedAccount == null) return;

    await controller.stop();
    controller.dispose();

    Navigator.pushReplacementNamed(
      context,
      '/amountPage',
      arguments: {
        'controller': TextEditingController(),
        'recipientName': verifiedName,
        'recipientAccount': verifiedAccount,
      },
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _scanLocked) return;

    _isProcessing = true;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null) {
      _isProcessing = false;
      return;
    }

    try {
      Map<String, dynamic>? data;

      try {
        data = jsonDecode(rawValue);
      } catch (_) {
        data = jsonDecode(rawValue.replaceAll("'", '"'));
      }

      if (data != null &&
          data['type'] == 'bia_wallet' &&
          data.containsKey('account')) {
        final account = data['account'].toString();

        final dashboardCtrl =
        ref.read(dashboardControllerProvider.notifier);

        final result = await dashboardCtrl.verifyAccount(context, account);

        if (result?.responseSuccessful == true) {
          final fullname =
              result?.responseBody?.user?.fullname ?? 'Unknown User';

          setState(() {
            isVerified = true;
            verifiedName = fullname;
            verifiedAccount = account;
            _scanLocked = true;
          });

          await controller.stop();
          return;
        } else {
          _showError(result?.responseMessage ?? "Verification failed");
        }
      } else {
        _showError("Invalid QR Code");
      }
    } catch (e) {
      _showError("Invalid QR Format");
    }

    _isProcessing = false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const double boxSize = 290;

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔲 SCANNER FRAME
                Container(
                  width: boxSize.w,
                  height: boxSize.w,
                  decoration: BoxDecoration(
                    color: darkSurface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: primaryColor, width: 3.w),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Stack(
                      children: [
                        if (!_scanLocked)
                          MobileScanner(
                            controller: controller,
                            onDetect: _onDetect,
                          ),

                        // 🔵 Scanning line animation
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Positioned(
                              top: boxSize * _animation.value,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3.h,
                                color: primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // 🟩 VERIFIED CONTAINER
                if (isVerified) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: lightSurface,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: primaryColor, size: 22.sp),
                            SizedBox(width: 8.w),
                            Text(
                              "Account Verified",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text("Name: $verifiedName",
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text("Account: $verifiedAccount",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: darkSecondaryText)),
                        SizedBox(height: 15.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () => _goToAmountPage(context),
                            child: Text(
                              "Send Money",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: lightText,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],

                Text(
                  "Align the QR code inside the box",
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 40.h),

                // 🔦 TORCH BUTTON
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (_, state, __) {
                    final torch = state.torchState;

                    return IconButton(
                      icon: Icon(
                        torch == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        size: 38.sp,
                        color: primaryColor,
                      ),
                      onPressed: controller.toggleTorch,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}