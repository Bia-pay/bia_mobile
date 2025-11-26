import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bia/core/__core.dart';
import 'package:bia/core/constraint.dart';
import '../../../app/view/widget/app_button.dart';
import '../../../app/view/widget/app_textfield.dart';

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
    return BottomSheet(
      enableDrag: true,
      builder: (context) {
        return Container(
          height: 800.h(context),
          padding: padR(context, horizontal: 200.w(context)),
          decoration: BoxDecoration(
            color: context.themeContext.grayWhiteBg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(40),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Recipient header
              RRow(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recipient",
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RSvg('assets/svg/cancel.svg', height: 20.h(context)),
                ],
              ),

              20.vSpace(context),

              // Recipient card
              Container(
                height: 90.h(context),
                padding: padR(
                  context,
                  vertical: 13.h(context),
                  left: 150.w(context),
                  right: 90.w(context),
                ),
                decoration: BoxDecoration(
                  color: context.themeContext.offWhiteBg,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: RRow(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RRow(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: widget.recipientIconPath != null
                              ? RSvg(widget.recipientIconPath!,
                              height: 30.h(context))
                              : Icon(Icons.person, size: 30),
                        ),
                        30.hSpace(context),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipientName,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.themeContext.titleTextColor,
                                fontSize: 15.sp(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.recipientAccount,
                              style: context.textTheme.labelSmall?.copyWith(
                                color:
                                context.themeContext.secondaryTextColor,
                                fontSize: 11.sp(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    RSvg('assets/svg/edit.svg', height: 20.h(context)),
                  ],
                ),
              ),

              20.vSpace(context),

              // Title
              Text(
                widget.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              10.vSpace(context),

              // Amount input
              Center(
                child: AppTextField(
                  borderRadius: 8,
                  controller: widget.controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: context.themeContext.kPrimary,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: context.themeContext.kPrimary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              10.vSpace(context),

              // Next button
              Center(
                child: SizedBox(
                  width: 750.w(context),
                  child: SolidAppButton.primary(
                    text: 'Next',
                    borderRadius: 8,
                    onPressed: widget.onNext,
                  ),
                ),
              ),

              15.vSpace(context),

              // Keypad
              Expanded(
                child: GridView.builder(
                  itemCount: 12,
                  padding: padR(context, vertical: 0),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 55,
                    mainAxisExtent: 75,
                    childAspectRatio: 2,
                  ),
                  itemBuilder: (context, index) {
                    List<String> keys = [
                      "1", "2", "3",
                      "4", "5", "6",
                      "7", "8", "9",
                      "x", "0", "ok",
                    ];
                    String key = keys[index];

                    Color keyColor = context.themeContext.keyColor;
                    Color textColor = context.themeContext.secondaryTextColor;

                    if (key == "x") {
                      keyColor = context.themeContext.kPrimary;
                      textColor =
                          context.themeContext.tertiaryTextColor;
                    } else if (key == "ok") {
                      keyColor = context.themeContext.kPrimary;
                      textColor = context.themeContext.tertiaryBackgroundColor;
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
                            if (widget.onOk != null) {
                              widget.onOk!();
                            } else {
                              Navigator.pop(context);
                            }
                          } else {
                            addDigit(key);
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 280.h(context),
                          width: 190,
                          decoration: BoxDecoration(
                            color: keyColor,
                            borderRadius: BorderRadius.circular(50),
                            border: isSelected
                                ? Border.all(
                              color: context.themeContext.kPrimary,
                              width: 2.0,
                            )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: key == "x"
                              ? RSvg(
                            'assets/svg/cancel.svg',
                            height: 20.h(context),
                            color: context.themeContext
                                .tertiaryBackgroundColor,
                          )
                              : key == "ok"
                              ? Icon(Icons.arrow_forward,
                              color: textColor, size: 24)
                              : Text(
                            key,
                            style: context.textTheme.headlineSmall
                                ?.copyWith(
                              color: context.themeContext
                                  .secondaryTextColor,
                              fontSize: 24.sp(context),
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
