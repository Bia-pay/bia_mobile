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
      _showSnack('Failed to share QR code: $e', Colors.red);
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

      _showSnack("QR Code saved successfully!", Colors.green);
    } catch (e) {
      _showSnack('Failed to download QR code: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground, // from colors.dart
      body: Padding(
        padding: EdgeInsets.all(20.h),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: primaryColor)
              : qrUrl == null
              ? Text(
                  "Failed to load QR code",
                  style: TextStyle(color: Colors.red, fontSize: 14.sp),
                )
              : Column(
                  children: [
                    SizedBox(height: 50.h),
                    CustomHeader(title: 'Qr Code'),
                    SizedBox(height: 100.h),
                    Container(
                      decoration: BoxDecoration(
                        color: lightSurface,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.network(
                        qrUrl!,
                        height: 250.h,
                        width: 250.w,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error, size: 80.sp, color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Text(
                      "Scan this to send money to your Bia wallet",
                      style: TextStyle(
                        color: lightText,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    /// ✅ Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: lightBackground,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onPressed: _shareQrCode,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text("Download"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightSurface,
                              foregroundColor: lightText,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            onPressed: _downloadQrCode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
