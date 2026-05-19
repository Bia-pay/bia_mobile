import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

import '../../../../../app/utils/colors.dart';
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
  late ConfettiController _confettiController;
  late String _reference;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    final status = widget.type?.toLowerCase() ?? 'success';
    if (status == 'success') {
      _confettiController.play();
    }

    // Set stable reference fallback if backend returns empty/null
    final refVal = widget.reference;
    if (refVal == null || refVal.trim().isEmpty || refVal == '-') {
      final rand = DateTime.now().millisecondsSinceEpoch.toString();
      final suffix = rand.length > 10 ? rand.substring(rand.length - 10) : rand;
      _reference = 'BIA$suffix';
    } else {
      _reference = refVal;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _statusConfig {
    final status = widget.type?.toLowerCase() ?? 'success';
    switch (status) {
      case 'success':
        return {
          'title': 'Transfer Successful',
          'color': const Color(0xFF00C853),
          'showActions': true,
          'icon': Icons.check_rounded,
        };
      case 'pending':
        return {
          'title': 'Transaction Pending',
          'color': const Color(0xFFFFAB00),
          'showActions': true,
          'icon': Icons.hourglass_empty_rounded,
        };
      case 'failed':
      default:
        return {
          'title': 'Transaction Failed',
          'color': const Color(0xFFFF1744),
          'showActions': false,
          'icon': Icons.close_rounded,
        };
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Reference copied to clipboard');
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
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: Colors.white)),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: Colors.white)),
        backgroundColor: const Color(0xFFFF1744),
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
    final config = _statusConfig;
    final primaryThemeColor = config['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Soft dynamic blue-grey background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isSmallHeight = screenHeight < 720;
            final isNarrow = screenWidth < 360;

            final badgeSize = isSmallHeight ? 60.r : 72.r;
            final horizontalPadding = isNarrow ? 18.w : 24.w;

            // Pixel perfect Y position for notches and dashed line
            final notchY = 166.h;

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
                        reference: _reference,
                        createdAt: DateTime.now(),
                        metadata: {
                          'recipientAccount': widget.recipientAccount,
                        },
                      ),
                      statusTitle: config['title'],
                    ),
                  ),
                ),

                // Top Glowing Radial mesh wash
                Positioned(
                  top: -80.h,
                  left: -50.w,
                  right: -50.w,
                  height: 300.h,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryThemeColor.withOpacity(0.08),
                          primaryThemeColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Scrollable viewport covering the entire body to ensure complete responsiveness
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallHeight ? 16.h : 32.h),

                        // Floating Header Status Badge
                        _buildHeaderBadge(badgeSize, primaryThemeColor, config['icon'] as IconData),

                        SizedBox(height: 12.h),

                        // Status Title
                        Text(
                          config['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isSmallHeight ? 15.sp : 17.sp,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        SizedBox(height: isSmallHeight ? 16.h : 24.h),

                        // Master Receipt Card (with side notches and dashed lines)
                        ClipPath(
                          clipper: TicketClipper(notchRadius: 10.r, notchY: notchY),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Top Receipt Header Section (exactly sized to notchY)
                                Container(
                                  height: notchY,
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Large Amount Display
                                      Text(
                                        "₦${widget.amount ?? "0.00"}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: isSmallHeight ? 32.sp : 38.sp,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: -1,
                                        ),
                                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),
                                      
                                      SizedBox(height: 16.h),
                                      
                                      // Flow line diagram
                                      _buildTimelineFlow(primaryThemeColor),
                                    ],
                                  ),
                                ),

                                // Mid Dashed perforated line aligned exactly at notchY
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                                  child: Row(
                                    children: List.generate(
                                      24,
                                      (index) => Expanded(
                                        child: Container(
                                          height: 1.2.h,
                                          margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                                          color: const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom Details section
                                Padding(
                                  padding: EdgeInsets.all(20.w),
                                  child: Column(
                                    children: [
                                      _buildTicketRow("Account Number", widget.recipientAccount ?? "-", isSmallHeight),
                                      _buildTicketRow("Payment Channel", widget.channel ?? "Bank Transfer", isSmallHeight),
                                      _buildTicketRow("Transaction Date", _formattedDate, isSmallHeight),
                                      _buildReferenceRow(_reference, isSmallHeight),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuad),

                        SizedBox(height: 24.h),

                        // Action Buttons block
                        if (config['showActions']) ...[
                          _buildActionButtons(),
                          SizedBox(height: 16.h),
                        ],

                        // Main Slate Confirmation Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.pushNamed(RouteList.bottomNavBar),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A), // Luxury dark slate
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                            ),
                            child: Text(
                              "Go to Dashboard",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 350.ms),

                        SizedBox(height: 36.h),
                      ],
                    ),
                  ),
                ),

                // Celebratory confetti overlay
                if (widget.type == null || widget.type!.toLowerCase() == 'success')
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        maxBlastForce: 15,
                        minBlastForce: 5,
                        emissionFrequency: 0.05,
                        numberOfParticles: 45,
                        gravity: 0.12,
                        colors: const [
                          Color(0xFF00C853),
                          Color(0xFF2979FF),
                          Color(0xFFFF3D00),
                          Color(0xFFFFEA00),
                          Color(0xFFD500F9),
                          Color(0xFF00E5FF),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(double size, Color color, IconData icon) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
      ),
      child: Center(
        child: Container(
          width: size - 14.r,
          height: size - 14.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.45,
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 550.ms, curve: Curves.elasticOut);
  }

  Widget _buildTimelineFlow(Color themeColor) {
    final recipientNameVal = widget.recipientName ?? "Recipient";
    final recipientInitials = recipientNameVal.isNotEmpty
        ? recipientNameVal.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : "RE";

    return Row(
      children: [
        // Sender Account Bubble
        Column(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: primaryColor.withOpacity(0.08),
              child: Text(
                "BIA",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11.sp,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "My Wallet",
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        // Line flow connecting
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    8,
                    (index) => Expanded(
                      child: Container(
                        height: 2.h,
                        margin: EdgeInsets.symmetric(horizontal: 1.2.w),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(index == 3 || index == 4 ? 1 : 0.25),
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    widget.channel ?? "Transfer",
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: themeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recipient Account Bubble
        Column(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: themeColor.withOpacity(0.08),
              child: Text(
                recipientInitials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11.sp,
                  color: themeColor,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              recipientNameVal.length > 12 ? "${recipientNameVal.substring(0, 10)}..." : recipientNameVal,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketRow(String label, String value, bool isSmallHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallHeight ? 9.h : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 13.sp,
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
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceRow(String reference, bool isSmallHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallHeight ? 9.h : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reference",
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    reference,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF1E293B),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: () => _copyToClipboard(reference),
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 12.sp,
                      color: const Color(0xFF64748B),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: onTap == null ? const Color(0xFFE2E8F0) : primaryColor.withOpacity(0.25),
              width: 1.2,
            ),
            color: onTap == null ? const Color(0xFFF8FAFC) : Colors.white,
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
                  size: 16.sp,
                ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? const Color(0xFF94A3B8) : primaryColor,
                  fontWeight: FontWeight.w800,
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

// Ultra-Premium Custom Clipper for Receipt Slips
class TicketClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchY;

  TicketClipper({required this.notchRadius, required this.notchY});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Start top left
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    
    // Top right to right notch
    path.lineTo(size.width, notchY - notchRadius);
    // Right notch arc cutout
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Right notch to bottom right
    path.lineTo(size.width, size.height);
    
    // Perforated/Zigzag bottom edge
    double toothWidth = 8.0;
    double toothHeight = 4.0;
    int teethCount = (size.width / toothWidth).floor();
    double remainingWidth = size.width - (teethCount * toothWidth);
    
    path.lineTo(size.width - remainingWidth / 2, size.height);
    for (int i = 0; i < teethCount; i++) {
      double curX = size.width - (remainingWidth / 2) - (i * toothWidth);
      path.lineTo(curX - toothWidth / 2, size.height - toothHeight);
      path.lineTo(curX - toothWidth, size.height);
    }
    path.lineTo(0, size.height);
    
    // Bottom left to left notch
    path.lineTo(0, notchY + notchRadius);
    // Left notch arc cutout
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    // Left notch to top left
    path.lineTo(0, 0);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}