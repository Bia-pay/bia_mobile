import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class TransactionPinSecure extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;

  const TransactionPinSecure({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
  });

  @override
  ConsumerState<TransactionPinSecure> createState() => _TransactionPinSecureState();
}

class _TransactionPinSecureState extends ConsumerState<TransactionPinSecure> {
  String pin = "";
  bool showPinWarning = false;
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
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId', defaultValue: '');
    final phone = authBox.get('phone', defaultValue: '');

    // Match the logic used in EnableTransactionPinBiometricSecure
    final effectiveUserId = userId.isNotEmpty ? userId : phone;

    debugPrint('🔐 TransactionPinSecure - userId: "$userId", phone: "$phone", effective: "$effectiveUserId"');

    if (effectiveUserId.isEmpty) {
      setState(() {
        _hasBiometric = false;
        _biometricEnabled = false;
      });
      debugPrint('❌ No user ID found');
      return;
    }

    final biometricService = BiometricService();
    final isAvailable = await biometricService.canCheckBiometrics();
    final isEnabled = await biometricService.isPaymentEnabled(effectiveUserId);
    final typeName = await biometricService.getBiometricTypeName();
    final savedPin = await biometricService.getTransactionPin(effectiveUserId);

    debugPrint('🔐 Checking biometric for user: "$effectiveUserId"');
    debugPrint('🔐 Key used: "biometric_payment_enabled_$effectiveUserId"');
    debugPrint('🔐 isEnabled: $isEnabled, hasPin: ${savedPin != null}');

    setState(() {
      _hasBiometric = isAvailable;
      _biometricEnabled = isEnabled && savedPin != null; // Both must be true!
      _biometricTypeName = typeName;
    });
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
      showPinWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      pinController.text = pin;
    });
  }

  /// Authenticate with biometric and get PIN
  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;
    
    if (!_hasBiometric || !_biometricEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_biometricTypeName authentication is not enabled'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      if (effectiveUserId.isEmpty) {
        _showError('User session not found');
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
        debugPrint('✅ Biometric authentication successful, processing transfer...');
        await _processTransferWithPin(savedPin);
      } else {
        debugPrint('❌ No saved PIN found');
        _showError('Please set up your transaction PIN first');
      }
    } catch (e) {
      debugPrint('⚠️ Biometric error: $e');
      _showError('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processTransfer() async {
    if (pin.length != 4) {
      setState(() => showPinWarning = true);
      return;
    }

    await _processTransferWithPin(pin);
  }

  /// Process transfer with PIN or auth token
  /// @param pinOrToken - Either user-entered PIN or biometric auth token
  Future<void> _processTransferWithPin(String pinOrToken) async {
    final controller = ref.read(dashboardControllerProvider.notifier);

    // Backend validates the PIN/token and authorizes the transaction
    final response = await controller.sendMoney(
      context,
      widget.recipientAccount,
      widget.amount.toStringAsFixed(2),
      'Transfer',
      pinOrToken, // This is validated by backend
      save: widget.saveAsBeneficiary,
    );

    if (response != null && response.responseSuccessful) {
      context.pushNamed(
        RouteList.successScreen,
        extra: {
          "type": "transfer",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": "",
          "channel": "",
        },
      );
    } else {
      // Show error if PIN/token is wrong or transfer failed
      final msg = response?.responseMessage ?? "Transfer failed. Check your PIN.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50.h),
            Container(
              padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
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
                borderRadius: BorderRadius.all(Radius.circular(10.r)),
              ),
              child: Icon(
                Icons.lock,
                color: Colors.white,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Enter Transaction PIN',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 15.h),
            if (_hasBiometric && _biometricEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  textAlign: TextAlign.center,
                  'You can use your $_biometricTypeName for faster confirmation',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < pin.length;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  decoration: BoxDecoration(
                    color: isFilled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? inactiveColor : disabledTextColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            SizedBox(height: 70.h),
            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: (value) {
                  addDigit(value);
                },
                leftAction: ActionKey(
                  child: Icon(
                    Icons.backspace,
                    color: primaryColor,
                  ),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
                rightAction: ActionKey(
                  child: _hasBiometric && _biometricEnabled
                      ? (_isAuthenticating
                          ? SizedBox(
                              width: 30.w,
                              height: 30.h,
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : SvgPicture.asset(
                              fingerPrint,
                              height: 75.h,
                            ))
                      : Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                  backgroundColor: _hasBiometric && _biometricEnabled
                      ? Colors.transparent
                      : primaryColor,
                  onTap: _hasBiometric && _biometricEnabled
                      ? _authenticateWithBiometric
                      : _processTransfer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GestureDetector(
                onTap: () => context.go(RouteList.forgotPassword),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Forget Pin?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: lightText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
