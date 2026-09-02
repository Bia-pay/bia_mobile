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
    final status = tx.status?.toUpperCase();
    final isPending = status == 'PENDING';
    final isFailed = status == 'FAILED';
    final isCredit = tx.isCredit;

    final Color displayColor = isPending
        ? pendingColor
        : isFailed
            ? errorColor
            : successColor; // Green for success (both credit & debit)

    final Color statusLabelColor = isPending
        ? pendingColor
        : isFailed
            ? errorColor
            : isCredit
                ? successColor // Credits stay Green
                : errorColor;  // Debits stay Red to show difference

    final List<String> serviceTitles = ['AIRTIME', 'DATA', 'CABLE', 'CABLE_TV', 'ELECTRICITY', 'ELECTRICITY_BILL', 'TOPUP'];
    final normalizedService = tx.serviceType?.toUpperCase();

    final String titleText = serviceTitles.contains(normalizedService)
        ? (normalizedService == 'CABLE' || normalizedService == 'CABLE_TV' ? 'Cable TV' : 
           normalizedService == 'TOPUP' ? 'Top Up' : 
           (normalizedService?.startsWith('ELECTRICITY') == true) ? 'Electricity' :
           normalizedService![0] + normalizedService.substring(1).toLowerCase())
        : isCredit
            ? (tx.senderName ?? tx.provider ?? 'Transfer')
            : (tx.receiverName ?? tx.provider ?? 'Transfer');

    final String statusLabel = tx.status ?? '';
    final String amountLabel =
        '${isCredit ? '+' : '-'}₦${NumberFormat('#,##0.00').format(tx.amount)}';

    final IconData iconData = _iconForType(tx.serviceType, isCredit);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(
          vertical: 9.h,
          horizontal: 12.w,
        ),
        decoration: BoxDecoration(
          color: lightBackground,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 38.w,
              width: 38.w,
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                iconData,
                color: displayColor,
                size: 17.sp,
              ),
            ),

            SizedBox(width: 10.w),

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
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    formatTransactionDate(tx.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: displayColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusLabelColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: statusLabelColor,
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
