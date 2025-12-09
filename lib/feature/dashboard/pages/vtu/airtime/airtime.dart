import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../widgets/transaction.dart';
import '../../send_money/widget/tabs.dart';

class Airtime extends ConsumerStatefulWidget {
  const Airtime({super.key});

  @override
  ConsumerState<Airtime> createState() => _AirtimeState();
}

class _AirtimeState extends ConsumerState<Airtime> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Airtime',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'History',
                    style: textTheme.bodyMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30.h),

              const CardTwo(),
              SizedBox(height: 20.h),
              const CardOne(),
              SizedBox(height: 20.h),
              const CardThree(),

              SizedBox(height: 20.h),

              /// 🔹 Airtime Services
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 18.h),
                decoration: BoxDecoration(
                  // color: themeContext.tertiaryBackgroundColor,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Airtime Service',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height: 250.h,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: topUp.length,
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        itemBuilder: (context, index) {
                          final tx = topUp[index];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 6.h),
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              //  color: themeContext.kSecondary,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 40.h,
                                  width: 40.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      // color: themeContext.kPrimary
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/svg/bank.png',
                                    height: 18.h,
                                  ),
                                ),
                                SizedBox(width: 15.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.name,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        tx.dateTime,
                                        style: textTheme.bodySmall?.copyWith(
                                          // color: themeContext
                                          //     .secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  size: 14.sp,
                                  // color: themeContext.secondaryTextColor
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
            ],
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
  final String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: lightSurface,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [AirtimeAmountSelector()],
      ),
    );
  }
}

class CardThree extends ConsumerStatefulWidget {
  const CardThree({super.key});

  @override
  ConsumerState<CardThree> createState() => _CardThreeState();
}

class _CardThreeState extends ConsumerState<CardThree> {
  Map<String, dynamic>? _selectedProvider;
  final String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        //  color: themeContext.tertiaryBackgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [BeneficiarySelector()],
      ),
    );
  }
}

class CardTwo extends ConsumerStatefulWidget {
  const CardTwo({super.key});

  @override
  ConsumerState<CardTwo> createState() => _CardTwoState();
}

class _CardTwoState extends ConsumerState<CardTwo> {
  Map<String, dynamic>? _selectedProvider;
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 19.h),
      decoration: BoxDecoration(
        // color: themeContext.tertiaryBackgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Service Provider',
            textAlign: TextAlign.start,
            // style: textTheme.titleMedium?.copyWith(
            //   fontWeight: FontWeight.w600,
            // ),
          ),
          SizedBox(height: 10.h),
          NetworkDropdown(
            onChanged: (provider) =>
                setState(() => _selectedProvider = provider),
            onPhoneChanged: (number) => setState(() => _phoneNumber = number),
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
    {'name': '', 'logo': 'assets/svg/mtn.jpg'},
    {'name': '', 'logo': 'assets/svg/airtel.png'},
    {'name': '', 'logo': 'assets/svg/glo.jpg'},
    {'name': '', 'logo': 'assets/svg/9mobile.png'},
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
              child: CustomTextField(hint: 'Kano Electricity (KEDCO)'),
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

  final List<int> amounts = [100, 200, 300, 400, 500, 1000, 2000, 3000, 5000];
  final List<String> cashback = [
    '+₦1 Cashback',
    '+₦2 Cashback',
    '+₦3 Cashback',
    '+₦4 Cashback',
    '+₦5 Cashback',
    '+₦10 Cashback',
    '+₦20 Cashback',
    '+₦30 Cashback',
    '+₦50 Cashback',
  ];

  Map<String, dynamic>? _selectedProvider;
  final String _phoneNumber = '';
  int? selectedAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        Wrap(
          spacing: 10.w, // horizontal space between items
          runSpacing: 10.h, // vertical space between rows
          children: List.generate(amounts.length, (index) {
            final amount = amounts[index];
            final isSelected = selectedAmount == amount;

            // ✅ Make second-row items wider
            final isSecondRow = index >= 5; // since 5 items per row
            final itemWidth = isSecondRow ? 62.w : 52.w; // 👈 adjust as needed
            final itemHeight = 50.h;

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
                curve: Curves.easeOut,
                width: itemWidth,
                height: itemHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    // color: isSelected ? themeContext.kPrimary : Colors.grey.shade300,
                    width: 1.3,
                  ),
                ),
                child: Text(
                  '₦$amount',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    // color: themeContext.titleTextColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 25.h),
      ],
    );
  }
}

class BeneficiarySelector extends ConsumerStatefulWidget {
  final Function(int amount)? onAmountSelected;
  final Map<String, dynamic>? selectedProvider;
  final String? phoneNumber;

  const BeneficiarySelector({
    super.key,
    this.onAmountSelected,
    this.selectedProvider,
    this.phoneNumber,
  });

  @override
  ConsumerState<BeneficiarySelector> createState() =>
      _BeneficiarySelectorState();
}

class _BeneficiarySelectorState extends ConsumerState<BeneficiarySelector> {
  final TextEditingController _amountController = TextEditingController();

  Map<String, dynamic>? _selectedProvider;
  final String _phoneNumber = '';
  int? selectedAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 💰 Amount Grid (matching your image layout)
        Text(
          'Select Beneficiary',
          textAlign: TextAlign.start,
          // style: textTheme.titleMedium?.copyWith(
          //   fontWeight: FontWeight.w600,
          // ),
        ),
        SizedBox(height: 10.h),
        BeneficiaryTabSection(
          favorites: [
            {"name": "Mustapha Garba", "account": "0123456789"},
            {"name": "Aisha Bello", "account": "0145678901"},
          ],
          recents: [
            {"name": "Fatima Yusuf", "account": "0234567891"},
            {"name": "John Musa", "account": "0345678912"},
            {"name": "Fatima Yusuf", "account": "0234567891"},
            {"name": "John Musa", "account": "0345678912"},
          ],
          onSelectBeneficiary: (name, account) {
            debugPrint('Selected $name - $account');
          },
          onSearchTap: () => debugPrint('Search tapped'),

          // optional config:
          showProgress: false, // hide progress circle
          showLogo: true,
        ),

        SizedBox(height: 25.h),
      ],
    );
  }
}

/// 🔹 Bottom Sheet Confirmation
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
                // color: Theme.of(context)Context.secondaryTextColor,
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
                        //  color: Theme.of(context)Context.titleTextColor,
                      ),
                    ),
                    TextSpan(
                      text: '$amount.00', // bigger number
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        //  color: Theme.of(context)Context.titleTextColor,
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
                //   color: Theme.of(context)Context.offWhiteBg,
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
                    // color: false ? Theme.of(context)Context.kPrimary : Colors.grey.shade300,
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

/// 🔹 Helper Payment Row Widget
Widget _buildPaymentRow(
  BuildContext context,
  String method,
  String amount, {
  required bool selected,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          method,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
        Row(
          children: [
            if (amount.isNotEmpty)
              Text(
                amount,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
          ],
        ),
      ],
    ),
  );
}
