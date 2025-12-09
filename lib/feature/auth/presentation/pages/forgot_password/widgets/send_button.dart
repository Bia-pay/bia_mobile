import 'package:flutter/material.dart';

class SendButton extends StatelessWidget {
  final double screenWidth;
  final VoidCallback? onPressed; // Make nullable
  final bool isEnabled; // Add this parameter

  const SendButton({
    super.key,
    required this.screenWidth,
    required this.onPressed,
    this.isEnabled = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null, // Use isEnabled here
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? Colors.blue : Colors.grey, // Change color when disabled
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth < 375 ? 14 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Send',
          style: TextStyle(
            fontSize: screenWidth < 375 ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}