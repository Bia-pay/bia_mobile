import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/provider.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import 'package:bia/app/utils/image.dart';
import 'package:bia/app/view/widget/dashboard_header.dart';
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
    final userProfile = ref.watch(userProfileProvider);
    final box = Hive.box('authBox');
    
    final isLoggedIn = box.get('is_logged_in', defaultValue: false) == true;
    final userId = box.get('userId', defaultValue: '');

    // Null/loading guard: Never render dashboard if session is not fully established
    if (!isLoggedIn || userId.toString().isEmpty) {
      return const Scaffold(
        backgroundColor: offWhiteBackground,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final fullname = userProfile?.fullname ?? box.get('fullname', defaultValue: 'User');
    final picture = userProfile?.picture ?? box.get('picture');
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    // Responsive padding & spacings
    final double paddingHorizontal = isTablet ? 24.w : 16.w;
    final double elementSpacing = isTablet ? 16.h : 14.h;

    // Split Layout for Tablet / Large screen form factor
    Widget buildBody() {
      if (isTablet) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Main Dashboard Controls
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 8.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BalanceCard().animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, duration: 350.ms),
                        SizedBox(height: elementSpacing),
                        const ActionRibbon().animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.08, end: 0, duration: 400.ms),
                        SizedBox(height: elementSpacing),
                        const BiaAiCard().animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: 0.08, end: 0, duration: 450.ms),
                        SizedBox(height: elementSpacing),
                        const QuickActionsGrid().animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.08, end: 0, duration: 500.ms),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                
                // Right Column: Recent Transactions & Activity log
                Expanded(
                  flex: 9,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(right: paddingHorizontal, top: 8.h, bottom: 16.h),
                    child: Container(
                      padding: EdgeInsets.all(18.r),
                      decoration: BoxDecoration(
                        color: offWhite,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: lightBorderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction History',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  color: lightText,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.pushNamed(RouteList.transactionHistory),
                                child: Text(
                                  'View all',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.sp,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          const RecentTransactionsList(),
                        ],
                      ),
                    ).animate().fadeIn(duration: 550.ms, delay: 200.ms).slideX(begin: 0.05, end: 0, duration: 550.ms),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Mobile / Compact Layout
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  const BalanceCard().animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, duration: 350.ms),
                  SizedBox(height: elementSpacing),
                  const ActionRibbon().animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.08, end: 0, duration: 400.ms),
                  SizedBox(height: elementSpacing),
                  const BiaAiCard().animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: 0.08, end: 0, duration: 450.ms),
                  SizedBox(height: elementSpacing),
                  const QuickActionsGrid().animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.08, end: 0, duration: 500.ms),
                  SizedBox(height: elementSpacing + 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction History',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: lightText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteList.transactionHistory),
                        child: Text(
                          'View all',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5.sp,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  const RecentTransactionsList().animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
                color: primaryColor,
                backgroundColor: Colors.white,
                child: buildBody(),
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
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: lightBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionButton(
            label: 'Send TP',
            icon: SvgPicture.asset(
              send, 
              height: 20.h,
              colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            onTap: () => context.pushNamed(RouteList.sendMoneyTransfer),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ActionButton(
                label: 'Bia Trike',
                icon: Icon(Icons.electric_rickshaw_rounded, color: primaryColor, size: 21.sp),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bia Trike coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              Positioned(
                top: -6.h,
                right: -24.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
                  decoration: BoxDecoration(
                    color: primaryGreenColor,
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreenColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Soon',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 6.5.sp,
                      color: Colors.white,
                    ),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scaleXY(begin: 0.94, end: 1.06, duration: 1000.ms),
              ),
            ],
          ),
          ActionButton(
            label: 'Withdrawal',
            icon: Image.asset(
              atm, 
              height: 20.h,
              color: primaryColor,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
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
      height: 96.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C284E), Color(0xFF133A6F), Color(0xFF1E569F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C284E).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () async {
            final authBox = await Hive.openBox('authBox');
            final userId = authBox.get('userId', defaultValue: '') as String;
            final phone = authBox.get('phone', defaultValue: '') as String;
            final effectiveUserId = userId.isNotEmpty ? userId : phone;

            final box = await Hive.openBox('appPrefs');
            final hasSelectedLang = box.get('biaAiLanguageSelected_$effectiveUserId', defaultValue: false) as bool;
            if (!context.mounted) return;
            if (!hasSelectedLang) {
              context.pushNamed(RouteList.biaLanguageOnboarding);
            } else {
              context.pushNamed(RouteList.aiChat);
            }
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              Positioned(
                right: -15.w,
                bottom: -15.h,
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.cyan.withOpacity(0.22), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Text(
                            'Make any Transaction with Bia AI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Tap to start voice or text assistant in local dialect',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 9.sp,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44.r,
                              height: 44.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                              ),
                            ).animate(
                              onPlay: (controller) => controller.repeat(reverse: true),
                            ).scaleXY(begin: 1.1, end: 1.3, duration: 1500.ms),
                            Container(
                              width: 42.r,
                              height: 42.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  mic,
                                  height: 25.h,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            return Container(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 52.r,
                      width: 52.r,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 24,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "No recent transactions",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: lightText,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Your transactions will appear here.",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: lightSecondaryText,
                      ),
                    ),
                  ],
                ),
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
        loading: () => const ShimmerTransactionLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              "Could not load transactions.",
              style: TextStyle(color: errorColor, fontSize: 11.sp),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerTransactionLoader extends StatelessWidget {
  const ShimmerTransactionLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(
        children: List.generate(2, (index) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Container(
                height: 38.w,
                width: 38.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12.h,
                      width: 120.w,
                      color: Colors.white,
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      height: 8.h,
                      width: 60.w,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 12.h,
                    width: 50.w,
                    color: Colors.white,
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    height: 8.h,
                    width: 30.w,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        )),
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
      height: 120.h,
      decoration: BoxDecoration(
        gradient: brandGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            Positioned(
              right: -25.w,
              top: -25.h,
              child: Container(
                width: 110.r,
                height: 110.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -10.w,
              bottom: -35.h,
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.035),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 16.h,
                horizontal: 16.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Available Balance',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                ref.read(balanceVisibilityProvider.notifier).state =
                                !isVisible;
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: anim,
                                  child: child,
                                ),
                                child: Icon(
                                  isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  key: ValueKey<bool>(isVisible),
                                  size: 15.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isVisible
                                ? '${Constants.nairaCurrencySymbol}$formattedBalance'
                                : '••••••',
                            key: ValueKey<String>(isVisible ? formattedBalance : 'hidden'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 23.sp,
                              letterSpacing: isVisible ? 0.2 : 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed(RouteList.topUp),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Add money',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            height: 46.r,
            width: 46.r,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: icon),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: lightText,
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
      'icon': Icon(Icons.phone_iphone_rounded, color: const Color(0xFF0EA5E9), size: 20.sp),
      'color': const Color(0xFFE0F2FE),
      'onTap': () => context.pushNamed(RouteList.airtime),
    },
    {
      'label': 'Data',
      'icon': Icon(Icons.wifi_rounded, color: const Color(0xFF8B5CF6), size: 20.sp),
      'color': const Color(0xFFF5F3FF),
      'onTap': () => context.pushNamed(RouteList.data),
    },
    {
      'label': 'Cable TV',
      'icon': Icon(Icons.live_tv_rounded, color: const Color(0xFFF59E0B), size: 20.sp),
      'color': const Color(0xFFFEF3C7),
      'onTap': () => context.pushNamed(RouteList.cable),
    },
    {
      'label': 'Electricity',
      'icon': Icon(Icons.bolt_rounded, color: const Color(0xFF10B981), size: 20.sp),
      'color': const Color(0xFFD1FAE5),
      'onTap': () => context.pushNamed(RouteList.electricity),
    },
    {
      'label': 'Internet',
      'icon': Icon(Icons.router_rounded, color: const Color(0xFF64748B), size: 20.sp),
      'color': const Color(0xFFF1F5F9),
      'isSoon': true,
    },
    {
      'label': 'Water Bill',
      'icon': Icon(Icons.water_drop_rounded, color: const Color(0xFF06B6D4), size: 20.sp),
      'color': const Color(0xFFECFEFF),
      'isSoon': true,
    },
    {
      'label': 'Insurance',
      'icon': Icon(Icons.health_and_safety_rounded, color: const Color(0xFFEF4444), size: 20.sp),
      'color': const Color(0xFFFEF2F2),
      'isSoon': true,
    },
    {
      'label': 'Education',
      'icon': Icon(Icons.school_rounded, color: const Color(0xFFEC4899), size: 20.sp),
      'color': const Color(0xFFFDF2F8),
      'isSoon': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final actions = getActions(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: lightBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Quick Utilities',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
                color: lightText,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: showMore ? actions.length : 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              return QuickActionButton(
                label: item['label'],
                icon: item['icon'],
                backgroundColor: item['color'],
                isSoon: item['isSoon'] ?? false,
                onTap: item['isSoon'] == true
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item['label']} coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : item['onTap'],
              ).animate().fade(duration: 200.ms).slideY(begin: 0.05, end: 0, duration: 200.ms);
            },
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () => setState(() => showMore = !showMore),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    showMore ? "Show Less" : "Show More",
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    showMore ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: primaryColor,
                    size: 16.sp,
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
  final Color backgroundColor;
  final bool isSoon;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.isSoon = false,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 44.r,
                width: 44.r,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: icon),
              ),
              if (isSoon)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    height: 12.r,
                    width: 12.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock_rounded,
                        size: 7.r,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
