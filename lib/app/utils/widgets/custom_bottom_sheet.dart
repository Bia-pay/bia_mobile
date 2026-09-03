import 'package:bia/app/utils/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../colors.dart';
import '../router/route_constant.dart';
import '../image.dart';

/// Configuration class for bottom sheet customization
class BottomSheetConfig {
  final String title;
  final String? subtitle;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool showDragHandle;
  final bool showCashback;
  final bool showWalletBalance;
  final String? cashbackAmount;
  final String? walletBalance;
  final List<BottomSheetDetailItem> details;
  final int pinLength;
  final bool obscurePin;
  final String confirmButtonText;
  final String? cancelButtonText;
  final VoidCallback? onCancel;
  final double amount;

  const BottomSheetConfig({
    required this.title,
    this.subtitle,
    this.primaryColor,
    this.backgroundColor,
    this.showDragHandle = true,
    this.showCashback = false,
    this.showWalletBalance = true,
    this.cashbackAmount,
    this.walletBalance,
    this.details = const [],
    this.pinLength = 4,
    this.obscurePin = true,
    this.confirmButtonText = 'Confirm',
    this.cancelButtonText,
    this.onCancel,
    required this.amount,
  });
}

/// Detail item for the bottom sheet
class BottomSheetDetailItem {
  final String label;
  final String value;
  final String? logo;
  final bool isHighlighted;

  const BottomSheetDetailItem({
    required this.label,
    required this.value,
    this.logo,
    this.isHighlighted = false,
  });
}

/// Responsive helper class
class _ResponsiveHelper {
  final BuildContext context;

  _ResponsiveHelper(this.context);

  Size get size => MediaQuery.of(context).size;
  double get width => size.width;
  double get height => size.height;

  bool get isSmall => width < 360;
  bool get isMedium => width >= 360 && width < 600;
  bool get isTablet => width >= 600 && width < 900;
  bool get isLarge => width >= 900;
  bool get isLandscape => width > height;

  // Responsive padding
  double get horizontalPadding => isSmall ? 16.w : (isTablet ? 32.w : 24.w);
  double get verticalPadding => isSmall ? 16.h : (isTablet ? 32.h : 24.h);
  double get cardPadding => isSmall ? 16.w : (isTablet ? 28.w : 20.w);

  // Responsive font sizes
  double get titleFontSize => isSmall ? 20.sp : (isTablet ? 32.sp : 25.sp);
  double get subtitleFontSize => isSmall ? 11.sp : (isTablet ? 16.sp : 12.sp);
  double get bodyFontSize => isSmall ? 10.sp : (isTablet ? 14.sp : 11.sp);
  double get smallFontSize => isSmall ? 9.sp : (isTablet ? 12.sp : 10.sp);

  // Responsive spacing
  double get smallSpacing => isSmall ? 6.h : (isTablet ? 12.h : 8.h);
  double get mediumSpacing => isSmall ? 12.h : (isTablet ? 20.h : 16.h);
  double get largeSpacing => isSmall ? 16.h : (isTablet ? 28.h : 24.h);

  // Responsive border radius
  double get sheetRadius => isSmall ? 16.r : (isTablet ? 32.r : 24.r);
  double get cardRadius => isSmall ? 12.r : (isTablet ? 20.r : 16.r);
  double get buttonRadius => isSmall ? 8.r : (isTablet ? 16.r : 12.r);

  // Responsive icon/logo sizes
  double get logoSize => isSmall ? 16.w : (isTablet ? 28.w : 20.w);
  double get iconSize => isSmall ? 18.sp : (isTablet ? 24.sp : 20.sp);

  // Responsive toggle dimensions
  double get toggleWidth => isSmall ? 36.w : (isTablet ? 48.w : 40.w);
  double get toggleHeight => isSmall ? 20.h : (isTablet ? 26.h : 22.h);
  double get toggleKnobSize => isSmall ? 16.w : (isTablet ? 22.w : 18.w);

  // Responsive button height
  double get buttonHeight => isSmall ? 44.h : (isTablet ? 60.h : 48.h);

  // Max width constraint for large screens (centered content but bottom positioned)
  double get maxContentWidth => isLarge ? 600.w : double.infinity;
}

/// Reusable confirmation bottom sheet with PIN input
class ConfirmationBottomSheet {
  static String? _detectProviderLogo(String providerName, List<BottomSheetDetailItem> details) {
    // First check if any detail item already provides a logo
    for (final item in details) {
      if (item.logo != null && item.logo!.isNotEmpty) {
        return item.logo;
      }
    }
    // Fallback based on provider name match
    final name = providerName.toLowerCase();
    if (name.contains('mtn')) return 'assets/svg/mtn.jpg';
    if (name.contains('airtel')) return 'assets/svg/airtel.png';
    if (name.contains('glo')) return 'assets/svg/glo.jpg';
    if (name.contains('9mobile') || name.contains('etisalat')) return 'assets/svg/9mobile.png';
    if (name.contains('dstv')) return 'assets/svg/dstv.png';
    if (name.contains('gotv')) return 'assets/svg/gotv.png';
    if (name.contains('startimes')) return 'assets/svg/startimes.png';
    if (name.contains('showmax')) return 'assets/svg/showmax.png';
    return null;
  }

  static void show({
    required BuildContext context,
    required BottomSheetConfig config,
    required Function(String pin) onConfirm,
  }) {
    final r = _ResponsiveHelper(context);
    final currencySymbol = Constants.nairaCurrencySymbol;
    final ValueNotifier<bool> useCashback = ValueNotifier<bool>(false);
    final Color primary = config.primaryColor ?? primaryColor;
    final Color bgColor = config.backgroundColor ?? offWhiteBackground;
    final isTablet = MediaQuery.of(context).size.width > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext modalContext) {
        return PopScope(
          canPop: true,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(isTablet ? 24.0 : r.sheetRadius)),
            ),
            padding: EdgeInsets.only(
              left: isTablet ? 24.0 : r.horizontalPadding,
              right: isTablet ? 24.0 : r.horizontalPadding,
              top: isTablet ? 16.0 : r.verticalPadding,
              bottom: 0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                      // Drag Handle
                      if (config.showDragHandle)
                        Container(
                          width: isTablet ? 40.0 : 40.w,
                          height: isTablet ? 4.0 : 4.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      if (config.showDragHandle) SizedBox(height: isTablet ? 12.0 : 16.h),

                      // Title - Centered
                      Text(
                        config.title.startsWith('₦') || config.title.startsWith(currencySymbol)
                            ? (config.subtitle ?? 'Confirm Payment')
                            : config.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4.0 : 6.h),
                      Text(
                        'Verify details before completing transaction',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 12.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12.0 : 16.h),

                      // Premium Large Amount Display
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isTablet ? 480.0 : r.maxContentWidth),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 16.w,
                            vertical: isTablet ? 14.0 : 18.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                            border: Border.all(
                              color: const Color(0xFFF1F5F9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TOTAL TRANSACTION AMOUNT',
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 10.sp,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: isTablet ? 6.0 : 8.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$currencySymbol${NumberFormat('#,##0.00').format(config.amount)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 26.0 : 28.sp,
                                    fontWeight: FontWeight.w900,
                                    color: primary,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                              if (config.showCashback &&
                                  config.cashbackAmount != null &&
                                  config.cashbackAmount!.isNotEmpty) ...[
                                SizedBox(height: isTablet ? 6.0 : 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 10.0 : 10.w,
                                    vertical: isTablet ? 4.0 : 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 8.0 : 10.r),
                                    border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.card_giftcard_rounded,
                                        color: const Color(0xFF10B981),
                                        size: isTablet ? 13.0 : 13.sp,
                                      ),
                                      SizedBox(width: isTablet ? 4.0 : 4.w),
                                      Flexible(
                                        child: Text(
                                          'Earn ${config.cashbackAmount}',
                                          style: TextStyle(
                                            color: const Color(0xFF10B981),
                                            fontSize: isTablet ? 11.0 : 11.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 12.0 : 16.h),

                      // Visual Diagram (Sender -> Recipient)
                      Builder(builder: (ctx) {
                        String? getValue(String label) {
                          try {
                            return config.details.firstWhere(
                              (e) => e.label.toLowerCase() == label.toLowerCase() || 
                                     (label.toLowerCase() == "provider" && e.label.toLowerCase() == "network") ||
                                     (label.toLowerCase() == "network" && e.label.toLowerCase() == "provider")
                            ).value;
                          } catch (_) {
                            return null;
                          }
                        }
                        final providerVal = getValue("Network") ?? getValue("Provider") ?? "";
                        final recipientName = providerVal.isNotEmpty ? providerVal : (config.subtitle ?? "Utility");
                        final logoPath = _detectProviderLogo(recipientName, config.details);

                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 480.0 : r.maxContentWidth),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16.0 : 20.w,
                              vertical: isTablet ? 10.0 : 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Sender Card
                                Column(
                                  children: [
                                    Container(
                                      width: isTablet ? 40.0 : 48.r,
                                      height: isTablet ? 40.0 : 48.r,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _buildUserAvatar(),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 4.0 : 6.h),
                                    Text(
                                      'My Wallet',
                                      style: TextStyle(
                                        fontSize: isTablet ? 11.0 : 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),

                                // Connection
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(4, (index) {
                                          return Container(
                                            margin: EdgeInsets.symmetric(horizontal: isTablet ? 2.0 : 2.w),
                                            width: isTablet ? 4.0 : 5.w,
                                            height: isTablet ? 4.0 : 5.w,
                                            decoration: BoxDecoration(
                                              color: primary.withValues(alpha: (index + 1) * 0.25),
                                              shape: BoxShape.circle,
                                            ),
                                          );
                                        }),
                                      ),
                                      SizedBox(height: isTablet ? 3.0 : 4.h),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: primary,
                                        size: isTablet ? 14.0 : 16,
                                      ),
                                    ],
                                  ),
                                ),

                                // Recipient Card
                                Column(
                                  children: [
                                    if (logoPath != null)
                                      Container(
                                        width: isTablet ? 40.0 : 48.r,
                                        height: isTablet ? 40.0 : 48.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primary.withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            logoPath,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: isTablet ? 40.0 : 48.r,
                                        height: isTablet ? 40.0 : 48.r,
                                        decoration: BoxDecoration(
                                          color: primaryGreenColor600.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primaryGreenColor600.withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'U',
                                            style: TextStyle(
                                              color: primaryGreenColor600,
                                              fontSize: isTablet ? 16.0 : 18.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: isTablet ? 4.0 : 6.h),
                                    SizedBox(
                                      width: isTablet ? 70.0 : 80.w,
                                      child: Text(
                                        recipientName.split(' ')[0],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isTablet ? 11.0 : 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: isTablet ? 12.0 : 16.h),

                      // Details Card
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isTablet ? 480.0 : r.maxContentWidth),
                        child: _buildDetailsCard(
                          modalContext,
                          config: config,
                          useCashback: useCashback,
                          currencySymbol: currencySymbol,
                          primaryColor: primary,
                          r: _ResponsiveHelper(modalContext),
                        ),
                      ),
                      SizedBox(height: isTablet ? 12.0 : 16.h),

                      // Wallet Balance Mini Card
                      if (config.showWalletBalance) ...[
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 480.0 : r.maxContentWidth),
                          child: _buildWalletBalanceRow(
                            modalContext,
                            balance: config.walletBalance ?? NumberFormat('#,##0.00').format(_getWalletBalance()),
                            currencySymbol: currencySymbol,
                            primaryColor: primary,
                          ),
                        ),
                        SizedBox(height: isTablet ? 16.0 : 24.h),
                      ],

                      // Continue Button - Full width responsive
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isTablet ? 480.0 : r.maxContentWidth),
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            buttonColor: primary,
                            buttonTextColor: Colors.white,
                            buttonName: 'Continue to PIN',
                            onPressed: () {
                              // 🔥 DISMISS KEYBOARD FIRST
                              FocusScope.of(modalContext).unfocus();
                              Navigator.pop(modalContext);

                              String? getValue(String label) {
                                try {
                                  return config.details.firstWhere(
                                    (e) => e.label.toLowerCase() == label.toLowerCase() || 
                                           (label.toLowerCase() == "provider" && e.label.toLowerCase() == "network") ||
                                           (label.toLowerCase() == "network" && e.label.toLowerCase() == "provider")
                                  ).value;
                                } catch (_) {
                                  return null;
                                }
                              }

                              final network = getValue("Network") ?? getValue("Provider") ?? "";
                              final meterNumber = getValue("Meter Number") ?? "";
                              final serviceId = getValue("serviceId") ?? network.toLowerCase();
                              final phone = getValue("Phone Number") ?? getValue("Smartcard") ?? getValue("Meter Number") ?? "";
                              final userPhone = Hive.box('authBox').get('phone', defaultValue: '');

                              final variationCode = config.details
                                  .firstWhere(
                                    (e) => e.label.toLowerCase().contains("variation"),
                                    orElse: () => const BottomSheetDetailItem(label: "", value: ""),
                                  )
                                  .value;

                              final packageName = config.details
                                  .firstWhere(
                                    (e) => e.label.toLowerCase().contains("package"),
                                    orElse: () => const BottomSheetDetailItem(label: "", value: ""),
                                  )
                                  .value;

                              modalContext.pushNamed(
                                RouteList.transactionPin,
                                extra: {
                                  "type": config.subtitle?.toLowerCase().contains("electricity") == true
                                      ? "electricity"
                                      : config.subtitle?.toLowerCase().contains("data") == true
                                      ? "data"
                                      : config.subtitle?.toLowerCase().contains("cable") == true
                                      ? "cable"
                                      : "airtime",
                                  "amount": config.amount,
                                  "recipientName": network,
                                  "recipientAccount": phone,
                                  "meta": {
                                    "network": network.toLowerCase(),
                                    "serviceId": serviceId,
                                    "variationCode": variationCode,
                                    "packageName": packageName,
                                    "meterNumber": meterNumber, 
                                    "userPhone": userPhone,
                                  },
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Cancel Button
                      if (config.cancelButtonText != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            config.onCancel?.call();
                          },
                          child: Text(
                            config.cancelButtonText!,
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(height: 16.h + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static Widget _buildDetailsCard(
    BuildContext context, {
    required BottomSheetConfig config,
    required ValueNotifier<bool> useCashback,
    required String currencySymbol,
    required Color primaryColor,
    required _ResponsiveHelper r,
  }) {
    // Filter out internal metadata details (not shown to user, used for navigation)
    final visibleDetails = config.details.where((e) {
      final label = e.label.toLowerCase().replaceAll(' ', '');
      return label != "serviceid" && label != "variationcode";
    }).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Detail Rows
          for (int i = 0; i < visibleDetails.length; i++) ...[
            _buildDetailRow(
              context,
              label: visibleDetails[i].label,
              value: visibleDetails[i].value,
              logo: visibleDetails[i].logo,
              isHighlighted: visibleDetails[i].isHighlighted,
            ),
            if (i < visibleDetails.length - 1 || 
                (config.showCashback && config.cashbackAmount != null))
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ],

          // Cashback Bonus
          if (config.showCashback && config.cashbackAmount != null) ...[
            _buildSummaryRow(
              context,
              'Cashback Earned',
              config.cashbackAmount!,
              isHighlighted: true,
              isCashbackEarned: true,
            ),
          ],
        ],
      ),
    );
  }

  static double _getWalletBalance() {
    try {
      final box = Hive.box('authBox');
      final balanceStr = box.get('balance', defaultValue: '0').toString();
      return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    String? logo,
    bool isHighlighted = false,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: isTablet ? 13.0 : 13.sp,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: isTablet ? 8.0 : 8.w),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (logo != null)
                Container(
                  width: isTablet ? 18.0 : 18.w,
                  height: isTablet ? 18.0 : 18.w,
                  margin: EdgeInsets.only(right: isTablet ? 6.0 : 6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isHighlighted ? primaryGreenColor600 : const Color(0xFF0F172A),
                    fontSize: isTablet ? 13.0 : 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSummaryRow(
    BuildContext context,
    String title,
    String value, {
    bool isHighlighted = false,
    bool isCashbackEarned = false,
    bool hasToggle = false,
    bool isToggled = false,
    ValueChanged<bool>? onToggle,
    Color? primaryColor,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: isTablet ? 13.0 : 13.sp,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              color: isCashbackEarned 
                  ? primaryGreenColor600 
                  : (isHighlighted ? (primaryColor ?? const Color(0xFF0F172A)) : const Color(0xFF0F172A)),
              fontSize: isTablet ? 14.0 : 14.sp,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (hasToggle)
          GestureDetector(
            onTap: () {
              if (onToggle != null) {
                onToggle(!isToggled);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTablet ? 38.0 : 38.w,
              height: isTablet ? 22.0 : 22.h,
              decoration: BoxDecoration(
                color: isToggled ? (primaryColor ?? const Color(0xFF26B4DF)) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isToggled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: isTablet ? 18.0 : 18.w,
                  height: isTablet ? 18.0 : 18.w,
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 2.0 : 2.w),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildWalletBalanceRow(
    BuildContext context, {
    required String balance,
    required String currencySymbol,
    required Color primaryColor,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 10.0 : 12.h,
        horizontal: isTablet ? 14.0 : 16.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 6.0 : 8.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: primaryColor,
              size: isTablet ? 18.0 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 10.0 : 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: isTablet ? 11.0 : 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isTablet ? 2.0 : 2.h),
                Text(
                  '$currencySymbol$balance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 14.0 : 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: primaryColor,
            size: isTablet ? 18.0 : 20,
          ),
        ],
      ),
    );
  }

  static Widget _buildUserAvatar() {
    try {
      final box = Hive.box('authBox');
      final picture = box.get('picture')?.toString();
      final fullname = box.get('fullname')?.toString() ?? 'default';
      
      final avatarUrl = (picture != null && picture.isNotEmpty)
          ? picture
          : getDiceBearAvatar(fullname);

      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(getDiceBearAvatar(fullname), fit: BoxFit.cover),
      );
    } catch (_) {
      return const Icon(
        Icons.account_balance_wallet_rounded,
        color: Colors.white,
        size: 22,
      );
    }
  }
}