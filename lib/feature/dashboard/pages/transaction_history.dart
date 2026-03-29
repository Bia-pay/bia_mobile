import 'package:bia/app/view/widget/app_bar.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import '../../../core/helper/helper.dart';
import '../dashboardcontroller/provider.dart';

class TransactionHistory extends ConsumerStatefulWidget {
  const TransactionHistory({super.key});

  @override
  ConsumerState<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends ConsumerState<TransactionHistory> {
  Future<void> _handleRefresh() async {
    await ref.read(allTransactionsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box('authBox');
    final fullname = box.get('fullname', defaultValue: 'User');

    final asyncTx = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: asyncTx.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (transactions) {
              if (transactions.isEmpty) {
                return ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 40.h,
                  ),
                  children: [
                    CustomHeader(title: 'Transaction History'),
                    SizedBox(height: 205.h),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt, size: 60, color: inactiveColor),
                          Text("No recent transactions"),
                          Text(
                            "Your activity will appear here",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: lightSecondaryText.withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.h),

                  ],
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                itemCount: transactions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        CustomHeader(title: 'Transaction History'),
                        SizedBox(height: 20.h),
                      ],
                    );
                  }

                  final tx = transactions[index - 1];

                  final isPending = tx.status == "PENDING";
                  final isCredit = tx.isCredit;

                  final amountColor = isPending
                      ? pendingColor
                      : isCredit
                      ? successColor
                      : errorColor;

                  final titleText = tx.serviceType == "TOPUP"
                      ? (tx.serviceType ?? "Top Up")
                      : (isCredit
                            ? (tx.senderName ?? (tx.provider ?? "Transfer"))
                            : (tx.receiverName ?? (tx.provider ?? "Transfer")));

                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// ICON
                        Container(
                          height: 40.w,
                          width: 40.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: amountColor.withOpacity(.08),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: amountColor,
                            size: 18.sp,
                          ),
                        ),

                        SizedBox(width: 10.w),

                        /// TITLE + DATE
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: darkBackground,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                formatTransactionDate(tx.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10.sp,
                                  color: lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// AMOUNT + STATUS
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isCredit ? '+' : '-'}₦${tx.amount}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                color: amountColor,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: amountColor.withOpacity(.08),
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                              child: Text(
                                tx.status ?? "",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 7.sp,
                                  color: amountColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
