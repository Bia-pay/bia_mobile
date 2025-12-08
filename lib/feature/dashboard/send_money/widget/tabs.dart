import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/utils/colors.dart';

class BeneficiaryTabSection extends ConsumerStatefulWidget {
  final List<Map<String, String>> favorites;
  final List<Map<String, String>> recents;
  final void Function(String name, String account)? onSelectBeneficiary;
  final VoidCallback? onSearchTap;
  final bool showProgress;
  final bool showLogo;
  final Widget? customLogo;
  final double progressValue;

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
  String selectedTab = "Recent";

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
           // color: Theme.of(context)Context.pinfieldTextColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTab(context, "Recent"),
                  SizedBox(width: 10.w),
                  _buildTab(context, "Favorites"),
                ],
              ),
              GestureDetector(
                onTap: widget.onSearchTap,
                child: Icon(Icons.search, color: primaryColor),
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
                  color: lightSurface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (widget.showProgress)
                          CircularPercentageIndicator(
                            percentage: widget.progressValue,
                            size: 50.h,
                            color: primaryColor,
                          ),
                        if (widget.showProgress) SizedBox(width: 20.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: lightText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              account,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.showLogo)
                      widget.customLogo ??
                          CircleAvatar(
                            radius: 18.r,
                            backgroundColor: primaryColor.withOpacity(0.1),
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
            color: isSelected ? primaryColor : lightSecondaryText,
          ),
        ),
      ),
    );
  }
}

class CircularPercentageIndicator extends StatelessWidget {
  final double percentage;
  final double size;
  final Color color;
  final double strokeWidth;

  const CircularPercentageIndicator({
    super.key,
    required this.percentage,
    this.size = 50,
    this.color = primaryColor,
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
            AlwaysStoppedAnimation<Color>(kGray.withOpacity(0.2)),
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
              color: lightText,
            ),
          ),
        ],
      ),
    );
  }
}