import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

class CableTv extends StatefulWidget {
  const CableTv({super.key});

  @override
  State<CableTv> createState() => _CableTvState();
}

class _CableTvState extends State<CableTv> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Cable',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/svg/bank.png', height: 20),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Constants.nairaCurrencySymbol}100',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '(1)',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                const CardOne(),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 17, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CableTv Service',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
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
  Map<String, dynamic>? _selectedProvider;
  String _smartcardNumber = '';
  List<Map<String, dynamic>> _plans = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 17, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        children: [
          CableProviderDropdown(
            onChanged: (provider) async {
              setState(() => _selectedProvider = provider);

              final controller = ref.read(dashboardControllerProvider.notifier);
              final plans = await controller.fetchCablePlans(
                context,
                provider['serviceID'],
              );

              setState(() {
                _plans = plans;
              });
            },
            onSmartcardChanged: (number) {
              setState(() => _smartcardNumber = number);
            },
          ),
          Divider(color: Colors.grey.shade300),
          CableTvAmountSelector(
            selectedProvider: _selectedProvider,
            phoneNumber: _smartcardNumber,
            plans: _plans,
              onAmountSelected: (amount, variationCode) async {
                final controller = ref.read(dashboardControllerProvider.notifier);

                final result = await controller.verifyCable(
                  context,
                  serviceId: _selectedProvider!['serviceID'],
                  smartcard: _smartcardNumber,
                );
                if (variationCode.isEmpty) {
                  print("❌ variationCode is empty");
                  return;
                }
                if (result == null) return;

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
                        value: result['Customer_Name'],
                      ),
                      BottomSheetDetailItem(
                        label: "Variation Code", // ✅ CRITICAL
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
                        value: _selectedProvider!['serviceID'], // ✅ CRITICAL
                      ),
                    ],
                  ),
                  onConfirm: (pin) {},
                );
              }
          ),
        ],
      ),
    );
  }
}

class CableProviderDropdown extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;
  final Function(String)? onSmartcardChanged;

  const CableProviderDropdown({
    super.key,
    this.onChanged,
    this.onSmartcardChanged,
  });

  @override
  ConsumerState<CableProviderDropdown> createState() => _CableProviderDropdownState();
}

class _CableProviderDropdownState extends ConsumerState<CableProviderDropdown> {
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;
  bool isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders() async {
    final controller = ref.read(dashboardControllerProvider.notifier);
    final result = await controller.fetchCableProviders(context);

    setState(() {
      _providers = result;
      _selectedProvider = _providers.isNotEmpty ? _providers.first : null;
      isLoading = false;
    });

    if (_selectedProvider != null) {
      widget.onChanged?.call(_selectedProvider!);
    }
  }

  String getProviderLogo(String name) {
    switch (name.toLowerCase()) {
      case 'dstv':
        return 'assets/svg/logo.png';
      case 'gotv':
        return 'assets/svg/logo.png';
      case 'startimes':
        return 'assets/svg/logo.png';
      case 'showmax':
        return 'assets/svg/logo.png';
      default:
        return 'assets/svg/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_providers.isEmpty) {
      return const Text("No providers available");
    }

    return Row(
      children: [
        DropdownButton<Map<String, dynamic>>(
          value: _selectedProvider,
          items: _providers.map((provider) {
            return DropdownMenuItem(
              value: provider,
              child: Row(
                children: [
                  Image.asset(
                    getProviderLogo(provider['name']),
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(provider['name']),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedProvider = value);
            widget.onChanged?.call(value!);
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Smartcard Number',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onSmartcardChanged,
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

  late TabController _tabController;
  int? selectedAmount;
  String? selectedVariationCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didUpdateWidget(CableTvAmountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedProvider?['serviceID'] !=
        widget.selectedProvider?['serviceID']) {
      selectedAmount = null;
      selectedVariationCode = null;
    }

    final oldExtracted = _extractPlans(oldWidget.plans);
    final newExtracted = _extractPlans(widget.plans);

    if (oldExtracted.length != newExtracted.length && newExtracted.isNotEmpty) {
      final newTabs = _buildTabs();
      final newLength = newTabs.length;

      if (newLength != _tabController.length) {
        final oldIndex = _tabController.index;
        _tabController.dispose();
        _tabController = TabController(
          length: newLength,
          vsync: this,
          initialIndex: oldIndex < newLength ? oldIndex : 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Extract plans from nested API response
  List<Map<String, dynamic>> get _plans {
    return _extractPlans(widget.plans);
  }

  List<Map<String, dynamic>> _extractPlans(List<Map<String, dynamic>> rawPlans) {
    if (rawPlans.isEmpty) return [];

    final first = rawPlans.first;

    // Check if it's the raw API response with responseBody
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

    // Already flat structure
    return rawPlans;
  }

  String _extractDuration(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('1 year') || lower.contains('year')) return '1 Year';
    if (lower.contains('3 month') || lower.contains('3months')) return '3 Months';
    if (lower.contains('weekly') || lower.contains('1 week')) return 'Weekly';
    if (lower.contains('month') || lower.contains('monthly')) return 'Monthly';
    return 'Monthly';
  }

  String _getPlanImage(Map<String, dynamic> plan) {
    final code = plan['variation_code']?.toString().toLowerCase() ?? '';

    if (code.contains('padi')) return 'assets/images/padi.jpg';
    if (code.contains('yanga')) return 'assets/images/yanga.jpg';
    if (code.contains('confam')) return 'assets/images/confam.jpg';
    if (code.contains('compact') && code.contains('plus')) return 'assets/images/compact_plus.png';
    if (code.contains('compact')) return 'assets/images/compact.png';
    if (code.contains('premium')) return 'assets/images/premium.jpg';
    if (code.contains('asia')) return 'assets/images/asia.jpg';
    if (code.contains('french')) return 'assets/images/french.jpg';
    if (code.contains('jolli')) return 'assets/images/yanga.jpg';
    if (code.contains('jinja')) return 'assets/images/padi.jpg';
    if (code.contains('max')) return 'assets/images/compact.png';
    if (code.contains('supa')) return 'assets/images/compact_plus.png';
    if (code.contains('lite')) return 'assets/images/padi.jpg';

    return 'assets/images/compact.png';
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

  String _getPlanDescription(String? code) {
    final descriptions = {
      'dstv-padi': 'Enjoy over 45+ channels, thrilling Nollywood movies and dramas.',
      'dstv-yanga': 'Enjoy over 85+ channels, great movies, sports and more.',
      'dstv-confam': 'Family time comes first with over 105+ channels, entertainment and sports.',
      'dstv79': 'Get your entertainment kicks with DStv Compact.',
      'dstv3': 'Premium entertainment with 175+ channels.',
      'dstv6': 'Asian content and entertainment.',
      'dstv7': 'Get more action with Premier League, movies and local series.',
      'dstv9': 'Premium French content and entertainment.',
      'gotv-jolli': 'Great entertainment for the whole family.',
      'gotv-jinja': 'Affordable entertainment with great channels.',
      'gotv-max': 'Maximum entertainment experience.',
      'gotv-lite': 'Basic entertainment at affordable price.',
      'gotv-supa-plus': 'Supa plus entertainment package.',
    };
    return descriptions[code?.toLowerCase()] ??
        'Enjoy great entertainment with premium channels.';
  }

  String _formatPrice(dynamic amount) {
    if (amount == null) return '0';
    final str = amount.toString();
    // Remove trailing .00 or .0
    if (str.contains('.')) {
      final parts = str.split('.');
      if (parts[1] == '00' || parts[1] == '0') {
        return parts[0];
      }
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();

    if (_plans.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Select a provider to see available plans')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 520,
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((tab) {
              List<Map<String, dynamic>> displayPlans;
              if (tab == 'Hot Offers') {
                displayPlans = _plans;
              } else {
                displayPlans = _plans.where((p) =>
                _extractDuration(p['name']?.toString() ?? '') == tab
                ).toList();
              }

              if (displayPlans.isEmpty) {
                return const Center(child: Text('No packages available'));
              }

              return MasonryGridView.count(
                padding: const EdgeInsets.all(10),
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: displayPlans.length,
                itemBuilder: (context, index) {
                  final plan = displayPlans[index];
                  final price = double.tryParse(plan['variation_amount']?.toString() ?? '0')?.toInt() ?? 0;
                  final isSelected = selectedVariationCode == plan['variation_code'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = price;
                        selectedVariationCode = plan['variation_code']?.toString();
                      });
                      widget.onAmountSelected?.call(
                          price,
                          plan['variation_code']?.toString() ?? ''
                      );                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: index.isEven ? 250 : 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 1.5,
                        ),
                        image: DecorationImage(
                          image: AssetImage(_getPlanImage(plan)),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.25),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.2),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Hot',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              plan['name']?.toString() ?? 'Unknown Plan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // FIXED: Use _formatPrice to handle the amount properly
                            Text(
                              '₦${_formatPrice(plan['variation_amount'])}',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '₦20 Cashback',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPlanDescription(plan['variation_code']?.toString()),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
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
  }
}