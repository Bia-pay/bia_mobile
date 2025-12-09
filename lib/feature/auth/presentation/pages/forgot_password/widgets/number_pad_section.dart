import 'package:flutter/material.dart';
import '../../../widgets/number_pad_widget.dart';

class NumberPadSection extends StatelessWidget {
  final double screenWidth;
  final ValueChanged<String> onNumberPressed;

  const NumberPadSection({
    super.key,
    required this.screenWidth,
    required this.onNumberPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NumberPadWidget(
      onNumberPressed: onNumberPressed,
      buttonFontSize: screenWidth < 375 ? 10 : 12,
      buttonVerticalPadding: screenWidth < 375 ? 8 : 10,
      containerPadding: screenWidth < 375 ? 8 : 10,
      rowSpacing: screenWidth < 375 ? 8 : 10,
    );
  }
}
