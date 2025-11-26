import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/theme_extension.dart';

class BeneficiaryTabSection extends ConsumerStatefulWidget {
  final List<Map<String, String>> favorites;
  final List<Map<String, String>> recents;
  final void Function(String name, String account)? onSelectBeneficiary;
  final VoidCallback? onSearchTap;
  final bool showProgress; // optional progress circle
  final bool showLogo; // optional logo
  final Widget? customLogo; // allows custom logo widget
  final double progressValue; // dynamic percentage (if enabled)

  const BeneficiaryTabSection({
    super.key,
    required this.favorites,
    required this.recents,
    this.onSelectBeneficiary,
    this.onSearchTap,
    this.showProgress = true,
    this.showLogo = true,
    this.customLogo,
    this.progressValue = 80,
  });

  @override
  ConsumerState<BeneficiaryTabSection> createState() =>
      _BeneficiaryTabSectionState();
}

class _BeneficiaryTabSectionState extends ConsumerState<BeneficiaryTabSection> {
  String selectedTab = "Recent"; // 🔹 Default selected tab changed to Recent

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listToShow =
    selectedTab == "Favorites" ? widget.favorites : widget.recents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs + Search Bar
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.themeContext.pinfieldTextColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTab(context, "Recent"), // 🔹 Recent first
                  SizedBox(width: 10.w),
                  _buildTab(context, "Favorites"),
                ],
              ),
              GestureDetector(
                onTap: widget.onSearchTap,
                child: Icon(Icons.search, color: context.themeContext.kPrimary),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Beneficiaries List
        ...listToShow.map((beneficiary) {
          final name = beneficiary['name'] ?? '';
          final account = beneficiary['account'] ?? '';

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: GestureDetector(
              onTap: () => widget.onSelectBeneficiary?.call(name, account),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 15.w),
                decoration: BoxDecoration(
                  color: context.themeContext.offWhiteBg,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // optional progress ring
                        if (widget.showProgress)
                          CircularPercentageIndicator(
                            percentage: widget.progressValue,
                            size: 50.h,
                            color: context.themeContext.kPrimary,
                          ),
                        if (widget.showProgress) SizedBox(width: 20.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.themeContext.titleTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              account,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // optional logo
                    if (widget.showLogo)
                      widget.customLogo ??
                          CircleAvatar(
                            radius: 18.r,
                            backgroundColor:
                            context.themeContext.kPrimary.withOpacity(0.1),
                            child: Image.asset(
                              'assets/svg/logo-two.png',
                              height: 25.h,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String label) {
    final isSelected = selectedTab == label;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => selectedTab = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? context.themeContext.kPrimary : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// Reusable Circular Progress Widget
class CircularPercentageIndicator extends StatelessWidget {
  final double percentage; // 0–100
  final double size;
  final Color color;
  final double strokeWidth;

  const CircularPercentageIndicator({
    super.key,
    required this.percentage,
    this.size = 50,
    this.color = Colors.green,
    this.strokeWidth = 5,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.grey.withOpacity(0.2)),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.transparent,
          ),
          Text(
            "${percentage.toStringAsFixed(0)}%",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.25,
              color: context.themeContext.titleTextColor,
            ),
          ),
        ],
      ),
    );
  }
}