import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../model/recent_transaction.dart';
import 'package:bia/app/utils/colors.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionItem transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction.status?.toUpperCase() ?? "SUCCESSFUL";
    final isCredit = transaction.isCredit;

    // Exact color codes matching Transaction History for perfect alignment
    final Color statusColor = status == "PENDING"
        ? const Color(0xFFFACC15) // History Yellow
        : isCredit
            ? const Color(0xFF22C55E) // History Green
            : const Color(0xFFEF4444); // History Red

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF2D2D2D)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              // Main Card
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

                    _buildTimeline(transaction, status, statusColor),
                    SizedBox(height: 32.h),

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
                      () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
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
    final isDone = status == "SUCCESSFUL";
    final isFailed = status == "FAILED";
    final isPending = status == "PENDING";

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          _buildHorizontalStep(
            'Initiated',
            DateFormat('HH:mm').format(creationTime),
            isCompleted: true,
            activeColor: const Color(0xFF22C55E),
          ),
          _buildHorizontalLine(
            isCompleted: isDone || isFailed, 
            activeColor: statusColor
          ),
          _buildHorizontalStep(
            isDone ? 'Success' : (isFailed ? 'Failed' : (isPending ? 'Pending' : 'Processing')),
            DateFormat('HH:mm').format(creationTime),
            isCompleted: isDone || isFailed || isPending,
            activeColor: statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStep(String title, String time, {bool isCompleted = false, Color activeColor = successColor}) {
    Color dotColor = const Color(0xFFE0E0E0);
    if (isCompleted) dotColor = activeColor;

    return Column(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: isCompleted ? const Color(0xFF2D2D2D) : const Color(0xFF999999),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 9.sp,
            color: const Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLine({bool isCompleted = false, Color activeColor = successColor}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: 24.h), // Align with the dots
        child: Container(
          height: 2.h,
          color: isCompleted ? activeColor : const Color(0xFFE0E0E0),
        ),
      ),
    );
  }

  Widget _buildAmountBreakdown(TransactionItem tx) {
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
        _buildAmountRow('Transaction Fee', 0.00), // Original had fixed layout
        const Divider(height: 24, thickness: 1, color: Color(0xFFF5F5F5)),
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
              '₦${NumberFormat('#,##0.00').format(tx.amount)}',
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
    String accountName = tx.isCredit 
        ? (tx.senderName ?? "External Account")
        : (tx.receiverName ?? "External Account");
        
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
        _buildDetailRow('Bank/Provider', tx.provider ?? "Bia Wallet"),
        _buildDetailRow('Account Name', accountName),
        _buildDetailRow('Transaction No.', tx.transactionId ?? "N/A"),
        _buildDetailRow('Payment Method', "Bia Wallet"),
        _buildDetailRow('Transaction Date', DateFormat('MMM dd, yyyy HH:mm').format(tx.createdAt ?? DateTime.now())),
        _buildDetailRow('Status', status),
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

  Widget _buildActionButton(String text, Color bgColor, Color textColor, VoidCallback onTap, {bool hasBorder = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: hasBorder ? Border.all(color: const Color(0xFFE0E0E0)) : null,
        ),
        child: Center(
          child: Text(
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
    final List<String> serviceTypes = ['AIRTIME', 'DATA', 'CABLE', 'ELECTRICITY', 'TOPUP'];
    final normalized = tx.serviceType?.toUpperCase();

    if (serviceTypes.contains(normalized)) {
      if (normalized == 'CABLE') return 'Cable TV';
      if (normalized == 'TOPUP') return 'Top Up';
      return normalized![0] + normalized.substring(1).toLowerCase();
    }
    return normalized ?? "Transaction";
  }
}