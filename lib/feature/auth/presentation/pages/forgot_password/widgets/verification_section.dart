import 'package:flutter/material.dart';

class VerificationSection extends StatelessWidget {
  final double screenWidth;
  final TextEditingController codeController;

  const VerificationSection({
    super.key,
    required this.screenWidth,
    required this.codeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We texted you a code to verify your phone number',
          style: TextStyle(
            fontSize: screenWidth < 375 ? 12 : 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: codeController,
          decoration: InputDecoration(
            hintText: 'Enter verification code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }
}
