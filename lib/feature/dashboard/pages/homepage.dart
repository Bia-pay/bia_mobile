import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bia/core/__core.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/dashboardcontroller.dart';
import 'package:bia/feature/dashboard/dashboardcontroller/provider.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import 'package:bia/app/utils/image.dart';
import 'package:bia/app/view/widget/dashboard_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  Future<void> _handleRefresh() async {
    await ref
        .read(dashboardControllerProvider.notifier)
        .refreshWalletBalance();
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = screenWidth > 600;
    final bool isLargeTablet = screenWidth > 900;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;

    // Responsive padding & spacings
    final double paddingHorizontal = isLargeTablet ? 32.w : isTablet ? 24.w : 16.w;
    final double elementSpacing = isTablet
        ? 18.h
        : isXSmall
            ? 8.h
            : isSmall
                ? 10.h
                : isLarge
                    ? 16.h
                    : 14.h;

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
                    padding: EdgeInsets.only(left: paddingHorizontal, right: paddingHorizontal / 2, top: 8.h, bottom: 130.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BalanceCard().animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, duration: 350.ms),
                        SizedBox(height: 6.h),
                        const VirtualAccountCard().animate().fadeIn(duration: 370.ms, delay: 30.ms).slideY(begin: 0.06, end: 0, duration: 370.ms),
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

                // Right Column: Promo Banner
                Expanded(
                  flex: 9,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(right: paddingHorizontal, top: 8.h, bottom: 130.h),
                    child: const PromoBannerCarousel()
                        .animate()
                        .fadeIn(duration: 550.ms, delay: 200.ms)
                        .slideX(begin: 0.05, end: 0, duration: 550.ms),
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
                  SizedBox(height: 6.h),
                  const VirtualAccountCard().animate().fadeIn(duration: 370.ms, delay: 30.ms).slideY(begin: 0.06, end: 0, duration: 370.ms),
                  SizedBox(height: elementSpacing),
                  const ActionRibbon().animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.08, end: 0, duration: 400.ms),
                  SizedBox(height: elementSpacing),
                  const BiaAiCard().animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: 0.08, end: 0, duration: 450.ms),
                  SizedBox(height: elementSpacing),
                  const QuickActionsGrid().animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.08, end: 0, duration: 500.ms),
                  SizedBox(height: elementSpacing),
                  const PromoBannerCarousel().animate().fadeIn(duration: 550.ms, delay: 200.ms).slideY(begin: 0.06, end: 0, duration: 550.ms),
                  SizedBox(height: isXSmall ? 110.h : isLarge ? 160.h : 140.h),
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
        bottom: false,
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;
    final double vPad = isXSmall ? 8.h : isSmall ? 10.h : isLarge ? 16.h : 14.h;
    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8.w),
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;
    final double cardHeight = isXSmall ? 56.h : isSmall ? 64.h : isLarge ? 80.h : 72.h;
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: lightBorderColor, width: 1),
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
                      colors: [Colors.cyan.withOpacity(0.12), Colors.transparent],
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
                              color: lightText,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Tap to start voice or text assistant in local dialect',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 9.sp,
                              color: lightSecondaryText,
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
                                color: primaryColor.withOpacity(0.08),
                                border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
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
                          color: lightText.withOpacity(0.6),
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

// ── Promo Banner Carousel ─────────────────────────────────────────────────────

class _BannerData {
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final String? route;

  const _BannerData({
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.route,
  });
}

class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  static const _banners = [
    _BannerData(
      gradientColors: [Color(0xFF0C284E), Color(0xFF1E569F)],
      title: 'Send Money Instantly',
      subtitle: 'Transfer to any Bia wallet or bank account in seconds.',
      icon: Icons.send_rounded,
      actionLabel: 'Send Now',
      route: RouteList.sendMoneyTransfer,
    ),
    _BannerData(
      gradientColors: [Color(0xFF065F46), Color(0xFF059669)],
      title: 'Pay Bills Effortlessly',
      subtitle: 'Airtime, data, electricity & more — all in one place.',
      icon: Icons.receipt_rounded,
      actionLabel: 'Pay Bills',
      route: RouteList.airtime,
    ),
    _BannerData(
      gradientColors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      title: 'Bia AI Assistant',
      subtitle: 'Make transactions with voice commands in your local dialect.',
      icon: Icons.mic_rounded,
      actionLabel: 'Try Bia AI',
      route: RouteList.aiChat,
    ),
    _BannerData(
      gradientColors: [Color(0xFF92400E), Color(0xFFD97706)],
      title: 'Bia Trike — Coming Soon',
      subtitle: 'Book affordable rides right from your wallet. Stay tuned!',
      icon: Icons.electric_rickshaw_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;
    // Reduced by exactly 1/4 (25%)
    final double bannerHeight = isXSmall ? 75.h : isSmall ? 84.h : isLarge ? 102.h : 91.5.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return _BannerCard(
                banner: banner,
                onTap: banner.route != null
                    ? () => context.pushNamed(banner.route!)
                    : null,
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final isActive = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 18.w : 6.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: isActive ? primaryColor : lightBorderColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;
  final VoidCallback? onTap;

  const _BannerCard({required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;

    final double verticalPadding = isXSmall ? 4.h : isSmall ? 6.h : 8.h;
    final double titleSize = isXSmall ? 11.5.sp : isSmall ? 12.sp : 13.sp;
    final double subtitleSize = isXSmall ? 8.5.sp : isSmall ? 9.sp : 9.5.sp;
    final double spacing = isXSmall ? 3.h : isSmall ? 4.h : 5.h;
    final double iconContainerSize = isXSmall ? 36.r : isSmall ? 42.r : 48.r;
    final double iconSize = isXSmall ? 16.sp : isSmall ? 19.sp : 22.sp;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: banner.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: banner.gradientColors.last.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20.w,
                top: -20.h,
                child: Container(
                  width: 90.r,
                  height: 90.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                left: -15.w,
                bottom: -25.h,
                child: Container(
                  width: 70.r,
                  height: 70.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: verticalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: titleSize,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            banner.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.78),
                              fontWeight: FontWeight.w400,
                              fontSize: subtitleSize,
                              height: 1.35,
                            ),
                          ),
                          if (banner.actionLabel != null) ...[
                            SizedBox(height: spacing),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isXSmall ? 8.w : 10.w,
                                vertical: isXSmall ? 2.h : 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    banner.actionLabel!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isXSmall ? 8.sp : 9.sp,
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Icon(Icons.arrow_forward_ios_rounded, size: isXSmall ? 7.sp : 8.sp, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: iconContainerSize,
                      height: iconContainerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: Center(
                        child: Icon(
                          banner.icon,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
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

    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;
    final double cardHeight = isXSmall ? 72.h : isSmall ? 81.h : isLarge ? 99.h : 90.h;
    return Container(
      height: cardHeight,
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
                vertical: isXSmall ? 8.h : isSmall ? 10.h : 12.h,
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
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Right: Add Money Icon
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteList.topUp),
                        child: Container(
                          padding: EdgeInsets.all(5.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: isXSmall ? 14.sp : 16.sp,
                          ),
                        ),
                      ),
                      // Bottom Right: Transaction History Link
                      GestureDetector(
                        onTap: () => context.pushNamed(RouteList.transactionHistory),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: Colors.white.withOpacity(0.95),
                                size: isXSmall ? 10.sp : 12.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'History',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: isXSmall ? 8.5.sp : 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class QuickActionsGrid extends ConsumerStatefulWidget {
  const QuickActionsGrid({super.key});

  @override
  ConsumerState<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends ConsumerState<QuickActionsGrid> {
  bool showMore = false;

  static List<Map<String, dynamic>> getActions(BuildContext context) => [
    {
      'label': 'Airtime',
      'icon': Icon(Icons.phone_iphone_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'onTap': () => context.pushNamed(RouteList.airtime),
    },
    {
      'label': 'Data',
      'icon': Icon(Icons.wifi_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'onTap': () => context.pushNamed(RouteList.data),
    },
    {
      'label': 'Cable TV',
      'icon': Icon(Icons.live_tv_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'onTap': () => context.pushNamed(RouteList.cable),
    },
    {
      'label': 'Electricity',
      'icon': Icon(Icons.bolt_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'onTap': () => context.pushNamed(RouteList.electricity),
    },
    {
      'label': 'Internet',
      'icon': Icon(Icons.router_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'isSoon': true,
    },
    {
      'label': 'Water Bill',
      'icon': Icon(Icons.water_drop_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'isSoon': true,
    },
    {
      'label': 'Insurance',
      'icon': Icon(Icons.health_and_safety_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'isSoon': true,
    },
    {
      'label': 'Education',
      'icon': Icon(Icons.school_rounded, color: primaryColor, size: 20.sp),
      'color': secondaryColor,
      'isSoon': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final actions = getActions(context);
    final servicesStatus = ref.watch(servicesStatusProvider);
    final theme = Theme.of(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final bool isSmall = screenHeight < 780;
    final bool isLarge = screenHeight > 900;
    final bool isTablet = screenWidth > 600;
    final double vPad = isXSmall ? 6.h : isSmall ? 8.h : isLarge ? 12.h : 10.h;

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 10.w),
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
          SizedBox(height: isXSmall ? 6.h : isSmall ? 8.h : 10.h),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: showMore ? actions.length : (isTablet ? actions.length : 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 8 : 4,
              mainAxisExtent: isTablet ? 75.h : (isXSmall ? 68.h : isSmall ? 72.h : isLarge ? 80.h : 76.h),
              mainAxisSpacing: isXSmall ? 6 : isSmall ? 8 : 10,
              crossAxisSpacing: isTablet ? 4 : 8,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              final label = item['label'] as String;

              bool isDisabled = false;
              if (label == 'Airtime') {
                isDisabled = !servicesStatus.airtime;
              } else if (label == 'Data') {
                isDisabled = !servicesStatus.data;
              } else if (label == 'Cable TV' || label == 'Electricity') {
                isDisabled = !servicesStatus.utility;
              }

              return QuickActionButton(
                label: label,
                icon: item['icon'],
                backgroundColor: item['color'],
                isSoon: item['isSoon'] ?? false,
                isDisabled: isDisabled,
                onTap: item['isSoon'] == true
                    ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                    : (isDisabled
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$label service is temporarily disabled for maintenance.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.orange.shade800,
                              ),
                            );
                          }
                        : item['onTap']),
              );
            },
          ),
          SizedBox(height: 4.h),
          if (!isTablet) GestureDetector(
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
  final bool isDisabled;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.isSoon = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = (isSoon || isDisabled) ? 0.4 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(builder: (ctx) {
                  final h = MediaQuery.of(ctx).size.height;
                  final w = MediaQuery.of(ctx).size.width;
                  final sz = w > 600 ? 40.r : h < 680 ? 38.r : h < 780 ? 42.r : h > 900 ? 48.r : 44.r;
                
                return Container(
                  height: sz,
                  width: sz,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14.r),
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
                );
              }),
              if (isSoon || isDisabled)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    height: 12.r,
                    width: 12.r,
                    decoration: BoxDecoration(
                      color: isDisabled ? Colors.orange.shade800 : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        isDisabled ? Icons.construction_rounded : Icons.lock_rounded,
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
              color: (isSoon || isDisabled) ? lightSecondaryText.withOpacity(0.4) : lightSecondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
     ),
    );
  }
}

// ── Virtual Account Card (slim banner) ───────────────────────────────────────

class VirtualAccountCard extends ConsumerStatefulWidget {
  const VirtualAccountCard({super.key});

  @override
  ConsumerState<VirtualAccountCard> createState() => _VirtualAccountCardState();
}

class _VirtualAccountCardState extends ConsumerState<VirtualAccountCard> {
  bool _copied = false;

  Future<void> _copyAccountNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountAsync = ref.watch(virtualAccountProvider);

    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isXSmall = screenHeight < 680;
    final double cardHeight = isXSmall ? 40.h : 44.h;

    final account = accountAsync.value;

    if (account == null) {
      return _ShimmerBanner(height: cardHeight);
    }

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: primaryColor.withOpacity(0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.012),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        child: Row(
          children: [
            // Bank logo indicator
            Icon(
              Icons.account_balance_rounded,
              color: primaryColor,
              size: isXSmall ? 13.sp : 14.sp,
            ),
            SizedBox(width: 8.w),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Row 1: Provider + Account Name
                  Row(
                    children: [
                      Text(
                        account.provider,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: isXSmall ? 8.sp : 9.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '  •  ${account.virtualAccountName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: isXSmall ? 8.sp : 9.sp,
                            fontWeight: FontWeight.w600,
                            color: lightSecondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  // Row 2: Account Number
                  Text(
                    account.virtualAccountNo,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: isXSmall ? 10.sp : 11.sp,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Copy button icon
            GestureDetector(
              onTap: () => _copyAccountNumber(account.virtualAccountNo),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                  key: ValueKey<bool>(_copied),
                  size: isXSmall ? 12.sp : 13.sp,
                  color: _copied ? successColor : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Slim shimmer placeholder shown while virtual account loads or is generated
class _ShimmerBanner extends StatefulWidget {
  final double height;

  const _ShimmerBanner({required this.height});

  @override
  State<_ShimmerBanner> createState() => _ShimmerBannerState();
}

class _ShimmerBannerState extends State<_ShimmerBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: lightBorderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Container(
                  width: 15.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: lightBorderColor.withOpacity(_animation.value),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 60.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: lightBorderColor.withOpacity(_animation.value),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 100.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: lightBorderColor.withOpacity(_animation.value),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


