import 'package:bia/app/view/widget/app_bar.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
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
    final txFuture = ref.read(allTransactionsProvider.notifier).refresh();


    await Future.wait([txFuture,]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box('authBox');
    final fullname = box.get('fullname', defaultValue: 'User');

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Scaffold(
        backgroundColor: offWhiteBackground,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            children: [
              // TOP SECTION: WELCOME + ICON
              CustomHeader(title: 'Transaction History'),

              SizedBox(height: 20.h),

              // TRANSACTIONS LIST
              Consumer(
                builder: (context, ref, _) {
                  final asyncTx = ref.watch(allTransactionsProvider);

                  return asyncTx.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const Center(child: Text("No recent transactions"));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];

                          final titleText = tx.serviceType == "TOPUP"
                              ? (tx.provider ?? "Top Up")
                              : (tx.isCredit
                              ? (tx.senderName ?? "Unknown")
                              : (tx.receiverName ?? "Unknown"));

                          return Container(
                            margin: EdgeInsets.only(bottom: 6.h),
                            decoration: BoxDecoration(
                              color: offWhite,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                    color: tx.isCredit ? successColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                                    shape: BoxShape.circle
                                ),
                                child: Icon(
                                  tx.isCredit ? Icons.call_received : Icons.call_made,
                                  color: tx.isCredit ? successColor : errorColor,
                                ),
                              ),
                              title: Text(titleText),
                              subtitle: Text(
                                formatTransactionDate(tx.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              trailing: Text(
                                "${tx.isCredit ? '+' : '-'}₦${tx.amount}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tx.isCredit ? successColor : errorColor,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}