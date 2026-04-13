import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class BankTransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String bankCode;
  final String bankName;

  const BankTransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.bankCode,
    required this.bankName,
  });

  @override
  ConsumerState<BankTransactionPin> createState() => _BankTransactionPinState();
}

class _BankTransactionPinState extends ConsumerState<BankTransactionPin> {
  String pin = '';
  bool showPinWarning = false;

  // ── Biometric state ───────────────────────────────────────────────────────
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initializeBiometric();
  }

  /// Checks whether biometric payment is set up for the current user and,
  /// if so, auto-triggers the prompt.
  Future<void> _initializeBiometric() async {
    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone  = authBox.get('phone',  defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) return;

      final biometricService = BiometricService();
      final isAvailable = await biometricService.canCheckBiometrics();
      final isEnabled   = await biometricService.isPaymentEnabled(effectiveUserId);
      final savedPin    = await biometricService.getTransactionPin(effectiveUserId);

      debugPrint('🔐 BankTxnPin biometric — user: "$effectiveUserId" '
          'available: $isAvailable enabled: $isEnabled hasPin: ${savedPin != null}');

      if (mounted) {
        setState(() {
          _hasBiometric     = isAvailable;
          _biometricEnabled = isEnabled && savedPin != null;
        });
      }

      // Auto-prompt if everything is set up
      if (isAvailable && isEnabled && savedPin != null) {
        Future.delayed(
          const Duration(milliseconds: 500),
          _authenticateWithBiometric,
        );
      }
    } catch (e) {
      debugPrint('❌ BankTxnPin biometric init error: $e');
    }
  }

  /// Authenticate with biometric, retrieve the saved PIN, then submit.
  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating || !_hasBiometric || !_biometricEnabled) return;

    setState(() => _isAuthenticating = true);

    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone  = authBox.get('phone',  defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) return;

      final biometricService = BiometricService();
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to complete bank transfer',
        biometricOnly: true,
      );

      if (!authenticated) {
        debugPrint('❌ Biometric cancelled by user');
        return;
      }

      final savedPin = await biometricService.getTransactionPin(effectiveUserId);

      if (savedPin != null && savedPin.isNotEmpty) {
        debugPrint('✅ Biometric OK — processing bank transfer');
        await _processTransfer(savedPin: savedPin);
      } else {
        _showErrorModal('Error', 'Please set up your transaction PIN first');
      }
    } catch (e) {
      debugPrint('⚠️ Biometric error: $e');
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void addDigit(String value) {
    if (pin.length >= 4) return;

    setState(() {
      pin += value;
      showPinWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;

    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  // Show error modal instead of routing to success page
  void _showErrorModal(String title, String message, {bool isNetworkError = false, VoidCallback? onRetry, bool clearPin = false}) {
    if (clearPin && mounted) {
      setState(() {
        pin = "";
        showPinWarning = false;
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
                color: isNetworkError ? Colors.orange.withOpacity(0.1) : errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetworkError ? Icons.wifi_off : Icons.error_outline,
                color: isNetworkError ? Colors.orange : errorColor,
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
    // Check if responseSuccessful is explicitly false
    return response.responseSuccessful == false;
  }

  // Check if error is specifically a wrong PIN error
  bool _isWrongPinError(dynamic response, String errorMessage) {
    final msg = (response?.responseMessage ?? errorMessage).toString().toLowerCase();
    return msg.contains('pin') ||
        msg.contains('incorrect') ||
        msg.contains('invalid') ||
        msg.contains('wrong') ||
        msg.contains('unauthorized') ||
        msg.contains('incorrect pin');
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
        msg.contains('connection') && !msg.contains('database') ||
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

  /// Main transfer handler.
  /// [savedPin]: supplied by the biometric path; falls back to the manually
  /// entered [pin] field when null.
  Future<void> _processTransfer({String? savedPin}) async {
    final effectivePin = savedPin ?? pin;

    if (effectivePin.length != 4) {
      setState(() => showPinWarning = true);
      return;
    }

    final controller = ref.read(dashboardControllerProvider.notifier);

    EasyLoading.show(status: 'Processing...');

    try {
      final response = await controller.sendMoneyToBank(
        context,
        accountNumber: widget.recipientAccount,
        bankCode: widget.bankCode,
        bankName: widget.bankName,
        amount: widget.amount.toStringAsFixed(2),
        narration: 'Bank Transfer',
        pin: effectivePin,
        saveBeneficiary: widget.saveAsBeneficiary,
      );

      EasyLoading.dismiss();

      // Check if API returned failure (responseSuccessful: false)
      if (_isApiFailure(response)) {
        final errorMessage = _getErrorMessage(response, null);

        // Wrong PIN
        if (_isWrongPinError(response, '')) {
          _showErrorModal(
            'Incorrect PIN',
            'The PIN you entered is incorrect. Please try again.',
            clearPin: true,
          );
          return;
        }

        // Server/database error
        if (_isServerError(response, '')) {
          _showErrorModal(
            'Server Error',
            errorMessage,
            isNetworkError: true,
            onRetry: _processTransfer,
          );
          return;
        }

        // Generic failure
        _showErrorModal(
          'Transaction Failed',
          errorMessage,
          clearPin: false,
        );
        return;
      }

      final status    = _determineStatus(response);
      final reference = response?.responseBody?.txnRef ?? response?.responseBody?.paymentRef ?? '';

      if (!mounted) return;
      context.pushNamed(
        RouteList.successScreen,
        extra: {
          'type':             status,
          'amount':           widget.amount.toStringAsFixed(2),
          'recipientName':    widget.recipientName,
          'recipientAccount': widget.recipientAccount,
          'reference':        reference,
          'channel':          widget.bankName,
          'message':          response?.responseMessage ?? '',
        },
      );
    } catch (e) {
      EasyLoading.dismiss();

      if (_isNetworkError(e)) {
        _showErrorModal(
          'No Internet Connection',
          'Please check your internet connection and try again.',
          isNetworkError: true,
          onRetry: _processTransfer,
        );
        return;
      }

      if (_isWrongPinError(null, e.toString())) {
        _showErrorModal(
          'Incorrect PIN',
          'The PIN you entered is incorrect. Please try again.',
          clearPin: true,
        );
        return;
      }

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

    // Adaptive spacing
    final topSpacing = isSmallScreen ? 30.h : (isLargeScreen ? 80.h : 60.h);
    final sectionSpacing = isSmallScreen ? 20.h : (isLargeScreen ? 40.h : 30.h);
    final pinSpacing = isSmallScreen ? 40.h : (isLargeScreen ? 60.h : 50.h);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
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

                      // Lock Icon
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

                      // Title
                      Text(
                        'Enter Transaction PIN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 18.sp : 22.sp,
                        ),
                      ),

                      SizedBox(height: pinSpacing),

                      // PIN Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < pin.length;

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 5.w),
                            width: isSmallScreen ? 14.w : 16.w,
                            height: isSmallScreen ? 14.w : 16.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? primaryColor : Colors.transparent,
                              border: Border.all(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),

                      if (showPinWarning)
                        Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            "Enter a valid 4-digit PIN",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: errorColor,
                              fontSize: isSmallScreen ? 11.sp : 12.sp,
                            ),
                          ),
                        ),

                      SizedBox(height: isSmallScreen ? 40.h : 50.h),

                      // Keypad
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
                            onTap: _processTransfer,
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

                      // Row: biometric button (left) + Forget Pin (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Fingerprint / biometric button — only shown when
                          // the current user has biometric payment enabled.
                          if (_hasBiometric && _biometricEnabled)
                            GestureDetector(
                              onTap: _isAuthenticating
                                  ? null
                                  : _authenticateWithBiometric,
                              child: AnimatedOpacity(
                                opacity: _isAuthenticating ? 0.4 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.fingerprint,
                                    color: primaryColor,
                                    size: isSmallScreen ? 28.sp : 32.sp,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Forget PIN
                          GestureDetector(
                            onTap: _handleForgotPin,
                            child: Text(
                              'Forget Pin?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: lightText,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 13.sp : 14.sp,
                              ),
                            ),
                          ),
                        ],
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