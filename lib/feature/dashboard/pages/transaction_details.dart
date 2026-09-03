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
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../widgets/branded_receipt.dart';

class _Dims {
  final bool isTablet;
  const _Dims(this.isTablet);

  double get cardMaxWidth => isTablet ? 500.0 : double.infinity;
  double get padH => isTablet ? 20.0 : 20.w;
  double get padV => isTablet ? 16.0 : 16.h;
  double get cardPad => isTablet ? 24.0 : 24.w;
  double get cardRadius => isTablet ? 16.0 : 16.r;

  double get serviceTitleFont => isTablet ? 14.0 : 14.sp;
  double get amountFont => isTablet ? 30.0 : 28.sp;
  double get statusFont => isTablet ? 12.0 : 12.sp;
  double get sectionHeaderFont => isTablet ? 15.0 : 14.sp;
  double get rowLabelFont => isTablet ? 12.5 : 12.sp;
  double get rowValueFont => isTablet ? 12.5 : 12.sp;
  double get btnFont => isTablet ? 14.0 : 14.sp;
  double get btnHeight => isTablet ? 48.0 : 50.h;

  double get timelineCircle => isTablet ? 30.0 : 28.w;
  double get timelineIcon => isTablet ? 15.0 : 14.sp;
  double get timelineTitleFont => isTablet ? 10.5 : 10.sp;
  double get timelineTimeFont => isTablet ? 9.0 : 8.sp;
}

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
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final d = _Dims(isTablet);

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
        toolbarHeight: isTablet ? 50.0 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: const Color(0xFF2D2D2D), size: isTablet ? 16.0 : 18.sp),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: isTablet ? 17.0 : 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Hidden Receipt for capture
          Positioned(
            left: -5000,
            top: 0,
            child: SizedBox(
              width: 380,
              child: RepaintBoundary(
                key: _receiptKey,
                child: BrandedReceipt(transaction: transaction),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: d.cardMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: d.padH,
                    vertical: d.padV,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(d.cardPad),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(d.cardRadius),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _getServiceTitle(transaction),
                              style: TextStyle(
                                fontSize: d.serviceTitleFont,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₦${NumberFormat('#,##0.00').format(transaction.amount)}',
                                style: TextStyle(
                                  fontSize: d.amountFont,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 12.0 : 12.h),
                            _buildStatusBadge(status, statusColor, d),
                            SizedBox(height: isTablet ? 24.0 : 32.h),

                            if (transaction.isBankTransfer) ...[
                              _buildTimeline(transaction, status, statusColor, d),
                              SizedBox(height: isTablet ? 24.0 : 32.h),
                            ],

                            _buildAmountBreakdown(transaction, d),
                            SizedBox(height: isTablet ? 24.0 : 32.h),

                            _buildTransactionDetails(transaction, status, d),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 20.0 : 24.h),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Report Issue',
                              Colors.white,
                              const Color(0xFF2D2D2D),
                              () {},
                              d: d,
                              hasBorder: true,
                            ),
                          ),
                          SizedBox(width: isTablet ? 12.0 : 12.w),
                          Expanded(
                            child: _buildActionButton(
                              'Share Receipt',
                              primaryColor,
                              Colors.white,
                              _handleShare,
                              d: d,
                              isLoading: _isProcessing,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 24.0 : 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, _Dims d) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: d.isTablet ? 16.0 : 12.w,
        vertical: d.isTablet ? 6.0 : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: d.statusFont,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimeline(TransactionItem tx, String status, Color statusColor, _Dims d) {
    final creationTime = tx.createdAt ?? DateTime.now();
    final isDone = status == "SUCCESSFUL" || status == "SUCCESS";
    final isFailed = status == "FAILED";
    final isPending = status == "PENDING";

    return Padding(
      padding: EdgeInsets.symmetric(vertical: d.isTablet ? 12.0 : 16.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: d.isTablet ? 320.0 : 320.w,
          child: Row(
            children: [
              _buildHorizontalStep(
                'Sent',
                DateFormat('hh:mm a').format(creationTime),
                Icons.send_rounded,
                isCompleted: true,
                activeColor: successColor,
                d: d,
              ),
              _buildHorizontalLine(
                isCompleted: !isPending, 
                activeColor: isFailed ? errorColor : successColor,
                d: d,
              ),
              _buildHorizontalStep(
                'Processing',
                isPending ? 'Ongoing' : DateFormat('hh:mm a').format(creationTime),
                Icons.sync_rounded,
                isCompleted: !isPending,
                activeColor: isFailed ? errorColor : (isPending ? pendingColor : successColor),
                d: d,
              ),
              _buildHorizontalLine(
                isCompleted: isDone || isFailed, 
                activeColor: isFailed ? errorColor : successColor,
                d: d,
              ),
              _buildHorizontalStep(
                isFailed ? 'Failed' : 'Received',
                isDone || isFailed ? DateFormat('hh:mm a').format(creationTime.add(const Duration(minutes: 2))) : 'Pending',
                isFailed ? Icons.error_rounded : Icons.check_circle_rounded,
                isCompleted: isDone || isFailed,
                activeColor: isFailed ? errorColor : successColor,
                d: d,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalStep(
    String title,
    String time,
    IconData icon, {
    bool isCompleted = false,
    Color activeColor = successColor,
    required _Dims d,
  }) {
    Color dotColor = const Color(0xFFE2E8F0);
    Color iconColor = const Color(0xFF94A3B8);
    
    if (isCompleted) {
      dotColor = activeColor;
      iconColor = Colors.white;
    }

    return Column(
      children: [
        Container(
          width: d.timelineCircle,
          height: d.timelineCircle,
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
            size: d.timelineIcon,
            color: iconColor,
          ),
        ),
        SizedBox(height: d.isTablet ? 6.0 : 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: d.timelineTitleFont,
            fontWeight: FontWeight.w600,
            color: isCompleted ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: d.timelineTimeFont,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLine({
    bool isCompleted = false,
    Color activeColor = successColor,
    required _Dims d,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: d.isTablet ? 22.0 : 24.h),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: isCompleted ? activeColor : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBreakdown(TransactionItem tx, _Dims d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount Breakdown',
          style: TextStyle(
            fontSize: d.sectionHeaderFont,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        SizedBox(height: d.isTablet ? 14.0 : 16.h),
        _buildAmountRow('Transaction Amount', tx.amount, d),
        _buildAmountRow('Transaction Fee', tx.fee, d),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, _Dims d) {
    return Padding(
      padding: EdgeInsets.only(bottom: d.isTablet ? 12.0 : 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: d.rowLabelFont,
              color: const Color(0xFF999999),
            ),
          ),
          Text(
            '₦${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: d.rowValueFont,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(TransactionItem tx, String status, _Dims d) {
    final serviceType = tx.serviceType?.toUpperCase() ?? '';
    final isTransfer = serviceType == 'TRANSFER';
    final isUtility = serviceType == 'AIRTIME' || serviceType == 'DATA' || serviceType == 'CABLE' || serviceType == 'CABLE_TV' || serviceType == 'ELECTRICITY' || serviceType == 'ELECTRICITY_BILL';
    
    final metadata = tx.metadata ?? {};
    final info = metadata['info'] as Map?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: d.sectionHeaderFont,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        SizedBox(height: d.isTablet ? 14.0 : 16.h),
        
        // --- Dynamic Fields based on Service Type ---
        if (isTransfer) ...[
          if (tx.isBankTransfer) ...[
             _buildDetailRow('Recipient Name', metadata['recipientName'] ?? tx.receiverName ?? "N/A", d),
             _buildDetailRow('Account Number', metadata['recipientAccount'] ?? "N/A", d),
             _buildDetailRow('Bank Name', tx.provider ?? "External Bank", d),
          ] else ...[
             _buildDetailRow(tx.isCredit ? 'Sender Name' : 'Recipient Name', tx.isCredit ? tx.senderName ?? "N/A" : tx.receiverName ?? "N/A", d),
             if (!tx.isCredit && metadata['receiverPhone'] != null)
                _buildDetailRow('Recipient Phone', metadata['receiverPhone'].toString(), d),
             if (tx.isCredit && metadata['senderPhone'] != null)
                _buildDetailRow('Sender Phone', metadata['senderPhone'].toString(), d),
          ],
        ] else if (serviceType == 'CABLE' || serviceType == 'CABLE_TV') ...[
          if (info != null) ...[
             _buildDetailRow('Card Number', info['cardNumber'] ?? info['accountNumber'] ?? "N/A", d),
             if (info['package'] != null) _buildDetailRow('Package', info['package'], d),
             _buildDetailRow('Provider', info['provider'] ?? tx.provider ?? "N/A", d),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!, d),
          ]
        ] else if (serviceType == 'ELECTRICITY' || serviceType == 'ELECTRICITY_BILL') ...[
          if (info != null) ...[
             _buildDetailRow('Meter Number', info['meterNumber']?.toString() ?? info['accountNumber']?.toString() ?? "N/A", d),
             ...(() {
                final localName = Hive.isBoxOpen('authBox') ? Hive.box('authBox').get('fullname') : null;
                final cName = info['Customer_Name'] ?? info['customerName'] ?? info['customer_name'] ?? info['name'] ?? info['CustomerName'] ?? info['Customer_name'];
                final addr = info['Address'] ?? info['address'] ?? info['customerAddress'] ?? info['meterAddress'];
                return [
                  if (localName != null && localName.toString().trim().isNotEmpty)
                    _buildDetailRow('Account Name', localName.toString(), d),
                  if (cName != null && cName.toString().trim().isNotEmpty)
                    _buildDetailRow('Meter Name', cName.toString(), d),
                  if (addr != null && addr.toString().trim().isNotEmpty)
                    _buildDetailRow('Address', addr.toString(), d),
                ];
             })(),
             if (info['token'] != null && info['token'].toString().isNotEmpty) 
                _buildDetailRow('Token', info['token'].toString(), d, isCopyable: true),
             _buildDetailRow('Provider', info['provider']?.toString() ?? tx.provider ?? "N/A", d),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!, d),
          ]
        ] else if (isUtility) ...[
          if (info != null) ...[
             _buildDetailRow('Beneficiary', info['phone'] ?? info['meterNumber'] ?? info['accountNumber'] ?? "N/A", d),
             _buildDetailRow('Provider', info['network'] ?? tx.provider ?? "N/A", d),
          ] else ...[
             if (tx.provider != null) _buildDetailRow('Provider', tx.provider!, d),
          ]
        ] else ...[
          _buildDetailRow('Service', _getServiceTitle(tx), d),
          if (tx.provider != null) _buildDetailRow('Provider', tx.provider!, d),
        ],

        _buildDetailRow('Transaction No.', tx.reference ?? "N/A", d, isCopyable: true),
        _buildDetailRow('Transaction Date', DateFormat('MMM dd, yyyy hh:mm a').format(tx.createdAt ?? DateTime.now()), d),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, _Dims d, {bool isCopyable = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: d.isTablet ? 12.0 : 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: d.rowLabelFont,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          SizedBox(width: d.isTablet ? 12.0 : 8.w),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: d.rowValueFont,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                if (isCopyable) ...[
                  SizedBox(width: d.isTablet ? 6.0 : 6.w),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, size: d.isTablet ? 15.0 : 14.sp, color: primaryColor),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    required _Dims d,
    bool hasBorder = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: d.btnHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder ? Border.all(color: const Color(0xFFE0E0E0)) : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: d.isTablet ? 20.0 : 20.h,
                  width: d.isTablet ? 20.0 : 20.h,
                  child: CustomLoader(size: 20, color: textColor),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: d.btnFont,
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