import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/utils/image.dart';
import '../model/recent_transaction.dart';
import 'package:bia/app/utils/colors.dart';
class BrandedReceipt extends StatelessWidget {
  final TransactionItem transaction;
  final String? statusTitle;

  const BrandedReceipt({
    super.key,
    required this.transaction,
    this.statusTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = statusTitle ?? transaction.status?.toUpperCase() ?? "SUCCESSFUL";
    
    const footerBg = Color(0xFF0D0D0D); // Deep black/dark grey

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1, 2 & 3. UNIFIED RECEIPT (ZIG-ZAG TOP & BOTTOM) ---
          ClipPath(
            clipper: ZigZagClipper(),
            child: Container(
              width: 380.w,
              color: lightBackground,
              child: Column(
                children: [
                  // Top Zig-Zag Strip
                  Container(
                    width: 380.w,
                    height: 12.h,
                    color: primaryColor,
                  ),
                  
                  // Main Content
                  Container(
                    width: 380.w,
                    color: lightBackground,
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 30.h),
                    child: Stack(
                      children: [
                        // OPay-style Diagonal Watermark
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DiagonalWatermarkPainter(
                              logoOpacity: 0.04,
                            ),
                          ),
                        ),

                        Column(
                          children: [
                            // Header (Logo)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  logoPng,
                                  height: 30.h,
                                ),
                              ],
                            ),
                            SizedBox(height: 32.h),
                            
                            // Amount
                            Text(
                              '₦${NumberFormat('#,##0.00').format(transaction.amount)}',
                              style: TextStyle(
                                fontSize: 42.sp,
                                fontWeight: FontWeight.w900,
                                color: darkBackground,
                                letterSpacing: -1,
                              ),
                            ),
                            
                            // Date & Time
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(transaction.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: grey500,
                              ),
                            ),
                            
                            SizedBox(height: 40.h),
                            _buildDashedDivider(),
                            SizedBox(height: 30.h),

                            // Details
                            _buildReceiptRow("Sender", transaction.senderName ?? "BIA Wallet"),
                            ...(() {
                              final st = transaction.serviceType?.toUpperCase() ?? '';
                              final md = transaction.metadata ?? {};
                              final info = md['info'] as Map<String, dynamic>?;

                              if (st == 'CABLE' || st == 'CABLE_TV') {
                                return [
                                  if (info != null) ...[
                                    _buildReceiptRow("Provider", info['provider'] ?? transaction.provider ?? "N/A"),
                                    _buildReceiptRow("Card Number", info['cardNumber'] ?? info['accountNumber'] ?? "N/A"),
                                    if (info['package'] != null)
                                      _buildReceiptRow("Package", info['package']),
                                  ] else ...[
                                    _buildReceiptRow("Provider", transaction.provider ?? "N/A"),
                                  ]
                                ];
                              } else if (st == 'ELECTRICITY' || st == 'ELECTRICITY_BILL') {
                                return [
                                  if (info != null) ...[
                                    _buildReceiptRow("Provider", info['provider'] ?? transaction.provider ?? "N/A"),
                                    _buildReceiptRow("Meter Number", info['meterNumber'] ?? info['accountNumber'] ?? "N/A"),
                                    if (info['token'] != null)
                                      _buildReceiptRow("Token", info['token']),
                                  ] else ...[
                                    _buildReceiptRow("Provider", transaction.provider ?? "N/A"),
                                  ]
                                ];
                              } else if (st == 'AIRTIME' || st == 'DATA') {
                                return [
                                  if (info != null) ...[
                                    _buildReceiptRow("Provider", info['network'] ?? transaction.provider ?? "N/A"),
                                    _buildReceiptRow("Beneficiary", info['phone'] ?? info['meterNumber'] ?? info['accountNumber'] ?? "N/A"),
                                  ] else ...[
                                    _buildReceiptRow("Provider", transaction.provider ?? "N/A"),
                                  ]
                                ];
                              } else {
                                return [
                                  _buildReceiptRow("Recipient", transaction.receiverName ?? "N/A"),
                                  if (transaction.isBankTransfer)
                                    _buildReceiptRow("Recipient Bank", transaction.provider ?? "External Bank"),
                                  if (md['recipientAccount'] != null)
                                    _buildReceiptRow("Account", md['recipientAccount'].toString()),
                                ];
                              }
                            })(),
                            _buildReceiptRow("Reference", transaction.reference ?? transaction.transactionId ?? "N/A"),

                          ],
                        ),
                      ],
                    ),
                  ),

                  // Marketing Banner (Now inside the clipper)
                  Container(
                    width: 380.w,
                    decoration: BoxDecoration(
                      color: grey50,
                      border: Border(top: BorderSide(color: grey200, width: 1)),
                    ),
                    child: Column(
                      children: [
                        // Fancy Ads Box
                        Container(
                          margin: EdgeInsets.all(16.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPromotionalMessage(transaction),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Visit www.bia.com.ng",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.qr_code, color: Colors.white, size: 40.sp),
                            ],
                          ),
                        ),
                        
                        // Legal Footer
                        Padding(
                          padding: EdgeInsets.only(bottom: 24.h, left: 16.w, right: 16.w),
                          child: Column(
                            children: [
                              Text(
                                "BIA is powered by licensed partners and protected by NDIC.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: grey600,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "The smart and stress-free way to handle money.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: grey400,
                                  fontSize: 8.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Zig-Zag Strip
                        Container(
                          width: 380.w,
                          height: 12.h,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPromotionalMessage(TransactionItem transaction) {
    final type = (transaction.serviceType ?? '').toUpperCase();
    if (type.contains('BILL')) {
      return "Pay electricity bills, buy airtime, and data on WhatsApp with BIA.";
    } else if (type.contains('TRANSFER')) {
      return "Send money safely and instantly. Experience seamless banking on BIA.";
    } else if (type.contains('AIRTIME') || type.contains('DATA')) {
      return "Recharge with ease! Buy airtime and data instantly on the BIA app.";
    }
    return "Managing your money just got a whole lot smarter. Experience BIA today!";
  }

  Widget _buildDashedDivider() {
    return Row(
      children: List.generate(20, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            height: 1,
            color: grey300,
          ),
        );
      }),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF4B4B4B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper to create the zig-zag "torn paper" effect for receipts.
class ZigZagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    const double step = 8.0; // Size of each zig
    const double height = 6.0; // Depth of each zig

    // Top Zig-Zags
    path.moveTo(0, height);
    for (double i = step; i <= size.width; i += step * 2) {
      path.lineTo(i - step, 0);
      path.lineTo(i, height);
    }
    path.lineTo(size.width, height);

    // Right side
    path.lineTo(size.width, size.height - height);

    // Bottom Zig-Zags
    for (double i = size.width - step; i >= 0; i -= step * 2) {
      path.lineTo(i + step, size.height);
      path.lineTo(i, size.height - height);
    }
    path.lineTo(0, size.height - height);

    // Left side
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom painter to create an OPay-style diagonal repeating watermark.
class DiagonalWatermarkPainter extends CustomPainter {
  final double logoOpacity;

  DiagonalWatermarkPainter({this.logoOpacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    const double fontSize = 14.0;
    const double spacingX = 100.0;
    const double spacingY = 60.0;
    const double angle = -0.45; // ~25 degrees

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    canvas.save();
    canvas.rotate(angle);

    // We need to cover a larger area because of the rotation
    for (double x = -size.width; x < size.width * 2; x += spacingX) {
      for (double y = -size.height; y < size.height * 2; y += spacingY) {
        textPainter.text = TextSpan(
          text: "BIA",
          style: TextStyle(
            color: Colors.black.withOpacity(logoOpacity),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
