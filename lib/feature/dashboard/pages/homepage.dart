import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboard_repo/repo.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../core/helper/helper.dart';
import '../dashboardcontroller/provider.dart';
import '../widgets/transaction.dart';
import '../dashboard_repo/repo.dart'; // or wherever you put recentTransactionsProvider

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    final box = Hive.box('authBox');
    final fullname = box.get('fullname', defaultValue: 'NGN');

    final recentTransactions = transactions.length > 3
        ? transactions.sublist(transactions.length - 3)
        : transactions;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recentTransactionsProvider.notifier).refresh();
        await ref.read(dashboardControllerProvider.notifier).refreshWalletBalance();
      },
      child: Scaffold(
        backgroundColor: themeContext.grayWhiteBg,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42.h,
                            width: 45.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: themeContext.kPrimary),
                            ),
                            child: Image.asset('assets/svg/logo-two.png'),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Hi, ${fullname}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 45.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: SvgPicture.asset('assets/svg/bell.svg'),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  /// 💳 Balance Card
                  const BalanceCard(),

                  SizedBox(height: 10.h),

                  /// ⚡ Actions Row
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 19.h,
                      horizontal: 5.w,
                    ),
                    decoration: BoxDecoration(
                      color: themeContext.offWhiteBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ActionButton(
                          label: 'Send TP',
                          icon: SvgPicture.asset('assets/svg/send.svg'),
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteList.sendMoneyTransfer,
                          ),
                        ),
                        ActionButton(
                          label: 'Bia Trike',
                          icon: Icon(
                            Icons.car_crash_sharp,
                            color: context.themeContext.kPrimary,
                          ),
                        ),
                        ActionButton(
                          label: 'Other Banks',
                          icon: Image.asset('assets/svg/atm.png', height: 23.h),
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteList.sendMoneyToBank,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10.h),

                  /// ⚙️ Quick Actions
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 20.h,
                      horizontal: 25.w,
                    ),
                    decoration: BoxDecoration(
                      color: themeContext.offWhiteBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        QuickActionButton(
                          label: 'Airtime',
                          icon: Icon(
                            Icons.bar_chart,
                            color: context.themeContext.kPrimary,
                          ),
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            RouteList.airtime,
                          ),
                        ),
                        QuickActionButton(
                          label: 'Data',
                          icon: Icon(
                            Icons.four_g_plus_mobiledata,
                            color: context.themeContext.kPrimary,
                          ),
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            RouteList.data,
                          ),
                        ),
                        QuickActionButton(
                          label: 'Cable TV',
                          icon: Icon(
                            Icons.tv,
                            color: context.themeContext.kPrimary,
                          ),
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            RouteList.cable,
                          ),
                        ),
                        QuickActionButton(
                          label: 'Utility Bill',
                          icon: Icon(
                            Icons.accessibility,
                            color: context.themeContext.kPrimary,
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteList.electricity,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Transaction History',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Consumer(
                  //   builder: (context, ref, _) {
                  //     final asyncData = ref.watch(recentTransactionsProvider);
                  //
                  //     return asyncData.when(
                  //       data: (response) {
                  //         if (!response.responseSuccessful || response.transactions.isEmpty) {
                  //           return Center(
                  //             child: Text(response.responseMessage.isNotEmpty
                  //                 ? response.responseMessage
                  //                 : "No recent transactions"),
                  //           );
                  //         }
                  //
                  //         return ListView.builder(
                  //           shrinkWrap: true,
                  //           physics: const NeverScrollableScrollPhysics(),
                  //           itemCount: response.transactions.length,
                  //           itemBuilder: (context, index) {
                  //             final tx = response.transactions[index];
                  //             return Container(
                  //               margin: EdgeInsets.only(bottom: 6.h),
                  //               decoration: BoxDecoration(
                  //                 color: themeContext.offWhiteBg,
                  //                 borderRadius: BorderRadius.circular(8.r),
                  //               ),
                  //               child: ListTile(
                  //                 leading: Icon(
                  //                   tx.isCredit == true ? Icons.call_received : Icons.call_made,
                  //                   color: tx.isCredit == true ? Colors.green : Colors.red,
                  //                 ),
                  //                 title: Text(tx.isCredit == true
                  //                     ? tx.senderName ?? 'Unknown'
                  //                     : tx.receiverName ?? 'Unknown',
                  //                   style: theme.textTheme.bodyMedium?.copyWith(
                  //                 fontWeight: FontWeight.w600,
                  //                 ),),
                  //                 subtitle: Text(tx.createdAt ?? '',
                  //                   style: theme.textTheme.bodySmall?.copyWith(
                  //                     fontWeight: FontWeight.w300,
                  //                   ),),
                  //                 trailing: Text("${tx.isCredit == true ? '+' : '-'}₦${tx.amount}",
                  //                   style: theme.textTheme.bodyLarge?.copyWith(
                  //                     fontWeight: FontWeight.w600,
                  //                     color: tx.isCredit == true ? Colors.green : Colors.red,
                  //                   ),),
                  //               ),
                  //             );
                  //           },
                  //         );
                  //       },
                  //       loading: () => const Center(child: CircularProgressIndicator()),
                  //       error: (err, _) => Center(child: Text("Error: ${err.toString()}")),
                  //     );
                  //   },
                  // ),
                  Consumer(
                    builder: (context, ref, _) {
                      final asyncTx = ref.watch(recentTransactionsProvider);
                      return asyncTx.when(
                        data: (transactions) {
                          if (transactions.isEmpty) {
                            return const Center(
                              child: Text("No recent transactions"),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 6.h),
                                decoration: BoxDecoration(
                                  color: themeContext.offWhiteBg,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    tx.isCredit == true
                                        ? Icons.call_received
                                        : Icons.call_made,
                                    color: tx.isCredit == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  title: Text(
                                    tx.isCredit == true
                                        ? tx.senderName ?? 'Unknown'
                                        : tx.receiverName ?? 'Unknown',
                                  ),
                                  subtitle: Text(
                                    formatTransactionDate(tx.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${tx.isCredit == true ? '+' : '-'}₦${tx.amount}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tx.isCredit == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Error: $e")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeContext = context.themeContext;
    final theme = Theme.of(context);

    // 🔹 Listen to the wallet balance from DashboardController
    final walletState = ref.watch(dashboardControllerProvider);

    // Extract wallet info safely
    final wallet = walletState.when(
      data: (responseBody) => responseBody?.wallet,
      loading: () => null,
      error: (_, __) => null,
    );

    // Get balance from wallet or fallback to Hive
    final balance = wallet?.balance?.toString() ??
        Hive.box('authBox').get('balance', defaultValue: '0').toString();

    // Format balance with commas
    final formattedBalance = balance.isEmpty
        ? '0'
        : balance.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
      decoration: BoxDecoration(
        color: themeContext.kPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 💰 Balance Texts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${Constants.nairaCurrencySymbol}$formattedBalance',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),

          /// ➕ Add Money Button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, RouteList.topUp),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: themeContext.tertiaryBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/svg/plus.png', height: 15.h),
                  SizedBox(width: 6.w),
                  Text(
                    'Add money',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.themeContext.kPrimary,
                      fontWeight: FontWeight.w600,
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
}
/// 🔹 Extracted Action Button Widget
class ActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: context.themeContext.kSecondary,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.themeContext.secondaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Extracted Quick Action Widget
class QuickActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: context.themeContext.kSecondary,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.themeContext.secondaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
