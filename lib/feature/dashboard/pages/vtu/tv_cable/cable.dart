import 'dart:async';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboard_repo/repo.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'cable_plan_config.dart';

class CableTv extends ConsumerStatefulWidget {
  const CableTv({super.key});

  @override
  ConsumerState<CableTv> createState() => _CableTvState();
}

class _CableTvState extends ConsumerState<CableTv> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isVerifying = false;
  Map<String, dynamic>? _selectedProvider;
  String _smartcardNumber = '';
  String? _customerName;
  String? _verificationError;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _providers = [];
  
  final TextEditingController _smartcardController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  TabController? _tabController;

  // Selected package tracking
  int? _selectedAmount;
  String? _selectedVariationCode;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _smartcardController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final controller = ref.read(dashboardControllerProvider.notifier);
    final providers = await controller.fetchCableProviders(context);

    if (providers.isNotEmpty && mounted) {
      final firstProvider = providers.first;
      final plans = await controller.fetchCablePlans(context, firstProvider['serviceID']);

      setState(() {
        _providers = providers;
        _selectedProvider = firstProvider;
        _plans = plans;
        _isLoading = false;
        _initTabController();
      });
    } else if (mounted) {
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    }
  }

  void _initTabController() {
    final tabs = _buildTabs();
    _tabController?.dispose();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  Future<void> _onProviderChanged(Map<String, dynamic> provider) async {
    setState(() {
      _isLoading = true;
      _selectedProvider = provider;
      _smartcardNumber = '';
      _customerName = null;
      _verificationError = null;
      _selectedAmount = null;
      _selectedVariationCode = null;
      _smartcardController.clear();
      _searchController.clear();
      _searchQuery = '';
    });

    final controller = ref.read(dashboardControllerProvider.notifier);
    final plans = await controller.fetchCablePlans(context, provider['serviceID']);

    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
        _initTabController();
      });
    }
  }

  int _getMinLength() => 10;
  int _getMaxLength() => 13;

  Future<void> _verifySmartcard(String value) async {
    if (_selectedProvider == null) return;
    final serviceId = _selectedProvider!['serviceID']?.toString() ?? '';

    setState(() {
      _isVerifying = true;
      _customerName = null;
      _verificationError = null;
    });

    final repo = ref.read(dashboardRepositoryProvider);
    try {
      final result = await repo.verifyCableCard(
        serviceId: serviceId,
        billersCode: value.trim(),
      );

      if (!mounted) return;

      if (result != null && result['Customer_Name'] != null) {
        setState(() {
          _customerName = result['Customer_Name'];
          _isVerifying = false;
        });
      } else {
        setState(() {
          _verificationError = "Invalid smartcard number";
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _verificationError = "Verification failed. Please try again.";
        _isVerifying = false;
      });
    }
  }

  void _onSmartcardChanged(String value) {
    final isShowmax = _selectedProvider?['name']?.toString().toLowerCase() == 'showmax';
    String cleanedValue = value;

    if (!isShowmax) {
      cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanedValue != value) {
        _smartcardController.value = TextEditingValue(
          text: cleanedValue,
          selection: TextSelection.collapsed(offset: cleanedValue.length),
        );
      }
    }

    setState(() {
      _smartcardNumber = cleanedValue;
      _selectedAmount = null;
      _selectedVariationCode = null;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (_verificationError != null) {
      setState(() => _verificationError = null);
    }

    final minLength = _getMinLength();
    final maxLength = _getMaxLength();

    if (cleanedValue.length >= minLength && cleanedValue.length <= maxLength) {
      _debounce = Timer(const Duration(milliseconds: 800), () {
        _verifySmartcard(cleanedValue);
      });
    } else if (cleanedValue.length > maxLength) {
      final trimmed = cleanedValue.substring(0, maxLength);
      _smartcardController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      setState(() => _smartcardNumber = trimmed);
    }
  }

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    final balanceStr = box.get('balance', defaultValue: '0').toString();
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }

  List<Map<String, dynamic>> get _extractedPlans {
    if (_plans.isEmpty) return [];
    final first = _plans.first;
    if (first.containsKey('responseBody')) {
      final responseBody = first['responseBody'];
      if (responseBody is Map && responseBody.containsKey('variations')) {
        final variations = responseBody['variations'];
        if (variations is List) {
          return variations.cast<Map<String, dynamic>>();
        }
      }
      return [];
    }
    return _plans;
  }

  String _extractDuration(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('1 year') || lower.contains('year')) return '1 Year';
    if (lower.contains('3 month') || lower.contains('3months')) return '3 Months';
    if (lower.contains('weekly') || lower.contains('1 week')) return 'Weekly';
    if (lower.contains('month') || lower.contains('monthly')) return 'Monthly';
    return 'Monthly';
  }

  List<String> _buildTabs() {
    final plans = _extractedPlans;
    if (plans.isEmpty) return ['Hot Offers'];
    final durations = plans
        .map((p) => _extractDuration(p['name']?.toString() ?? ''))
        .toSet()
        .toList();
    durations.sort((a, b) {
      final order = {'Monthly': 0, 'Weekly': 1, '3 Months': 2, '1 Year': 3};
      return (order[a] ?? 99).compareTo(order[b] ?? 99);
    });
    return ['Hot Offers', ...durations];
  }

  String _formatPrice(dynamic amount) {
    if (amount == null) return '0';
    final str = amount.toString();
    if (str.contains('.')) {
      final parts = str.split('.');
      if (parts[1] == '00' || parts[1] == '0') {
        return parts[0];
      }
    }
    return str;
  }

  String _getProviderLogo(String name) {
    switch (name.toLowerCase()) {
      case 'dstv':
        return 'assets/svg/dstv.png';
      case 'gotv':
        return 'assets/svg/gotv.png';
      case 'startimes':
        return 'assets/svg/startimes.png';
      case 'showmax':
        return 'assets/svg/showmax.png';
      default:
        return 'assets/svg/logo-one.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'TV Cable',
        onBackPressed: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          if (!context.mounted) return;
          if (context.canPop()) {
            context.pop();
          }
        },
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 18.w),
            child: SvgPicture.asset(bell),
          ),
        ],
      ),
      body: SafeArea(
        child: _providers.isEmpty && _isLoading
            ? Center(
                child: PulsingLogoIndicator(
                  logoPath: 'assets/svg/logo-b.png',
                  size: 50,
                  pulseColor: primaryColor,
                ),
              )
            : _providers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tv_off, size: 48.w, color: grey),
                        SizedBox(height: 16.h),
                        Text(
                          'No cable providers available',
                          style: TextStyle(color: grey, fontSize: 16.sp),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isDesktop = width >= 1100;
                      final isTablet = width >= 600 && width < 1100;
                      final double horizontalPadding = isDesktop ? 48.w : (isTablet ? 24.w : 16.w);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 24.h,
                          ),
                          child: isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _buildFormCard(width),
                                    ),
                                    SizedBox(width: 32.w),
                                    Expanded(
                                      flex: 7,
                                      child: _buildPackagesSection(width),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormCard(width),
                                    SizedBox(height: 24.h),
                                    _buildPackagesSection(width),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildFormCard(double screenWidth) {
    final isShowmax = _selectedProvider?['name']?.toString().toLowerCase() == 'showmax';
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Provider",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: darkBackground,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _providers.map((provider) {
              final name = provider['name']?.toString() ?? '';
              final logo = _getProviderLogo(name);
              final isSelected = _selectedProvider?['serviceID'] == provider['serviceID'];

              Color brandColor = primaryColor;
              if (name.toLowerCase().contains('dstv')) {
                brandColor = const Color(0xFF0056B3);
              } else if (name.toLowerCase().contains('gotv')) {
                brandColor = successColor;
              } else if (name.toLowerCase().contains('startimes')) {
                brandColor = errorColor;
              } else if (name.toLowerCase().contains('showmax')) {
                brandColor = const Color(0xFF111111);
              }

              return GestureDetector(
                onTap: () => _onProviderChanged(provider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 68.w,
                  height: 68.h,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? brandColor : Colors.grey[200]!,
                      width: 2.5.w,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: brandColor.withValues(alpha: 0.15),
                              blurRadius: 12.r,
                              spreadRadius: 1.r,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10.w),
                        child: Image.asset(
                          logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: brandColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),
          Text(
            isShowmax ? "Showmax Account Email" : "Smartcard Number",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: darkBackground,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _smartcardController,
              keyboardType: isShowmax ? TextInputType.emailAddress : TextInputType.number,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
              decoration: InputDecoration(
                hintText: isShowmax
                    ? "Enter your Showmax account email"
                    : "Enter smartcard number (10-13 digits)",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                prefixIcon: Icon(
                  isShowmax ? Icons.alternate_email : Icons.tv,
                  color: primaryColor,
                ),
                suffixIcon: _isVerifying
                    ? Padding(
                        padding: EdgeInsets.all(12.w),
                        child: SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      )
                    : _customerName != null
                        ? const Icon(Icons.check_circle, color: successColor)
                        : null,
              ),
              onChanged: _onSmartcardChanged,
            ),
          ),
          if (_customerName != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(top: 16.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: successColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: successColor),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Verified Customer",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _customerName!,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: darkBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_verificationError != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h, left: 4.w),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: errorColor, size: 16),
                  SizedBox(width: 8.w),
                  Text(
                    _verificationError!,
                    style: TextStyle(color: errorColor, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection(double screenWidth) {
    final theme = Theme.of(context);
    final plans = _extractedPlans;

    if (_isLoading) {
      return Container(
        height: 350.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: PulsingLogoIndicator(
            logoPath: 'assets/svg/logo-b.png',
            size: 40,
            pulseColor: primaryColor,
          ),
        ),
      );
    }

    if (plans.isEmpty) {
      return Container(
        height: 300.h,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_clear_outlined, size: 48.w, color: Colors.grey[300]),
              SizedBox(height: 12.h),
              Text(
                'No packages found for this provider.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    final tabs = _buildTabs();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16.r,
            offset: const Offset(0, 8),
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
                "Choose Subscription Package",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: darkBackground,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Search & Filter Box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: "Search package (e.g. yanga, compact, basic)",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          SizedBox(height: 16.h),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: grey,
            indicatorColor: primaryColor,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: _getGridHeight(screenWidth, plans.length),
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((tab) {
                List<Map<String, dynamic>> displayPlans;
                if (tab == 'Hot Offers') {
                  displayPlans = plans;
                } else {
                  displayPlans = plans
                      .where(
                        (p) => _extractDuration(p['name']?.toString() ?? '') == tab,
                      )
                      .toList();
                }

                // Apply search query filter
                if (_searchQuery.isNotEmpty) {
                  displayPlans = displayPlans
                      .where((p) => p['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (displayPlans.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching packages available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  );
                }

                return MasonryGridView.count(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: _getCrossAxisCount(screenWidth),
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 16.w,
                  itemCount: displayPlans.length,
                  itemBuilder: (context, index) {
                    final plan = displayPlans[index];
                    final price = double.tryParse(
                          plan['variation_amount']?.toString() ?? '0',
                        )?.toInt() ?? 0;
                    final variationCode = plan['variation_code']?.toString() ?? '';
                    final isSelected = _selectedVariationCode == variationCode;
                    final cardHeight = _getCardHeight(screenWidth, index.isEven);

                    return GestureDetector(
                      onTap: () {
                        final walletBalance = _getWalletBalance();

                        if (price > walletBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Insufficient balance. Your balance is ₦${walletBalance.toStringAsFixed(2)}",
                              ),
                              backgroundColor: errorColor,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _selectedAmount = price;
                          _selectedVariationCode = variationCode;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.transparent,
                            width: 2.5.w,
                          ),
                          image: DecorationImage(
                            image: AssetImage(CablePlanConfig.getPlanImage(plan)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              darkBackground.withValues(alpha: 0.3),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: [
                                darkBackground.withValues(alpha: 0.7),
                                darkBackground.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index == 0 && tab == 'Hot Offers')
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: redAccent,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    'Hot',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: lightBackground,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                plan['name']?.toString() ?? 'Unknown Plan',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: lightBackground,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '₦${_formatPrice(plan['variation_amount'])}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: primaryColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '₦20 Cashback',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: greenAccent,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                CablePlanConfig.getPlanDescription(variationCode),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: lightBackground70,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          if (_selectedVariationCode != null) ...[
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: () {
                  if (_smartcardNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a smartcard number first"),
                        backgroundColor: errorColor,
                      ),
                    );
                    return;
                  }

                  if (_customerName == null || _customerName!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please verify smartcard first"),
                        backgroundColor: errorColor,
                      ),
                    );
                    return;
                  }

                  final selectedPlan = plans.firstWhere(
                    (p) => p['variation_code'] == _selectedVariationCode,
                    orElse: () => {},
                  );
                  final packageName = selectedPlan['name'] ?? _selectedVariationCode;

                  ConfirmationBottomSheet.show(
                    context: context,
                    config: BottomSheetConfig(
                      title: "Confirm Cable Purchase",
                      subtitle: "Cable Subscription",
                      amount: _selectedAmount!.toDouble(),
                      details: [
                        BottomSheetDetailItem(
                          label: "Provider",
                          value: _selectedProvider!['name'],
                        ),
                        BottomSheetDetailItem(
                          label: "Smartcard",
                          value: _smartcardNumber,
                        ),
                        BottomSheetDetailItem(
                          label: "Customer",
                          value: _customerName!,
                        ),
                        BottomSheetDetailItem(
                          label: "Variation Code",
                          value: _selectedVariationCode!,
                        ),
                        BottomSheetDetailItem(
                          label: "Package",
                          value: packageName,
                        ),
                        BottomSheetDetailItem(
                          label: "Amount",
                          value: "₦$_selectedAmount",
                          isHighlighted: true,
                        ),
                        BottomSheetDetailItem(
                          label: "serviceId",
                          value: _selectedProvider!['serviceID'],
                        ),
                      ],
                    ),
                    onConfirm: (pin) async {
                      final controller = ref.read(dashboardControllerProvider.notifier);
                      
                      final result = await controller.buyCable(
                        context,
                        serviceId: _selectedProvider!['serviceID'],
                        smartcard: _smartcardNumber,
                        packageName: packageName,
                        variationCode: _selectedVariationCode!,
                        amount: _selectedAmount!,
                        phone: _smartcardNumber,
                        pin: pin,
                      );

                      if (!mounted) return;

                      final isSuccess = result?.responseSuccessful == true ||
                                        result?.responseBody?.status == "SUCCESS";

                      context.goNamed(
                        RouteList.successScreen,
                        extra: {
                          "type": isSuccess ? "success" : "failed",
                          "amount": _selectedAmount.toString(),
                          "recipientName": _selectedProvider!['name'],
                          "recipientAccount": _smartcardNumber,
                          "reference": result?.responseBody?.reference ?? '',
                          "channel": "Cable TV",
                        },
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  "Proceed to Subscription",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1400) return 3;
    if (width >= 1100) return 2;
    if (width >= 800) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  double _getCardHeight(double width, bool isEven) {
    double baseHeight;
    if (width >= 1400) {
      baseHeight = 240.h;
    } else if (width >= 1100) {
      baseHeight = 220.h;
    } else if (width >= 800) {
      baseHeight = 200.h;
    } else if (width >= 600) {
      baseHeight = 190.h;
    } else if (width >= 400) {
      baseHeight = 180.h;
    } else {
      baseHeight = 175.h;
    }
    return isEven ? baseHeight : baseHeight + 25.h;
  }

  double _getGridHeight(double width, int itemCount) {
    final crossAxisCount = _getCrossAxisCount(width);
    final rows = (itemCount / crossAxisCount).ceil();
    final cardHeight = _getCardHeight(width, false) + 16.h;
    final totalHeight = rows * cardHeight + 24.h;

    final maxHeight = width >= 1400 ? 550.h : (width >= 1100 ? 500.h : 450.h);
    return totalHeight > maxHeight ? maxHeight : totalHeight;
  }
}