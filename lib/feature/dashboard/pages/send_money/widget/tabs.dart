import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/utils/colors.dart';

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

class _BeneficiaryTabSectionState extends ConsumerState<BeneficiaryTabSection>
    with SingleTickerProviderStateMixin {
  String selectedTab = "Recent";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          selectedTab = _tabController.index == 0 ? "Recent" : "Favorites";
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.height < 600;
    final isVerySmallScreen = mediaQuery.size.width < 320;

    final listToShow =
    selectedTab == "Favorites" ? widget.favorites : widget.recents;

    // 🔥 FIX: Wrap everything in a scrollable view to handle small constraints
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(), // Parent handles scrolling
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 Use min instead of max
        children: [
          /// 🔹 TABS with better responsiveness
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 8.w : 12.w,
              vertical: isSmallScreen ? 8.h : 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tab buttons with flexible sizing
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTab(context, "Recent", isVerySmallScreen),
                        SizedBox(width: isVerySmallScreen ? 6.w : 12.w),
                        _buildTab(context, "Favorites", isVerySmallScreen),
                      ],
                    ),
                  ),
                ),
                // Search icon with proper touch target
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSearchTap,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Icon(
                        Icons.search,
                        color: primaryColor,
                        size: isVerySmallScreen ? 20.sp : 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 6.h : 10.h),

          /// 🔥 LIST - Use constrained height instead of Expanded
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 200.h, // 🔥 Fixed max height for list
              minHeight: 50.h,
            ),
            child: listToShow.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 32.sp,
                      color: lightSecondaryText.withOpacity(0.5),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "No beneficiaries",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: lightSecondaryText,
                        fontSize: isSmallScreen ? 12.sp : 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : ListView.separated(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true, // 🔥 Important: shrink to fit content
              itemCount: listToShow.length,
              separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 6.h : 10.h),
              itemBuilder: (context, index) {
                final beneficiary = listToShow[index];
                final name = beneficiary['name'] ?? '';
                final account = beneficiary['account'] ?? '';
                final logoUrl = beneficiary['logoUrl'];

                return _buildBeneficiaryItem(
                  context,
                  name: name,
                  account: account,
                  logoUrl: logoUrl,
                  isSmallScreen: isSmallScreen,
                  isVerySmallScreen: isVerySmallScreen,
                  onTap: () => widget.onSelectBeneficiary?.call(name, account),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, bool isVerySmallScreen) {
    final isSelected = selectedTab == label;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => selectedTab = label),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 12.w : 16.w,
            vertical: isVerySmallScreen ? 6.h : 10.h,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isVerySmallScreen ? 12.sp : 14.sp,
              color: isSelected ? primaryColor : lightSecondaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeneficiaryItem(
      BuildContext context, {
        required String name,
        required String account,
        String? logoUrl,
        required bool isSmallScreen,
        required bool isVerySmallScreen,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final progressSize = isVerySmallScreen ? 32.w : (isSmallScreen ? 36.w : 44.w);
    final avatarRadius = isVerySmallScreen ? 14.r : (isSmallScreen ? 16.r : 20.r);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 8.h : 12.h,
            horizontal: isVerySmallScreen ? 8.w : 12.w,
          ),
          decoration: BoxDecoration(
            color: lightSurface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// LEFT SIDE - Flexible to prevent overflow
              Expanded(
                child: Row(
                  children: [
                    if (widget.showProgress)
                    Container(
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    if (widget.showProgress)
                      SizedBox(width: isVerySmallScreen ? 8.w : 12.w),

                    /// TEXT - Expanded to take available space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: lightText,
                              fontSize: isVerySmallScreen ? 12.sp : (isSmallScreen ? 13.sp : 14.sp),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 1.h : 2.h),
                          Text(
                            account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: lightSecondaryText,
                              fontSize: isVerySmallScreen ? 10.sp : 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              /// RIGHT SIDE - Logo/Avatar
              if (widget.showLogo)
                widget.customLogo ??
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: (logoUrl != null && logoUrl.isNotEmpty)
                            ? Image.network(
                                logoUrl,
                                height: isVerySmallScreen ? 24.h : (isSmallScreen ? 28.h : 32.h),
                                width: isVerySmallScreen ? 24.w : (isSmallScreen ? 28.w : 32.w),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/svg/logo-two.png',
                                    height: isVerySmallScreen ? 18.h : (isSmallScreen ? 22.h : 26.h),
                                    width: isVerySmallScreen ? 18.w : (isSmallScreen ? 22.w : 26.w),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.account_circle,
                                      color: primaryColor,
                                      size: avatarRadius * 1.5,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/svg/logo-two.png',
                                height: isVerySmallScreen ? 18.h : (isSmallScreen ? 22.h : 26.h),
                                width: isVerySmallScreen ? 18.w : (isSmallScreen ? 22.w : 26.w),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.account_circle,
                                    color: primaryColor,
                                    size: avatarRadius * 1.5,
                                  );
                                },
                              ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 PROGRESS INDICATOR - Responsive
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
    final fontSize = (size * 0.28).clamp(8.0, 14.0);

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth.toDouble(),
            valueColor: AlwaysStoppedAnimation<Color>(kGray.withOpacity(0.2)),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth.toDouble(),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.transparent,
          ),
          // Percentage text
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize.sp,
                  color: lightText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}