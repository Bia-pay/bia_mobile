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
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboard_repo/repo.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import 'cable_plan_config.dart';

final cableProvidersProvider = FutureProvider<List<Map<String, dynamic>>>((
    ref,
    ) async {
  final repo = ref.read(dashboardRepositoryProvider);
  final result = await repo.getCableProviders();
  return result;
});

class CableTv extends ConsumerStatefulWidget {
  const CableTv({super.key});

  @override
  ConsumerState<CableTv> createState() => _CableTvState();
}

class _CableTvState extends ConsumerState<CableTv> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'TV Cable',
        onBackPressed: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(Duration(milliseconds: 150));
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final isDesktop = constraints.maxWidth >= 1200;
            final horizontalPadding = isDesktop
                ? 120.w
                : (isTablet ? 32.w : 16.w);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const CardOne()],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CardOne extends ConsumerStatefulWidget {
  const CardOne({super.key});

  @override
  ConsumerState<CardOne> createState() => _CardOneState();
}

class _CardOneState extends ConsumerState<CardOne> {
  bool _isLoading = true;
  Map<String, dynamic>? _selectedProvider;
  String _smartcardNumber = '';
  String? _customerName; // ✅ ADD THIS LINE
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _providers = [];
  Key _selectorKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final controller = ref.read(dashboardControllerProvider.notifier);

    final providers = await controller.fetchCableProviders(context);

    if (providers.isNotEmpty && mounted) {
      final provider = providers.first;
      final plans = await controller.fetchCablePlans(context, provider['serviceID']);

      if (mounted) {
        setState(() {
          _providers = providers;
          _selectedProvider = provider;
          _plans = plans;
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    }
  }

  Future<void> _onProviderChanged(Map<String, dynamic> provider) async {
    setState(() {
      _isLoading = true;
      _selectedProvider = provider;
      _selectorKey = UniqueKey();
    });

    final controller = ref.read(dashboardControllerProvider.notifier);
    final plans = await controller.fetchCablePlans(context, provider['serviceID']);

    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1200;
        final cardPadding = isDesktop
            ? EdgeInsets.symmetric(vertical: 32.h, horizontal: 48.w)
            : (isTablet
            ? EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w)
            : EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w));

        if (_isLoading && _providers.isEmpty) {
          return Container(
            padding: cardPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16.r)),
              color: lightBackground,
              boxShadow: [
                BoxShadow(
                  color: darkBackground.withValues(alpha: 0.05),
                  blurRadius: 10.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 140.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: grey300.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: grey300.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: grey300.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 24.h),
                Wrap(
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: List.generate(4, (index) => Container(
                    width: (constraints.maxWidth - 64.w) / 2,
                    height: 180.h,
                    decoration: BoxDecoration(
                      color: grey300.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  )),
                ),
              ],
            ),
          );
        }

        if (_providers.isEmpty) {
          return Container(
            padding: cardPadding,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.tv_off, size: 48.w, color: grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No cable providers available',
                    style: TextStyle(color: grey, fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16.r)),
            color: lightBackground,
            boxShadow: [
              BoxShadow(
                color: darkBackground.withValues(alpha: 0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            children: [
              CableProviderDropdown(
                providers: _providers,
                selectedProvider: _selectedProvider,
                onChanged: _onProviderChanged,
                onSmartcardChanged: (number) {
                  setState(() => _smartcardNumber = number);
                },
                onCustomerResolved: (name) {
                  setState(() => _customerName = name);
                },
              ),
              Divider(color: grey300, height: isTablet ? 40.h : 32.h),
              if (_isLoading)
                Container(
                  height: 200.h,
                  child: Center(
                    child: PulsingLogoIndicator(
                      logoPath: 'assets/svg/logo-b.png',
                      size: 40,
                      pulseColor: primaryColor,
                    ),
                  ),
                )
              else
                CableTvAmountSelector(
                  key: _selectorKey,
                  selectedProvider: _selectedProvider,
                  phoneNumber: _smartcardNumber,
                  plans: _plans,
                  onAmountSelected: (amount, variationCode) async {
                    if (variationCode.isEmpty) return;

                    if (_customerName == null || _customerName!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please verify smartcard first"),
                          backgroundColor: errorColor,
                        ),
                      );
                      return;
                    }

                    final selectedPlan = _plans.firstWhere(
                          (p) => p['variation_code'] == variationCode,
                      orElse: () => {},
                    );

                    final packageName = selectedPlan['name'] ?? variationCode;

                    ConfirmationBottomSheet.show(
                      context: context,
                      config: BottomSheetConfig(
                        title: "Confirm Cable Purchase",
                        subtitle: "Cable Subscription",
                        amount: amount.toDouble(),
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
                            value: _customerName!, // ✅ FIXED
                          ),
                          BottomSheetDetailItem(
                            label: "Variation Code",
                            value: variationCode,
                          ),
                          BottomSheetDetailItem(
                            label: "Package",
                            value: packageName,
                          ),
                          BottomSheetDetailItem(
                            label: "Amount",
                            value: "₦$amount",
                            isHighlighted: true,
                          ),
                          BottomSheetDetailItem(
                            label: "serviceId",
                            value: _selectedProvider!['serviceID'],
                          ),
                        ],
                      ),
                      onConfirm: (pin) {},
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class CableProviderDropdown extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> providers;
  final Map<String, dynamic>? selectedProvider;
  final Function(Map<String, dynamic>)? onChanged;
  final Function(String)? onSmartcardChanged;
  final Function(String)? onCustomerResolved;

  const CableProviderDropdown({
    super.key,
    required this.providers,
    this.selectedProvider,
    this.onChanged,
    this.onSmartcardChanged,
    this.onCustomerResolved, // ✅ ADD THIS
  });

  @override
  ConsumerState<CableProviderDropdown> createState() =>
      _CableProviderDropdownState();
}

class _CableProviderDropdownState extends ConsumerState<CableProviderDropdown> {
  late Map<String, dynamic>? _selectedProvider;
  final TextEditingController _controller = TextEditingController();

  bool _isVerifying = false;
  String? _customerName;
  String? _error;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.selectedProvider;
  }

  @override
  void didUpdateWidget(CableProviderDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedProvider != oldWidget.selectedProvider) {
      setState(() {
        _selectedProvider = widget.selectedProvider;
        _customerName = null;
        _error = null;
      });
      _controller.clear();
    }
  }

  /// 🔥 UPDATED: All providers verify at 10 digits, max 13 digits
  int getMinLength(String? provider) {
    // Start verification at 10 digits for all providers
    return 10;
  }

  /// 🔥 NEW: Max length is 13 for all providers
  int getMaxLength(String? provider) {
    return 13;
  }

  Future<void> _verifyCard(String value) async {
    if (_selectedProvider == null) {
      debugPrint('❌ No provider selected');
      return;
    }

    final serviceId = _selectedProvider!['serviceID']?.toString() ?? '';
    final providerName = _selectedProvider!['name']?.toString() ?? '';

    debugPrint('🔥 VERIFYING CABLE CARD:');
    debugPrint('   Provider: $providerName');
    debugPrint('   ServiceID: $serviceId');
    debugPrint('   Smartcard: "$value"');
    debugPrint('   Length: ${value.length}');

    if (serviceId.isEmpty) {
      debugPrint('❌ ServiceID is empty!');
      setState(() {
        _error = "Provider not configured properly";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _customerName = null;
      _error = null;
    });

    final repo = ref.read(dashboardRepositoryProvider);

    try {
      final result = await repo.verifyCableCard(
        serviceId: serviceId,
        billersCode: value.trim(),
      );

      debugPrint('📡 API Result: $result');

      if (!mounted) return;

      if (result != null && result['Customer_Name'] != null) {
        final name = result['Customer_Name'];

        setState(() {
          _customerName = name;
          _isVerifying = false;
        });

        widget.onCustomerResolved?.call(name); // ✅ THIS WAS MISSING
      } else {
        setState(() {
          _error = "Invalid smartcard number";
          _isVerifying = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 Verification error: $e');
      setState(() {
        _error = "Verification failed. Please try again.";
        _isVerifying = false;
      });
    }
  }

  void _onChanged(String value) {
    // 🔥 Remove any non-digit characters for numeric providers
    final isShowmax = _selectedProvider?['name']?.toString().toLowerCase() == 'showmax';

    String cleanedValue = value;
    if (!isShowmax) {
      // For all providers except Showmax, keep only digits
      cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      // Update controller if value changed (cursor might jump)
      if (cleanedValue != value) {
        _controller.value = TextEditingValue(
          text: cleanedValue,
          selection: TextSelection.collapsed(offset: cleanedValue.length),
        );
      }
    }

    widget.onSmartcardChanged?.call(cleanedValue);

    final minLength = getMinLength(_selectedProvider?['name']);
    final maxLength = getMaxLength(_selectedProvider?['name']);

    debugPrint('📱 Input: "$cleanedValue", Length: ${cleanedValue.length}, Min: $minLength, Max: $maxLength');

    // Cancel previous debounce
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Clear error if user is typing
    if (_error != null) {
      setState(() => _error = null);
    }

    // Only verify if within valid range (10-13 digits)
    if (cleanedValue.length >= minLength && cleanedValue.length <= maxLength) {
      _debounce = Timer(const Duration(milliseconds: 800), () {
        debugPrint('⏱️ Debounce fired - verifying $cleanedValue');
        _verifyCard(cleanedValue);
      });
    } else if (cleanedValue.length > maxLength) {
      // Trim to max length
      final trimmed = cleanedValue.substring(0, maxLength);
      _controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      widget.onSmartcardChanged?.call(trimmed);
      debugPrint('✂️ Trimmed to max length: $maxLength');
    }
  }

  String getProviderLogo(String name) {
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
        return 'assets/svg/logo.png';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isShowmax = _selectedProvider?['name']?.toString().toLowerCase() == 'showmax';
    final maxLength = getMaxLength(_selectedProvider?['name']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// PROVIDER DROPDOWN
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: grey300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedProvider,
              isExpanded: true,
              items: widget.providers.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Row(
                    children: [
                      Image.asset(
                        getProviderLogo(provider['name']),
                        height: 24.h,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        provider['name'],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedProvider = value);
                widget.onChanged?.call(value!);
              },
            ),
          ),
        ),

        SizedBox(height: 12.h),

        /// INPUT FIELD
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: grey300),
          ),
          child: CustomTextField(
            controller: _controller,
            keyboardType: isShowmax ? TextInputType.emailAddress : TextInputType.number,
            hint: isShowmax
                ? 'Enter Showmax Email'
                : 'Smartcard Number (10-13 digits)',
            maxLength: isShowmax ? null : maxLength, // 🔥 Limit to 13 digits
            onChanged: _onChanged,
          ),
        ),

        SizedBox(height: 8.h),

        /// VERIFYING
        if (_isVerifying)
          Row(
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: PulsingLogoIndicator(
                  logoPath: 'assets/svg/logo-b.png',
                  size: 40,
                  pulseColor: primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                "Verifying...",
                style: TextStyle(color: grey),
              ),
            ],
          ),

        /// SUCCESS
        if (_customerName != null)
          Text(
            _customerName!,
            style: TextStyle(
              color: greenAccent,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

        /// ERROR
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(
              color: errorColor,
              fontSize: 14.sp,
            ),
          ),
      ],
    );
  }
}

class CableTvAmountSelector extends StatefulWidget {
  final Function(int amount, String variationCode)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;
  final List<Map<String, dynamic>> plans;

  const CableTvAmountSelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
    required this.plans,
  });

  @override
  State<CableTvAmountSelector> createState() => _CableTvAmountSelectorState();
}

class _CableTvAmountSelectorState extends State<CableTvAmountSelector>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int? selectedAmount;
  String? selectedVariationCode;

  double _getWalletBalance() {
    final box = Hive.box('authBox');
    final balanceStr = box.get('balance', defaultValue: '0').toString();
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final tabs = _buildTabs();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void didUpdateWidget(CableTvAmountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPlans = _extractPlans(oldWidget.plans);
    final newPlans = _extractPlans(widget.plans);

    if (oldPlans.length != newPlans.length ||
        oldPlans.isEmpty != newPlans.isEmpty) {
      final tabs = _buildTabs();
      final newLength = tabs.length;

      _tabController?.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: 0,
      );

      selectedAmount = null;
      selectedVariationCode = null;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _plans {
    return _extractPlans(widget.plans);
  }

  List<Map<String, dynamic>> _extractPlans(
      List<Map<String, dynamic>> rawPlans,
      ) {
    if (rawPlans.isEmpty) return [];
    final first = rawPlans.first;
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
    return rawPlans;
  }

  String _extractDuration(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('1 year') || lower.contains('year')) return '1 Year';
    if (lower.contains('3 month') || lower.contains('3months'))
      return '3 Months';
    if (lower.contains('weekly') || lower.contains('1 week')) return 'Weekly';
    if (lower.contains('month') || lower.contains('monthly')) return 'Monthly';
    return 'Monthly';
  }

  List<String> _buildTabs() {
    if (_plans.isEmpty) return ['Hot Offers'];
    final durations = _plans
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

  int _getCrossAxisCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1100) return 3;
    if (width >= 800) return 3;
    if (width >= 600) return 2;
    return 2;
  }

  double _getCardHeight(double width, bool isEven) {
    double baseHeight;
    if (width >= 1400) {
      baseHeight = 280.h;
    } else if (width >= 1100) {
      baseHeight = 260.h;
    } else if (width >= 800) {
      baseHeight = 240.h;
    } else if (width >= 600) {
      baseHeight = 220.h;
    } else if (width >= 400) {
      baseHeight = 200.h;
    } else {
      baseHeight = 180.h;
    }
    return isEven ? baseHeight : baseHeight + 40.h;
  }

  double _getGridHeight(double width, int itemCount) {
    final crossAxisCount = _getCrossAxisCount(width);
    final rows = (itemCount / crossAxisCount).ceil();
    final cardHeight = _getCardHeight(width, false) + 16.h;
    final totalHeight = rows * cardHeight + 24.h;

    final maxHeight = width >= 1400 ? 700.h : (width >= 1100 ? 650.h : 600.h);
    return totalHeight > maxHeight ? maxHeight : totalHeight;
  }

  double _getFontSize(double width) {
    if (width >= 1400) return 18.sp;
    if (width >= 1100) return 16.sp;
    if (width >= 800) return 15.sp;
    if (width >= 600) return 14.sp;
    return 14.sp;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();

    if (_tabController == null || _tabController!.length != tabs.length) {
      _tabController?.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    final controller = _tabController!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1400;
        final isTablet = width >= 600;

        final crossAxisCount = _getCrossAxisCount(width);
        final gridHeight = _getGridHeight(width, _plans.length);
        final fontSize = _getFontSize(width);
        final tabFontSize = isDesktop ? 16.sp : (isTablet ? 15.sp : 14.sp);
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: controller,
              isScrollable: true,
              labelColor: primaryColor,
              unselectedLabelColor: grey,
              indicatorColor: primaryColor,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: tabFontSize,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: tabFontSize),
              tabs: tabs.map((e) => Tab(text: e)).toList(),
            ),
            SizedBox(height: isTablet ? 24.h : 16.h),
            SizedBox(
              height: gridHeight,
              child: TabBarView(
                controller: controller,
                children: tabs.map((tab) {
                  List<Map<String, dynamic>> displayPlans;
                  if (tab == 'Hot Offers') {
                    displayPlans = _plans;
                  } else {
                    displayPlans = _plans
                        .where(
                          (p) =>
                      _extractDuration(p['name']?.toString() ?? '') ==
                          tab,
                    )
                        .toList();
                  }

                  if (displayPlans.isEmpty) {
                    return Center(
                      child: Text(
                        'No packages available',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize),
                      ),
                    );
                  }

                  return MasonryGridView.count(
                    padding: EdgeInsets.all(isTablet ? 10.w : 0.w),
                    physics: const BouncingScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: isTablet ? 20.h : 16.h,
                    crossAxisSpacing: isTablet ? 20.w : 16.w,
                    itemCount: displayPlans.length,
                    itemBuilder: (context, index) {
                      final plan = displayPlans[index];
                      final price =
                          double.tryParse(
                            plan['variation_amount']?.toString() ?? '0',
                          )?.toInt() ??
                              0;
                      final isSelected =
                          selectedVariationCode == plan['variation_code'];
                      final cardHeight = _getCardHeight(width, index.isEven);

                      final planNameFontSize = isDesktop
                          ? 18.sp
                          : (isTablet ? 16.sp : 15.sp);
                      final priceFontSize = isDesktop
                          ? 20.sp
                          : (isTablet ? 18.sp : 16.sp);
                      final cashbackFontSize = isDesktop
                          ? 14.sp
                          : (isTablet ? 13.sp : 12.sp);
                      final descFontSize = isDesktop
                          ? 13.sp
                          : (isTablet ? 12.sp : 12.sp);

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
                            selectedAmount = price;
                            selectedVariationCode = plan['variation_code']?.toString();
                          });

                          widget.onAmountSelected?.call(
                            price,
                            plan['variation_code']?.toString() ?? '',
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: cardHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              isTablet ? 20.r : 16.r,
                            ),
                            border: Border.all(
                              color: isSelected ? primaryColor : transparent,
                              width: isTablet ? 3.w : 2.w,
                            ),
                            image: DecorationImage(
                              image: AssetImage(
                                CablePlanConfig.getPlanImage(plan),
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                darkBackground.withValues(alpha: 0.25),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                isTablet ? 20.r : 16.r,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  darkBackground.withValues(alpha: 0.6),
                                  darkBackground.withValues(alpha: 0.2),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 14.w : 10.w,
                                      vertical: isTablet ? 4.h : 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: redAccent,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      'Hot',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: lightBackground,
                                        fontSize: isTablet ? 10.sp : 9.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  plan['name']?.toString() ?? 'Unknown Plan',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: lightBackground,
                                    fontSize: planNameFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isTablet ? 10.h : 6.h),
                                Text(
                                  '₦${_formatPrice(plan['variation_amount'])}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: primaryColor,
                                    fontSize: priceFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 10.h : 6.h),
                                Text(
                                  '₦20 Cashback',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: greenAccent,
                                    fontSize: cashbackFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 10.h : 6.h),
                                Text(
                                  CablePlanConfig.getPlanDescription(
                                    plan['variation_code'],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: lightBackground70,
                                    fontSize: descFontSize,
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
          ],
        );
      },
    );
  }
}