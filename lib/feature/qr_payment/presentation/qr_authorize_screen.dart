import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../dashboard/widgets/keypad.dart';
import '../controller/qr_payment_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../../core/services/security_service.dart';

class QrAuthorizeScreen extends ConsumerStatefulWidget {
  final String requestId;
  final double amount;
  final String senderName;

  const QrAuthorizeScreen({
    super.key,
    required this.requestId,
    required this.amount,
    required this.senderName,
  });

  @override
  ConsumerState<QrAuthorizeScreen> createState() => _QrAuthorizeScreenState();
}

class _QrAuthorizeScreenState extends ConsumerState<QrAuthorizeScreen> {
  String pin = "";

  void addDigit(String value) {
    if (pin.length >= 4) return;
    setState(() {
      pin += value;
    });

    if (pin.length == 4) {
      _processPayment(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processPayment(String enteredPin) async {
    if (enteredPin.length < 4) return;
    
    final controller = ref.read(qrPaymentControllerProvider.notifier);
    EasyLoading.show(status: "Authorizing Request...");

    try {
      final success = await controller.authorizeQrPayment(
        context: context,
        requestId: widget.requestId,
        pin: enteredPin,
      );

      EasyLoading.dismiss();

      if (!success) {
        // Clear pin on failure
        setState(() => pin = "");
        return;
      }

      await SecurityService.clearFailures();
      
      if (mounted) {
        context.goNamed(RouteList.successScreen, extra: {
          "type": "success",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.senderName,
          "recipientAccount": "Payment Request",
          "reference": widget.requestId,
          "channel": "QR",
          "message": "Payment authorized successfully",
        });
      }
    } catch (e) {
      EasyLoading.dismiss();
      setState(() => pin = "");
      _showError('Error', e.toString());
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        title: const Text("Authorize Payment"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: isSmallScreen ? 20.h : 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Payment Request From',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.senderName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                '₦${widget.amount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Enter Transaction PIN to Approve',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? primaryColor : Colors.transparent,
                      border: Border.all(
                        color: filled ? primaryColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              Flexible(
                fit: FlexFit.loose,
                child: CustomGridKeypad(
                  onNumberPressed: addDigit,
                  leftAction: ActionKey(
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 24.sp),
                    backgroundColor: primaryColor,
                    onTap: () => _processPayment(pin),
                  ),
                  rightAction: ActionKey(
                    child: Icon(Icons.backspace_rounded, color: primaryColor, size: 24.sp),
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    onTap: removeDigit,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
