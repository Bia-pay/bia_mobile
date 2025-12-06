import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/view/widget/app_bar.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../widget/tabs.dart';

class SendMoneyToBank extends ConsumerStatefulWidget {
  const SendMoneyToBank({super.key});

  @override
  ConsumerState<SendMoneyToBank> createState() => _SendMoneyToBankState();
}

class _SendMoneyToBankState extends ConsumerState<SendMoneyToBank> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _goToAmountPage(BuildContext context, String name, String account) {
    Navigator.pushNamed(
      context,
      '/amountPage',
      arguments: {
        'controller': TextEditingController(),
        'recipientName': name,
        'recipientAccount': account,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: lightSurface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Custom Header
                CustomHeader(
                  title: 'Transfer to Bank',
                  onBackPressed: () => Navigator.of(context).pop(),
                ),

                SizedBox(height: 20.h),

                /// 🔹 Section Title
                Text(
                  'Recipient Account',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: lightText,
                  ),
                ),

                SizedBox(height: 15.h),

                /// 🔹 Account Number Input
                Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: lightSurface,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: lightBorderColor),
                  ),
                  alignment: Alignment.center,
                  child: AppField.transparent(
                    hintText: 'Enter 10-digit Account Number',
                    // hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    //   color: lightSecondaryText,
                    // ),
                    onChanged: (value) {
                      if (value.length == 10) {
                        _goToAmountPage(
                          context,
                          'Detected User', // Or fetch actual account name
                          value,
                        );
                      }
                    },
                  ),
                ),

                SizedBox(height: 40.h),

                /// 🔹 Beneficiary Section Tabs
                BeneficiaryTabSection(
                  favorites: [
                    {"name": "Mustapha Garba", "account": "0123456789"},
                    {"name": "Aisha Bello", "account": "0145678901"},
                  ],
                  recents: [
                    {"name": "Fatima Yusuf", "account": "0234567891"},
                    {"name": "John Musa", "account": "0345678912"},
                  ],
                  onSelectBeneficiary: (name, account) {
                    Navigator.pushNamed(context, '/amountPage', arguments: {
                      'recipientName': name,
                      'recipientAccount': account,
                      'controller': TextEditingController(),
                    });
                  },
                  onSearchTap: () {
                    print("Search tapped");
                  },
                  showProgress: true,
                  showLogo: true,
                  progressValue: 80,
                ),

                SizedBox(height: 50.h),

                /// 🔹 Continue Button (example)
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: lightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}