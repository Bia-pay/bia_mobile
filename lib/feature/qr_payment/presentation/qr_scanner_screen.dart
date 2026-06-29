import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/toast_helper.dart';
import 'package:bia/feature/dashboard/widgets/service_guard.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _isCollectMode = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      _processQrData(code);
    }
  }

  void _processQrData(String data) {
    setState(() => _isProcessing = true);
    _scannerController.stop();

    String receiverAccount = data.trim();

    try {
      final json = jsonDecode(data);
      if (json is Map && json.containsKey('account')) {
        receiverAccount = json['account'].toString();
      } else if (json is Map && json.containsKey('phone')) {
        receiverAccount = json['phone'].toString();
      }
    } catch (_) {
      // If not JSON, assume raw account string
    }

    if (receiverAccount.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: 'Invalid QR Code',
      );
      Future.delayed(const Duration(seconds: 2), () => _isProcessing = false);
      _scannerController.start();
      return;
    }

    // Navigate to Amount Entry Screen
    context.push(RouteList.qrAmountEntryScreen, extra: {
      'account': receiverAccount,
      'isCollectMode': _isCollectMode,
    }).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ServiceGuard(
      service: ServiceType.qr,
      child: Scaffold(
          backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 250.w,
                height: 250.w,
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 100.h),
                child: Text(
                  'Position QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isCollectMode = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: !_isCollectMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            'Pay',
                            style: TextStyle(
                              color: !_isCollectMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isCollectMode = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: _isCollectMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            'Collect',
                            style: TextStyle(
                              color: _isCollectMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteList.qrScreen),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            'My QR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
