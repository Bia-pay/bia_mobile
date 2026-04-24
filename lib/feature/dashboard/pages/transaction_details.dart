import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../model/recent_transaction.dart';
import 'package:bia/app/utils/colors.dart';
import '../../../app/utils/custom_loader.dart';

import '../widgets/branded_receipt.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionItem transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final GlobalKey _receiptKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _handleShare() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${widget.transaction.reference}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Transaction Receipt - ₦${NumberFormat('#,##0.00').format(widget.transaction.amount)}",
      );
    } catch (e) {
      debugPrint("Share error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final status = transaction.status?.toUpperCase() ?? "SUCCESSFUL";
    final isFailed = status == "FAILED";
    final isPending = status == "PENDING";
    final theme = Theme.of(context);

    final Color statusColor = isPending
        ? pendingColor
        : isFailed
            ? errorColor
            : successColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Hidden Receipt for capture
          Positioned(
            left: -1000,
            child: RepaintBoundary(
              key: _receiptKey,
              child: BrandedReceipt(transaction: transaction),
            ),
          ),
          
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getServiceTitle(transaction),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '₦${NumberFormat('#,##0.00').format(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildStatusBadge(status, statusColor),
                        SizedBox(height: 32.h),

                        if (transaction.isBankTransfer) ...[
                          _buildTimeline(transaction, status, statusColor),
                          SizedBox(height: 32.h),
                        ],

                        _buildAmountBreakdown(transaction),
                        SizedBox(height: 32.h),

                        _buildTransactionDetails(transaction, status),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Report Issue',
                          Colors.white,
                          const Color(0xFF2D2D2D),
                          () {},
                          hasBorder: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionButton(
                          'Share Receipt',
                          primaryColor,
                          Colors.white,
                          _handleShare,
                          isLoading: _isProcessing,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimeline(TransactionItem tx, String status, Color statusColor) {
    final creationTime = tx.createdAt ?? DateTime.now();
    final isDone = status == "SUCCESSFUL" || status == "SUCCESS";
    final isFailed = status == "FAILED";
    final isPending = status == "PENDING";

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          _buildHorizontalStep(
            'Sent',
            DateFormat('hh:mm a').format(creationTime),
            Icons.send_rounded,
            isCompleted: true,
            activeColor: const Color(0xFF22C55E),
          ),
          _buildHorizontalLine(
            isCompleted: !isPending, 
            activeColor: isFailed ? errorColor : successColor,
          ),
          _buildHorizontalStep(
            'Processing',
            isPending ? 'Ongoing' : DateFormat('hh:mm a').format(creationTime),
            Icons.sync_rounded,
            isCompleted: !isPending,
            activeColor: isFailed ? errorColor : (isPending ? pendingColor : successColor),
          ),
          _buildHorizontalLine(
            isCompleted: isDone || isFailed, 
            activeColor: isFailed ? errorColor : successColor,
          ),
          _buildHorizontalStep(
            isFailed ? 'Failed' : 'Received',
            isDone || isFailed ? DateFormat('hh:mm a').format(creationTime.add(const Duration(minutes: 2))) : 'Pending',
            isFailed ? Icons.error_rounded : Icons.check_circle_rounded,
            isCompleted: isDone || isFailed,
            activeColor: isFailed ? errorColor : successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStep(String title, String time, IconData icon, {bool isCompleted = false, Color activeColor = successColor}) {
    Color dotColor = const Color(0xFFE2E8F0);
    Color iconColor = const Color(0xFF94A3B8);
    
    if (isCompleted) {
      dotColor = activeColor;
      iconColor = Colors.white;
    }

    return Column(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: isCompleted ? [
              BoxShadow(
                color: activeColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Icon(
            icon,
            size: 14.sp,
            color: iconColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: isCompleted ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 8.sp,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLine({bool isCompleted = false, Color activeColor = successColor}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: 24.h), // Align with the icons
        child: Container(
          height: 2.h,
          decoration: BoxDecoration(
            color: isCompleted ? activeColor : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBreakdown(TransactionItem tx) {
    final serviceType = tx.serviceType?.toUpperCase() ?? '';
    final isUtility = serviceType == 'AIRTIME' || serviceType == 'DATA' || serviceType == 'CABLE' || serviceType == 'CABLE_TV' || serviceType == 'ELECTRICITY' || serviceType == 'ELECTRICITY_BILL';
    final showFee = tx.fee > 0 || !isUtility;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Breakdown',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        SizedBox(height: 16.h),
        _buildAmountRow('Transaction Amount', tx.amount),
        if (showFee) _buildAmountRow('Transaction Fee', tx.fee),
        Divider(height: 24, thickness: 1, color: lightBackground),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            Text(
              '₦${NumberFormat('#,##0.00').format(tx.amount + tx.fee)}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return Row(
      children: List.generate(20, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
        );
      }),
    );
  }

  Widget _buildAmountRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF999999),
            ),
          ),
          Text(
            '₦${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(TransactionItem tx, String status) {
    final serviceType = tx.serviceType?.toUpperCase() ?? '';
    final isTransfer = serviceType == 'TRANSFER';
    final isUtility = serviceType == 'AIRTIME' || serviceType == 'DATA' || serviceType == 'CABLE' || serviceType == 'CABLE_TV' || serviceType == 'ELECTRICITY' || serviceType == 'ELECTRICITY_BILL';
    
    final metadata = tx.metadata ?? {};
    final info = metadata['info'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        SizedBox(height: 16.h),
        
        // --- Dynamic Fields based on Service Type ---
        if (isTransfer) ...[
          if (tx.isBankTransfer) ...[
             _buildDetailRow('Recipient Name', metadata['recipientName'] ?? tx.receiverName ?? "N/A"),
             _buildDetailRow('Account Number', metadata['recipientAccount'] ?? "N/A"),
             _buildDetailRow('Bank Name', tx.provider ?? "External Bank"),
          ] else ...[
             _buildDetailRow(tx.isCredit ? 'Sender Name' : 'Recipient Name', tx.isCredit ? tx.senderName ?? "N/A" : tx.receiverName ?? "N/A"),
             if (!tx.isCredit && metadata['receiverPhone'] != null)
                _buildDetailRow('Recipient Phone', metadata['receiverPhone'].toString()),
             if (tx.isCredit && metadata['senderPhone'] != null)
                _buildDetailRow('Sender Phone', metadata['senderPhone'].toString()),
          ],
        ] else if (serviceType == 'CABLE' || serviceType == 'CABLE_TV') ...[
          if (info != null) ...[
             _buildDetailRow('Card Number', info['cardNumber'] ?? info['accountNumber'] ?? "N/A"),
             if (info['package'] != null) _buildDetailRow('Package', info['package']),
             _buildDetailRow('Provider', info['provider'] ?? tx.provider ?? "N/A"),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!),
          ]
        ] else if (serviceType == 'ELECTRICITY' || serviceType == 'ELECTRICITY_BILL') ...[
          if (info != null) ...[
             _buildDetailRow('Meter Number', info['meterNumber'] ?? info['accountNumber'] ?? "N/A"),
             if (info['token'] != null) _buildDetailRow('Token', info['token']),
             _buildDetailRow('Provider', info['provider'] ?? tx.provider ?? "N/A"),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!),
          ]
        ] else if (isUtility) ...[
          if (info != null) ...[
             _buildDetailRow('Beneficiary', info['phone'] ?? info['meterNumber'] ?? info['accountNumber'] ?? "N/A"),
             _buildDetailRow('Provider', info['network'] ?? tx.provider ?? "N/A"),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!),
          ]
        ] else ...[
          _buildDetailRow('Service', _getServiceTitle(tx)),
          if (tx.provider != null) _buildDetailRow('Provider', tx.provider!),
        ],

        _buildDetailRow('Transaction No.', tx.reference ?? "N/A"),
        _buildDetailRow('Payment Method', "Bia Wallet"),
        _buildDetailRow('Transaction Date', DateFormat('MMM dd, yyyy hh:mm a').format(tx.createdAt ?? DateTime.now())),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color bgColor, Color textColor, VoidCallback onTap, {bool hasBorder = false, bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: hasBorder ? Border.all(color: const Color(0xFFE0E0E0)) : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.h,
                  child: CustomLoader(size: 20, color: textColor),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  String _getServiceTitle(TransactionItem tx) {
    final List<String> serviceTypes = ['AIRTIME', 'DATA', 'CABLE', 'CABLE_TV', 'ELECTRICITY', 'ELECTRICITY_BILL', 'TOPUP'];
    final normalized = tx.serviceType?.toUpperCase();

    if (serviceTypes.contains(normalized)) {
      if (normalized == 'CABLE' || normalized == 'CABLE_TV') return 'Cable TV';
      if (normalized == 'TOPUP') return 'Top Up';
      if (normalized?.startsWith('ELECTRICITY') == true) return 'Electricity';
      return normalized![0] + normalized.substring(1).toLowerCase();
    }
    return normalized ?? "Transaction";
  }
}