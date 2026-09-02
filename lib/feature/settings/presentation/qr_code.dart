import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bia/app/utils/widgets/premium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:gal/gal.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  String? staticQrUrl;
  String? dynamicQrUrl;
  bool isLoading = true;
  
  // Dynamic QR form
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  // User details
  String? fullname;
  String? account;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserDetails();
    _fetchStaticQrCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    final box = Hive.box('authBox');
    setState(() {
      fullname = box.get('fullname', defaultValue: 'User Name');
      account = box.get('phone', defaultValue: '');
    });
  }

  Future<void> _fetchStaticQrCode() async {
    setState(() => isLoading = false);
  }

  Future<void> _generateDynamicQr() async {
    if (_amountController.text.isEmpty) {
      _showSnack("Please enter an amount", errorColor);
      return;
    }
    setState(() {
      dynamicQrUrl = "local";
    });
  }

  Future<void> _saveToGallery() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);
        _showSnack("QR Card saved to gallery!", successColor);
      }
    } catch (e) {
      _showSnack("Failed to save: $e", errorColor);
    }
  }

  Future<void> _shareQrCode() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/bia_qr_card.png').create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Scan to pay me on Bia!');
      }
    } catch (e) {
      _showSnack('Failed to share: $e', errorColor);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack("Copied to clipboard!", successColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(RouteList.bottomNavBar);
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Receive Money",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),

              // Tab Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.all(4.r),
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: Colors.white,
                    ),
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.white,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    tabs: const [
                      Tab(text: "My QR Code"),
                      Tab(text: "Request Payment"),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStaticTab(),
                    _buildDynamicTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticTab() {
    final qrData = "https://bia.com.ng/pay?account=${account ?? ''}&name=${Uri.encodeComponent(fullname ?? '')}";

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          Screenshot(
            controller: _screenshotController,
            child: PremiumGlassCard(
              title: fullname ?? "Bia User",
              subtitle: "Account: ${account ?? ''}",
              child: account == null || account!.isEmpty
                  ? SizedBox(
                      height: 200.r,
                      width: 200.r,
                      child: Center(child: CustomLoader()),
                    )
                  : Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 180.r,
                        gapless: false,
                      ),
                    ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
          
          SizedBox(height: 30.h),
          
          _buildActionButtons(isDynamic: false),
          
          SizedBox(height: 40.h),
          
          Text(
            "Scan this QR code to pay me instantly",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTab() {
    final qrData = "https://bia.com.ng/pay?account=${account ?? ''}&name=${Uri.encodeComponent(fullname ?? '')}&amount=${_amountController.text}&narration=${Uri.encodeComponent(_narrationController.text)}";

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          if (dynamicQrUrl == null) ...[
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Enter Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "0.00",
                      prefixText: "₦ ",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text("What's it for? (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _narrationController,
                    decoration: InputDecoration(
                      hintText: "Lunch, Services, etc.",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: _generateDynamicQr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: const Text("Generate Payment QR", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ] else ...[
            PremiumGlassCard(
              title: "Payment Requested",
              subtitle: "Amount: ₦${_amountController.text}",
              child: account == null || account!.isEmpty
                  ? SizedBox(height: 200.r, width: 200.r, child: Center(child: CustomLoader()))
                  : Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 180.r,
                        gapless: false,
                      ),
                    ),
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: () => setState(() => dynamicQrUrl = null),
              child: const Text("Create New Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20.h),
            _buildActionButtons(isDynamic: true),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool isDynamic}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircularAction(Icons.download_rounded, "Save", _saveToGallery),
        _buildCircularAction(Icons.share_rounded, "Share", _shareQrCode),
        _buildCircularAction(
          Icons.copy_rounded, 
          "Copy Link", 
          () {
            String link;
            if (isDynamic && _amountController.text.isNotEmpty) {
              link = "https://bia.com.ng/pay?account=${account ?? ''}&name=${Uri.encodeComponent(fullname ?? '')}&amount=${_amountController.text}&narration=${Uri.encodeComponent(_narrationController.text)}";
            } else {
              link = "https://bia.com.ng/pay?account=${account ?? ''}&name=${Uri.encodeComponent(fullname ?? '')}";
            }
            _copyToClipboard(link);
          },
        ),
      ],
    );
  }

  Widget _buildCircularAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
