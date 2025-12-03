import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final double screenWidth;

  const HeaderSection({
    super.key,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your phone number',
          style: TextStyle(
            fontSize: screenWidth < 375 ? 14 : 16,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: screenWidth < 375 ? 8 : 10),
      ],
    );
  }
}
