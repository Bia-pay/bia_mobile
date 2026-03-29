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
import 'package:intl/intl.dart';

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
  bool _isProcessing = false;

  Future<File?> _captureAndSave() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) {
        _showError('Unable to capture screenshot');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showError('Failed to process image');
        return null;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transaction_success.png');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint("Capture error: $e");
      _showError('Failed to capture receipt');
      return null;
    }
  }

  Future<void> _downloadToGallery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) {
        _showError('Unable to capture image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showError('Failed to process image');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempPath = await _writeTempFile(pngBytes);
      final mediaStore = MediaStore();

      await mediaStore.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      if (mounted) {
        _showSuccess('Saved to gallery');
      }
    } catch (e) {
      debugPrint("Download error: $e");
      _showError('Failed to save to gallery');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String> _writeTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/payment_success_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _handleShare() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final file = await _captureAndSave();
      if (file != null && mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "Payment Successful - ₦${widget.amount ?? '0.00'}",
        );
      }
    } catch (e) {
      debugPrint("Share error: $e");
      _showError('Failed to share receipt');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  String get _formattedDate {
    return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now());
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
            final screenHeight = constraints.maxHeight;
            final isSmallHeight = screenHeight < 700;
            final isNarrow = screenWidth < 360;

            // Responsive calculations
            final badgeSize = isSmallHeight
                ? screenWidth * 0.22
                : (isNarrow ? screenWidth * 0.28 : screenWidth * 0.32);

            final verticalSpacing = isSmallHeight ? 10.h : 20.h;
            final horizontalPadding = isNarrow ? 16.w : screenWidth * 0.05;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: isSmallHeight ? 12.h : 24.h),

                  // Success Badge
                  _buildSuccessBadge(badgeSize),

                  SizedBox(height: verticalSpacing),

                  // Capture Area
                  Expanded(
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Container(
                        color: Colors.white, // Ensure white background for capture
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildTitle(textTheme, isSmallHeight),
                            SizedBox(height: 8.h),
                            _buildAmount(textTheme, isSmallHeight),
                            SizedBox(height: verticalSpacing),
                            _buildDetailsCard(isSmallHeight, isNarrow),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: verticalSpacing),

                  // Action Buttons
                  _buildActionButtons(),

                  SizedBox(height: verticalSpacing),

                  // Done Button
                  CustomButton(
                    buttonName: "Done",
                    buttonColor: primaryColor,
                    buttonTextColor: Colors.white,
                    onPressed: () => context.pushNamed(RouteList.bottomNavBar),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessBadge(double badgeSize) {
    return Hero(
      tag: 'success_badge',
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  successColor,
                  successColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: successColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            successs,
            height: badgeSize * 1.1,
            width: badgeSize * 1.1,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(TextTheme textTheme, bool isSmallHeight) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        "Payment Successful",
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: isSmallHeight ? 18.sp : 22.sp,
          color: darkBackground,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildAmount(TextTheme textTheme, bool isSmallHeight) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        "₦${widget.amount ?? "0.00"}",
        style: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: isSmallHeight ? 28.sp : 36.sp,
          color: darkBackground,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isSmallHeight, bool isNarrow) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallHeight ? 12.w : 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailRow("Recipient", widget.recipientName ?? "-", isNarrow),
          _buildDivider(),
          _buildDetailRow("Account", widget.recipientAccount ?? "-", isNarrow),
          _buildDivider(),
          _buildDetailRow("Reference", widget.reference ?? "-", isNarrow),
          _buildDivider(),
          _buildDetailRow("Channel", widget.channel ?? "Transfer", isNarrow),
          _buildDivider(),
          _buildDetailRow("Date", _formattedDate, isNarrow),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, bool isNarrow) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isNarrow ? 10.h : 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isNarrow ? 12.sp : 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: darkBackground,
                fontSize: isNarrow ? 13.sp : 15.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade100,
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.share_outlined,
            label: "Share",
            onTap: _isProcessing ? null : _handleShare,
            isLoading: _isProcessing,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _ActionButton(
            icon: Icons.download_outlined,
            label: "Download",
            onTap: _isProcessing ? null : _downloadToGallery,
            isLoading: _isProcessing,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: onTap == null ? Colors.grey.shade300 : primaryColor,
              width: 1.5,
            ),
            color: onTap == null ? Colors.grey.shade50 : secondaryColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 18.w,
                  width: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      onTap == null ? Colors.grey : darkBackground,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: onTap == null ? Colors.grey : darkBackground,
                  size: 18.sp,
                ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Colors.grey : darkBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}