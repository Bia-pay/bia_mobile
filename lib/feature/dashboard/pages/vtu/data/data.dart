import 'package:bia/app/utils/colors.dart';
import 'package:bia/app/utils/colors.dart';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../widgets/transaction.dart';
import '../airtime/airtime.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Data extends StatefulWidget {
  const Data({super.key});
  static const String routeName = '/data';

  @override
  State<Data> createState() => _DataState();
}

class _DataState extends State<Data> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(62.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          color: lightBackground,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      height: 45.h,
                      width: 100.w,
                      child: const Icon(Icons.arrow_back_ios),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
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

      /// ✅ FIXED BODY (scrollable)
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ─── Card One ───
                const CardTwo(),
                SizedBox(height: 20.h),
                const CardOne(),
                SizedBox(height: 20.h),
                const CardThree(),

                SizedBox(height: 20.h),

                /// ─── Data Service Section ───
                Container(
                  padding: EdgeInsets.symmetric(vertical: 17, horizontal: 10),
                  decoration: BoxDecoration(
                    // color: Theme.of(context)Context.tertiaryBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Service',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      SizedBox(
                        height: 180.h,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 0,
                          ),
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: dataPlans.length,
                          itemBuilder: (context, index) {
                            final tx = dataPlans[index];
                            return Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 18,
                              ),
                              margin: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 7,
                              ),
                              height: 70.h,
                              decoration: BoxDecoration(
                                //color: Theme.of(context)Context.kSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 35.h,
                                    width: 35.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: primaryColor),
                                    ),
                                    child: Image.asset(
                                      'assets/svg/bank.png',
                                      height: 20.h,
                                    ),
                                  ),
                                  SizedBox(width: 15.h),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.name,
                                          style: Theme.of(context).textTheme.bodyMedium
                                              ?.copyWith(
                                                // color: context
                                                //     .themeContext.titleTextColor,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          tx.dateTime,
                                          style: Theme.of(context).textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 11.sp,
                                                // color: Theme.of(context)Context
                                                //     .secondaryTextColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 12.sp,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25.h),
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
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;
  const CardOne({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  State<CardOne> createState() => _CardOneState();
}

class _CardOneState extends State<CardOne> {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 17, horizontal: 25),
      decoration: BoxDecoration(
        // color: Theme.of(context)Context.tertiaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
                          //color: Theme.of(context)Context.checkboxBorderColor
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
                SizedBox(width: 5.w),
                Expanded(
                  child: CustomButton(
                    buttonName: 'PAY',
                    buttonColor: Colors.lightBlueAccent,
                    buttonTextColor: Colors.white,
                    onPressed: () {
                      final amountText = _amountController.text.trim();
                      if (amountText.isEmpty) return;
                      final amount = int.tryParse(amountText) ?? 0;

                      showAirtimeConfirmationSheet(
                        context,
                        amount: amount,
                        networkName: widget.selectedProvider?['name'] ?? 'MTN',
                        networkLogo:
                            widget.selectedProvider?['logo'] ??
                            'assets/svg/mtn.jpg',
                        recipientNumber: widget.phoneNumber ?? '',
                      );
                    },
                  ),
                ),
              ],
            ),
            DataAmountSelector(
              selectedProvider: _selectedProvider,
              phoneNumber: _phoneNumber,
              onAmountSelected: (amount) {
                debugPrint('Selected amount: ₦$amount');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── NETWORK DROPDOWN ───
class NetworkDropdown extends StatefulWidget {
  final Function(Map<String, dynamic>)? onChanged;
  final Function(String)? onPhoneChanged;
  const NetworkDropdown({super.key, this.onChanged, this.onPhoneChanged});

  @override
  State<NetworkDropdown> createState() => _NetworkDropdownState();
}

class _NetworkDropdownState extends State<NetworkDropdown> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'MTN', 'logo': 'assets/svg/mtn.jpg'},
    {'name': 'Airtel', 'logo': 'assets/svg/airtel.png'},
    {'name': 'Glo', 'logo': 'assets/svg/glo.jpg'},
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

    if (['0803', '0806', '0703', '0706', '0813', '0816'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'MTN');
    } else if (['0802', '0808', '0812', '0701', '0902'].contains(prefix)) {
      detected = _providers.firstWhere((p) => p['name'] == 'Airtel');
    } else if (['0805', '0807', '0811', '0705', '0905'].contains(prefix)) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔽 Provider Dropdown (logo only when closed)
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
                      height: 20.h, // same height & width = perfect circle
                      width: 100.w,
                      decoration: BoxDecoration(
                        shape: BoxShape
                            .circle, // 👈 cleaner than borderRadius for circles
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
                          height: 30.h,
                          width: 30.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            image: DecorationImage(
                              image: AssetImage(provider['logo']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          provider['name'],
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9.sp,
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

          // 📞 Borderless phone input
          Expanded(
            flex: 5,
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.deepPurple,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                _detectNetwork(value); // ✅ still auto-detect network
                widget.onPhoneChanged?.call(
                  value,
                ); // ✅ send phone number upward
              },
            ),
          ),

          SizedBox(height: 5.h),
          // 👤 Profile icon
          Container(
            height: 30.h,
            width: 60.w,
            decoration: BoxDecoration(
              //color: Theme.of(context)Context.kSecondary,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Icon(Icons.person_rounded, color: primaryColor, size: 18),
          ),
        ],
      ),
    );
  }
}

/// ─── DATA SELECTOR (tabs + bonus chip restored) ───
class DataAmountSelector extends StatefulWidget {
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  const DataAmountSelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  State<DataAmountSelector> createState() => _DataAmountSelectorState();
}

class _DataAmountSelectorState extends State<DataAmountSelector>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  int? selectedAmount;

  // Tabs
  final List<String> _tabs = [
    'Gifting',
    'Corporate',
    'SME',
    'Hot',
    'Exclusive',
  ];
  late final TabController _tabController;

  // Plans PER TAB — includes your specific bonus labels like TikTok / Facebook
  final Map<String, List<Map<String, dynamic>>> categorizedPlans = {
    'Gifting': [
      {'data': '110MB', 'price': 100, 'duration': '1 DAY', 'bonus': 'Facebook'},
      {'data': '150MB', 'price': 200, 'duration': '1 DAY', 'bonus': 'TikTok'},
      {
        'data': '500MB',
        'price': 400,
        'duration': '3 DAYS',
        'bonus': 'Instagram',
      },
      {'data': '1GB', 'price': 800, 'duration': '7 DAYS', 'bonus': 'YouTube'},
      {
        'data': '2GB',
        'price': 1200,
        'duration': '10 DAYS',
        'bonus': 'WhatsApp',
      },
      {
        'data': '3GB',
        'price': 1800,
        'duration': '14 DAYS',
        'bonus': 'Facebook',
      },
    ],
    'Corporate': [
      {
        'data': '2GB',
        'price': 1500,
        'duration': '14 DAYS',
        'bonus': 'Team Share',
      },
      {
        'data': '5GB',
        'price': 3000,
        'duration': '30 DAYS',
        'bonus': 'Staff Bonus',
      },
      {
        'data': '10GB',
        'price': 6000,
        'duration': '60 DAYS',
        'bonus': 'Office Pack',
      },
      {
        'data': '20GB',
        'price': 11000,
        'duration': '90 DAYS',
        'bonus': 'Conference',
      },
    ],
    'SME': [
      {
        'data': '500MB',
        'price': 250,
        'duration': '1 DAY',
        'bonus': 'SME Share',
      },
      {'data': '1GB', 'price': 500, 'duration': '3 DAYS', 'bonus': 'Reseller'},
      {'data': '2GB', 'price': 900, 'duration': '7 DAYS', 'bonus': 'Reseller'},
      {'data': '5GB', 'price': 2200, 'duration': '14 DAYS', 'bonus': 'Bulk'},
    ],
    'Hot': [
      {'data': '1.5GB', 'price': 500, 'duration': '1 DAY', 'bonus': '🔥 Flash'},
      {
        'data': '3GB',
        'price': 1000,
        'duration': '3 DAYS',
        'bonus': '🔥 Weekend',
      },
      {'data': '5GB', 'price': 1500, 'duration': '7 DAYS', 'bonus': '🔥 Promo'},
    ],
    'Exclusive': [
      {'data': '15GB', 'price': 3500, 'duration': '30 DAYS', 'bonus': 'VIP'},
      {'data': '25GB', 'price': 5500, 'duration': '45 DAYS', 'bonus': 'VIP+'},
      {
        'data': '40GB',
        'price': 8000,
        'duration': '60 DAYS',
        'bonus': 'Premium',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),

        // Grids (fixed height you asked for)
        SizedBox(
          height: 240.h,
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              final plans = categorizedPlans[tabName]!;
              return GridView.builder(
                padding: EdgeInsets.all(12),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // ✅ exactly 3 columns
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85, // ✅ slightly taller to avoid overflow
                ),
                itemCount: plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  final isSelected = selectedAmount == plan['price'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAmount = plan['price'];
                        _amountController.text = plan['price'].toString();
                      });
                      widget.onAmountSelected?.call(plan['price']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(top: 1.h, left: 10, right: 10.w),
                      decoration: BoxDecoration(
                        // color: isSelected
                        //     ? primaryColor.withOpacity(0.15)
                        //     : Theme.of(context)Context.kSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // DATA
                          Text(
                            plan['data'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              // color: Theme.of(context)Context.titleTextColor,
                            ),
                          ),

                          // PRICE
                          SizedBox(height: 5.h),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: Constants.nairaCurrencySymbol,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                TextSpan(
                                  text: '${plan['price']}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // DURATION
                          SizedBox(height: 5.h),
                          Text(
                            plan['duration'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 11.sp,
                            ),
                          ),

                          // Push bonus chip to the bottom
                          const Spacer(),

                          // BONUS CHIP (Facebook, TikTok, etc.)
                          if (plan['bonus'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                plan['bonus'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                        ],
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

void showAirtimeConfirmationSheet(
  BuildContext context, {
  required int amount,
  required String networkName,
  required String networkLogo,
  required String recipientNumber,
}) {
  final currencySymbol = Constants.nairaCurrencySymbol;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          left: 10.w,
          right: 10.w,
          top: 20.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Drag Handle ───
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              width: 40.w,
              height: 30.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/svg/cancel.svg',
                //color: Theme.of(context)Context.secondaryTextColor,
              ),
            ),

            // 💰 Big Amount
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Constants.nairaCurrencySymbol, // ₦ sign
                      style: TextStyle(
                        fontSize: 14.spMin, // smaller ₦
                        fontWeight: FontWeight.w600,

                        /// color: Theme.of(context)Context.titleTextColor,
                      ),
                    ),
                    TextSpan(
                      text: '$amount.00', // bigger number
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        // color: Theme.of(context)Context.titleTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // 📄 Transaction summary
            Container(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                // color: Theme.of(context)Context.offWhiteBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 👇 Network logo + name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product Name',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            height: 26.h,
                            width: 26.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(networkLogo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),

                          Text(
                            networkName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildSummaryRow(
                    context,
                    'Recipient Mobile',
                    recipientNumber,
                  ),
                  _buildSummaryRow(
                    context,
                    'Amount',
                    '$currencySymbol$amount.00',
                  ),
                  _buildSummaryRow(
                    context,
                    'Use Cashback (${currencySymbol}34.00)',
                    '-${currencySymbol}34.00',
                    hasToggle: true,
                  ),
                  _buildSummaryRow(
                    context,
                    'Bonus to Earn',
                    '+${currencySymbol}1 Cashback',
                    bonus: true,
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade300),
            SizedBox(height: 10.h),
            // 💳 Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance (${currencySymbol}314,171.32)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // 🟩 Pay Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: CustomButton(
                buttonColor: Colors.white,
                buttonTextColor: Colors.white,
                buttonName: 'Pay',
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 🔹 Helper Summary Row Widget
Widget _buildSummaryRow(
  BuildContext context,
  String title,
  String value, {
  bool bonus = false,
  bool hasToggle = false,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Row(
          children: [
            if (bonus)
              Text(
                value,
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith()),
            SizedBox(height: 5.h),
            if (hasToggle)
              GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 25,
                  height: 15,
                  decoration: BoxDecoration(
                    color: false ? primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Align(
                    alignment: false
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
