import 'package:bia/app/utils/image.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/custom_textfiels_with_contact.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../send_money/widget/tabs.dart';

// ==================== RESPONSIVE HELPERS ====================

class ResponsiveConfig {
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide > 600;

  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.w;
    if (width > 600) return 24.w;
    return 16.w;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 320) return 3;
    if (width < 400) return 4;
    if (width > 600) return 6;
    return 4;
  }
}

// ==================== STATE PROVIDERS ====================

final airtimeFormProvider =
    StateNotifierProvider<AirtimeFormNotifier, AirtimeFormState>((ref) {
      return AirtimeFormNotifier();
    });

class AirtimeFormState {
  final Map<String, dynamic>? selectedProvider;
  final String phoneNumber;
  final int? amount;
  final bool isLoading;
  final String? error;

  const AirtimeFormState({
    this.selectedProvider,
    this.phoneNumber = '',
    this.amount,
    this.isLoading = false,
    this.error,
  });

  AirtimeFormState copyWith({
    Map<String, dynamic>? selectedProvider,
    String? phoneNumber,
    int? amount,
    bool? isLoading,
    String? error,
  }) {
    return AirtimeFormState(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isValid =>
      phoneNumber.length >= 10 &&
      amount != null &&
      amount! > 0 &&
      selectedProvider != null;
}

class AirtimeFormNotifier extends StateNotifier<AirtimeFormState> {
  AirtimeFormNotifier() : super(const AirtimeFormState());

  void setProvider(Map<String, dynamic> provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void setAmount(int amount) {
    state = state.copyWith(amount: amount);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clear() {
    state = const AirtimeFormState();
  }
}

// ==================== MAIN SCREEN ====================

class Airtime extends ConsumerStatefulWidget {
  const Airtime({super.key});

  @override
  ConsumerState<Airtime> createState() => _AirtimeState();
}

class _AirtimeState extends ConsumerState<Airtime> {
  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveConfig.isTablet(context);
    final padding = ResponsiveConfig.getPadding(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: CustomAppBar(
        title: 'Airtime',
        onBackPressed: () async {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          // Check if context is still valid before using it
          if (!context.mounted) return;

          if (context.canPop()) {
            context.pop();
          }
        },
        actions: [
          Padding(
            padding: EdgeInsets.only(right: padding),
            child: SvgPicture.asset(
              bell,
              width: isTablet ? 28.w : 24.w,
              height: isTablet ? 28.h : 24.h,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: padding,
                  ),
                  child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),
        const CardTwo(),
        SizedBox(height: 12.h),
        const CardOne(),
        SizedBox(height: 12.h),
        const CardThree(),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const CardTwo(),
                  SizedBox(height: 16.h),
                  const CardOne(),
                ],
              ),
            ),
            SizedBox(width: 20.w),
            const Expanded(flex: 1, child: CardThree()),
          ],
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}

// ==================== CARD TWO: NETWORK SELECTOR ====================

// ==================== CARD TWO: NETWORK SELECTOR ====================

class CardTwo extends ConsumerStatefulWidget {
  const CardTwo({super.key});

  @override
  ConsumerState<CardTwo> createState() => _CardTwoState();
}

class _CardTwoState extends ConsumerState<CardTwo> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'MTN', 'logo': 'assets/svg/mtn.jpg', 'id': 'mtn'},
    {'name': 'Airtel', 'logo': 'assets/svg/airtel.png', 'id': 'airtel'},
    {'name': 'Glo', 'logo': 'assets/svg/glo.jpg', 'id': 'glo'},
    {'name': '9mobile', 'logo': 'assets/svg/9mobile.png', 'id': '9mobile'},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();
  bool _isVerifying = false;
  String? _selectedContactName;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(airtimeFormProvider.notifier).setProvider(_selectedProvider!);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _detectNetwork(String input) {
    if (input.length < 4) return;
    final prefix = input.substring(0, 4);

    Map<String, dynamic>? detected;
    final mtnPrefixes = [
      '0803',
      '0806',
      '0703',
      '0706',
      '0813',
      '0816',
      '0810',
      '0814',
      '0903',
      '0906',
      '0913',
      '0916',
    ];
    final airtelPrefixes = [
      '0802',
      '0808',
      '0708',
      '0812',
      '0701',
      '0902',
      '0907',
      '0901',
      '0912',
      '0911',
    ];
    final gloPrefixes = [
      '0805',
      '0807',
      '0811',
      '0705',
      '0815',
      '0905',
      '0915',
    ];
    final etisalatPrefixes = ['0809', '0818', '0817', '0909', '0908'];

    if (mtnPrefixes.contains(prefix)) {
      detected = _providers.firstWhere(
        (p) => p['name'] == 'MTN',
        orElse: () => _providers.first,
      );
    } else if (airtelPrefixes.contains(prefix)) {
      detected = _providers.firstWhere(
        (p) => p['name'] == 'Airtel',
        orElse: () => _providers.first,
      );
    } else if (gloPrefixes.contains(prefix)) {
      detected = _providers.firstWhere(
        (p) => p['name'] == 'Glo',
        orElse: () => _providers.first,
      );
    } else if (etisalatPrefixes.contains(prefix)) {
      detected = _providers.firstWhere(
        (p) => p['name'] == '9mobile',
        orElse: () => _providers.first,
      );
    }

    if (detected != null && detected != _selectedProvider) {
      setState(() => _selectedProvider = detected);
      ref.read(airtimeFormProvider.notifier).setProvider(detected);
    }
  }

  void _onContactSelected(String phoneNumber, String? contactName) {
    setState(() => _selectedContactName = contactName);
    _detectNetwork(phoneNumber);
    ref.read(airtimeFormProvider.notifier).setPhoneNumber(phoneNumber);

    if (phoneNumber.length == 11) {
      _verifyPhoneNumber(phoneNumber);
    }

    if (contactName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: $contactName'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _verifyPhoneNumber(String phone) async {
    if (phone.length != 11) return;

    setState(() => _isVerifying = true);

    final result = await ref
        .read(dashboardControllerProvider.notifier)
        .verifyPhone(context, phone);

    setState(() => _isVerifying = false);

    if (result != null) {
      debugPrint('✅ Phone verified');
    } else {
      debugPrint('❌ Phone verification failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Responsive breakpoints
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isTablet = size.width > 600;

    // Responsive values
    final horizontalPadding = isSmall ? 10.w : (isTablet ? 24.w : 16.w);
    final verticalPadding = isSmall ? 10.h : (isTablet ? 24.h : 10.h);
    final borderRadius = isTablet ? 20.r : 16.r;
    final titleFontSize = isSmall ? 14.sp : (isTablet ? 20.sp : 16.sp);
    final innerPadding = isSmall ? 8.w : 12.w;
    final dividerHeight = isTablet ? 32.h : 24.h;
    final dropdownSize = isSmall ? 28.w : (isTablet ? 44.w : 36.w);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: whiteBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Center the column
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered title
          Text(
            'Select Service Provider',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: titleFontSize,
            ),
            // textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmall ? 12.h : 16.h),

          // Main input container - everything centered
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: innerPadding,
              vertical: isSmall ? 2.h : 2.h,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: grey300),
              borderRadius: BorderRadius.circular(borderRadius - 4.r),
              color: grey50,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center row contents
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Network Dropdown (left)
                _buildNetworkDropdown(isSmall, isTablet, dropdownSize),

                // Centered divider
                Container(
                  height: dividerHeight,
                  width: 1,
                  color: grey300,
                  margin: EdgeInsets.symmetric(horizontal: innerPadding),
                ),

                // Phone Input (centered, takes remaining space)
                Expanded(
                  child: Center(
                    child: CustomTextFieldWithContacts(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: isSmall ? 'Phone Number' : 'Enter Phone Number',
                      maxLength: 11,
                      onChanged: (value) {
                        setState(() => _selectedContactName = null);
                        _detectNetwork(value);
                        ref
                            .read(airtimeFormProvider.notifier)
                            .setPhoneNumber(value);
                        if (value.length == 11) {
                          _verifyPhoneNumber(value);
                        }
                      },
                      onContactSelected: _onContactSelected,
                    ),
                  ),
                ),

                // // Verification indicator (right, centered vertically)
                // if (_isVerifying)
                //   Padding(
                //     padding: EdgeInsets.only(left: innerPadding),
                //     child: Center(
                //       child: SizedBox(
                //         width: isSmall ? 16.w : 20.w,
                //         height: isSmall ? 16.h : 20.h,
                //         child: CircularProgressIndicator(
                //           strokeWidth: 2,
                //           valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                //         ),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),

          // Selected info row - centered
          if (_selectedProvider != null || _selectedContactName != null)
            Padding(
              padding: EdgeInsets.only(top: isSmall ? 10.h : 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedProvider != null) ...[
                    Container(
                      width: isSmall ? 8.w : 10.w,
                      height: isSmall ? 8.h : 10.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _selectedProvider!['name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmall ? 12.sp : 14.sp,
                      ),
                    ),
                  ],
                  if (_selectedContactName != null) ...[
                    if (_selectedProvider != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Container(
                          width: 4.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: grey400,
                          ),
                        ),
                      ),
                    Icon(
                      Icons.person_outline,
                      size: isSmall ? 14.sp : 16.sp,
                      color: grey600,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        _selectedContactName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: grey700,
                          fontWeight: FontWeight.w500,
                          fontSize: isSmall ? 12.sp : 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkDropdown(bool isSmall, bool isTablet, double size) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Map<String, dynamic>>(
        value: _selectedProvider,
        isDense: true,
        icon: Icon(
          Icons.arrow_drop_down,
          size: isSmall ? 20.sp : 24.sp,
          color: grey,
        ),
        selectedItemBuilder: (context) {
          return _providers.map((provider) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(provider['logo']),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList();
        },
        items: _providers.map((provider) {
          return DropdownMenuItem(
            value: provider,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSmall ? 24.w : (isTablet ? 36.w : 28.w),
                  height: isSmall ? 24.h : (isTablet ? 36.h : 28.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(provider['logo']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: isSmall ? 8.w : 12.w),
                Text(
                  provider['name'],
                  style: TextStyle(fontSize: isSmall ? 12.sp : 14.sp),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedProvider = value);
          ref.read(airtimeFormProvider.notifier).setProvider(value!);
        },
      ),
    );
  }
}

// ==================== CARD ONE: AMOUNT SELECTOR ====================

class CardOne extends ConsumerStatefulWidget {
  const CardOne({super.key});

  @override
  ConsumerState<CardOne> createState() => _CardOneState();
}

class _CardOneState extends ConsumerState<CardOne> {
  final TextEditingController _amountController = TextEditingController();
  final List<int> amounts = [50, 100, 200, 500, 1000, 2000, 5000, 10000];
  int? selectedAmount;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(airtimeFormProvider);
    final isSmall = ResponsiveConfig.isSmallScreen(context);
    final isTablet = ResponsiveConfig.isTablet(context);
    final crossAxisCount = ResponsiveConfig.getGridCrossAxisCount(context);

    return Container(
      padding: EdgeInsets.all(isSmall ? 10.w : (isTablet ? 20.w : 12.w)),
      decoration: BoxDecoration(
        color: lightSurface,
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 15.r),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 14.sp : (isTablet ? 18.sp : 16.sp),
            ),
          ),
          SizedBox(height: isSmall ? 12.h : 16.h),

          // Amount Input & Pay Button - Responsive Row
          Row(
            children: [
              Expanded(
                flex: isTablet ? 4 : 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: grey300),
                    borderRadius: BorderRadius.all(Radius.circular(10.r)),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: isSmall ? 14.sp : 16.sp),
                    onChanged: (value) {
                      final amount = int.tryParse(value);
                      if (amount != null) {
                        setState(() => selectedAmount = amount);
                        ref
                            .read(airtimeFormProvider.notifier)
                            .setAmount(amount);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      hintStyle: TextStyle(
                        color: grey400,
                        fontSize: isSmall ? 12.sp : 14.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isSmall ? 10.h : 12.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 8.w : 10.w),
              Expanded(
                flex: isTablet ? 1 : 1,
                child: CustomButton(
                  buttonName: 'PAY',
                  buttonColor: formState.isValid ? primaryColor : grey,
                  buttonTextColor: whiteBackground,
                  // height: isSmall ? 44.h : (isTablet ? 56.h : 48.h),
                  // fontSize: isSmall ? 12.sp : 14.sp,
                  onPressed: formState.isValid ? _handlePay : null,
                ),
              ),
            ],
          ),

          SizedBox(height: isSmall ? 16.h : 20.h),
          Text(
            'Quick Select',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: grey700,
              fontSize: isSmall ? 11.sp : 12.sp,
            ),
          ),
          SizedBox(height: isSmall ? 10.h : 12.h),

          // Responsive Amount Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = isSmall ? 8.w : 10.w;
              final runSpacing = isSmall ? 8.h : 10.h;
              final totalSpacing = spacing * (crossAxisCount - 1);
              final itemWidth =
                  (constraints.maxWidth - totalSpacing) / crossAxisCount;
              final itemHeight = isSmall ? 36.h : (isTablet ? 48.h : 40.h);

              return Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: amounts.map((amount) {
                  final isSelected = selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = amount;
                        _amountController.text = amount.toString();
                      });
                      ref.read(airtimeFormProvider.notifier).setAmount(amount);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: itemWidth,
                      height: itemHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : whiteBackground,
                        borderRadius: BorderRadius.circular(
                          isSmall ? 8.r : 10.r,
                        ),
                        border: Border.all(
                          color: isSelected ? primaryColor : grey300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            '₦$amount',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall
                                  ? 11.sp
                                  : (isTablet ? 14.sp : 13.sp),
                              color: isSelected
                                  ? whiteBackground
                                  : semiTransparentBlack,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handlePay() async {
    final formState = ref.read(airtimeFormProvider);

    if (!formState.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    final provider = formState.selectedProvider!;
    final amount = formState.amount!;
    final phone = formState.phoneNumber;

    ConfirmationBottomSheet.show(
      context: context,
      config: BottomSheetConfig(
        title: '${Constants.nairaCurrencySymbol}$amount.00',
        subtitle: 'Confirm Airtime Purchase',
        showCashback: true,
        amount: amount.toDouble(),
        cashbackAmount: '+${Constants.nairaCurrencySymbol}1 Cashback',
        details: [
          BottomSheetDetailItem(
            label: 'Network',
            value: provider['name'],
            logo: provider['logo'],
          ),
          BottomSheetDetailItem(label: 'Phone Number', value: phone),
          BottomSheetDetailItem(
            label: 'Amount',
            value: '${Constants.nairaCurrencySymbol}$amount.00',
          ),
        ],
      ),
      onConfirm: (pin) async {
        ref.read(airtimeFormProvider.notifier).setLoading(true);

        final result = await ref
            .read(dashboardControllerProvider.notifier)
            .buyAirtime(
              context,
              phone: phone,
              amount: amount,
              network: provider['id'],
              pin: pin,
            );

        ref.read(airtimeFormProvider.notifier).setLoading(false);

        // ✅ Guard with mounted check before using context
        if (!mounted) return;

        final isSuccess =
            result?.responseSuccessful == true ||
            result?.responseBody?.status == "SUCCESS";

        context.goNamed(
          RouteList.successScreen,
          extra: {
            "type": isSuccess ? "success" : "failed",
            "amount": amount.toString(),
            "recipientName": provider['name'],
            "recipientAccount": phone,
            "reference": result?.responseBody?.reference ?? '',
            "channel": "Airtime",
          },
        );
      },
    );
  }
}

// ==================== CARD THREE: BENEFICIARY ====================

class CardThree extends ConsumerStatefulWidget {
  const CardThree({super.key});

  @override
  ConsumerState<CardThree> createState() => _CardThreeState();
}

class _CardThreeState extends ConsumerState<CardThree> {
  @override
  Widget build(BuildContext context) {
    final isSmall = ResponsiveConfig.isSmallScreen(context);
    final isTablet = ResponsiveConfig.isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12.w : (isTablet ? 24.w : 20.w),
        vertical: isSmall ? 12.h : (isTablet ? 24.h : 16.h),
      ),
      decoration: BoxDecoration(
        color: whiteBackground,
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 15.r),
        boxShadow: [
          BoxShadow(
            color: darkBackground.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Beneficiary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 14.sp : (isTablet ? 18.sp : 16.sp),
            ),
          ),
          SizedBox(height: isSmall ? 10.h : 12.h),

          // Flexible height based on available space
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: isSmall ? 120.h : 150.h,
                maxHeight: isTablet ? 400.h : 250.h,
              ),
              child: BeneficiaryTabSection(
                favorites: const [
                  {"name": "Mustapha Garba", "account": "0123456789"},
                  {"name": "Aisha Bello", "account": "0145678901"},
                ],
                recents: const [
                  {"name": "Fatima Yusuf", "account": "0234567891"},
                  {"name": "John Musa", "account": "0345678912"},
                ],
                onSelectBeneficiary: (name, account) {
                  debugPrint('Selected $name - $account');
                  ref
                      .read(airtimeFormProvider.notifier)
                      .setPhoneNumber(account);
                },
                onSearchTap: () => debugPrint('Search tapped'),
                showProgress: false,
                showLogo: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkDropdown extends ConsumerStatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final ValueChanged<String>? onPhoneChanged;

  const NetworkDropdown({super.key, this.onChanged, this.onPhoneChanged});

  @override
  ConsumerState<NetworkDropdown> createState() => _NetworkDropdownState();
}

class _NetworkDropdownState extends ConsumerState<NetworkDropdown> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'mtn', 'logo': 'assets/svg/mtn.jpg'},
    {'name': 'airtel', 'logo': 'assets/svg/airtel.png'},
    {'name': 'glo', 'logo': 'assets/svg/glo.jpg'},
    {'name': '9mobile', 'logo': 'assets/svg/9mobile.png'},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
  }

  void _detectNetwork(String input) {
    if (input.length < 4) return;
    final prefix = input.substring(0, 4);

    Map<String, dynamic>? detected;
    if ([
      '0803',
      '0806',
      '0703',
      '0706',
      '0813',
      '0816',
      '0810',
      '0814',
      '0903',
      '0906',
    ].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'MTN');
    } else if ([
      '0802',
      '0808',
      '0708',
      '0812',
      '0701',
      '0902',
      '0907',
      '0901',
    ].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'Airtel');
    } else if ([
      '0805',
      '0807',
      '0811',
      '0705',
      '0815',
      '0905',
    ].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'Glo');
    } else if (['0809', '0818', '0817', '0909', '0908'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == '9mobile');
    }

    if (detected != null && detected != _selectedProvider) {
      setState(() => _selectedProvider = detected);
      widget.onChanged?.call(detected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          border: Border.all(
            //color: Theme.of(context)Context.checkboxBorderColor
          ),
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
        child: Row(
          children: [
            /// 🔹 Dropdown
            Flexible(
              flex: 2,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedProvider,
                  // dropdownColor: themeContext.offWhiteBg,
                  borderRadius: BorderRadius.circular(10.r),
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    // color: themeContext.secondaryTextColor, size: 20.sp
                  ),
                  selectedItemBuilder: (_) {
                    return _providers.map((provider) {
                      return Container(
                        height: 24.h,
                        width: 24.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(provider['logo']),
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  items: _providers.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Row(
                        children: [
                          Container(
                            height: 28.h,
                            width: 28.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              image: DecorationImage(
                                image: AssetImage(provider['logo']),
                                fit: BoxFit.cover,
                              ),
                            ),
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

            /// 👤 Icon
            SvgPicture.asset('assets/svg/line.svg'),
            SizedBox(width: 10.w),

            /// 📞 Input field
            Expanded(
              flex: 5,
              child: CustomTextField(
                hint: 'Enter Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  widget.onPhoneChanged?.call(value);
                  _detectNetwork(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AirtimeAmountSelector extends ConsumerStatefulWidget {
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  const AirtimeAmountSelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  ConsumerState<AirtimeAmountSelector> createState() =>
      _AirtimeAmountSelectorState();
}

class _AirtimeAmountSelectorState extends ConsumerState<AirtimeAmountSelector> {
  final TextEditingController _amountController = TextEditingController();

  final List<int> amounts = [50, 100, 200, 500, 1000, 2000];
  final List<String> cashback = [
    '+₦1 Cashback',
    '+₦2 Cashback',
    '+₦3 Cashback',
    '+₦4 Cashback',
    '+₦5 Cashback',
    '+₦10 Cashback',
  ];

  int? selectedAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 💰 Amount Grid (matching your image layout)
        Text(
          'Enter Amount',
          textAlign: TextAlign.start,
          // style: textTheme.titleMedium?.copyWith(
          //   fontWeight: FontWeight.w600,
          // ),
        ),
        SizedBox(height: 10.h),

        /// 🔹 Pay Button
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      //  color: Theme.of(context)Context.checkboxBorderColor
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10.r)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// 📞 Input field
                      Expanded(
                        child: CustomTextField(
                          hint: 'Phone Number',
                          controller: _amountController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: CustomButton(
                buttonName: 'PAY',
                buttonColor: primaryColor,
                buttonTextColor: whiteBackground,
                onPressed: () async {
                  FocusScope.of(context).unfocus();  // Dismiss keyboard first
                  await Future.delayed(const Duration(milliseconds: 150));  // Wait for animation
                  if (!context.mounted) return;
                  if (context.canPop()) {
                    context.pop();
                  }
                  final result = await ref
                      .read(dashboardControllerProvider.notifier)
                      .buyAirtime(
                        context,
                        phone: widget.phoneNumber ?? "",
                        amount: selectedAmount ?? 0,
                        network: widget.selectedProvider?['name'] ?? "mtn",
                        pin: "1234",
                      );

                  if (result != null && result.responseSuccessful) {
                    // ✅ Guard with context.mounted check
                    if (!context.mounted) return;

                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          'Select Amount',
          textAlign: TextAlign.start,
          // style: textTheme.titleMedium?.copyWith(
          //   fontWeight: FontWeight.w600,
          // ),
        ),
        SizedBox(height: 10.h),

        /// 🔹 Clean grid layout
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 40.w) / 4;

            return Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: List.generate(amounts.length, (index) {
                final amount = amounts[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAmount = amount;
                      _amountController.text = amount.toString();
                    });
                    widget.onAmountSelected?.call(amount);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: itemWidth,
                    height: 50.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: whiteBackground,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(width: 1.3),
                    ),
                    child: Text(
                      '₦$amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        SizedBox(height: 25.h),
      ],
    );
  }
}

class BeneficiarySelector extends ConsumerStatefulWidget {
  const BeneficiarySelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  @override
  ConsumerState<BeneficiarySelector> createState() =>
      _BeneficiarySelectorState();
}

class _BeneficiarySelectorState extends ConsumerState<BeneficiarySelector> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Beneficiary'),

              SizedBox(height: 10.h),

              Expanded(
                child: BeneficiaryTabSection(
                  favorites: const [
                    {"name": "Mustapha Garba", "account": "0123456789"},
                    {"name": "Aisha Bello", "account": "0145678901"},
                  ],
                  recents: const [
                    {"name": "Fatima Yusuf", "account": "0234567891"},
                    {"name": "John Musa", "account": "0345678912"},
                    {"name": "Fatima Yusuf", "account": "0234567891"},
                    {"name": "John Musa", "account": "0345678912"},
                  ],
                  onSelectBeneficiary: (name, account) {
                    debugPrint('Selected $name - $account');
                  },
                  onSearchTap: () => debugPrint('Search tapped'),
                  showProgress: false,
                  showLogo: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
