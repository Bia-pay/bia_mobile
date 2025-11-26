import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/extensions/theme_extension.dart';
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

  // 🔥 navigate only when user taps button
  void _goToAmountPage(BuildContext context) async {
    if (verifiedName == null || verifiedAccount == null) return;

    // FULLY stop and dispose scanner before navigating
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
            _scanLocked = true; // stop scanning completely
          });

          // Stop camera after verification
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
    final themeContext = context.themeContext;
    final colorScheme = theme.colorScheme;

    const double boxSize = 290;

    return Scaffold(
      backgroundColor: Colors.black,
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                                height: 3,
                                color: colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // 🟩 VERIFIED CONTAINER (restored)
                if (isVerified) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: themeContext.offWhiteBg,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: themeContext.kPrimary, size: 22),
                            SizedBox(width: 8.w),
                            Text(
                              "Account Verified",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: themeContext.kPrimary,
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
                                color: themeContext.secondaryTextColor)),
                        SizedBox(height: 15.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeContext.kPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _goToAmountPage(context),
                            child: Text(
                              "Send Money",
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
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
                        size: 38,
                        color: colorScheme.primary,
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