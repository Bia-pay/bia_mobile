import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:hive/hive.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../app/utils/custom_button.dart';
import '../../../app/utils/image.dart';
import '../../../app/utils/widgets/pin_field.dart';
import '../../../core/helper/helper.dart';
import '../../auth/authrepo/repo.dart';
import '../dashboardcontroller/provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  Future<void> _handleRefresh() async {
    final txFuture = ref.read(recentTransactionsProvider.notifier).refresh();
    final walletFuture = ref.read(dashboardControllerProvider.notifier)
        .refreshWalletBalance();

    await Future.wait([txFuture, walletFuture]);
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
                          border: Border.all(color: primaryColor),
                        ),
                        child: Image.asset(appLogoPng),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Hello, $fullname',
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
                    child: SvgPicture.asset(bell),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // BALANCE CARD
              const BalanceCard(),

              SizedBox(height: 10.h),

              // QUICK SEND ROW
              Container(
                padding: EdgeInsets.symmetric(vertical: 19.h, horizontal: 5.w),
                decoration: BoxDecoration(
                  color: offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionButton(
                      label: 'Send TP',
                      icon: SvgPicture.asset(send),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteList.sendMoneyTransfer,
                      ),
                    ),
                    ActionButton(
                      label: 'Bia Trike',
                      icon: Icon(Icons.car_crash_sharp, color: primaryColor),
                    ),
                    ActionButton(
                      label: 'Other Banks',
                      icon: Image.asset(atm, height: 23.h),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteList.sendMoneyToBank,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // QUICK ACTION TITLE
              Text(
                'Quick Actions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 8.h),

              // QUICK ACTION BUTTONS
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 25.w),
                decoration: BoxDecoration(
                  color: offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    QuickActionButton(
                      label: 'Airtime',
                      icon: Icon(Icons.bar_chart, color: primaryColor),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        RouteList.airtime,
                      ),
                    ),
                    QuickActionButton(
                      label: 'Data',
                      icon: Icon(Icons.four_g_plus_mobiledata, color: primaryColor),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        RouteList.data,
                      ),
                    ),
                    QuickActionButton(
                      label: 'Cable TV',
                      icon: Icon(Icons.tv, color: primaryColor),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        RouteList.cable,
                      ),
                    ),
                    QuickActionButton(
                      label: 'Utility Bill',
                      icon: Icon(Icons.accessibility, color: primaryColor),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteList.electricity,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10.h),

              // TRANSACTION HISTORY TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteList.transactionHistory,
                    ),
                    child: Text(
                      'View all',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 10.sp,
                        color: lightSecondaryText,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),
              Consumer(
                builder: (context, ref, _) {
                  final asyncTx = ref.watch(recentTransactionsProvider);

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
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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
        color: primaryColor,
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
                color: whiteBackground,
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
                      color: primaryColor,
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
             color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
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
             color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetPinSheet extends ConsumerStatefulWidget {
  const _SetPinSheet({super.key});

  @override
  ConsumerState<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends ConsumerState<_SetPinSheet> {
  final pinController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Set Your Transaction PIN",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          AppPinCodeField(
            controller: pinController,
            length: 4,
            activeColor: primaryColor,
            selectedColor: primaryColor,
            fillColor: keyAColor,
          ),
          SizedBox(height: 25),
          CustomButton(
            buttonName: isLoading ? "Saving..." : "Save PIN",
            buttonColor: primaryColor,
            buttonTextColor: Colors.white,
            onPressed: isLoading ? null : () async {
              final pin = pinController.text.trim();

              if (pin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN must be 4 digits")),
                );
                return;
              }

              setState(() => isLoading = true);

              final authRepo = ref.read(authRepositoryProvider);
              final res = await authRepo.setPin(pin, pin); // call backend

              setState(() => isLoading = false);

              if (!res.responseSuccessful) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.responseMessage)),
                );
                return;
              }

              // ✅ Save locally
              final box = Hive.box('authBox');
              await box.put('saved_pin', pin);
              await box.put('has_pin', true);

              Navigator.pop(context); // close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PIN set successfully")),
              );
            },
          ),
        ],
      ),
    );
  }
}