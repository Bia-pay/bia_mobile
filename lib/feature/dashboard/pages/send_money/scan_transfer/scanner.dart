import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:bia/app/utils/colors.dart';
import 'package:bia/app/utils/router/router.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController controller;
  bool isScanning = true;
  bool flashOn = false;
  bool _isCollectMode = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.displayValue;
      if (code != null) {
        _handleQrResult(code);
      }
    }
  }

  Future<void> _handleQrResult(String result) async {
    setState(() => isScanning = false);
    debugPrint("📥 Scanned Result: $result");
    
    try {
      // 1. Handle single quotes (common in some QR generators)
      String jsonStr = result;
      if (result.contains("'") && !result.contains('"')) {
        jsonStr = result.replaceAll("'", '"');
      }
      
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      // 2. Validate Type
      if (data['type'] != 'bia_wallet') {
        debugPrint("⚠️ QR Type mismatch: expected bia_wallet, got ${data['type']}");
        _showError("Invalid Bia QR Code");
        return;
      }

      final String account = data['account'] ?? "";
      final double? amount = (data['amount'] as num?)?.toDouble();
      final String? narration = data['narration'];

      if (account.isEmpty) {
        _showError("Invalid Account in QR");
        return;
      }

      // 3. Verify Receiver
      _verifyAndProceed(account, amount, narration);

    } catch (e) {
      debugPrint("❌ QR Parsing Error: $e");
      _showError("Invalid QR Code format");
    }
  }

  Future<void> _verifyAndProceed(String account, double? amount, String? narration) async {
    debugPrint("🔍 Verifying receiver: $account");
    final dashboardController = ref.read(dashboardControllerProvider.notifier);
    
    final response = await dashboardController.verifyAccount(
      context,
      account,
    );

    if (response?.responseSuccessful == true) {
      final fullname = response?.responseBody?.user?.fullname ?? "Unknown";
      debugPrint("✅ Receiver verified: $fullname");
      
      // Navigate to Payment Confirmation / Input
      // If amount is present, go to amount page with pre-filled amount
      // Both go to amountPage as it handles the confirmation sheet trigger
      if (_isCollectMode) {
        context.pushNamed(
          RouteList.qrAmountEntryScreen,
          extra: {
            'account': account,
            'isCollectMode': true,
          },
        ).then((_) {
          if (mounted) setState(() => isScanning = true);
        });
      } else {
        context.pushNamed(
          RouteList.amountPage,
          extra: {
            'recipientAccount': account,
            'recipientName': fullname,
            'amount': amount,
            'narration': narration ?? "",
          },
        ).then((_) {
          if (mounted) setState(() => isScanning = true);
        });
      }
    } else {
      debugPrint("❌ Verification failed: ${response?.responseMessage}");
      _showError(response?.responseMessage ?? "Verification failed");
    }
  }

  void _showError(String message) {
    debugPrint("⚠️ Scanner UI Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Resume scanning after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanning = true);
    });
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      debugPrint("🖼️ Selected gallery image: ${image.path}");
      
      try {
        // Pre-process: Compress and resize to ensure detection works better
        final tempDir = await getTemporaryDirectory();
        final targetPath = "${tempDir.path}/temp_qr_scan.jpg";
        
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          quality: 90,
          minWidth: 1024,
          minHeight: 1024,
        );

        final String pathToAnalyze = compressedFile?.path ?? image.path;
        debugPrint("🧪 Analyzing optimized image: $pathToAnalyze");

        final capture = await controller.analyzeImage(pathToAnalyze);
        
        if (capture == null || capture.barcodes.isEmpty) {
          debugPrint("❌ No QR found in optimized image");
          _showError("No QR Code found in image");
        } else {
          final String? code = capture.barcodes.first.displayValue;
          debugPrint("✅ Found QR in optimized image: $code");
          if (code != null) {
            _handleQrResult(code);
          }
        }
      } catch (e) {
        debugPrint("❌ Image processing error: $e");
        _showError("Failed to process image");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final frameSize = screenWidth * 0.65; // Dynamic frame size
    
    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Scanner view
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // 2. Immersive Overlay
          _buildOverlay(frameSize),

          // 3. Top Controls
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircularButton(
                    Icons.close,
                    () => Navigator.pop(context),
                  ),
                  Text(
                    _isCollectMode ? "Collect from Customer" : "Scan to Pay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildCircularButton(
                    flashOn ? Icons.flash_on : Icons.flash_off,
                    () {
                      setState(() => flashOn = !flashOn);
                      controller.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Actions
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Align QR code within the frame to scan",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _isCollectMode = false;
                          isScanning = true;
                        }),
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
                        onTap: () => setState(() {
                          _isCollectMode = true;
                          isScanning = true;
                        }),
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
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBottomAction(
                      Icons.photo_library_rounded,
                      "Gallery",
                      _pickFromGallery,
                    ),
                    SizedBox(width: 40.w),
                    _buildBottomAction(
                      Icons.qr_code_2_rounded,
                      "Scan to Receive",
                      () => context.pushNamed(RouteList.qrScreen),
                    ),
                  ],
                ),
                
                // Privacy Toggle (if needed)
                if (Hive.box('authBox').get('qr_payments_enabled', defaultValue: false))
                  Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.security, color: successColor, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(
                            "Secure QR Payment Active",
                            style: TextStyle(color: Colors.white, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(double frameSize) {
    return Stack(
      children: [
        // Darken outside
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.4),
                child: Container(
                  height: frameSize,
                  width: frameSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scan Frame
        Align(
          alignment: const Alignment(0, -0.4),
          child: Container(
            height: frameSize,
            width: frameSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Stack(
              children: [
                // Animated Scanning Line
                _ScanningLine(frameSize: frameSize),

                // Corners
                ..._buildCorners(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const double length = 40;
    const double width = 4;
    return [
      // Top Left
      Positioned(top: 0, left: 0, child: _corner(top: true, left: true)),
      // Top Right
      Positioned(top: 0, right: 0, child: _corner(top: true, left: false)),
      // Bottom Left
      Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true)),
      // Bottom Right
      Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false)),
    ];
  }

  Widget _corner({required bool top, required bool left}) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: Colors.white, width: 4.w) : BorderSide.none,
          bottom: !top ? BorderSide(color: Colors.white, width: 4.w) : BorderSide.none,
          left: left ? BorderSide(color: Colors.white, width: 4.w) : BorderSide.none,
          right: !left ? BorderSide(color: Colors.white, width: 4.w) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? Radius.circular(20.r) : Radius.zero,
          topRight: top && !left ? Radius.circular(20.r) : Radius.zero,
          bottomLeft: !top && left ? Radius.circular(20.r) : Radius.zero,
          bottomRight: !top && !left ? Radius.circular(20.r) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final double frameSize;
  const _ScanningLine({required this.frameSize});

  @override
  State<_ScanningLine> createState() => __ScanningLineState();
}

class __ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * widget.frameSize,
          left: 0,
          right: 0,
          child: Container(
            height: 2.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white,
                  Colors.white.withOpacity(0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}