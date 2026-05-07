import 'package:bia/app/utils/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/constants.dart';
import '../colors.dart';
import '../router/route_constant.dart';

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
  static String _getServiceId(String providerName) {
    final map = {
      'MTN': 'mtn-data',
      'Airtel': 'airtel-data',
      'Glo': 'glo-data',
      '9mobile': 'etisalat-data',
    };
    return map[providerName] ?? 'mtn-data';
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
    final Color bgColor = config.backgroundColor ?? lightBackground;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext modalContext) {
        final theme = Theme.of(context);

        return WillPopScope(
          onWillPop: () async => false,
          child: AnimatedPadding(
            padding: MediaQuery.of(modalContext).viewInsets,
            duration: const Duration(milliseconds: 100),
            child: Align(
              alignment: Alignment.bottomCenter, // 🔥 FORCE BOTTOM ALIGNMENT
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(r.sheetRadius)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: r.horizontalPadding,
                  vertical: r.verticalPadding,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Drag Handle
                      if (config.showDragHandle)
                        Container(
                          width: isSmallScreen(modalContext) ? 32.w : 40.w,
                          height: isSmallScreen(modalContext) ? 3.h : 4.h,
                          decoration: BoxDecoration(
                            color: grey300,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      if (config.showDragHandle) SizedBox(height: r.mediumSpacing),

                      // Title - Centered
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          config.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith (
                            fontSize: r.titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (config.subtitle != null) ...[
                        SizedBox(height: r.smallSpacing),
                        Text(
                          config.subtitle!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith (
                            fontSize: r.subtitleFontSize,
                            color: grey600,
                          ),
                        ),
                      ],
                      SizedBox(height: r.largeSpacing),

                      // Details Card - Responsive with max width
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                        child: _buildDetailsCard(
                          modalContext,
                          config: config,
                          useCashback: useCashback,
                          currencySymbol: currencySymbol,
                          primaryColor: primary,
                          r: _ResponsiveHelper(modalContext),
                        ),
                      ),
                      SizedBox(height: r.largeSpacing),

                      // Continue Button - Full width responsive
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                        child: SizedBox(
                          width: double.infinity,
                          height: r.buttonHeight,
                          child: CustomButton(
                            buttonColor: primary,
                            buttonTextColor: lightBackground,
                            buttonName: 'Continue',
                            //fontSize: r.bodyFontSize,
                            onPressed: () {

                              // 🔥 DISMISS KEYBOARD FIRST
                              FocusScope.of(modalContext).unfocus();
                              Navigator.pop(modalContext);

                              String? getValue(String label) {
                                try {
                                  return config.details.firstWhere((e) => e.label == label).value;
                                } catch (_) {
                                  return null;
                                }
                              }

                         // 🔥 Handle BOTH airtime/data AND cable
                              final network =
                                  getValue("Network") ??
                                      getValue("Provider") ??
                                      "";
                              final meterNumber = getValue("Meter Number") ?? "";
                              final serviceId =
                                  getValue("serviceId") ?? network.toLowerCase();

                              final phone =
                                  getValue("Phone Number") ??
                                      getValue("Smartcard") ??
                                      getValue("Meter Number") ??
                                      "";

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
                                    "userPhone": userPhone, // Pass user's phone
                                  },
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: r.mediumSpacing),

                      // Cancel Button
                      if (config.cancelButtonText != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            config.onCancel?.call();
                          },
                          child: Text(
                            config.cancelButtonText!,
                            style: theme.textTheme.bodyMedium?.copyWith (
                              color: grey,
                              fontSize: r.bodyFontSize,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.cardPadding),
      decoration: BoxDecoration(
        color: grey50,
        borderRadius: BorderRadius.circular(r.cardRadius),
        border: Border.all(color: grey200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Detail Rows
          for (int i = 0; i < config.details.length; i++) ...[
            _buildDetailRow(
              context,
              label: config.details[i].label,
              value: config.details[i].value,
              logo: config.details[i].logo,
              isHighlighted: config.details[i].isHighlighted,
              r: r,
            ),
            if (i < config.details.length - 1)
              Divider(height: r.mediumSpacing, color: grey300),
          ],

          // Cashback Bonus
          if (config.showCashback && config.cashbackAmount != null) ...[
            if (config.details.isNotEmpty)
              Divider(height: r.mediumSpacing, color: grey300),
            _buildCashbackBonusRow(context, config.cashbackAmount!, r),
          ],

          // Cashback Toggle
          if (config.showCashback) ...[
            ValueListenableBuilder<bool>(
              valueListenable: useCashback,
              builder: (context, isUsing, child) {
                return _buildSummaryRow(
                  context,
                  'Use Cashback (${currencySymbol}34.00)',
                  '-${currencySymbol}34.00',
                  hasToggle: true,
                  isToggled: isUsing,
                  onToggle: (value) => useCashback.value = value,
                  primaryColor: primaryColor,
                  r: r,
                );
              },
            ),
          ],

          // Wallet Balance
          if (config.showWalletBalance) ...[
            Divider(height: r.mediumSpacing, color: grey300),
            _buildWalletBalanceRow(
              context,
              balance: config.walletBalance ?? _getWalletBalance().toStringAsFixed(2),
              currencySymbol: currencySymbol,
              primaryColor: primaryColor,
              r: r,
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
        required _ResponsiveHelper r,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.smallSpacing / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith (
                color: grey600,
                fontSize: r.bodyFontSize,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (logo != null)
                  Container(
                    width: r.logoSize,
                    height: r.logoSize,
                    margin: EdgeInsets.only(right: 6.w),
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
                    style: theme.textTheme.bodyMedium?.copyWith (
                      color: isHighlighted ? primaryGreenColor600 : transparentBlack87,
                      fontSize: r.bodyFontSize,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCashbackBonusRow(
      BuildContext context,
      String value,
      _ResponsiveHelper r,
      ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith (
              color: primaryGreenColor600,
              fontWeight: FontWeight.bold,
              fontSize: r.bodyFontSize,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSummaryRow(
      BuildContext context,
      String title,
      String value, {
        bool bonus = false,
        bool hasToggle = false,
        bool isToggled = false,
        ValueChanged<bool>? onToggle,
        required Color primaryColor,
        required _ResponsiveHelper r,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.smallSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: grey600,
                fontSize: r.bodyFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: bonus
                    ? theme.textTheme.bodyMedium?.copyWith (
                  color: primaryGreenColor600,
                  fontWeight: FontWeight.bold,
                  fontSize: r.bodyFontSize,
                )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: r.bodyFontSize,
                ),
              ),
              SizedBox(width: 8.w),
              if (hasToggle)
                GestureDetector(
                  onTap: () {
                    if (onToggle != null) {
                      onToggle(!isToggled);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: r.toggleWidth,
                    height: r.toggleHeight,
                    decoration: BoxDecoration(
                      color: isToggled ? primaryColor : grey300,
                      borderRadius: BorderRadius.circular(r.toggleHeight / 2),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isToggled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: r.toggleKnobSize,
                        height: r.toggleKnobSize,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: const BoxDecoration(
                          color: lightBackground,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildWalletBalanceRow(
      BuildContext context, {
        required String balance,
        required String currencySymbol,
        required Color primaryColor,
        required _ResponsiveHelper r,
      }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: r.mediumSpacing,
        horizontal: r.cardPadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: grey300),
        borderRadius: BorderRadius.circular(r.buttonRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: primaryColor,
            size: r.iconSize,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: grey600,
                    fontSize: r.smallFontSize,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$currencySymbol$balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: r.bodyFontSize,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: primaryColor,
            size: r.iconSize,
          ),
        ],
      ),
    );
  }
}