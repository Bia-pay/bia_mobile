import 'dart:async';

import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/cus_textfield.dart';
import '../../../../../app/utils/widgets/custom_bottom_sheet.dart';
import '../../../../../app/view/widget/quick_access_app_bar.dart';
import '../../../dashboard_repo/repo.dart';
import '../../../dashboardcontroller/provider.dart';
import '../../../widgets/transaction.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../airtime/airtime.dart';

class Electricity extends StatefulWidget {
  const Electricity({super.key});

  @override
  State<Electricity> createState() => _ElectricityState();
}

class _ElectricityState extends State<Electricity> {
  Map<String, dynamic>? _selectedProvider;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Electricity',
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
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS - prevents infinite height
              children: [
                /// ─── Card Two ───
                CardTwo(
                  onChanged: (provider) {
                    setState(() {
                      _selectedProvider = provider;
                    });
                  },
                ),
                SizedBox(height: 20.h),

                /// ─── Card One ───
                CardOne(
                  selectedProvider: _selectedProvider,
                ),
                SizedBox(height: 20.h),

                /// ─── Card Three ───
                // 🔥 FIX: Wrap in ConstrainedBox or remove if BeneficiarySelector has issues
                // const CardThree(), // Comment out temporarily to test
                // SizedBox(height: 20.h),

                /// ─── Electricity Service Section ───
                Container(
                  padding: EdgeInsets.symmetric(vertical: 17, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS
                    children: [
                      Text(
                        'Electricity Service',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // 🔥 FIX: Replace ListView.builder with Column + List.generate
                      // or use shrinkWrap properly with physics: NeverScrollableScrollPhysics
                      ...dataPlans.map((tx) => Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 7),
                        height: 70.h,
                        decoration: BoxDecoration(
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
                                border: Border.all(),
                              ),
                              child: Image.asset(
                                'assets/svg/bank.png',
                                height: 20.h,
                              ),
                            ),
                            SizedBox(width: 15.h),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    tx.dateTime,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11.sp,
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
                      )).toList(),
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
  Timer? _debounce;
  String? _customerName;
  String? _address;
  bool _isVerifying = false;

  void _onMeterChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (value.length < 10) return; // avoid premature calls
      _verifyMeter(value);
    });
  }

  @override
  void didUpdateWidget(covariant CardOne oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedProvider != oldWidget.selectedProvider) {
      final meter = _meterController.text.trim();
      if (meter.isNotEmpty) {
        _verifyMeter(meter);
      }
    }
  }

  Future<void> _verifyMeter(String meter) async {
    final serviceId = widget.selectedProvider?['serviceID'];

    if (serviceId == null) return;

    setState(() {
      _isVerifying = true;
      _customerName = null;
      _address = null;
    });

    final repo = ProviderScope.containerOf(context)
        .read(dashboardRepositoryProvider);

    final result = await repo.verifyElectricityMeter(
      serviceId: serviceId,
      meterNumber: meter,
      type: "prepaid",
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _customerName = result['Customer_Name'];
        _address = result['Address'];
        _isVerifying = false;
      });
    } else {
      setState(() {
        _customerName = "Invalid meter";
        _address = "";
        _isVerifying = false;
      });
    }
  }
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 17, horizontal: 25),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS
          children: [
            Text(
              'Enter Meter Number',
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hint: 'Meter Number',
                              controller: _meterController,
                              onChanged: (value) {
                                _onMeterChanged(value);
                              },
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isVerifying)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14.w,
                      height: 14.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10.w),
                    Text("Verifying meter..."),
                  ],
                ),
              ),

            if (_customerName != null)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customerName!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _customerName == "Invalid meter"
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    if (_address != null && _address!.isNotEmpty)
                      Text(
                        _address!,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 20.h),
            Text(
              'Amount',
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hint: 'Amount',
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            CustomButton(
              buttonName: 'PAY',
              buttonColor: Colors.lightBlueAccent,
              buttonTextColor: Colors.white,
                onPressed: () {
                  final serviceId = widget.selectedProvider?['serviceID'];
                  final meter = _meterController.text.trim();
                  final amountText = _amountController.text.trim();

                  if (serviceId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select provider")),
                    );
                    return;
                  }

                  if (meter.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter meter number")),
                    );
                    return;
                  }

                  if (_customerName == null || _customerName == "Invalid meter") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid meter")),
                    );
                    return;
                  }

                  if (amountText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter amount")),
                    );
                    return;
                  }

                  final amount = int.tryParse(amountText) ?? 0;

                  ConfirmationBottomSheet.show(
                    context: context,
                    config: BottomSheetConfig(
                      title: "Confirm Electricity",
                      subtitle: "electricity",
                      amount: amount.toDouble(),
                      details: [
                        BottomSheetDetailItem(
                          label: "Provider",
                          value: widget.selectedProvider?['name'] ?? "",
                        ),
                        BottomSheetDetailItem(
                          label: "Meter Number",
                          value: meter,
                        ),
                        BottomSheetDetailItem(
                          label: "Customer",
                          value: _customerName ?? "",
                          isHighlighted: true,
                        ),
                        BottomSheetDetailItem(
                          label: "Amount",
                          value: "₦$amount",
                        ),

                        /// 🔥 VERY IMPORTANT (THIS IS WHAT YOUR PIN SCREEN USES)
                        BottomSheetDetailItem(
                          label: "serviceId",
                          value: serviceId,
                        ),
                        BottomSheetDetailItem(
                          label: "variationCode",
                          value: "prepaid",
                        ),
                      ],
                    ),
                    onConfirm: (pin) {},
                  );
                }
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 CardThree is commented out - fix BeneficiarySelector first or provide its code
// class CardThree extends ConsumerStatefulWidget {
//   const CardThree({super.key});

//   @override
//   ConsumerState<CardThree> createState() => _CardThreeState();
// }

// class _CardThreeState extends ConsumerState<CardThree> {
//   Map<String, dynamic>? _selectedProvider;
//   String _phoneNumber = '';

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(15.r),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           BeneficiarySelector()
//         ],
//       ),
//     );
//   }
// }

class CardTwo extends ConsumerStatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onChanged;

  const CardTwo({super.key, this.onChanged});

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
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS
        children: [
          Text(
            'Select Service Provider',
            textAlign: TextAlign.start,
          ),
          SizedBox(height: 10.h),
          NetworkDropdown(
            onChanged: (provider) {
              setState(() => _selectedProvider = provider);
              widget.onChanged?.call(provider); // 🔥 propagate up
            },
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
  Map<String, dynamic>? _selectedProvider;

  @override
  Widget build(BuildContext context) {
    final providersAsync = ref.watch(electricityProviderListProvider);

    return providersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ),

      error: (err, _) => Text("Error loading providers"),

      data: (providers) {
        if (providers.isEmpty) {
          return const Text("No providers available");
        }

        // ✅ Ensure selected provider is always valid
        if (_selectedProvider == null ||
            !providers.contains(_selectedProvider)) {
          _selectedProvider = providers.first;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged?.call(_selectedProvider!);
          });
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedProvider,
              menuMaxHeight: 300.h,
              borderRadius: BorderRadius.circular(10.r),

              items: providers.map((provider) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: provider,
                  child: Text(
                    provider['name'],
                    overflow: TextOverflow.ellipsis,
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
        );
      },
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
          mainAxisSize: MainAxisSize.min, // 🔥 ENSURE THIS IS SET
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
              child: SvgPicture.asset('assets/svg/cancel.svg'),
            ),

            // 💰 Big Amount
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Constants.nairaCurrencySymbol,
                      style: TextStyle(
                        fontSize: 14.spMin,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: '$amount.00',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS
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
                mainAxisSize: MainAxisSize.min, // 🔥 ADD THIS
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
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
              ),
            SizedBox(height: 5.h),
            if (hasToggle)
              GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 25,
                  height: 15,
                  decoration: BoxDecoration(
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