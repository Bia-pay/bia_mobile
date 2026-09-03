import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:bia/app/utils/colors.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'package:bia/feature/auth/modal/reponse/response_modal.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
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
      final String? code = barcodes.first.rawValue ?? barcodes.first.displayValue;
      if (code != null && code.isNotEmpty) {
        _handleQrResult(code);
      }
    }
  }

  Future<void> _handleQrResult(String rawResult) async {
    setState(() => isScanning = false);
    final String result = rawResult.trim();
    debugPrint("📥 Scanned Result: $result");

    String? account;
    double? amount;
    String? narration;

    try {
      // 1. Try parsing as JSON first
      dynamic decoded;
      try {
        String jsonStr = result;
        if (result.contains("'") && !result.contains('"')) {
          jsonStr = result.replaceAll("'", '"');
        }
        decoded = jsonDecode(jsonStr);
      } catch (_) {
        decoded = null;
      }

      if (decoded is Map<String, dynamic>) {
        // Check if it is a Split Payment QR
        if (decoded.containsKey('splitId') && decoded.containsKey('token')) {
          final splitId = decoded['splitId'].toString();
          final token = decoded['token'].toString();
          if (mounted) {
            context
                .pushNamed(
                  RouteList.splitScanView,
                  extra: {'splitId': splitId, 'token': token},
                )
                .then((_) {
                  if (mounted) setState(() => isScanning = true);
                });
          }
          return;
        }

        account = decoded['account']?.toString() ??
            decoded['phone']?.toString() ??
            decoded['receiverAccount']?.toString() ??
            decoded['user']?.toString();

        if (decoded['amount'] != null) {
          amount = (decoded['amount'] as num?)?.toDouble();
        }
        narration = decoded['narration']?.toString();
      }

      // 2. If not JSON or account not found, try parsing as URI/URL
      if (account == null || account.isEmpty) {
        final uri = Uri.tryParse(result);
        if (uri != null) {
          if (uri.queryParameters.containsKey('splitId') &&
              uri.queryParameters.containsKey('token')) {
            final splitId = uri.queryParameters['splitId']!;
            final token = uri.queryParameters['token']!;
            if (mounted) {
              context
                  .pushNamed(
                    RouteList.splitScanView,
                    extra: {'splitId': splitId, 'token': token},
                  )
                  .then((_) {
                    if (mounted) setState(() => isScanning = true);
                  });
            }
            return;
          }

          account = uri.queryParameters['account'] ??
              uri.queryParameters['phone'] ??
              uri.queryParameters['receiverAccount'] ??
              uri.queryParameters['user'];

          if (uri.queryParameters['amount'] != null) {
            amount = double.tryParse(uri.queryParameters['amount']!);
          }
          if (uri.queryParameters['narration'] != null) {
            narration = uri.queryParameters['narration'];
          }
        }
      }

      // 3. Fallback: If result is a raw account/phone number string or tag
      if (account == null || account.isEmpty) {
        final cleaned = result.replaceAll(RegExp(r'[^a-zA-Z0-9@]'), '');
        if (cleaned.isNotEmpty && !result.contains('{') && !result.contains('}')) {
          account = cleaned;
        }
      }

      if (account == null || account.isEmpty) {
        _showError("Invalid QR Code format");
        return;
      }

      // 4. Verify Receiver
      _verifyAndProceed(account, amount, narration);
    } catch (e) {
      debugPrint("❌ QR Parsing Error: $e");
      _showError("Invalid QR Code format");
    }
  }

  Future<void> _verifyAndProceed(
    String account,
    double? amount,
    String? narration,
  ) async {
    debugPrint("🔍 Verifying receiver: $account");
    final dashboardController = ref.read(dashboardControllerProvider.notifier);

    String cleanAccount = account.trim().replaceAll('@', '');
    if (cleanAccount.startsWith('+234')) {
      cleanAccount = cleanAccount.substring(4);
    } else if (cleanAccount.startsWith('234') && cleanAccount.length == 13) {
      cleanAccount = cleanAccount.substring(3);
    }
    if (cleanAccount.startsWith('0') && cleanAccount.length == 11) {
      cleanAccount = cleanAccount.substring(1);
    }

    ResponseModel? response;
    // 1. Try account verification if length is 10 digits
    if (cleanAccount.length == 10) {
      response = await dashboardController.verifyAccount(context, cleanAccount);
    }

    // 2. Fallback to tag / phone verification if response is null or failed
    if (response == null || !response.responseSuccessful) {
      response = await dashboardController.verifyTag(context, cleanAccount);
    }

    if (!mounted) return;

    if (response?.responseSuccessful == true) {
      final fullname = response?.responseBody?.user?.fullname ?? "Unknown";
      final resolvedAccount = response?.responseBody?.user?.phone ??
          response?.responseBody?.user?.tag ??
          cleanAccount;
      debugPrint("✅ Receiver verified: $fullname ($resolvedAccount)");

      if (_isCollectMode) {
        context
            .pushNamed(
              RouteList.qrAmountEntryScreen,
              extra: {'account': resolvedAccount, 'isCollectMode': true},
            )
            .then((_) {
              if (mounted) setState(() => isScanning = true);
            });
      } else {
        context
            .pushNamed(
              RouteList.amountPage,
              extra: {
                'recipientAccount': resolvedAccount,
                'recipientName': fullname,
                'amount': amount,
                'narration': narration ?? "",
              },
            )
            .then((_) {
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
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isTablet = screenWidth >= 600;
    // On tablet use a 300px fixed size frame positioned in upper half
    final frameSize = isTablet
        ? 300.0
        : (screenWidth * 0.65);
    // Bottom clearance elevated to 115.0 on tablet to clear bottom nav bar & bump
    final bottomClearance = isTablet ? 115.0 : (MediaQuery.of(context).padding.bottom + 90.h);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Scanner view
          MobileScanner(controller: controller, onDetect: _onDetect),

          // 2. Immersive Overlay
          _buildOverlay(frameSize, isTablet),

          // 3. Top Controls
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24.0 : 16.w,
                vertical: isTablet ? 12.0 : 10.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isCollectMode ? "Collect from Customer" : "Scan to Pay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 16.0 : 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildCircularButton(
                    flashOn ? Icons.flash_on : Icons.flash_off,
                    () {
                      setState(() => flashOn = !flashOn);
                      controller.toggleTorch();
                    },
                    isTablet,
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Actions
          Positioned(
            bottom: bottomClearance,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Align QR code within the frame to scan",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isTablet ? 13.0 : 14.sp,
                  ),
                ),
                SizedBox(height: isTablet ? 14.0 : 20.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28.0 : 30.w,
                            vertical: isTablet ? 10.0 : 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: !_isCollectMode
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
                          ),
                          child: Text(
                            'Pay',
                            style: TextStyle(
                              color: !_isCollectMode
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14.0 : 14.sp,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28.0 : 30.w,
                            vertical: isTablet ? 10.0 : 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: _isCollectMode
                                ? primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(isTablet ? 24.0 : 30.r),
                          ),
                          child: Text(
                            'Collect',
                            style: TextStyle(
                              color: _isCollectMode
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14.0 : 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isTablet ? 18.0 : 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBottomAction(
                      Icons.photo_library_rounded,
                      "Gallery",
                      _pickFromGallery,
                      isTablet,
                    ),
                    SizedBox(width: isTablet ? 36.0 : 30.w),
                    _buildBottomAction(
                      Icons.qr_code_2_rounded,
                      "Receive",
                      () => context.pushNamed(RouteList.qrScreen),
                      isTablet,
                    ),
                    SizedBox(width: isTablet ? 36.0 : 30.w),
                    _buildBottomAction(
                      Icons.splitscreen_rounded,
                      "Split Bill",
                      () => context.pushNamed(RouteList.splitCreatorSetup),
                      isTablet,
                    ),
                  ],
                ),

                // Privacy Toggle (if needed)
                if (Hive.box(
                  'authBox',
                ).get('qr_payments_enabled', defaultValue: false))
                  Padding(
                    padding: EdgeInsets.only(top: isTablet ? 14.0 : 20.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16.0 : 16.w,
                        vertical: isTablet ? 8.0 : 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            color: successColor,
                            size: isTablet ? 16.0 : 16.sp,
                          ),
                          SizedBox(width: isTablet ? 8.0 : 8.w),
                          Text(
                            "Secure QR Payment Active",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12.0 : 12.sp,
                            ),
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

  Widget _buildOverlay(double frameSize, bool isTablet) {
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
                alignment: Alignment(0, isTablet ? -0.28 : -0.4),
                child: Container(
                  height: frameSize,
                  width: frameSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 28.0 : 40.r),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scan Frame
        Align(
          alignment: Alignment(0, isTablet ? -0.28 : -0.4),
          child: Container(
            height: frameSize,
            width: frameSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 28.0 : 40.r),
            ),
            child: Stack(
              children: [
                // Animated Scanning Line
                _ScanningLine(frameSize: frameSize),

                // Corners
                ..._buildCorners(isTablet),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners(bool isTablet) {
    return [
      // Top Left
      Positioned(top: 0, left: 0, child: _corner(top: true, left: true, isTablet: isTablet)),
      // Top Right
      Positioned(top: 0, right: 0, child: _corner(top: true, left: false, isTablet: isTablet)),
      // Bottom Left
      Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true, isTablet: isTablet)),
      // Bottom Right
      Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false, isTablet: isTablet)),
    ];
  }

  Widget _corner({required bool top, required bool left, required bool isTablet}) {
    return Container(
      width: isTablet ? 32.0 : 40.r,
      height: isTablet ? 32.0 : 40.r,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? BorderSide(color: Colors.white, width: isTablet ? 3.5 : 4.w)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: Colors.white, width: isTablet ? 3.5 : 4.w)
              : BorderSide.none,
          left: left
              ? BorderSide(color: Colors.white, width: isTablet ? 3.5 : 4.w)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: Colors.white, width: isTablet ? 3.5 : 4.w)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? Radius.circular(isTablet ? 16.0 : 20.r) : Radius.zero,
          topRight: top && !left ? Radius.circular(isTablet ? 16.0 : 20.r) : Radius.zero,
          bottomLeft: !top && left ? Radius.circular(isTablet ? 16.0 : 20.r) : Radius.zero,
          bottomRight: !top && !left ? Radius.circular(isTablet ? 16.0 : 20.r) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 10.0 : 10.r),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: isTablet ? 20.0 : 20.sp),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 14.0 : 16.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 22.0 : 28.sp),
          ),
          SizedBox(height: isTablet ? 6.0 : 8.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 12.0 : 12.sp,
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

class __ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
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
