import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_textfield.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

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
  int _selectedIndex = -1;
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
      amountController.text = amount;   // ✅ FIXED

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
      amountController.text = amount;    // ✅ FIXED

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewPage(
            url: url,
            reference: reference,
          ),
        ),
      );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50.h),
            Text(
              'Enter Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5.h),
            AppTextField(
              controller: amountController,   // ✅ FIXED              readOnly: true,
              borderRadius: 8.r,
              hintTextAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "₦0.00",
                hintStyle: theme.textTheme.titleLarge?.copyWith(
                  color: lightSecondaryText,
                  fontSize: 23.sp,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h, left: 4.w),
                child: Text(
                  "Minimum amount you can send is ₦50",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: 75.h),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 25.w),
                itemCount: 12,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 35.w,
                  mainAxisExtent: 70.h,
                ),
                itemBuilder: (context, index) {
                  List<String> keys = [
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "x",
                    "0",
                    "ok",
                  ];
                  String key = keys[index];

                  Color keyColor = keyAColor;
                  Color textColor = lightSecondaryText;

                  if (key == "x") {
                    keyColor = primaryColor.withOpacity(0.1);
                    textColor = primaryColor;
                  } else if (key == "ok") {
                    keyColor = primaryColor;
                    textColor = whiteBackground;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(50.r),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      setState(() => _selectedIndex = index);

                      if (key == "x") {
                        removeDigit();
                      } else if (key == "ok") {
                        _processTopUp();
                      } else {
                        addDigit(key);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        _selectedIndex == index ? Colors.white : keyColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedIndex == index
                              ? primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _selectedIndex == index
                            ? [
                          BoxShadow(
                            color:
                            primaryColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: key == "x"
                          ? SvgPicture.asset(
                        'assets/svg/cancel.svg',
                        height: 20.h,
                        colorFilter: ColorFilter.mode(
                          primaryColor,
                          BlendMode.srcIn,
                        ),
                      )
                          : key == "ok"
                          ? Icon(
                        Icons.arrow_forward,
                        color: _selectedIndex == index
                            ? primaryColor
                            : textColor,
                        size: 24.sp,
                      )
                          : Text(
                        key,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: _selectedIndex == index
                              ? primaryColor
                              : lightText,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
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

  const PaymentWebViewPage({super.key, required this.url, required this.reference});

  @override
  ConsumerState<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends ConsumerState<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _hasVerified = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _verifyPayment(String reference) async {
    if (_hasVerified) return;
    _hasVerified = true;

    print("📡 Verifying payment... $reference");

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null && res.responseSuccessful && res.data?.status == "success") {
        print("🎉 Payment verified: ${res.responseMessage}");

        if (!mounted) return;

        // Close WebView
        Navigator.pop(context);
        print("🎉 Payment verified: ${res.data?.amount.toString()}");
        // Go to success screen
        Navigator.pushNamed(
          context,
          RouteList.successScreen,
          arguments: {
            "type": "deposit",
            "amount": res.data?.amount.toString(),
            "reference": res.data?.reference,
            "channel": res.data?.channel ?? "Paystack",
          },
        );

        return;
      } else {
        print("⚠️ Payment not completed");
        _showDialog("Failed", "Payment was not completed.");
      }
    } catch (e) {
      print("❌ Verification error: $e");
      _showDialog("Error", "An error occurred while verifying payment.");
    }
  }
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  void _showDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close WebView
            },
            child: const Text("OK"),
          ),
        ],
      ),
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
