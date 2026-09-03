import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/utils/colors.dart';

/// Shared beneficiary selector used across the app.
///
/// - When [favorites] is empty the "Favourites" tab is hidden entirely and
///   the widget shows only the Recent list (used by VTU pages).
/// - When [favorites] is non-empty both tabs are shown (used by Send Money).
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
  String selectedTab = 'Recent';

  bool get _hasFavorites => widget.favorites.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.height < 600;
    final isVerySmallScreen = mediaQuery.size.width < 320;
    final isTablet = mediaQuery.size.width > 600;

    final listToShow =
        (selectedTab == 'Favorites' && _hasFavorites) ? widget.favorites : widget.recents;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ── Header row ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 4.0 : (isSmallScreen ? 6.h : 8.h),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tab buttons — show Favourites tab only when data exists
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTab(context, 'Recent', isVerySmallScreen),
                    if (_hasFavorites) ...[
                      SizedBox(width: isTablet ? 8.0 : (isVerySmallScreen ? 6.w : 10.w)),
                      _buildTab(context, 'Favorites', isVerySmallScreen),
                    ],
                  ],
                ),
                // Search icon
                if (widget.onSearchTap != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onSearchTap,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 6.0 : 6.w),
                        child: Icon(
                          Icons.search,
                          color: primaryColor,
                          size: isTablet ? 18.0 : (isVerySmallScreen ? 18.sp : 20.sp),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 4.0 : (isSmallScreen ? 4.h : 6.h)),

          /// ── List ────────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isTablet ? 260.0 : 220.h,
              minHeight: isTablet ? 50.0 : 50.h,
            ),
            child: listToShow.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 16.0 : 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: isTablet ? 28.0 : 32.sp,
                            color: lightSecondaryText.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: isTablet ? 6.0 : 8.h),
                          Text(
                            selectedTab == 'Favorites'
                                ? 'No saved beneficiaries'
                                : 'No recent transactions',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: lightSecondaryText,
                              fontSize: isTablet ? 12.5 : (isSmallScreen ? 12.sp : 13.sp),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: listToShow.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: isTablet ? 6.0 : (isSmallScreen ? 6.h : 8.h)),
                    itemBuilder: (context, index) {
                      final item = listToShow[index];
                      final name = item['name'] ?? '';
                      final account = item['account'] ?? '';
                      final logoUrl = item['logoUrl'];

                      return _BeneficiaryItem(
                        name: name,
                        account: account,
                        logoUrl: logoUrl,
                        showAvatar: showProgress,
                        showLogo: widget.showLogo,
                        customLogo: widget.customLogo,
                        isSmallScreen: isSmallScreen,
                        isVerySmallScreen: isVerySmallScreen,
                        onTap: () =>
                            widget.onSelectBeneficiary?.call(name, account),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool get showProgress => widget.showProgress;

  Widget _buildTab(
      BuildContext context, String label, bool isVerySmallScreen) {
    final isSelected = selectedTab == label;
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () => setState(() => selectedTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.0 : (isVerySmallScreen ? 12.w : 16.w),
          vertical: isTablet ? 6.0 : (isVerySmallScreen ? 5.h : 7.h),
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 13.0 : (isVerySmallScreen ? 12.sp : 14.sp),
            color: isSelected ? primaryColor : lightSecondaryText,
          ),
        ),
      ),
    );
  }
}

// ── Private item widget ──────────────────────────────────────────────────────

class _BeneficiaryItem extends StatelessWidget {
  final String name;
  final String account;
  final String? logoUrl;
  final bool showAvatar;
  final bool showLogo;
  final Widget? customLogo;
  final bool isSmallScreen;
  final bool isVerySmallScreen;
  final VoidCallback onTap;

  const _BeneficiaryItem({
    required this.name,
    required this.account,
    this.logoUrl,
    required this.showAvatar,
    required this.showLogo,
    this.customLogo,
    required this.isSmallScreen,
    required this.isVerySmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final avatarSize = isTablet
        ? 36.0
        : (isVerySmallScreen ? 34.w : (isSmallScreen ? 38.w : 42.w));
    final avatarRadius = avatarSize / 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 8.0 : (isSmallScreen ? 8.h : 10.h),
            horizontal: isTablet ? 12.0 : (isVerySmallScreen ? 8.w : 12.w),
          ),
          decoration: BoxDecoration(
            color: lightSurface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              /// Avatar with initials
              if (showAvatar) ...[
                Container(
                  height: avatarSize,
                  width: avatarSize,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 13.0 : (isVerySmallScreen ? 13.sp : 15.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 10.0 : (isVerySmallScreen ? 8.w : 10.w)),
              ],

              /// Name + account
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
                        fontSize: isTablet
                            ? 13.0
                            : (isVerySmallScreen
                                ? 12.sp
                                : (isSmallScreen ? 13.sp : 14.sp)),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      account,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: lightSecondaryText,
                        fontSize: isTablet ? 11.5 : (isVerySmallScreen ? 10.sp : 12.sp),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 4),

              /// Logo / icon on the right
              if (showLogo)
                customLogo ??
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: (logoUrl != null && logoUrl!.isNotEmpty)
                            ? Image.network(
                                logoUrl!,
                                height: avatarSize * 0.7,
                                width: avatarSize * 0.7,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.account_circle,
                                  color: primaryColor,
                                  size: avatarRadius,
                                ),
                              )
                            : Image.asset(
                                'assets/svg/logo-two.png',
                                height: avatarSize * 0.6,
                                width: avatarSize * 0.6,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.account_circle,
                                  color: primaryColor,
                                  size: avatarRadius,
                                ),
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

/// 🔹 PROGRESS INDICATOR - kept for any other call-sites that use it
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
          CircularProgressIndicator(
            value: 1,
            strokeWidth: strokeWidth.toDouble(),
            valueColor:
                AlwaysStoppedAnimation<Color>(kGray.withValues(alpha: 0.2)),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth.toDouble(),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: Colors.transparent,
          ),
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