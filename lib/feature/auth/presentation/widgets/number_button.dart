import 'package:flutter/material.dart';

class NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;
  final double borderRadius;

  const NumberButton({
    super.key,
    required this.number,
    required this.onPressed,
    this.horizontalPadding = 8.0,
    this.verticalPadding = 16.0,
    this.fontSize = 24.0,
    this.textColor = Colors.black,
    this.fontWeight = FontWeight.w400,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isBackspace = number == 'backspace';

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: isBackspace
              ? Icon(Icons.backspace_outlined, size: fontSize, color: textColor)
              : Text(
            number,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
