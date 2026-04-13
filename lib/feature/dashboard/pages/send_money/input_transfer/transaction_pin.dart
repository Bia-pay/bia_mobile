import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class TransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String type; // airtime | data | transfer | cable | electricity
  final Map<String, dynamic>? meta;

  const TransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.type,
    this.meta,
  });

  @override
  ConsumerState<TransactionPin> createState() => _TransactionPinState();
}

class _TransactionPinState extends ConsumerState<TransactionPin> {
  String pin = "";
  late final TextEditingController pinController;

  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');

      // Crucial for user-specific settings: Use the correct identifier
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) {
        debugPrint('🔐 TransactionPin: No userId found');
        return;
      }

      final biometricService = BiometricService();
      final isAvailable = await biometricService.canCheckBiometrics();
      final isEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
      final typeName = await biometricService.getBiometricTypeName();
      final savedPin = await biometricService.getTransactionPin(effectiveUserId);

      debugPrint('🔐 Checking biometric for user: "$effectiveUserId"');
      debugPrint('🔐 isEnabled: $isEnabled, hasPin: ${savedPin != null}');

      if (mounted) {
        setState(() {
          _hasBiometric = isAvailable;
          _biometricEnabled = isEnabled && savedPin != null;
          _biometricTypeName = typeName;
        });
      }

      // Automatically trigger biometric if enabled
      if (isAvailable && isEnabled && savedPin != null) {
        Future.delayed(const Duration(milliseconds: 500), _authenticateWithBiometric);
      }
    } catch (e) {
      debugPrint('❌ Error initializing biometrics: $e');
    }
  }

  /// Authenticate with biometric and get PIN
  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;
    
    if (!_hasBiometric || !_biometricEnabled) {
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) {
        return;
      }

      final biometricService = BiometricService();
      
      // Authenticate with biometric
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to complete transaction',
        biometricOnly: true,
      );

      if (!authenticated) {
        debugPrint('❌ Biometric authentication cancelled');
        return;
      }

      // Get saved PIN
      final savedPin = await biometricService.getTransactionPin(effectiveUserId);

      if (savedPin != null && savedPin.isNotEmpty) {
        debugPrint('✅ Biometric authentication successful, processing transaction...');
        await _processTransaction(savedPin);
      } else {
        debugPrint('❌ No saved PIN found');
        _showErrorModal('Error', 'Please set up your transaction PIN first');
      }
    } catch (e) {
      debugPrint('⚠️ Biometric error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  void addDigit(String value) {
    if (pin.length >= 4) return;
    setState(() {
      pin += value;
      pinController.text = pin;
    });

    if (pin.length == 4) {
      _processTransaction(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      pinController.text = pin;
    });
  }

  // Show error modal instead of routing to success page
  void _showErrorModal(String title, String message, {bool isNetworkError = false, VoidCallback? onRetry, bool clearPin = false}) {
    if (clearPin && mounted) {
      setState(() {
        pin = "";
        pinController.text = "";
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        contentPadding: EdgeInsets.all(24.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isNetworkError ? pendingColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: isNetworkError ? pendingColor : errorColor,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: darkBackground,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                if (onRetry != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onRetry();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check if API response indicates failure
  bool _isApiFailure(dynamic response) {
    if (response == null) return true;
    return response.responseSuccessful == false;
  }

  // Check if error is specifically a wrong PIN error
  bool _isWrongPinError(dynamic response, String errorMessage) {
    final msg = (response?.responseMessage ?? errorMessage).toString().toLowerCase();
    return msg.contains('pin') ||
        msg.contains('incorrect') ||
        msg.contains('invalid') ||
        msg.contains('wrong') ||
        msg.contains('unauthorized');
  }

  // Check if error is a server/database error (backend issue)
  bool _isServerError(dynamic response, String errorMessage) {
    final msg = (response?.responseMessage ?? errorMessage).toString().toLowerCase();
    return msg.contains('database') ||
        msg.contains('prisma') ||
        msg.contains('server') ||
        msg.contains('internal server error') ||
        msg.contains('500') ||
        msg.contains("can't reach") ||
        msg.contains('connection refused');
  }

  // Check if error is a network error (client-side)
  bool _isNetworkError(dynamic error) {
    if (error == null) return false;
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('timeout') ||
        (msg.contains('connection') && !msg.contains('database')) ||
        msg.contains('network') ||
        msg.contains('internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('no route to host');
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic response, dynamic error) {
    if (error != null) return error.toString();

    final msg = response?.responseMessage ?? "Transaction failed";

    // Clean up technical error messages
    if (_isServerError(response, '')) {
      return "Our servers are experiencing issues. Please try again later.";
    }

    // Truncate very long technical errors
    if (msg.length > 200) {
      return "${msg.substring(0, 200)}...";
    }

    return msg;
  }

  // Helper to determine status from response
  String _determineStatus(dynamic response) {
    if (response == null) return "failed";

    final isSuccess = response.responseSuccessful == true ||
        response.responseBody?.status == "SUCCESS" ||
        response.responseBody?.status == "success";

    if (isSuccess) return "success";

    final isPending = response.responseBody?.status == "PENDING" ||
        response.responseBody?.status == "pending" ||
        response.responseBody?.status == "PROCESSING";

    if (isPending) return "pending";

    return "failed";
  }

  Future<void> _processTransaction(String transactionPin) async {
    final controller = ref.read(dashboardControllerProvider.notifier);

    EasyLoading.show(status: "Processing...");

    dynamic response;
    String status = "failed";

    try {
      if (widget.type == "airtime") {
        final network = widget.meta?['network'];
        if (network == null || network.isEmpty) {
          throw Exception("Network not found");
        }

        response = await controller.buyAirtime(
          context,
          phone: widget.recipientAccount,
          amount: widget.amount.toInt(),
          network: network.toString().toLowerCase(),
          pin: transactionPin,
        );
      } else if (widget.type == "data") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];

        if (serviceId == null || variationCode == null) {
          throw Exception("Data plan not selected properly");
        }

        response = await controller.buyData(
          context,
          phone: widget.recipientAccount,
          serviceId: serviceId,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          pin: transactionPin,
        );
      } else if (widget.type == "cable") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];
        final packageName = widget.meta?['packageName'];

        if (serviceId == null || variationCode == null || variationCode.isEmpty) {
          throw Exception("Cable data missing");
        }

        response = await controller.buyCable(
          context,
          serviceId: serviceId,
          smartcard: widget.recipientAccount,
          packageName: packageName ?? variationCode,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          phone: widget.recipientAccount,
          pin: transactionPin,
        );
      } else if (widget.type == "electricity") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];

        if (serviceId == null || variationCode == null) {
          throw Exception("Electricity data missing");
        }

        response = await controller.buyElectricity(
          context,
          serviceId: serviceId,
          meterNumber: widget.recipientAccount,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          phone: widget.recipientAccount,
          pin: transactionPin,
        );
      } else {
        response = await controller.sendMoney(
          context,
          widget.recipientAccount,
          widget.amount.toStringAsFixed(2),
          'Transfer',
          transactionPin,
          save: widget.saveAsBeneficiary,
        );
      }

      EasyLoading.dismiss();

      // Check if API returned failure (responseSuccessful: false)
      if (_isApiFailure(response)) {
        final errorMessage = _getErrorMessage(response, null);

        // Check if it's specifically a wrong PIN error
        if (_isWrongPinError(response, '')) {
          _showErrorModal(
            'Incorrect PIN',
            'The PIN you entered is incorrect. Please try again.',
            clearPin: true,
          );
          return;
        }

        // Check if it's a server/database error
        if (_isServerError(response, '')) {
          _showErrorModal(
            'Server Error',
            errorMessage,
            isNetworkError: true,
            onRetry: () => _processTransaction(transactionPin),
          );
          return;
        }

        // Show generic error modal for other API failures
        _showErrorModal(
          'Transaction Failed',
          errorMessage,
          clearPin: false,
        );
        return;
      }

      // Determine status from response
      status = _determineStatus(response);

      // Navigate to result screen with appropriate status
      context.goNamed(
        RouteList.successScreen,
        extra: {
          "type": status,
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": response?.responseBody?.reference ?? '',
          "channel": widget.type.toUpperCase(),
          "message": response?.responseMessage ?? '',
        },
      );

    } catch (e) {
      EasyLoading.dismiss();

      // Check for network error - show modal with retry option
      if (_isNetworkError(e)) {
        _showErrorModal(
          'No Internet Connection',
          'Please check your internet connection and try again.',
          isNetworkError: true,
          onRetry: () => _processTransaction(transactionPin),
        );
        return;
      }

      // Check if it's a wrong PIN error in the exception message
      if (_isWrongPinError(null, e.toString())) {
        _showErrorModal(
          'Incorrect PIN',
          'The PIN you entered is incorrect. Please try again.',
          clearPin: true,
        );
        return;
      }

      // For other errors, show error modal
      _showErrorModal(
        'Transaction Failed',
        e.toString(),
        clearPin: false,
      );
    }
  }

  Future<void> _handleForgotPin() async {
    try {
      LoadingHelper.show();

      final controller = ref.read(dashboardControllerProvider.notifier);

      final result = await controller.forgotPaymentPin(context);

      LoadingHelper.dismiss();

      if (!mounted) return;

      if (result != null && result.responseSuccessful == true) {
        context.pushNamed(RouteList.forgotPin);
      } else {
        final errorMsg = _getErrorMessage(result, null);
        _showErrorModal(
          'Failed to Send OTP',
          errorMsg,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      _showErrorModal(
        'Something Went Wrong',
        "An error occurred: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isLargeScreen = screenHeight > 900;

    final topSpacing = isSmallScreen ? 20.h : (isLargeScreen ? 60.h : 55.h);
    final sectionSpacing = isSmallScreen ? 16.h : (isLargeScreen ? 30.h : 30.h);
    final pinSpacing = isSmallScreen ? 24.h : (isLargeScreen ? 40.h : 30.h);
    final keypadSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 50.h : 60.h);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: isSmallScreen ? 20.h : 30.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topSpacing),

                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12.h : 15.h,
                          horizontal: isSmallScreen ? 12.w : 15.w,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.4),
                              primaryColor,
                              primaryColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(isSmallScreen ? 8.r : 10.r),
                          ),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: isSmallScreen ? 24.sp : 30.sp,
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      Text(
                        'Enter Transaction PIN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16.sp : (isLargeScreen ? 24.sp : 20.sp),
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;
                          final dotSize = isSmallScreen ? 12.w : 14.w;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.symmetric(horizontal: 6.w),
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: filled ? primaryColor : Colors.grey,
                                width: isSmallScreen ? 1.5 : 2,
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: keypadSpacing),

                      Flexible(
                        fit: FlexFit.loose,
                        child: CustomGridKeypad(
                          onNumberPressed: addDigit,
                          leftAction: ActionKey(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor,
                            onTap: () => _processTransaction(pin),
                          ),
                          rightAction: ActionKey(
                            child: Icon(
                              Icons.backspace,
                              color: primaryColor,
                              size: isSmallScreen ? 20.sp : 24.sp,
                            ),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            onTap: removeDigit,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _handleForgotPin(),
                          child: Text(
                            'Forget Pin?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: lightText,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13.sp : 14.sp,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 10.h : 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}