import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/colors.dart';

class SuggestionChipRow extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions; // [{name, account, isBankTransfer, bankCode}, ...]
  final void Function(Map<String, dynamic> suggestion) onTap;

  const SuggestionChipRow({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: suggestions.map((s) {
              final name = s['name']?.toString() ?? '';
              final account = s['account']?.toString() ?? '';
              final isBank = s['isBankTransfer'] == true;
              final subTitle = isBank ? "Bank \u2022 $account" : "BIA \u2022 $account";

              return GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  margin: EdgeInsets.only(right: 10.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBank ? Icons.account_balance : Icons.account_circle,
                        color: primaryColor,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
