import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/custom_loader.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/utils/widgets/toast_helper.dart';
import '../../../../../app/view/widget/custom_textfiels_with_contact.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

// ─── PROVIDERS ───────────────────────────────────────────────────────────────

final List<Map<String, dynamic>> _kProviders = [
  {'name': 'MTN',     'logo': 'assets/svg/mtn.jpg',     'serviceId': 'mtn-data',      'color': const Color(0xFFFFCC00)},
  {'name': 'Airtel',  'logo': 'assets/svg/airtel.png',  'serviceId': 'airtel-data',   'color': const Color(0xFFE40000)},
  {'name': 'Glo',     'logo': 'assets/svg/glo.jpg',     'serviceId': 'glo-data',      'color': const Color(0xFF00A651)},
  {'name': '9mobile', 'logo': 'assets/svg/9mobile.png', 'serviceId': 'etisalat-data', 'color': const Color(0xFF006633)},
];

const Map<String, String> _kServiceIds = {
  'MTN':     'mtn-data',
  'Airtel':  'airtel-data',
  'Glo':     'glo-data',
  '9mobile': 'etisalat-data',
};

double _getWalletBalance() {
  final box = Hive.box('authBox');
  return double.tryParse(box.get('balance', defaultValue: '0').toString().replaceAll(',', '')) ?? 0.0;
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class Data extends ConsumerStatefulWidget {
  const Data({super.key});
  static const String routeName = '/data';

  @override
  ConsumerState<Data> createState() => _DataState();
}

class _DataState extends ConsumerState<Data> with SingleTickerProviderStateMixin {
  // Selection state
  Map<String, dynamic> _selectedProvider = _kProviders.first;
  String _phoneNumber = '';
  Map<String, dynamic>? _selectedPlan;

  // Plan data
  List<Map<String, dynamic>> _smePlans = [];
  bool _loadingPlans = true;

  // Tabs
  late final TabController _tabController;
  final List<String> _tabs = ['SME', 'Gifting', 'Corporate', 'Hot', 'Exclusive'];

  // Controllers
  final TextEditingController _phoneController = TextEditingController();

  // Amount (auto-filled from selected plan)
  int _selectedAmount = 0;
  bool _insufficientFunds = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Trigger provider init
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _loadPlans([String? serviceId]) async {
    if (!mounted) return;
    setState(() {
      _smePlans = [];
      _loadingPlans = true;
    });
    try {
      final sId = serviceId ?? _selectedProvider['serviceId'] ?? 'mtn-data';
      final result = await ref
          .read(dashboardControllerProvider.notifier)
          .fetchDataPlans(context, sId);

      if (!mounted) return;

      debugPrint("ℹ️ Fetch data plans count: ${result.length}");

      final formatted = result.map((plan) {
        int price = plan.amount;
        if (price == 0) price = _extractPriceFromName(plan.name);
        return {
          'data':           _extractData(plan.name),
          'price':          price,
          'duration':       _extractDuration(plan.name),
          'variation_code': plan.variationCode,
          'name':           plan.name,
        };
      }).where((e) => (e['price'] as int) > 0).toList();

      debugPrint("ℹ️ Mapped and filtered plans count: ${formatted.length}");

      setState(() {
        _smePlans = formatted;
        _loadingPlans = false;
      });
    } catch (e) {
      debugPrint("🔥 Widget load plans error: $e");
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  void _detectNetwork(String input) {
    if (input.length < 4) return;
    final prefix = input.substring(0, 4);
    Map<String, dynamic>? detected;

    if (['0803','0806','0703','0706','0813','0816','0903','0906','0913','0916'].contains(prefix)) {
      detected = _kProviders.firstWhere((p) => p['name'] == 'MTN');
    } else if (['0802','0808','0812','0701','0902','0901','0904','0907','0912'].contains(prefix)) {
      detected = _kProviders.firstWhere((p) => p['name'] == 'Airtel');
    } else if (['0805','0807','0811','0705','0905','0915'].contains(prefix)) {
      detected = _kProviders.firstWhere((p) => p['name'] == 'Glo');
    } else if (['0809','0818','0817','0909','0908'].contains(prefix)) {
      detected = _kProviders.firstWhere((p) => p['name'] == '9mobile');
    }

    if (detected != null && detected['name'] != _selectedProvider['name']) {
      setState(() {
        _selectedProvider = detected!;
        _selectedPlan = null;
        _selectedAmount = 0;
      });
      _loadPlans(detected['serviceId']);
    }
  }

  void _selectPlan(Map<String, dynamic> plan) {
    HapticFeedback.selectionClick();
    final price = plan['price'] as int;
    final balance = _getWalletBalance();
    setState(() {
      _selectedPlan = plan;
      _selectedAmount = price;
      _insufficientFunds = price > balance;
    });
  }

  bool get _isFormValid {
    final hasPhone   = _phoneNumber.length == 11;
    final hasPlan    = _selectedPlan != null;
    final hasAmount  = _selectedAmount > 0;
    final hasBalance = _selectedAmount <= _getWalletBalance();
    return hasPhone && hasPlan && hasAmount && hasBalance && !_insufficientFunds;
  }

  Future<void> _handlePurchase() async {
    if (_phoneNumber.length < 11) {
      _toast('Enter a valid 11-digit phone number');
      return;
    }
    if (_selectedPlan == null) {
      _toast('Please select a data plan');
      return;
    }

    final serviceId = _kServiceIds[_selectedProvider['name']] ?? 'mtn-data';
    final String variationCode =
        _selectedPlan!['variation_code']?.toString().isNotEmpty == true
            ? _selectedPlan!['variation_code']
            : '$serviceId-$_selectedAmount';

    ConfirmationBottomSheet.show(
      context: context,
      config: BottomSheetConfig(
        title: '₦$_selectedAmount.00',
        subtitle: 'Confirm Data Purchase',
        showCashback: true,
        amount: _selectedAmount.toDouble(),
        cashbackAmount: '+₦1 Cashback',
        details: [
          BottomSheetDetailItem(
            label: 'Network',
            value: _selectedProvider['name'],
            logo: _selectedProvider['logo'],
          ),
          BottomSheetDetailItem(label: 'Phone Number', value: _phoneNumber),
          BottomSheetDetailItem(label: 'Amount', value: '₦$_selectedAmount.00'),
          BottomSheetDetailItem(
            label: 'Data Plan',
            value: _selectedPlan!['data']?.toString().isNotEmpty == true
                ? '${_selectedPlan!['data']} — ₦$_selectedAmount'
                : variationCode,
          ),
          // Hidden from UI, used by bottom sheet for PIN screen navigation
          BottomSheetDetailItem(label: 'Variation Code', value: variationCode),
          BottomSheetDetailItem(label: 'serviceId', value: serviceId),
        ],
      ),
      onConfirm: (pin) async {
        if (pin.length != 4) { _toast('PIN must be 4 digits'); return; }

        EasyLoading.show(
          indicator: const CustomLoader(),
          maskType: EasyLoadingMaskType.black,
          dismissOnTap: false,
        );

        final response = await ref
            .read(dashboardControllerProvider.notifier)
            .buyData(context,
              phone:         _phoneNumber,
              serviceId:     serviceId,
              variationCode: variationCode,
              amount:        _selectedAmount,
              pin:           pin,
            );

        EasyLoading.dismiss();

        if (response == null) { _toast('No response from server. Try again.'); return; }

        if (!context.mounted) return;

        final extra = {
          'amount':          _selectedAmount.toString(),
          'recipientName':   _selectedProvider['name'],
          'recipientAccount': _phoneNumber,
          'reference':       response.responseBody?.reference ?? '',
          'channel':         'Data Purchase',
          'date':            DateTime.now().toIso8601String(),
        };

        if (response.responseSuccessful == true) {
          context.goNamed(RouteList.successScreen, extra: {'type': 'success', ...extra});
        } else if (response.responseMessage?.toLowerCase().contains('pending') == true) {
          context.goNamed(RouteList.successScreen, extra: {'type': 'pending', ...extra});
        } else if (response.responseMessage?.toLowerCase().contains('insufficient') == true) {
          _toast('Insufficient wallet balance. Please fund your wallet.');
        } else if (response.statusCode == 401) {
          _toast('Session expired. Please login again.');
        } else {
          context.goNamed(RouteList.successScreen, extra: {'type': 'failed', ...extra, 'message': response.responseMessage ?? 'Transaction failed'});
        }
      },
    );
  }

  void _toast(String msg) => ToastHelper.showToast(
    context: context, message: msg,
    icon: Icons.error, iconColor: errorColor, position: ToastPosition.top,
  );

  // ── Helpers ────────────────────────────────────────────────────────────────


  int _extractPriceFromName(String name) {
    final m = RegExp(r'(?:[₦N]\s*([\d,]+)|([\d,]+)\s*(?:Naira|N))', caseSensitive: false).firstMatch(name);
    if (m != null) {
      final val = m.group(1) ?? m.group(2);
      if (val != null) {
        return int.tryParse(val.replaceAll(',', '')) ?? 0;
      }
    }
    return 0;
  }

  String _extractData(String name) {
    final m = RegExp(r'(\d+(\.\d+)?\s?(GB|MB))', caseSensitive: false).firstMatch(name);
    return m?.group(0) ?? '';
  }

  String _extractDuration(String name) {
    final m = RegExp(r'(\d+\s?(day|days|month|months))', caseSensitive: false).firstMatch(name);
    return m?.group(0)?.toUpperCase() ?? '30 DAYS';
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final balance = _getWalletBalance();
    final providerColor = _selectedProvider['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverAppBar(
            expandedHeight: 180.h,
            pinned: true,
            backgroundColor: primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (context.canPop()) context.pop();
              },
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 18.w),
                child: SvgPicture.asset(bell, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0C284E),
                      primaryColor,
                      primaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 56.h, 24.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Buy Data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        // Wallet Balance chip
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withValues(alpha: 0.8), size: 14.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'Balance: ₦${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Network Provider ──────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(icon: Icons.cell_tower_rounded, label: 'Select Network'),
                      SizedBox(height: 14.h),
                      Row(
                        children: _kProviders.map((p) {
                          final isSelected = _selectedProvider['name'] == p['name'];
                          final pColor = p['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (_selectedProvider['name'] == p['name']) return;
                                setState(() {
                                  _selectedProvider = p;
                                  _selectedPlan = null;
                                  _selectedAmount = 0;
                                });
                                _loadPlans(p['serviceId']);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? pColor.withValues(alpha: 0.12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected ? pColor : const Color(0xFFE8ECF0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 38.r,
                                      height: 38.r,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage(p['logo']),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: isSelected ? [
                                          BoxShadow(color: pColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                        ] : [],
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      p['name'],
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? pColor : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Phone Number ──────────────────────────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(icon: Icons.phone_rounded, label: 'Phone Number'),
                      SizedBox(height: 12.h),
                      CustomTextFieldWithContacts(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hint: 'Enter 11-digit phone number',
                        maxLength: 11,
                        onChanged: (value) {
                          _detectNetwork(value);
                          setState(() => _phoneNumber = value);
                        },
                        onContactSelected: (phone, name) {
                          _phoneController.text = phone;
                          _detectNetwork(phone);
                          setState(() => _phoneNumber = phone);
                        },
                      ),
                      // Auto-detect indicator
                      if (_phoneNumber.length >= 4) ...[
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Container(
                              width: 18.r,
                              height: 18.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(_selectedProvider['logo']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${_selectedProvider['name']} detected',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.check_circle_rounded, color: primaryColor, size: 13.sp),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Plan Selector ─────────────────────────────────────────────
                _SectionCard(
                  padding: EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                        child: _SectionLabel(icon: Icons.data_usage_rounded, label: 'Choose a Plan'),
                      ),
                      SizedBox(height: 4.h),

                      // Tab bar
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: primaryColor,
                        unselectedLabelColor: const Color(0xFF94A3B8),
                        indicatorColor: primaryColor,
                        indicatorWeight: 2.5,
                        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        tabs: _tabs.map((e) => Tab(text: e)).toList(),
                      ),

                      // Plan grid
                      SizedBox(
                        height: 240.h,
                        child: TabBarView(
                          controller: _tabController,
                          children: _tabs.map((tabName) {
                            if (tabName == 'SME' && _loadingPlans) {
                              return Center(
                                child: PulsingLogoIndicator(
                                  logoPath: 'assets/svg/logo.png',
                                  size: 36,
                                  pulseColor: primaryColor,
                                ),
                              );
                            }
                            final plans = tabName == 'SME' ? _smePlans : <Map<String, dynamic>>[];
                            if (plans.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_empty_rounded, size: 36, color: grey300),
                                    SizedBox(height: 8.h),
                                    Text(
                                      tabName == 'SME' ? 'No plans available' : '$tabName plans coming soon',
                                      style: TextStyle(color: grey, fontSize: 13.sp, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: EdgeInsets.all(10.r),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8.r,
                                mainAxisSpacing: 8.r,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: plans.length,
                              itemBuilder: (ctx, i) {
                                final plan = plans[i];
                                final isSelected = _selectedPlan != null &&
                                    _selectedPlan!['variation_code'] == plan['variation_code'];
                                return _PlanCard(
                                  plan: plan,
                                  isSelected: isSelected,
                                  providerColor: providerColor,
                                  onTap: () => _selectPlan(plan),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Selected Plan Summary ─────────────────────────────────────
                if (_selectedPlan != null) ...[
                  SizedBox(height: 12.h),
                  _SelectedPlanSummary(
                    plan: _selectedPlan!,
                    providerColor: providerColor,
                    providerName: _selectedProvider['name'],
                    insufficient: _insufficientFunds,
                    balance: _getWalletBalance(),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),

      // ── Floating PAY Button ───────────────────────────────────────────────
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isFormValid || _selectedPlan != null ? 88.h : 0,
        child: OverflowBox(
          maxHeight: 88.h,
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isFormValid ? 1.0 : 0.45,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _handlePurchase : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: grey300,
                    elevation: _isFormValid ? 4 : 0,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 18),
                      SizedBox(width: 6.w),
                      Text(
                        _selectedPlan != null
                            ? 'Pay ₦$_selectedAmount'
                            : 'Select a Plan to Continue',
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 15.sp),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final Color providerColor;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.providerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: isSelected ? providerColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? providerColor : const Color(0xFFE8ECF0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: providerColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Data size badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isSelected ? providerColor.withValues(alpha: 0.15) : const Color(0xFFEDF2FF),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                plan['data']?.toString().isNotEmpty == true ? plan['data'] : '—',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? providerColor : const Color(0xFF3B82F6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 5.h),
            // Price
            Text(
              '₦${plan['price']}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: isSelected ? providerColor : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3.h),
            // Duration
            Text(
              plan['duration'] ?? '',
              style: TextStyle(
                fontSize: 8.sp,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              SizedBox(height: 4.h),
              Icon(Icons.check_circle_rounded, color: providerColor, size: 14.sp),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedPlanSummary extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Color providerColor;
  final String providerName;
  final bool insufficient;
  final double balance;

  const _SelectedPlanSummary({
    required this.plan,
    required this.providerColor,
    required this.providerName,
    required this.insufficient,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: insufficient
            ? const Color(0xFFFEE2E2)
            : providerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: insufficient
              ? errorColor.withValues(alpha: 0.3)
              : providerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: insufficient ? errorColor.withValues(alpha: 0.1) : providerColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              insufficient ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: insufficient ? errorColor : providerColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insufficient ? 'Insufficient Balance' : 'Plan Selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: insufficient ? errorColor : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  insufficient
                      ? 'Your balance ₦${balance.toStringAsFixed(0)} is less than ₦${plan['price']}'
                      : '${plan['data']} for $providerName · ${plan['duration']}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: insufficient ? errorColor.withValues(alpha: 0.8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₦${plan['price']}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15.sp,
              color: insufficient ? errorColor : providerColor,
            ),
          ),
        ],
      ),
    );
  }
}
