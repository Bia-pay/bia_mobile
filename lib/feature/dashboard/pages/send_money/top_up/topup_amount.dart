import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../app/utils/u_popup.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class TopUpAmountPage extends ConsumerStatefulWidget {
  final String title;
  final VoidCallback? onNext;
  final VoidCallback? onOk;

  const TopUpAmountPage({
    super.key,
    this.title = "Top Up",
    this.onNext,
    this.onOk,
  });

  @override
  ConsumerState<TopUpAmountPage> createState() => _TopUpAmountPageState();
}

class _TopUpAmountPageState extends ConsumerState<TopUpAmountPage> {
  String amount = "0";
  bool showMinWarning = false;
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void addDigit(String value) {
    setState(() {
      String current = amount.replaceAll('₦', '');

      if (current == "0") {
        current = value;
      } else {
        current += value;
      }

      amount = '₦$current';
      amountController.text = amount; // ✅ FIXED

      _checkMinLimit();
    });
  }

  void removeDigit() {
    setState(() {
      String current = amount.replaceAll('₦', '');
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
      }
      if (current.isEmpty) {
        current = "0";
      }

      amount = '₦$current';
      amountController.text = amount; // ✅ FIXED

      _checkMinLimit();
    });
  }

  void _checkMinLimit() {
    final numericValue =
        num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    showMinWarning = numericValue < 50 && numericValue != 0;
  }

  Future<void> _processTopUp() async {
    final raw = amount.replaceAll(RegExp(r'[^0-9]'), '');
    final numeric = int.tryParse(raw) ?? 0;

    if (numeric < 50) {
      setState(() => showMinWarning = true);
      return;
    }

    final controller = ref.read(dashboardControllerProvider.notifier);

    final response = await controller.depositMoney(context, numeric.toDouble());
    if (response != null) {
      final url = response.data!.authorizationUrl;
      final reference = response.data!.reference;

      print('Send Money PayStack URL: $url');
      print('Send Money PayStack REFERENCE: $reference');

      if (!mounted) return;

      // Navigate to WebView for payment and await the success screen argument map
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PaymentWebViewPage(url: url, reference: reference),
      );

      if (result != null && mounted) {
        context.pushNamed(
          RouteList.successScreen,
          extra: result,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Enter Amount to Fund',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: amount == "0" || amount == "₦0" ? 36.sp : 48.sp,
                fontWeight: FontWeight.bold,
                color: (amount == "0" || amount == "₦0")
                    ? lightSecondaryText
                    : primaryColor,
                letterSpacing: 1.5,
              ),
              child: Text(
                amount == "0" || amount == "₦0" ? "₦0.00" : amount,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 12.h),
            if (showMinWarning)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: errorColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Minimum amount you can send is ₦50",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 400.h,
              child: CustomGridKeypad(
                onNumberPressed: (value) {
                  addDigit(value);
                },

                leftAction: ActionKey(
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                  backgroundColor: primaryColor,
                  onTap: _processTopUp,
                ),

                rightAction: ActionKey(
                  child: Icon(Icons.backspace_rounded, color: primaryColor),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentWebViewPage extends ConsumerStatefulWidget {
  final String url;
  final String reference;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    required this.reference,
  });

  @override
  ConsumerState<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends ConsumerState<PaymentWebViewPage>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _hasVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('https://flutter.dev')) {
              _verifyPayment(widget.reference);
              return NavigationDecision.prevent;
            } else if (url.contains('your-failure-return-url')) {
              _showDialog("Failed", "Payment was not completed.");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            print("🌐 Page finished loading: $url");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        "🔄 Payment Webview resumed. Auto-checking deposit status for ref: ${widget.reference}",
      );
      // Wait briefly for the lock overlay to complete presentations/unlocks
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !_hasVerified) {
          _verifyPayment(widget.reference);
        }
      });
    }
  }

  Future<void> _verifyPayment(String reference) async {
    if (_hasVerified) return;
    _hasVerified = true;

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null && res.responseSuccessful && res.data != null) {
        if (!mounted) return;
        Navigator.pop(context, {
          "type": "deposit",
          "amount": res.data!.amount.toString(),
          "reference": res.data!.reference,
        });
      } else {
        _hasVerified = false;
        _showDialog("Failed", "Payment was not completed.");
      }
    } catch (e) {
      _hasVerified = false;
      _showDialog("Error", "Verification failed.");
    }
  }

  void _showDialog(String title, String message) {
    if (!mounted) return;

    UPopup.show(
      context,
      type: UPopupType.error,
      title: title,
      message: message,
      confirmLabel: "OK",
      onConfirm: () {
        Navigator.pop(context); // close WebView
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
