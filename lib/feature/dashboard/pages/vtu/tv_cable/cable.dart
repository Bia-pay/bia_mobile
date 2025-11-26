import 'package:bia/core/__core.dart';
import 'package:bia/core/constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CableTv extends StatefulWidget {
  const CableTv({super.key});
  static const String routeName = '/cableTv';

  @override
  State<CableTv> createState() => _CableTvState();
}

class _CableTvState extends State<CableTv> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeContext.grayWhiteBg,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(62.h(context)),
        child: Container(
          padding: padR(context, horizontal: 120.w(context)),
          color: context.themeContext.grayWhiteBg,
          alignment: Alignment.center,
          child: RRow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RRow(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      height: 45.h(context),
                      width: 100.w(context),
                      child: const Icon(Icons.arrow_back_ios),
                    ),
                  ),
                  5.hSpace(context),
                  Text(
                    'CableTv',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: padR(context, horizontal: 120.w(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ─── Top Header ───
                Container(
                  height: 50.h(context),
                  padding: padR(context, horizontal: 42),
                  decoration: BoxDecoration(
                    color: context.themeContext.offWhiteBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RImage('assets/svg/bank.png', height: 20.h(context)),
                      20.hSpace(context),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Constants.nairaCurrencySymbol}100',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.themeContext.kPrimary,
                                fontSize: 15.sp(context),
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
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.themeContext.secondaryTextColor,
                            ),
                          ),
                          10.hSpace(context),
                          Icon(
                            Icons.arrow_forward_ios_outlined,
                            size: 12.sp(context),
                            color: context.themeContext.secondaryTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                20.vSpace(context),

                /// ─── Card One ───
                const CardOne(),

                20.vSpace(context),

                /// ─── CableTv Service Section ───
                Container(
                  padding: padR(context, vertical: 17, horizontal: 35),
                  decoration: BoxDecoration(
                    color: context.themeContext.tertiaryBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CableTv Service',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      10.vSpace(context),
                    ],
                  ),
                ),

                20.vSpace(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── CARD ONE ───
class CardOne extends StatefulWidget {
  const CardOne({super.key});

  @override
  State<CardOne> createState() => _CardOneState();
}

class _CardOneState extends State<CardOne> {
  Map<String, dynamic>? _selectedProvider;
  String _smartcardNumber = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padR(context, vertical: 17, horizontal: 25),
      decoration: BoxDecoration(
        color: context.themeContext.tertiaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: padR(context, horizontal: 10),
        child: Column(
          children: [
            CableProviderDropdown(
              onChanged: (provider) {
                setState(() => _selectedProvider = provider);
              },
              onSmartcardChanged: (number) {
                setState(() => _smartcardNumber = number);
              },
            ),
            Divider(color: context.themeContext.lightGray),
            CableTvAmountSelector(
              selectedProvider: _selectedProvider,
              phoneNumber: _smartcardNumber,
              onAmountSelected: (amount) {
                print('Selected amount: ₦$amount');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── CABLE PROVIDER DROPDOWN ───
class CableProviderDropdown extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;
  final Function(String)? onSmartcardChanged;

  const CableProviderDropdown({
    super.key,
    this.onChanged,
    this.onSmartcardChanged,
  });

  @override
  State<CableProviderDropdown> createState() => _CableProviderDropdownState();
}

class _CableProviderDropdownState extends State<CableProviderDropdown> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'DStv', 'logo': 'assets/svg/dstv.png'},
    {'name': 'GOtv', 'logo': 'assets/svg/gotv.png'},
    {'name': 'Showmax', 'logo': 'assets/svg/showmax.png'},
    {'name': 'Startimes', 'logo': 'assets/svg/startimes.png'},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _smartcardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 2,
            fit: FlexFit.loose,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                padding: EdgeInsets.zero,
                isExpanded: false,
                alignment: Alignment.center,
                menuMaxHeight: 250,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                value: _selectedProvider,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black54,
                  size: 20,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _providers.map<Widget>((provider) {
                    return Container(
                      height: 24.h(context),
                      width: 24.h(context),
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
                      children: [
                        Container(
                          height: 30.h(context),
                          width: 30.h(context),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            image: DecorationImage(
                              image: AssetImage(provider['logo']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        8.hSpace(context),
                        Text(
                          provider['name'],
                          style: context.textTheme.labelSmall?.copyWith(
                            fontSize: 11.sp(context),
                            fontWeight: FontWeight.w600,
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

          // 📺 Smartcard Number Input — FULLY BORDERLESS
          Expanded(
            flex: 5,
            child: TextField(
              controller: _smartcardController,
              keyboardType: TextInputType.number,
              cursorColor: context.themeContext.kPrimary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter Smartcard Number',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isCollapsed: true,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                widget.onSmartcardChanged?.call(value);
              },
            ),
          ),

          135.hSpace(context),

          // 👤 Save/Beneficiary Icon
          Container(
            height: 30.h(context),
            width: 60.w(context),
            decoration: BoxDecoration(
              color: context.themeContext.kSecondary,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Icon(
              Icons.person_rounded,
              color: context.themeContext.kPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── CABLE TV SELECTOR (DSTV-style staggered grid) ───
class CableTvAmountSelector extends StatefulWidget {
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  const CableTvAmountSelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  State<CableTvAmountSelector> createState() => _CableTvAmountSelectorState();
}

class _CableTvAmountSelectorState extends State<CableTvAmountSelector>
    with SingleTickerProviderStateMixin {
  int? selectedAmount;

  final List<String> _tabs = ['Hot Offers', '1 Month', '2 Months', '3 Months'];
  late final TabController _tabController;

  final List<Map<String, dynamic>> hotOffers = [
    {
      'title': 'Yanga / month',
      'price': 6000,
      'cashback': '₦20 Cashback',
      'channels': 'Enjoy over 85+ channels, great movies, sports and more.',
      'image': 'assets/images/yanga.jpg',
      'tag': 'Hot',
    },
    {
      'title': 'Confam / month',
      'price': 11000,
      'cashback': '₦20 Cashback',
      'channels': 'Family time comes first with over 105+ channels, entertainment and sports.',
      'image': 'assets/images/confam.jpg',
    },
    {
      'title': 'Compact / month',
      'price': 19000,
      'cashback': '₦20 Cashback',
      'channels': 'Get your entertainment kicks with DStv Compact.',
      'image': 'assets/images/compact.png',
    },
    {
      'title': 'Padi / month',
      'price': 4400,
      'cashback': '₦20 Cashback',
      'channels': 'Enjoy over 45+ channels, thrilling Nollywood movies and dramas.',
      'image': 'assets/images/padi.jpg',
    },
    {
      'title': 'Compact Plus / month',
      'price': 26000,
      'cashback': '₦20 Cashback',
      'channels': 'Get more action with Premier League, movies and local series.',
      'image': 'assets/images/compact_plus.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: context.themeContext.kPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: context.themeContext.kPrimary,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),

        10.vSpace(context),

        SizedBox(
          height: 520.h(context),
          child: TabBarView(
            controller: _tabController,
            children: [
              // HOT OFFERS TAB (staggered grid)
              MasonryGridView.count(
                padding: padR(context, all: 10),
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: hotOffers.length,
                itemBuilder: (context, index) {
                  final plan = hotOffers[index];
                  final isSelected = selectedAmount == plan['price'];

                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedAmount = plan['price']);
                      widget.onAmountSelected?.call(plan['price']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: index.isEven ? 250.h(context) : 300.h(context),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? context.themeContext.kPrimary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        image: DecorationImage(
                          image: AssetImage(plan['image']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.25),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: padR(context, all: 20),
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
                            if (plan['tag'] == 'Hot')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Hot',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              plan['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            4.vSpace(context),
                            Text(
                              '₦${plan['price']}',
                              style: TextStyle(
                                color: context.themeContext.kPrimary,
                                fontSize: 14.sp(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            4.vSpace(context),
                            Text(
                              plan['cashback'],
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11.sp(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            4.vSpace(context),
                            Text(
                              plan['channels'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Center(child: Text('1 Month packages coming soon')),
              const Center(child: Text('2 Months packages coming soon')),
              const Center(child: Text('3 Months packages coming soon')),
            ],
          ),
        ),
      ],
    );
  }
}