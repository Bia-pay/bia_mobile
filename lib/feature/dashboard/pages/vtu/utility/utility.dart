import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../widgets/transaction.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../airtime/airtime.dart';


class Electricity extends StatefulWidget {
  const Electricity({super.key});

  @override
  State<Electricity> createState() => _ElectricityState();
}

class _ElectricityState extends State<Electricity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(62.h),
        child: Container(
          padding: EdgeInsets.symmetric( horizontal: 10.w,vertical: 40.h),
        //  color: Theme.of(context)Context.grayWhiteBg,
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
                  SizedBox(height: 5.h,),
                  Text(
                    'Electricity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Text(
                "History",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                ),
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
            padding: EdgeInsets.symmetric( horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ─── Card One ───
                const CardTwo(),
                SizedBox(height: 20.h,),
                const CardOne(),
                SizedBox(height: 20.h,),
                const CardThree(),
                SizedBox(height: 20.h,),

                /// ─── Electricity Service Section ───
                Container(
                  padding: EdgeInsets.symmetric( vertical: 17, horizontal: 10),
                  decoration: BoxDecoration(
                   // color: Theme.of(context)Context.tertiaryBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Electricity Service',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      SizedBox(height: 10.h,),

                      SizedBox(
                        height: 180.h,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric( vertical: 8, horizontal: 0),
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: dataPlans.length,
                          itemBuilder: (context, index) {
                            final tx = dataPlans[index];
                            return Container(
                              padding:
                              EdgeInsets.symmetric( vertical: 8, horizontal: 18),
                              margin: EdgeInsets.symmetric( vertical: 6, horizontal: 7),
                              height: 70.h,
                              decoration: BoxDecoration(
                               // color: Theme.of(context)Context.kSecondary,
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
                                      border: Border.all(
                                       // color: Theme.of(context)Context.kPrimary,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/svg/bank.png',
                                      height: 20.h,
                                    ),
                                  ),
                                  SizedBox(width: 15.h,),
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

                SizedBox(height: 25.h,),
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
  const CardOne({super.key, this.onAmountSelected, this.selectedProvider, this.phoneNumber});

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
      padding: EdgeInsets.symmetric( vertical: 17, horizontal: 25),
      decoration: BoxDecoration(
       // color: Theme.of(context)Context.tertiaryBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric( horizontal: 1.w,vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [    /// 💰 Amount Grid (matching your image layout)
            Text(
              'Enter Meter Number',
              textAlign: TextAlign.start,
              // style: textTheme.titleMedium?.copyWith(
              //   fontWeight: FontWeight.w600,
              // ),
            ),
            SizedBox(height: 10.h,),

            /// 🔹 Pay Button

            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w,),
                      decoration: BoxDecoration(
                          border: Border.all(
                            //  color: Theme.of(context)Context.checkboxBorderColor
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10.r))
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
              ],
            ),
            SizedBox(height: 20.h,),
            Text(
              'Amount',
              textAlign: TextAlign.start,
              // style: textTheme.titleMedium?.copyWith(
              //   fontWeight: FontWeight.w600,
              // ),
            ),
            SizedBox(height: 10.h,),

            /// 🔹 Pay Button

            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w,),
                      decoration: BoxDecoration(
                          border: Border.all(
                             // color: Theme.of(context)Context.checkboxBorderColor
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10.r))
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
              ],
            ),
            SizedBox(height: 20.h,),
            CustomButton(
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
                  networkLogo: widget.selectedProvider?['logo'] ?? 'assets/svg/mtn.jpg',
                  recipientNumber: widget.phoneNumber ?? '',
                );
              },
            ),
          ],
        ),
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
  String _phoneNumber = '';

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
       // color: themeContext.tertiaryBackgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BeneficiarySelector()
        ],
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
          SizedBox(height: 10.h,),
          NetworkDropdown(
            onChanged: (provider) => setState(() => _selectedProvider = provider),
            onPhoneChanged: (number) =>
                setState(() => _phoneNumber = number),
          ),
        ],
      ),
    );
  }
}
/// ─── NETWORK DROPDOWN ───

class NetworkDropdown extends ConsumerStatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final ValueChanged<String>? onPhoneChanged;

  const NetworkDropdown({
    super.key,
    this.onChanged,
    this.onPhoneChanged,
  });

  @override
  ConsumerState<NetworkDropdown> createState() => _NetworkDropdownState();
}

class _NetworkDropdownState extends ConsumerState<NetworkDropdown> {
  final List<Map<String, dynamic>> _providers = [
    {'name': 'Kano Electricity (KEDCO)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Abuja Electricity (AEDC)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Eko Electricity (EKEDC)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Ikeja Electricity (IKEDC)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Kaduna Electricity (KAEDCO)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Port Harcourt (PHED)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Jos (JED)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Ibadan (IBEDC)', 'logo': 'assets/svg/bank.png'},
    {'name': 'Benin (BEDC)', 'logo': 'assets/svg/bank.svg'},
    {'name': 'Enugu (EEDC)', 'logo': 'assets/svg/bank.png'},
  ];

  Map<String, dynamic>? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
  }

  @override
  Widget build(BuildContext context) {

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, ),
        decoration: BoxDecoration(
        //  border: Border.all(color: themeContext.checkboxBorderColor),
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
        child: Row(
          children: [
            // FIXED WIDTH dropdown so it doesn't collapse and hides
            Expanded(
              child: SizedBox(
                width: double.infinity, // <- adjust width as needed for your layout
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedProvider,
                   // dropdownColor: themeContext.offWhiteBg,
                    menuMaxHeight: 300.h,
                    borderRadius: BorderRadius.circular(10.r),
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                     // color: themeContext.secondaryTextColor,
                      size: 20.sp,
                    ),

                    // how the selected value is shown in the closed button
                    selectedItemBuilder: (BuildContext context) {
                      return _providers.map<Widget>((provider) {
                        return Row(
                          children: [
                            Container(
                              height: 28.h,
                              width: 28.h,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(provider['logo']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w), // vertical divider between dropdown and input (optional)
                            Container(
                              width: 1,
                              height: 36.h,
                             // color: themeContext.checkboxBorderColor,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                provider['name'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                 // color: themeContext.titleTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },

                    // items inside the dropdown menu
                    items: _providers.map((provider) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: provider,
                        child: Row(
                          children: [
                            Container(
                              height: 28.h,
                              width: 28.h,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(provider['logo']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                provider['name'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                               //   color: themeContext.titleTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedProvider = value);
                      widget.onChanged?.call(value);
                    },
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
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
              child: SvgPicture.asset('assets/svg/cancel.svg',
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
                        //color: Theme.of(context)Context.titleTextColor,
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
            SizedBox(height: 20.h,),


            // 📄 Transaction summary
            Container(
              padding: EdgeInsets.symmetric( vertical: 18, horizontal: 16),
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
                          SizedBox(height: 6.h,),

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
                  _buildSummaryRow(context, 'Recipient Mobile', recipientNumber),
                  _buildSummaryRow(context, 'Amount', '$currencySymbol$amount.00'),
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
            SizedBox(height: 10.h,),
            // 💳 Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10.h,),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric( vertical: 16, horizontal: 18),
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

            SizedBox(height: 20.h,),


            // 🟩 Pay Button
            Padding(
                padding: EdgeInsets.symmetric( horizontal: 10.w),
                child: CustomButton(buttonColor: Colors.white, buttonTextColor: Colors.white, buttonName: 'Pay')
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
              Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  )

              ),
            SizedBox(height: 5.h,),
            if (hasToggle)
              GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 25,
                  height: 15,
                  decoration: BoxDecoration(
                    //color: false ? Theme.of(context)Context.kPrimary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Align(
                    alignment: false ? Alignment.centerRight : Alignment.centerLeft,
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
