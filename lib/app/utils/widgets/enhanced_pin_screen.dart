import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../feature/dashboard/widgets/keypad.dart';
import '../colors.dart';

class PinInputScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int length;
  final Function(String pin) onComplete;

  const PinInputScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.length = 4,
    required this.onComplete,
  });

  @override
  State<PinInputScreen> createState() => _PinInputScreenState();
}

class _PinInputScreenState extends State<PinInputScreen> {
  String pin = "";

  void _addDigit(String value) {
    if (pin.length >= widget.length) return;
    setState(() => pin += value);

    if (pin.length == widget.length) {
      widget.onComplete(pin);
    }
  }

  void _removeDigit() {
    if (pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: offWhiteBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 40.h),
          Text(widget.subtitle, style: theme.textTheme.bodyMedium),
          SizedBox(height: 30.h),

          /// Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              final filled = index < pin.length;
              return Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: filled ? primaryColor : Colors.grey,
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          /// Keypad
          SizedBox(
            height: 350,
            child: CustomGridKeypad(
              onNumberPressed: _addDigit,
              leftAction: ActionKey(
                child: const Icon(Icons.backspace),
                onTap: _removeDigit,
              ),
              rightAction: ActionKey(
                child: const Icon(Icons.check),
                onTap: () {
                  if (pin.length == widget.length) {
                    widget.onComplete(pin);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}