import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/custom_loader.dart';
import '../../../widgets/branded_receipt.dart';
import '../../../model/recent_transaction.dart';

class SuccessScreen extends StatefulWidget {
  final String? amount;
  final String? recipientName;
  final String? recipientAccount;
  final String? reference;
  final String? channel;
  final String? type; // "success" | "failed" | "pending"

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
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSharing = false;
  bool _isDownloading = false;

  Map<String, dynamic> get _statusConfig {
    final status = widget.type?.toLowerCase() ?? 'success';
    switch (status) {
      case 'success':
        return {
          'title': 'Payment Successful',
          'color': successColor,
          'showActions': true,
          'gradientColors': [
            successColor,
            successColor.withOpacity(0.85),
          ],
          'icon': Icons.check_circle_rounded,
        };
      case 'pending':
        return {
          'title': 'Payment Pending',
          'color': pendingColor,
          'showActions': true,
          'gradientColors': [
            pendingColor,
            pendingColor.withOpacity(0.85),
          ],
          'icon': Icons.hourglass_empty_rounded,
        };
      case 'failed':
      default:
        return {
          'title': 'Payment Failed',
          'color': errorColor,
          'showActions': false,
          'gradientColors': [
            errorColor,
            errorColor.withOpacity(0.85),
          ],
          'icon': Icons.cancel_rounded,
        };
    }
  }

  Future<File?> _captureAndSave() async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to capture receipt');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError('Failed to process image');
        return null;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint("Capture error: $e");
      _showError('Failed to capture receipt');
      return null;
    }
  }

  Future<void> _downloadToGallery() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);

    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to capture image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 4.0);
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
        _showSuccess('Receipt saved to gallery');
      }
    } catch (e) {
      debugPrint("Download error: $e");
      _showError('Failed to save to gallery');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<String> _writeTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/payment_${widget.type}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _handleShare() async {
    if (_isSharing || _isDownloading) return;
    setState(() => _isSharing = true);

    try {
      final file = await _captureAndSave();
      if (file != null && mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "${_statusConfig['title']} - ₦${widget.amount ?? '0.00'}",
        );
      }
    } catch (e) {
      debugPrint("Share error: $e");
      _showError('Failed to share receipt');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  String get _formattedDate {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final config = _statusConfig;
    final primaryThemeColor = config['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallHeight = screenHeight < 720;
            final isNarrow = screenWidth < 360;

            final badgeSize = isSmallHeight ? 85.r : 110.r;
            final verticalSpacing = isSmallHeight ? 12.h : 24.h;
            final horizontalPadding = isNarrow ? 18.w : 24.w;

            return Stack(
              children: [
                // Hidden Receipt (Off-screen) for capturing
                Positioned(
                  left: -1500,
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: BrandedReceipt(
                      transaction: TransactionItem(
                        id: DateTime.now().millisecondsSinceEpoch % 1000000,
                        amount: double.tryParse(widget.amount?.replaceAll(',', '') ?? '0') ?? 0.0,
                        isCredit: false,
                        receiverName: widget.recipientName,
                        provider: widget.channel,
                        reference: widget.reference,
                        createdAt: DateTime.now(),
                        metadata: {
                          'recipientAccount': widget.recipientAccount,
                        },
                      ),
                      statusTitle: config['title'],
                    ),
                  ),
                ),

                // Top Gradient Wash
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: isSmallHeight ? 180.h : 240.h,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryThemeColor.withOpacity(0.08),
                          const Color(0xFFF8FAFC).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(height: isSmallHeight ? 20.h : 40.h),

                      // Gorgeous Animated Ring Status Badge
                      _buildAnimatedBadge(badgeSize, config, primaryThemeColor),

                      SizedBox(height: verticalSpacing),

                      // Payment Status Title & Amount
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            config['title'],
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: isSmallHeight ? 16.sp : 19.sp,
                              color: const Color(0xFF1E293B),
                              letterSpacing: 0.1,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                          SizedBox(height: 6.h),
                          Text(
                            "₦${widget.amount ?? "0.00"}",
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: isSmallHeight ? 32.sp : 38.sp,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.8,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
                        ],
                      ),

                      SizedBox(height: verticalSpacing * 1.2),

                      // Premium Transaction Details Card
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildDetailsCard(isSmallHeight, isNarrow, primaryThemeColor),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      ),

                      // Actions Block Fixed at Bottom
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: EdgeInsets.only(bottom: isSmallHeight ? 16.h : 24.h, top: 8.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (config['showActions']) ...[
                              _buildActionButtons(),
                              SizedBox(height: 16.h),
                            ],
                            CustomButton(
                              buttonName: "Done",
                              buttonColor: primaryThemeColor,
                              buttonTextColor: Colors.white,
                              onPressed: () => context.pushNamed(RouteList.bottomNavBar),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedBadge(double badgeSize, Map<String, dynamic> config, Color primaryColor) {
    return Hero(
      tag: 'status_badge_${widget.type}',
      child: Center(
        child: Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Container(
                width: badgeSize - 12.r,
                height: badgeSize - 12.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.06),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),

              // Solid Icon container
              Container(
                width: badgeSize - 28.r,
                height: badgeSize - 28.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: config['gradientColors'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  config['icon'] as IconData,
                  color: Colors.white,
                  size: badgeSize * 0.45,
                ),
              ).animate().scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isSmallHeight, bool isNarrow, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header Info (Visual indicator of Transaction)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.04),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23.r),
                topRight: Radius.circular(23.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 14.sp, color: themeColor),
                SizedBox(width: 6.w),
                Text(
                  "TRANSACTION RECEIPT",
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              children: [
                _buildModernDetailRow("Recipient", widget.recipientName ?? "-", Icons.person_outline_rounded, isNarrow, isSmallHeight),
                _buildDivider(),
                _buildModernDetailRow("Account", widget.recipientAccount ?? "-", Icons.wallet_outlined, isNarrow, isSmallHeight),
                _buildDivider(),
                _buildModernDetailRow("Reference", widget.reference ?? "-", Icons.receipt_long_outlined, isNarrow, isSmallHeight),
                _buildDivider(),
                _buildModernDetailRow("Channel", widget.channel ?? "Transfer", Icons.swap_horiz_rounded, isNarrow, isSmallHeight),
                _buildDivider(),
                _buildModernDetailRow("Date", _formattedDate, Icons.calendar_today_rounded, isNarrow, isSmallHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow(String title, String value, IconData icon, bool isNarrow, bool isSmallHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallHeight ? 10.h : 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isSmallHeight ? 15.sp : 18.sp, color: const Color(0xFF64748B)),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: isSmallHeight ? 12.sp : 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF1E293B),
                fontSize: isSmallHeight ? 12.sp : 14.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
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
    return const Divider(
      color: Color(0xFFF1F5F9),
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.share_rounded,
            label: "Share",
            onTap: (_isSharing || _isDownloading) ? null : _handleShare,
            isLoading: _isSharing,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _ActionButton(
            icon: Icons.download_rounded,
            label: "Download",
            onTap: (_isSharing || _isDownloading) ? null : _downloadToGallery,
            isLoading: _isDownloading,
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
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: onTap == null ? const Color(0xFFE2E8F0) : primaryColor.withOpacity(0.4),
              width: 1.2,
            ),
            color: onTap == null ? const Color(0xFFF8FAFC) : Colors.white,
            boxShadow: onTap == null
                ? []
                : [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CustomLoader(
                  size: 16,
                  color: onTap == null ? const Color(0xFF94A3B8) : primaryColor,
                )
              else
                Icon(
                  icon,
                  color: onTap == null ? const Color(0xFF94A3B8) : primaryColor,
                  size: 18.sp,
                ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? const Color(0xFF94A3B8) : primaryColor,
                  fontWeight: FontWeight.w700,
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