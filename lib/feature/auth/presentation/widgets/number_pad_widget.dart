import 'package:flutter/material.dart';

import 'number_row.dart';

class NumberPadWidget extends StatelessWidget {
  final ValueChanged<String> onNumberPressed;
  final double buttonFontSize;
  final double buttonVerticalPadding;
  final double containerPadding;
  final double rowSpacing;

  const NumberPadWidget({
    super.key,
    required this.onNumberPressed,
    this.buttonFontSize = 24.0,
    this.buttonVerticalPadding = 8.0,
    this.containerPadding = 8.0,
    this.rowSpacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          NumberRow(
            numbers: const ['1', '2', '3'],
            onNumberPressed: onNumberPressed,
            fontSize: buttonFontSize,
            verticalPadding: buttonVerticalPadding,
          ),
          SizedBox(height: rowSpacing),
          NumberRow(
            numbers: const ['4', '5', '6'],
            onNumberPressed: onNumberPressed,
            fontSize: buttonFontSize,
            verticalPadding: buttonVerticalPadding,
          ),
          SizedBox(height: rowSpacing),
          NumberRow(
            numbers: const ['7', '8', '9'],
            onNumberPressed: onNumberPressed,
            fontSize: buttonFontSize,
            verticalPadding: buttonVerticalPadding,
          ),
          SizedBox(height: rowSpacing),
          NumberRow(
            numbers: const ['.', '0', 'backspace'],
            onNumberPressed: onNumberPressed,
            fontSize: buttonFontSize,
            verticalPadding: buttonVerticalPadding,
          ),
        ],
      ),
    );
  }
}
