import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bia/app/utils/colors.dart';
import '../model/recent_transaction.dart';
import '../../../core/helper/helper.dart';
import 'package:intl/intl.dart';

/// A clean, modern transaction list tile used across
/// the Home page and the Transaction History page.
class TransactionTile extends StatelessWidget {
  final TransactionItem tx;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final status = tx.status?.toUpperCase();
    final isPending = status == 'PENDING';
    final isFailed = status == 'FAILED';
    final isCredit = tx.isCredit;

    final Color statusColor = isPending
        ? pendingColor
        : isFailed
            ? errorColor
            : successColor; // Green for SUCCESS / SUCCESSFUL

    final Color amountColor = isPending
        ? pendingColor
        : isFailed
            ? errorColor
            : isCredit
                ? successColor // Green for Credit
                : const Color(0xFF1E293B); // Dark Slate for Debit

    final List<String> serviceTitles = [
      'AIRTIME',
      'DATA',
      'CABLE',
      'CABLE_TV',
      'ELECTRICITY',
      'ELECTRICITY_BILL',
      'TOPUP'
    ];
    final normalizedService = tx.serviceType?.toUpperCase();

    final String titleText = serviceTitles.contains(normalizedService)
        ? (normalizedService == 'CABLE' || normalizedService == 'CABLE_TV'
            ? 'Cable TV'
            : normalizedService == 'TOPUP'
                ? 'Top Up'
                : (normalizedService?.startsWith('ELECTRICITY') == true)
                    ? 'Electricity'
                    : normalizedService![0] + normalizedService.substring(1).toLowerCase())
        : isCredit
            ? (tx.senderName ?? tx.provider ?? 'Transfer')
            : (tx.receiverName ?? tx.provider ?? 'Transfer');

    final String statusLabel = tx.status ?? '';
    final String amountLabel =
        '${isCredit ? '+' : '-'}₦${NumberFormat('#,##0.00').format(tx.amount)}';

    final IconData iconData = _iconForType(tx.serviceType, isCredit);

    final double iconBoxSize = isTablet ? 42.0 : 38.w;
    final double iconSize = isTablet ? 20.0 : 17.sp;
    final double titleFontSize = isTablet ? 15.0 : 12.sp;
    final double dateFontSize = isTablet ? 11.5 : 9.5.sp;
    final double amountFontSize = isTablet ? 15.0 : 12.sp;
    final double statusFontSize = isTablet ? 10.0 : 8.sp;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 10.0 : 8.h),
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12.0 : 9.h,
          horizontal: isTablet ? 16.0 : 12.w,
        ),
        decoration: BoxDecoration(
          color: lightBackground,
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 14.r),
          border: Border.all(color: Colors.grey.shade100, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: iconBoxSize,
              width: iconBoxSize,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.r),
              ),
              child: Icon(
                iconData,
                color: statusColor,
                size: iconSize,
              ),
            ),

            SizedBox(width: isTablet ? 14.0 : 10.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: isTablet ? 3.0 : 2.h),
                  Text(
                    formatTransactionDate(tx.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: dateFontSize,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: isTablet ? 12.0 : 8.w),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: amountFontSize,
                    color: amountColor,
                  ),
                ),
                SizedBox(height: isTablet ? 4.0 : 3.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 8.0 : 6.w,
                    vertical: isTablet ? 2.5 : 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: statusFontSize,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String? serviceType, bool isCredit) {
    switch (serviceType?.toUpperCase()) {
      case 'TOPUP':
        return Icons.account_balance_wallet_rounded;
      case 'AIRTIME':
        return Icons.phone_android_rounded;
      case 'DATA':
        return Icons.wifi_rounded;
      case 'CABLE':
      case 'CABLE_TV':
        return Icons.live_tv_rounded;
      case 'ELECTRICITY':
      case 'ELECTRICITY_BILL':
        return Icons.bolt_rounded;
      default:
        return isCredit
            ? Icons.south_east_rounded
            : Icons.north_west_rounded;
    }
  }
}
