import 'package:bia/app/utils/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bia/core/__core.dart';
import '../../../app/view/widget/app_textfield.dart';
import '../../utils/colors.dart';

class AmountBottomSheet extends StatefulWidget {
  final TextEditingController controller;

  // Reusable parameters
  final String recipientName;
  final String recipientAccount;
  final String? recipientIconPath;
  final String title;
  final VoidCallback? onNext;
  final VoidCallback? onOk;

  const AmountBottomSheet({
    super.key,
    required this.controller,
    required this.recipientName,
    required this.recipientAccount,
    this.recipientIconPath,
    this.title = "Enter Amount",
    this.onNext,
    this.onOk,
  });

  @override
  State<AmountBottomSheet> createState() => _AmountBottomSheetState();
}

class _AmountBottomSheetState extends State<AmountBottomSheet> {
  String amount = "0";
  int _selectedIndex = -1;

  void addDigit(String value) {
    setState(() {
      if (amount == "0") {
        amount = value;
      } else {
        amount += value;
      }
      widget.controller.text = amount;
    });
  }

  void removeDigit() {
    setState(() {
      if (amount.isNotEmpty) {
        amount = amount.substring(0, amount.length - 1);
      }
      if (amount.isEmpty) {
        amount = "0";
      }
      widget.controller.text = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomSheet(
      enableDrag: true,
      builder: (context) {
        return Container(
          height: 800.h,
          padding: EdgeInsets.symmetric(horizontal: 200.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Recipient header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recipient",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SvgPicture.asset('assets/svg/cancel.svg', height: 20.h),
                ],
              ),

              SizedBox(height: 20.h),

              // Recipient card
              Container(
                height: 90.h,
                padding: EdgeInsets.only(
                  top: 13.h,
                  bottom: 13.h,
                  left: 150.w,
                  right: 90.w,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: widget.recipientIconPath != null
                              ? SvgPicture.asset(
                                  widget.recipientIconPath!,
                                  height: 30.h,
                                )
                              : Icon(Icons.person, size: 30),
                        ),
                        SizedBox(height: 30.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipientName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.recipientAccount,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SvgPicture.asset('assets/svg/edit.svg', height: 20.h),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              // Title
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),

              // Amount input
              Center(
                child: AppTextField(
                  borderRadius: 8,
                  controller: widget.controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Next button
              Center(
                child: SizedBox(
                  width: 750.w,
                  child: CustomButton(
                    buttonColor: primaryColor,
                    buttonTextColor: primaryColor,
                    buttonName: 'Next',
                    onPressed: widget.onNext,
                  ),
                ),
              ),

              SizedBox(height: 15.h),

              // Keypad
              Expanded(
                child: GridView.builder(
                  itemCount: 12,
                  padding: EdgeInsets.symmetric(vertical: 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 55,
                    mainAxisExtent: 75,
                    childAspectRatio: 2,
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

                    Color keyColor = theme.colorScheme.surface;
                    Color textColor =
                        theme.textTheme.bodyMedium?.color ?? Colors.black;

                    if (key == "x") {
                      keyColor = theme.colorScheme.primary;
                      textColor = theme.colorScheme.onPrimary;
                    } else if (key == "ok") {
                      keyColor = theme.colorScheme.primary;
                      textColor = theme.colorScheme.onPrimary;
                    }

                    bool isSelected = _selectedIndex == index;

                    return Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                          if (key == "x") {
                            removeDigit();
                          } else if (key == "ok") {
                            widget.onOk != null
                                ? widget.onOk!()
                                : Navigator.pop(context);
                          } else {
                            addDigit(key);
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 280.h,
                          width: 190.w,
                          decoration: BoxDecoration(
                            color: keyColor,
                            borderRadius: BorderRadius.circular(50),
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2.0,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: key == "x"
                              ? SvgPicture.asset(
                                  'assets/svg/cancel.svg',
                                  height: 20.h,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : key == "ok"
                              ? Icon(
                                  Icons.arrow_forward,
                                  color: textColor,
                                  size: 24,
                                )
                              : Text(
                                  key,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: textColor,
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w300,
                                      ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      onClosing: () {},
    );
  }
}
