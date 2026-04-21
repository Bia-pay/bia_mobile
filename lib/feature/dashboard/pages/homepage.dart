import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../app/utils/image.dart';
import '../../../app/view/widget/dashboard_header.dart';
import '../../../core/helper/helper.dart';
import '../../dashboard/dashboardcontroller/provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool showMore = false;

  Future<void> _handleRefresh() async {
    final userId = ref.read(userIdProvider);

    final txFuture = ref
        .read(recentTransactionsProvider(userId).notifier)
        .refresh();
    final walletFuture = ref
        .read(dashboardControllerProvider.notifier)
        .refreshWalletBalance();

    await Future.wait([txFuture, walletFuture] as Iterable<Future<dynamic>>);
  }

  List<Map<String, dynamic>> _quickActions(BuildContext context) => [
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
    {
      'label': 'Tiktok Coin',
      'icon': Image.asset(tiktok, height: isSmallScreen(context) ? 18.h : 23.h),
      'onTap': () => context.pushNamed(RouteList.transactionDetailsScreen),
    },
    {
      'label': 'Utility Bill',
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

  bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 700;
  }

  bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.height > 900;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box('authBox');
    final fullname = box.get('fullname', defaultValue: 'User');
    final picture = box.get('picture');
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final headerSpacing = isSmallScreen ? 6.h : 10.h;
    final sectionSpacing = isSmallScreen ? 10.h : 15.h;
    final cardPadding = isSmallScreen ? 10.h : 15.h;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                HomeHeader(
                  isSmallScreen: isSmallScreen,
                  picture: picture,
                  fullname: fullname,
                  theme: theme,
                  primaryColor: primaryColor,
                  lightSecondaryText: lightSecondaryText,
                  lightText: lightText,
                  appLogoPng: appLogoPng,
                  bell: bell,
                  notificationRoute: RouteList.notification,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    // 🔥 FIX: Use CustomScrollView with SliverToBoxAdapter for each section
                    // This allows pull-to-refresh while preventing content scrolling
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: isSmallScreen ? 16.w : 20.w,
                              right: isSmallScreen ? 16.w : 20.w,
                              top: isSmallScreen ? 3.h : 2.h,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row

                                SizedBox(height: headerSpacing),

                                BalanceCard(isSmallScreen: isSmallScreen),
                                SizedBox(height: sectionSpacing),

                                buildContainer(context, theme, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 10.h : 13.h),

                                Text(
                                  'Quick Actions',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isSmallScreen ? 11.sp : 13.sp,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6.h : 8.h),

                                buildContainerTwo(theme, context, isSmallScreen),
                                SizedBox(height: sectionSpacing),

                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 10.h : 15.h,
                                    horizontal: isSmallScreen ? 3.w : 5.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: offWhite,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: _quickActions(context)
                                            .take(4)
                                            .map(
                                              (item) => QuickActionButton(
                                            label: item['label'],
                                            icon: item['icon'],
                                            onTap: item['onTap'],
                                            isSmallScreen: isSmallScreen,
                                          ),
                                        )
                                            .toList(),
                                      ),
                                      SizedBox(height: isSmallScreen ? 3.h : 5.h),

                                      if (showMore)
                                        Padding(
                                          padding: EdgeInsets.only(top: isSmallScreen ? 8.h : 10.h),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: _quickActions(context)
                                                .skip(4)
                                                .map(
                                                  (item) => QuickActionButton(
                                                label: item['label'],
                                                icon: item['icon'],
                                                onTap: item['onTap'],
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            )
                                                .toList(),
                                          ),
                                        ),

                                      GestureDetector(
                                        onTap: () => setState(() => showMore = !showMore),
                                        child: Padding(
                                          padding: EdgeInsets.only(top: isSmallScreen ? 8.h : 10.h),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                showMore ? "Less" : "More",
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 11.sp : 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              Icon(
                                                showMore
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: primaryColor,
                                                size: isSmallScreen ? 18.sp : 20.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 15.h : 20.h),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Transaction History',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmallScreen ? 11.sp : 13.sp,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.pushNamed(RouteList.transactionHistory),
                                      child: Text(
                                        'View all',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w300,
                                          fontSize: isSmallScreen ? 9.sp : 10.sp,
                                          color: lightSecondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 6.h : 8.h),

                                // 🔥 FIX: Use SizedBox with calculated height instead of Expanded
                                SizedBox(
                                  height: isSmallScreen ? 140.h : 180.h,
                                  child: buildExpanded(theme, isSmallScreen, isLargeScreen),
                                ),

                                // Bottom padding
                                SizedBox(height: isSmallScreen ? 10.h : 20.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Container buildContainerTwo(ThemeData theme, BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 15.h : 20.h,
        horizontal: isSmallScreen ? 12.w : 15.w,
      ),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () async {
          final box = await Hive.openBox('appPrefs');
          final hasSelectedLang = box.get('biaAiLanguageSelected', defaultValue: false) as bool;
          if (!context.mounted) return;
          if (!hasSelectedLang) {
            // First time – show language picker
            context.pushNamed(RouteList.biaLanguageOnboarding);
          } else {
            // Already picked a language – go straight to chat
            context.pushNamed(RouteList.aiChat);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  mic,
                  height: isSmallScreen ? 40.h : 50.h,
                  color: primaryColor,
                ),
                SvgPicture.asset(
                  chatting,
                  height: isSmallScreen ? 40.h : 50.h,
                  color: primaryColor,
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 3.h : 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bia AI',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 11.sp : 13.sp,
                    color: primaryColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: isSmallScreen ? 10.sp : 12.sp,
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container buildContainer(BuildContext context, ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 14.h),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionButton(
            label: 'Send TP',
            icon: SvgPicture.asset(send, height: isSmallScreen ? 18.h : 21.h),
            onTap: () => context.pushNamed(RouteList.sendMoneyTransfer),
            isSmallScreen: isSmallScreen,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ActionButton(
                label: 'Bia Trike',
                icon: Icon(Icons.car_crash_sharp, color: primaryColor, size: isSmallScreen ? 18.sp : 21.sp),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bia Trike coming soon!')),
                  );
                },
                isSmallScreen: isSmallScreen,
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
                      fontSize: isSmallScreen ? 5.sp : 6.sp,
                      color: whiteBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ActionButton(
            label: 'Withdrawal',
            icon: Image.asset(atm, height: isSmallScreen ? 18.h : 21.h),
            onTap: () => context.pushNamed(RouteList.sendMoneyToBank),
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget buildExpanded(ThemeData theme, bool isSmallScreen, bool isLargeScreen) {
    return SizedBox(
      // 🔥 CHANGED: Let height be determined by parent Expanded, not fixed
      width: double.infinity,
      child: Consumer(
        builder: (context, ref, _) {
          final userId = ref.watch(userIdProvider);

          final asyncTx = ref.watch(recentTransactionsProvider(userId));
          return asyncTx.when(
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
                // 🔥 CHANGED: Limit items to fit available space without scrolling
                itemCount: transactions.length > (isSmallScreen ? 2 : 2)
                    ? (isSmallScreen ? 2 : 2)
                    : transactions.length,
                // 🔥 CHANGED: Disable scrolling physics
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
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
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 5.h : 7.h),
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 7.h : 9.h,
                      horizontal: isSmallScreen ? 8.w : 10.w,
                    ),
                    decoration: BoxDecoration(
                      color: offWhite,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12.r : 16.r),
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
                        Container(
                          height: isSmallScreen ? 35.w : 40.w,
                          width: isSmallScreen ? 35.w : 40.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: amountColor.withOpacity(.08),
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: amountColor,
                            size: isSmallScreen ? 16.sp : 18.sp,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8.w : 10.w),
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
                                  fontSize: isSmallScreen ? 11.sp : 12.sp,
                                  color: darkBackground,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 3.h : 4.h),
                              Text(
                                formatTransactionDate(tx.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: isSmallScreen ? 9.sp : 10.sp,
                                  color: lightSecondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isCredit ? '+' : '-'}₦${tx.amount}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                color: amountColor,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4.h : 5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6.w : 8.w,
                                vertical: isSmallScreen ? 3.h : 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: amountColor.withOpacity(.08),
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                              child: Text(
                                tx.status ?? "",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 6.sp : 7.sp,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
          );
        },
      ),
    );
  }
}

class BalanceCard extends ConsumerWidget {
  final bool isSmallScreen;

  const BalanceCard({super.key, required this.isSmallScreen});

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
        vertical: isSmallScreen ? 12.h : 15.h,
        horizontal: isSmallScreen ? 12.w : 15.w,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8.r : 10.r),
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
                      fontSize: isSmallScreen ? 10.sp : 12.sp,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 6.w : 8.w),
                  GestureDetector(
                    onTap: () {
                      ref.read(balanceVisibilityProvider.notifier).state =
                      !isVisible;
                    },
                    child: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      size: isSmallScreen ? 14.sp : 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 3.h : 4.h),
              Text(
                isVisible
                    ? '${Constants.nairaCurrencySymbol}$formattedBalance'
                    : '******',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isSmallScreen ? 16.sp : 20.sp,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.pushNamed(RouteList.topUp),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8.w : 10.w,
                vertical: isSmallScreen ? 4.h : 5.h,
              ),
              decoration: BoxDecoration(
                color: whiteBackground,
                borderRadius: BorderRadius.all(Radius.circular(isSmallScreen ? 6.r : 8.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/svg/plus.png', height: isSmallScreen ? 12.h : 15.h),
                  SizedBox(width: isSmallScreen ? 4.w : 6.w),
                  Text(
                    'Add money',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 10.sp : 12.sp,
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
  final bool isSmallScreen;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    required this.isSmallScreen,
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
              vertical: isSmallScreen ? 6.h : 8.h,
              horizontal: isSmallScreen ? 9.w : 11.w,
            ),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: icon,
          ),
          SizedBox(height: isSmallScreen ? 8.h : 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 10.sp : 11.sp,
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
  final bool isSmallScreen;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    required this.isSmallScreen,
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
              vertical: isSmallScreen ? 7.h : 9.h,
              horizontal: isSmallScreen ? 7.w : 9.w,
            ),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
            ),
            child: icon,
          ),
          SizedBox(height: isSmallScreen ? 8.h : 10.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: lightSecondaryText,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 9.sp : 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}