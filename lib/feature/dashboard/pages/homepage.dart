import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool showMore = false;
  Future<void> _handleRefresh() async {
    final txFuture = ref.read(recentTransactionsProvider.notifier).refresh();
    final walletFuture = ref.read(dashboardControllerProvider.notifier)
        .refreshWalletBalance();

    await Future.wait([txFuture, walletFuture]);
  }
  List<Map<String, dynamic>> _quickActions(BuildContext context) => [
    {
      'label': 'Airtime',
      'icon': Icon(Icons.bar_chart, color: primaryColor),
      'onTap': () => context.pushReplacementNamed(RouteList.airtime),
    },
    {
      'label': 'Data',
      'icon': Icon(Icons.four_g_plus_mobiledata, color: primaryColor),
      'onTap': () => context.pushReplacementNamed(RouteList.data),
    },
    {
      'label': 'Cable TV',
      'icon': Icon(Icons.tv, color: primaryColor),
      'onTap': () => context.pushReplacementNamed(RouteList.cable),
    },
    {
      'label': 'Tiktok Coin',
      'icon': Image.asset(tiktok, height: 23.h),
      'onTap': () => context.pushNamed(RouteList.electricity),
    },
    {
      'label': 'Utility Bill',
      'icon': Icon(Icons.electrical_services, color: primaryColor),
      'onTap': () => context.pushNamed(RouteList.electricity),
    },
    {
      'label': 'Internet',
      'icon': Icon(Icons.wifi, color: primaryColor),
      'onTap': () {},
    },
  ];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _checkPinStatus();
      });
    });
  }
  Future<void> _checkPinStatus() async {
    final box = Hive.box('authBox');
    final hasPin = box.get('has_pin', defaultValue: false);

    if (!hasPin) {
      // Show bottom sheet for PIN
      //Navigator.pushNamed(context, RouteList.setTransactionPin);
      context.go( RouteList.setTransactionPin);

    }
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
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 1.h),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40.h,
                        width: 45.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Image.asset(appLogoPng),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: lightSecondaryText,
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            fullname,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: lightText,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
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
              BalanceCard(),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, ),
                decoration: BoxDecoration(
                  color: offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionButton(
                      label: 'Send TP      ',
                      icon: SvgPicture.asset(send),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteList.sendMoneyTransfer,
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ActionButton(
                          label: 'Bia Trike',
                          icon: Icon(Icons.car_crash_sharp, color: primaryColor),
                          onTap: () {
                            // Optional: show a SnackBar
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bia Trike coming soon!')),
                            );
                          },
                        ),
                        Positioned(
                          top: -5.h,
                          right: -20.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: primaryGreenColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 6.sp,
                                color: whiteBackground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ActionButton(
                      label: 'Other Banks',
                      icon: Image.asset(atm, height: 21.h),
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteList.sendMoneyToBank,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Quick Actions',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
                decoration: BoxDecoration(
                  color: offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // FIRST ROW (exactly 4 items)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(mic,height: 50.h,
                          color: primaryColor,
                        ), SvgPicture.asset(chatting,height: 50.h,
                          color: primaryColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bia AI',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: primaryColor,

                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteList.transactionHistory,
                          ),
                          child:Icon(Icons.arrow_forward_ios_sharp,size: 12.sp, color: primaryColor ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              Container(
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.w),
                decoration: BoxDecoration(
                  color: offWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // FIRST ROW (exactly 4 items)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _quickActions(context)
                          .take(4)
                          .map((item) => QuickActionButton(
                        label: item['label'],
                        icon: item['icon'],
                        onTap: item['onTap'],
                      ))
                          .toList(),
                    ),

                    SizedBox(height: 5.h),

                    // SECOND ROW (only visible if showMore)
                    if (showMore)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _quickActions(context)
                            .skip(4)
                            .map((item) => QuickActionButton(
                          label: item['label'],
                          icon: item['icon'],
                          onTap: item['onTap'],
                        ))
                            .toList(),
                      ),


                    // MORE / LESS TOGGLE
                    GestureDetector(
                      onTap: () => setState(() => showMore = !showMore),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showMore ? "Less" : "More",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          Icon(
                            showMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
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
              SizedBox(height: 8.h),
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
                              ? (tx.serviceType ?? "Top Up")
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
                                  color: tx.status == "PENDING"
                                      ? pendingColor.withOpacity(0.1)
                                      : tx.isCredit
                                      ? successColor.withOpacity(0.1)
                                      : errorColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tx.isCredit ? Icons.call_received : Icons.call_made,
                                  color: tx.status == "PENDING"
                                      ? pendingColor
                                      : tx.isCredit
                                      ? successColor
                                      : errorColor,
                                  size: 20.sp,
                                ),
                              ),
                              title: Text(
                                titleText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                  color: tx.status == "PENDING"
                                      ? pendingColor
                                      : lightSecondaryText,
                                ),
                              ),
                              subtitle: Text(
                                formatTransactionDate(tx.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 10.sp,
                                  color: lightSecondaryText,
                                ),
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${tx.isCredit ? '+' : '-'}₦${tx.amount}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                      color: tx.status == "PENDING"
                                          ? pendingColor
                                          : tx.isCredit
                                          ? successTextColor
                                          : errorColor,
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  /// BADGE
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: tx.status == "PENDING"
                                          ? pendingColor.withOpacity(0.1)
                                          : tx.isCredit
                                          ? successColor.withOpacity(0.1)
                                          : errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      tx.status ?? "",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 8.sp,
                                        color: tx.status == "PENDING"
                                            ? pendingColor
                                            : tx.isCredit
                                            ? successTextColor
                                            : errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
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

    // Wallet visibility state
    final isVisible = ref.watch(balanceVisibilityProvider);

    // Wallet balance from controller
    final walletState = ref.watch(dashboardControllerProvider);

    final wallet = walletState.when(
      data: (responseBody) => responseBody?.wallet,
      loading: () => null,
      error: (_, __) => null,
    );

    final balance = wallet?.balance?.toString() ??
        Hive.box('authBox').get('balance', defaultValue: '0').toString();

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
          /// Left side: Label + Balance + Eye Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Available Balance',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),

                  /// 👁 Visibility Toggle
                  GestureDetector(
                    onTap: () {
                      ref.read(balanceVisibilityProvider.notifier).state =
                      !isVisible;
                    },
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              SizedBox(height: 4.h),

              /// Balance display
              Text(
                isVisible
                    ? '${Constants.nairaCurrencySymbol}$formattedBalance'
                    : '******',
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
            onTap: () => context.pushNamed(RouteList.topUp),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 11.w),
            decoration: BoxDecoration(
             color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
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
            padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 9.w),
            decoration: BoxDecoration(
             color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
            ),
            child: icon,
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class SetPinSheet extends ConsumerStatefulWidget {
  const SetPinSheet({super.key});

  @override
  ConsumerState<SetPinSheet> createState() => SetPinSheetState();
}

class SetPinSheetState extends ConsumerState<SetPinSheet> {
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