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
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue ?? barcodes.first.displayValue;
      if (code != null && code.isNotEmpty) {
        _processQrData(code);
      }
    }
  }

  void _processQrData(String rawData) {
    setState(() => _isProcessing = true);
    _scannerController.stop();

    final data = rawData.trim();
    String? receiverAccount;

    try {
      final json = jsonDecode(data);
      if (json is Map) {
        if (json.containsKey('splitId') && json.containsKey('token')) {
          final splitId = json['splitId'].toString();
          final token = json['token'].toString();

          context.pushNamed(RouteList.splitScanView, extra: {
            'splitId': splitId,
            'token': token,
          }).then((_) {
            if (mounted) {
              setState(() => _isProcessing = false);
              _scannerController.start();
            }
          });
          return;
        }

        receiverAccount = json['account']?.toString() ??
            json['phone']?.toString() ??
            json['receiverAccount']?.toString() ??
            json['user']?.toString();
      }
    } catch (_) {
      // If not JSON
    }

    if (receiverAccount == null || receiverAccount.isEmpty) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        receiverAccount = uri.queryParameters['account'] ??
            uri.queryParameters['phone'] ??
            uri.queryParameters['receiverAccount'] ??
            uri.queryParameters['user'];
      }
    }

    if (receiverAccount == null || receiverAccount.isEmpty) {
      final cleaned = data.replaceAll(RegExp(r'[^a-zA-Z0-9@]'), '');
      if (cleaned.isNotEmpty && !data.contains('{') && !data.contains('}')) {
        receiverAccount = cleaned;
      }
    }

    if (receiverAccount == null || receiverAccount.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: 'Invalid QR Code',
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      });
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: !_isCollectMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              color: !_isCollectMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            child: const Text('Pay'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isCollectMode = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: _isCollectMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              color: _isCollectMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            child: const Text('Collect'),
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
