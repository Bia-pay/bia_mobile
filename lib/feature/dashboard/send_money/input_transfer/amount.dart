import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/view/widget/app_textfield.dart';
import 'complete_transaction.dart';

class AmountPage extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String recipientName;
  final String recipientAccount;
  final String? recipientIconPath;
  final String title;
  final VoidCallback? onNext;
  final VoidCallback? onOk;

  const AmountPage({
    super.key,
    required this.controller,
    required this.recipientName,
    required this.recipientAccount,
    this.recipientIconPath,
    this.title = "Enter Amount",
    this.onNext,
    this.onOk,
  });

  static const String routeName = '/amountPage';

  @override
  ConsumerState<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends ConsumerState<AmountPage> {
  String amount = "0";
  int _selectedIndex = -1;
  bool showMinWarning = false;

  /// ✅ Add digit normally
  void addDigit(String value) {
    setState(() {
      String current = amount.replaceAll('₦', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      amount = '₦$current';
      widget.controller.text = amount;

      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      String current = amount.replaceAll('₦', '');
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }
      if (current.isEmpty) {
        current = "0";
      }
      amount = '₦$current';
      widget.controller.text = amount;

      _checkMinLimit();
    });
  }

  /// ✅ Check if amount is below ₦100 and show warning
  void _checkMinLimit() {
    final numericValue =
        num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    showMinWarning = numericValue < 50 && numericValue != 0;
  }

  /// ✅ Only allow ₦100 and above
  void _showConfirmBottomSheet() {
    final numericAmount =
        num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    if (numericAmount < 50) {
      setState(() => showMinWarning = true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompleteTransactionBottomSheet(
        amount: numericAmount.toString(),
        recipientName: widget.recipientName,
        recipientAccount: widget.recipientAccount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    return Scaffold(
      backgroundColor: themeContext.grayWhiteBg,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeContext.grayWhiteBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: themeContext.titleTextColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipient',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),

            /// 🔹 Recipient Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: themeContext.offWhiteBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25.r,
                    backgroundColor: themeContext.kSecondary,
                    child: widget.recipientIconPath != null
                        ? SvgPicture.asset(
                      widget.recipientIconPath!,
                      height: 30.h,
                      colorFilter: ColorFilter.mode(
                        themeContext.kPrimary,
                        BlendMode.srcIn,
                      ),
                    )
                        : Icon(
                      Icons.person,
                      size: 30.sp,
                      color: themeContext.kPrimary,
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipientName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: themeContext.titleTextColor,
                          ),
                        ),
                        Text(
                          widget.recipientAccount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: themeContext.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset('assets/svg/edit.svg', height: 15.h),
                ],
              ),
            ),

            SizedBox(height: 15.h),
            Text(
              'Enter Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5.h),

            /// 🔹 Amount Field
            AppTextField(
              controller: widget.controller,
              readOnly: true,
              borderRadius: 8,
              hintTextAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "₦0.00",
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: themeContext.secondaryTextColor,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: themeContext.kPrimary, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: themeContext.kPrimary, width: 1.5),
                ),
              ),
            ),

            /// ⚠️ Minimum Amount Warning
            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Text(
                  "Minimum amount you can send is ₦50",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 20.h),

            /// 🔹 Next Button
            Center(
              child: SizedBox(
                width: 280.w,
                child: CustomButton(
                  buttonName: 'Next',
                  buttonColor: themeContext.kPrimary,
                  buttonTextColor: Colors.white,
                  onPressed: _showConfirmBottomSheet,
                ),
              ),
            ),

            SizedBox(height: 25.h),

            /// 🔢 Keypad
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 35.w,
                  mainAxisExtent: 70.h,
                ),
                itemBuilder: (context, index) {
                  List<String> keys = [
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "x",
                    "0",
                    "ok",
                  ];
                  String key = keys[index];

                  Color keyColor = themeContext.keyColor;
                  Color textColor = themeContext.secondaryTextColor;

                  if (key == "x") {
                    keyColor = themeContext.kPrimary.withOpacity(0.1);
                    textColor = themeContext.kPrimary;
                  } else if (key == "ok") {
                    keyColor = themeContext.kPrimary;
                    textColor = themeContext.tertiaryBackgroundColor;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(50.r),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() => _selectedIndex = index);

                      if (key == "x") {
                        removeDigit();
                      } else if (key == "ok") {
                        _showConfirmBottomSheet();
                      } else {
                        addDigit(key);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        _selectedIndex == index ? Colors.white : keyColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedIndex == index
                              ? themeContext.kPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _selectedIndex == index
                            ? [
                          BoxShadow(
                            color:
                            themeContext.kPrimary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: key == "x"
                          ? SvgPicture.asset(
                        'assets/svg/cancel.svg',
                        height: 20.h,
                        colorFilter: ColorFilter.mode(
                          themeContext.kPrimary,
                          BlendMode.srcIn,
                        ),
                      )
                          : key == "ok"
                          ? Icon(
                        Icons.arrow_forward,
                        color: _selectedIndex == index
                            ? themeContext.kPrimary
                            : textColor,
                        size: 24.sp,
                      )
                          : Text(
                        key,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: _selectedIndex == index
                              ? themeContext.kPrimary
                              : themeContext.titleTextColor,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}