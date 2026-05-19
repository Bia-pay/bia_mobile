import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/provider.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../app/utils/image.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/view/widget/dashboard_header.dart';
import '../../../core/helper/helper.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {


  Future<void> _handleRefresh() async {
    final userId = ref.read(userIdProvider);

    final txFuture = ref
        .read(recentTransactionsProvider(userId).notifier)
        .refresh();
    final walletFuture = ref
        .read(dashboardControllerProvider.notifier)
        .refreshWalletBalance();

    await Future.wait([txFuture, walletFuture]);
  }



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

    if (hasPin != true) {
      if (!mounted) return;
      context.go(RouteList.setTransactionPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box('authBox');
    final fullname = box.get('fullname', defaultValue: 'User');
    final picture = box.get('picture');
    
    // 🔥 Fluid spacing using consistent ScreenUtil values
    final headerSpacing = 8.h; 
    final sectionSpacing = 12.h;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              picture: picture,
              fullname: fullname,
              theme: theme,
              primaryColor: primaryColor,
              lightSecondaryText: lightSecondaryText,
              lightText: lightText,
              appLogoPng: appLogoPng,
              bell: bell,
              notificationRoute: RouteList.notification,
              profileRoute: RouteList.userSettings,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: headerSpacing),

                            const BalanceCard(),
                            SizedBox(height: sectionSpacing),

                            const ActionRibbon(),
                            SizedBox(height: 12.h),

                            Text(
                              'Quick Actions',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),

                            const BiaAiCard(),
                            SizedBox(height: sectionSpacing),

                            const QuickActionsGrid(),
                            SizedBox(height: sectionSpacing),

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
                                  onTap: () => context.pushNamed(RouteList.transactionHistory),
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

                            const RecentTransactionsList(),

                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class ActionRibbon extends StatelessWidget {
  const ActionRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionButton(
            label: 'Send TP',
            icon: SvgPicture.asset(send, height: 22.h),
            onTap: () => context.pushNamed(RouteList.sendMoneyTransfer),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ActionButton(
                label: 'Bia Trike',
                icon: Icon(Icons.car_crash_sharp, color: primaryColor, size: 22.sp),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bia Trike coming soon!')),
                  );
                },
              ),
              Positioned(
                top: -5.h,
                right: -20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
            label: 'Withdrawal',
            icon: Image.asset(atm, height: 22.h),
            onTap: () => context.pushNamed(RouteList.sendMoneyToBank),
          ),
        ],
      ),
    );
  }
}

class BiaAiCard extends ConsumerWidget {
  const BiaAiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 20.h,
        horizontal: 15.w,
      ),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: () async {
          final box = await Hive.openBox('appPrefs');
          final hasSelectedLang = box.get('biaAiLanguageSelected', defaultValue: false) as bool;
          if (!context.mounted) return;
          if (!hasSelectedLang) {
            context.pushNamed(RouteList.biaLanguageOnboarding);
          } else {
            context.pushNamed(RouteList.aiChat);
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  mic,
                  height: 50.h,
                  color: primaryColor,
                ),
                SvgPicture.asset(
                  chatting,
                  height: 50.h,
                  color: primaryColor,
                ),
              ],
            ),
            SizedBox(height: 6.h),
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
                Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: 13.sp,
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final asyncTx = ref.watch(recentTransactionsProvider(userId));

    return SizedBox(
      width: double.infinity,
      child: asyncTx.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt, size: 60, color: inactiveColor),
                  Text("No recent transactions"),
                ],
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: transactions.length > 2 ? 2 : transactions.length,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return TransactionTile(
                tx: tx,
                onTap: () => context.pushNamed(
                  RouteList.transactionDetailsScreen,
                  extra: tx,
                ),
              );
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}


class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isVisible = ref.watch(balanceVisibilityProvider);
    final walletState = ref.watch(dashboardControllerProvider);

    final wallet = walletState.when(
      data: (responseBody) => responseBody?.wallet,
      loading: () => null,
      error: (_, __) => null,
    );

    final rawBalance = wallet?.balance ?? Hive.box('authBox').get('balance');
    final balance = (rawBalance == null || rawBalance.toString() == 'null')
        ? '0'
        : rawBalance.toString();
    final formattedBalance = balance.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 15.h,
        horizontal: 15.w,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  ),
                ],
              ),
              SizedBox(height: 5.h),
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
          GestureDetector(
            onTap: () => context.pushNamed(RouteList.topUp),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: whiteBackground,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/svg/plus.png', height: 16.h),
                  SizedBox(width: 6.w),
                  Text(
                    'Add money',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
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
            padding: EdgeInsets.symmetric(
              vertical: 8.h,
              horizontal: 12.w,
            ),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(5.r),
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

class QuickActionsGrid extends StatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> {
  bool showMore = false;

  static List<Map<String, dynamic>> getActions(BuildContext context) => [
    {
      'label': 'Airtime',
      'icon': Icon(Icons.bar_chart, color: primaryColor, size: 20.sp),
      'onTap': () => context.pushNamed(RouteList.airtime),
    },
    {
      'label': 'Data',
      'icon': Icon(Icons.four_g_plus_mobiledata, color: primaryColor, size: 20.sp),
      'onTap': () => context.pushNamed(RouteList.data),
    },
    {
      'label': 'Cable TV',
      'icon': Icon(Icons.tv, color: primaryColor, size: 20.sp),
      'onTap': () => context.pushNamed(RouteList.cable),
    },
    // {
    //   'label': 'Tiktok Coin',
    //   'icon': Image.asset(tiktok, height: 22.h),
    //   'onTap': () {},
    // },
    {
      'label': 'Electricity',
      'icon': Icon(Icons.electrical_services, color: primaryColor, size: 20.sp),
      'onTap': () => context.pushNamed(RouteList.electricity),
    },
    {
      'label': 'Internet',
      'icon': Icon(Icons.wifi, color: primaryColor, size: 20.sp),
      'onTap': () {},
    },
  ];

  @override
  Widget build(BuildContext context) {
    final actions = getActions(context);
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 15.h,
        horizontal: 4.w,
      ),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions
                .take(4)
                .map(
                  (item) => QuickActionButton(
                label: item['label'],
                icon: item['icon'],
                onTap: item['onTap'],
              ),
            )
                .toList(),
          ),

          if (showMore)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions
                    .skip(4)
                    .map(
                      (item) => QuickActionButton(
                    label: item['label'],
                    icon: item['icon'],
                    onTap: item['onTap'],
                  ),
                )
                    .toList(),
              ),
            ),

          GestureDetector(
            onTap: () => setState(() => showMore = !showMore),
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
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
                    showMore
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: primaryColor,
                    size: 20.sp,
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
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
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
