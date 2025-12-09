import 'package:flutter/material.dart';
import 'number_button.dart';

class NumberRow extends StatelessWidget {
  final List<String> numbers;
  final ValueChanged<String> onNumberPressed;
  final double fontSize;
  final double verticalPadding;

  const NumberRow({
    super.key,
    required this.numbers,
    required this.onNumberPressed,
    this.fontSize = 24.0,
    this.verticalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: numbers.map((number) => NumberButton(
        number: number,
        onPressed: () => onNumberPressed(number),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        verticalPadding: verticalPadding,
      )).toList(),
    );
  }
}