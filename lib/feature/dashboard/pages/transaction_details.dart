import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // Main Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Transaction Type & Amount
                  Text(
                    transaction.type,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '₦${NumberFormat('#,##0').format(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildStatusBadge(transaction.status),
                  SizedBox(height: 24.h),

                  // Timeline
                  _buildTimeline(transaction),
                  SizedBox(height: 24.h),

                  // Amount Breakdown
                  _buildAmountBreakdown(transaction),
                  SizedBox(height: 20.h),
                  const Divider(color: Color(0xFFEEEEEE)),
                  SizedBox(height: 20.h),

                  // Transaction Details
                  _buildTransactionDetails(transaction),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Report issue',
                    const Color(0xFFE8D5F7),
                    const Color(0xFF7B4FA2),
                        () {},
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    'Share receipt',
                    const Color(0xFF6B4EE6),
                    Colors.white,
                        () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    final colors = {
      TransactionStatus.successful: const Color(0xFF4CAF50),
      TransactionStatus.failed: const Color(0xFFE53935),
      TransactionStatus.pending: const Color(0xFFFF9800),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors[status]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.name.capitalize(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: colors[status],
        ),
      ),
    );
  }

  Widget _buildTimeline(Transaction transaction) {
    final steps = _getTimelineSteps(transaction);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? const Color(0xFF4CAF50)
                        : step.isFailed
                        ? const Color(0xFFE53935)
                        : const Color(0xFFE0E0E0),
                    border: Border.all(
                      color: step.isCompleted || step.isFailed
                          ? Colors.transparent
                          : const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                  ),
                  child: step.isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                      : step.isFailed
                      ? Icon(Icons.close, color: Colors.white, size: 14.sp)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2.w,
                    height: 40.h,
                    color: step.isCompleted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE0E0E0),
                  ),
              ],
            ),
            SizedBox(width: 12.w),

            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    step.time,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<TimelineStep> _getTimelineSteps(Transaction transaction) {
    final dateFormat = DateFormat('MM-dd HH:mm:ss');

    switch (transaction.status) {
      case TransactionStatus.successful:
        return [
          TimelineStep(
            title: '${transaction.type} is being processed',
            time: dateFormat.format(transaction.createdAt),
            isCompleted: true,
          ),
          TimelineStep(
            title: '${transaction.type} processing',
            time: dateFormat.format(transaction.createdAt.add(const Duration(minutes: 1))),
            isCompleted: true,
          ),
          TimelineStep(
            title: '${transaction.type} successful',
            time: dateFormat.format(transaction.completedAt!),
            isCompleted: true,
          ),
        ];
      case TransactionStatus.failed:
        return [
          TimelineStep(
            title: '${transaction.type} is being processed',
            time: dateFormat.format(transaction.createdAt),
            isCompleted: true,
          ),
          TimelineStep(
            title: '${transaction.type} processing',
            time: dateFormat.format(transaction.createdAt.add(const Duration(minutes: 1))),
            isCompleted: true,
          ),
          TimelineStep(
            title: '${transaction.type} failed',
            time: dateFormat.format(transaction.failedAt!),
            isFailed: true,
          ),
        ];
      case TransactionStatus.pending:
        return [
          TimelineStep(
            title: '${transaction.type} is being processed',
            time: dateFormat.format(transaction.createdAt),
            isCompleted: true,
          ),
          TimelineStep(
            title: '${transaction.type} processing',
            time: dateFormat.format(transaction.createdAt.add(const Duration(minutes: 1))),
            isCompleted: false,
          ),
        ];
    }
  }

  Widget _buildAmountBreakdown(Transaction transaction) {
    return Column(
      children: [
        _buildAmountRow('Amount', '₦${NumberFormat('#,##0').format(transaction.amount)}'),
        SizedBox(height: 12.h),
        _buildAmountRow('Fee', '₦${NumberFormat('#,##0').format(transaction.fee)}'),
        SizedBox(height: 12.h),
        _buildAmountRow('Amount Paid', '₦${NumberFormat('#,##0').format(transaction.amountPaid)}', isBold: true),
      ],
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(Transaction transaction) {
    final details = [
      _DetailItem('Bank', transaction.bankName),
      _DetailItem('Account Name', transaction.accountName),
      _DetailItem('Transaction No.', transaction.transactionNumber),
      _DetailItem('Payment Method', transaction.paymentMethod),
      _DetailItem('Transaction Date', DateFormat('MMM dd,yyyy,HH:mm:ss').format(transaction.createdAt)),
      _DetailItem('Session ID', transaction.sessionId),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        SizedBox(height: 16.h),
        ...details.map((detail) => _buildDetailRow(detail.label, detail.value)),
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

  Widget _buildActionButton(
      String text,
      Color backgroundColor,
      Color textColor,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
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
}

// Data Models
enum TransactionStatus { successful, failed, pending }

class Transaction {
  final String type; // "Coin Withdrawal", "Coin Deposited", etc.
  final double amount;
  final double fee;
  final double amountPaid;
  final TransactionStatus status;
  final String bankName;
  final String accountName;
  final String transactionNumber;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final String sessionId;

  Transaction({
    required this.type,
    required this.amount,
    required this.fee,
    required this.amountPaid,
    required this.status,
    required this.bankName,
    required this.accountName,
    required this.transactionNumber,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    required this.sessionId,
  });
}

class TimelineStep {
  final String title;
  final String time;
  final bool isCompleted;
  final bool isFailed;

  TimelineStep({
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem(this.label, this.value);
}

// Extension for capitalize
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}