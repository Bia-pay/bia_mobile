import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';

class SuccessScreen extends StatefulWidget {
  final String? amount;
  final String? recipientName;
  final String? recipientAccount;
  final String? reference;
  final String? channel;
  final String? type;

  const SuccessScreen({
    super.key,
    this.amount,
    this.recipientName,
    this.recipientAccount,
    this.reference,
    this.channel,
    this.type,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<File> _captureAndSave() async {
    final boundary =
    _boundaryKey.currentContext!.findRenderObject()
    as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file =
    File('${directory.path}/transaction_success.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }


  Future<void> _downloadToGallery() async {
    try {
      final boundary = _boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image =
      await boundary.toImage(pixelRatio: 3.0);

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final Uint8List pngBytes =
      byteData.buffer.asUint8List();

      final mediaStore = MediaStore();

      await mediaStore.saveFile(
        tempFilePath: await _writeTempFile(pngBytes),
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved to gallery"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  Future<String> _writeTempFile(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp();
    final file =
    File('${tempDir.path}/payment_success.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final badgeSize = screenWidth * 0.32;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [

                      SizedBox(height: 30.h),

                      /// ===== SUCCESS BADGE =====
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: badgeSize,
                            height: badgeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  successColor,
                                  successColor.withOpacity(.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: successColor.withOpacity(.25),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                )
                              ],
                            ),
                          ),
                          SvgPicture.asset(
                            successs,
                            height: badgeSize * 1.2,
                          ),
                        ],
                      ),

                      SizedBox(height: 25.h),

                      /// ================= CAPTURE AREA =================
                      RepaintBoundary(
                        key: _boundaryKey,
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Column(
                            children: [

                              Text(
                                "Payment Successful",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20.spMin,
                                  color: darkBackground,
                                ),
                              ),

                              SizedBox(height: 12.h),

                              Text(
                                "₦${widget.amount ?? "0.00"}",
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34.spMin,
                                  color: darkBackground,
                                ),
                              ),

                              SizedBox(height: 20.h),

                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                ),
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(24.r),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _lightRow("Recipient",
                                        widget.recipientName ?? "-"),
                                    _lightDivider(),
                                    _lightRow("Account",
                                        widget.recipientAccount ?? "-"),
                                    _lightDivider(),
                                    _lightRow("Reference",
                                        widget.reference ?? "-"),
                                    _lightDivider(),
                                    _lightRow("Channel",
                                        widget.channel ?? "Transfer"),
                                    _lightDivider(),
                                    _lightRow(
                                      "Date",
                                      DateTime.now()
                                          .toString()
                                          .substring(0, 16),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
                      /// ================= END CAPTURE AREA =================

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 10.h,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _lightActionButton(
                                icon: Icons.share,
                                label: "Share",
                                onTap: () async {
                                  final file =
                                  await _captureAndSave();
                                  await Share.shareXFiles(
                                    [XFile(file.path)],
                                    text:
                                    "Payment Successful",
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 15.w),
                            Expanded(
                              child: _lightActionButton(
                                icon: Icons.download,
                                label: "Download",
                                onTap: _downloadToGallery,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: CustomButton(
                          buttonName: "Done",
                          buttonColor: primaryColor,
                          buttonTextColor: Colors.white,
                          onPressed: () =>
                              context.pushNamed(
                                  RouteList.bottomNavBar),
                        ),
                      ),

                      SizedBox(height: 25.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _lightRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.sp,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: darkBackground,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _lightDivider() {
    return Divider(
      color: Colors.grey.shade200,
      thickness: 1,
    );
  }
  Widget _lightActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: primaryColor,
          ),
          color: secondaryColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: darkBackground),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: darkBackground,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}