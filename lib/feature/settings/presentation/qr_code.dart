import 'dart:io';
import 'dart:typed_data';
import 'package:bia/app/view/widget/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../../app/utils/colors.dart';
import '../../../app/utils/custom_loader.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key});

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  String? qrUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  Future<void> _fetchQrCode() async {
    final controller = ref.read(dashboardControllerProvider.notifier);
    final response = await controller.getUserQrCode(context);

    if (response?.responseSuccessful == true) {
      final fetchedUrl = response?.responseBody?.url;
      setState(() {
        qrUrl = fetchedUrl;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _shareQrCode() async {
    try {
      if (qrUrl == null) return;
      final response = await http.get(Uri.parse(qrUrl!));
      final Uint8List bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/bia_qr.png').create();
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Bia Wallet QR Code');
    } catch (e) {
      _showSnack('Failed to share QR code: $e', errorColor);
    }
  }

  Future<void> _downloadQrCode() async {
    try {
      if (qrUrl == null) return;
      final response = await http.get(Uri.parse(qrUrl!));
      final Uint8List bytes = response.bodyBytes;

      final directory = await getApplicationDocumentsDirectory();
      final file = await File(
        '${directory.path}/bia_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(bytes);

      _showSnack("QR Code saved successfully!", successColor);
    } catch (e) {
      _showSnack('Failed to download QR code: $e', errorColor);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              /// Header
              CustomHeader(title: 'My QR Code'),

              SizedBox(height: 40.h),

              /// Content
              Expanded(
                child: Center(
                  child: isLoading
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomLoader(
                        size: 40,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Generating your QR...",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  )
                      : qrUrl == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 80.sp,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Failed to load QR code",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      /// Glass QR Card
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            color: Colors.white,
                            padding: EdgeInsets.all(16.w),
                            child: Image.network(
                              qrUrl!,
                              height: 240.h,
                              width: 240.w,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.error_outline,
                                size: 80.sp,
                                color: errorColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 28.h),

                      Text(
                        "Scan to send money instantly",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        "Share this QR to receive payments securely",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              /// Buttons
              if (!isLoading && qrUrl != null)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _shareQrCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          "Share QR Code",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _downloadQrCode,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          "Download",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
