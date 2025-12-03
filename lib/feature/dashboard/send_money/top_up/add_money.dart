import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../dashboardcontroller/dashboardcontroller.dart';
import '../../widgets/transaction.dart';

class AddMoney extends ConsumerStatefulWidget {
  const AddMoney({super.key});

  @override
  ConsumerState<AddMoney> createState() => _AddMoneyState();
}

class _AddMoneyState extends ConsumerState<AddMoney> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                            color: lightText,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Add Money',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                            color: lightText,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'FAQ',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                /// 💳 Balance Card
                const BalanceCard(),

                SizedBox(height: 20.h),

                /// 🔘 Divider Text
                Center(
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kGray,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                /// 🏦 Bank List
                SizedBox(
                  height: 400.h,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: topUp.length,
                    itemBuilder: (context, index) {
                      final tx = topUp[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          height: 70.h,
                          decoration: BoxDecoration(
                            color: lightSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 40.h,
                                  width: 40.w,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: primaryColor),
                                  ),
                                  child: Image.asset(
                                    'assets/svg/bank.png',
                                    height: 20.h,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.name,
                                        style: TextStyle(
                                          color: lightText,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        tx.dateTime,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: lightSecondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  size: 14.sp,
                                  color: lightSecondaryText,
                                ),
                              ],
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
        ),
      ),
    );
  }
}

/// 🔹 Balance Card Widget
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: lightSurface,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            'Bia Account Number',
            style: TextStyle(color: lightSecondaryText, fontSize: 13.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            '8037386998',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: lightText,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 15.h),

          /// 📤 Share Button
          SizedBox(
            width: 180.w,
            child: CustomButton(
              buttonColor: primaryColor,
              buttonTextColor: lightBackground,
              buttonName: 'Proceed to Deposit',
              onPressed: () async {
                final controller = ref.read(
                  dashboardControllerProvider.notifier,
                );
                final response = await controller.depositMoney(context, 10000);

                if (response != null) {
                  final url = response.data!.authorizationUrl;
                  final reference = response.data!.reference;
                  debugPrint('Send Money PayStack URL: $url');
                  debugPrint('Send Money PayStack REFERENCE: $reference');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentWebViewPage(url: url, reference: reference),
                    ),
                  );
                }
              },
            ),
          ),

          SizedBox(height: 20.h),
          Divider(color: lightBorderColor, thickness: 1),
          SizedBox(height: 5.h),

          /// Bank Transfer Option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              height: 45.h,
              width: 45.w,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: primaryColor),
              ),
              child: Image.asset('assets/svg/bank.png', height: 10.h),
            ),
            title: Text(
              'Via Bank Transfer',
              style: TextStyle(
                color: lightText,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'FREE Instant bank funding within 10s',
              style: TextStyle(fontSize: 11.sp, color: lightSecondaryText),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_outlined,
              size: 14.sp,
              color: lightSecondaryText,
            ),
          ),
        ],
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
            debugPrint("🌐 Page finished loading: $url");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _verifyPayment(String reference) async {
    if (_hasVerified) return;
    _hasVerified = true;

    debugPrint("📡 Verifying payment... $reference");

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null &&
          res.responseSuccessful &&
          res.data?.status == "success") {
        debugPrint("🎉 Payment verified: ${res.responseMessage}");

        if (!mounted) return;

        // Close WebView
        Navigator.pop(context);
        debugPrint("🎉 Payment verified: ${res.data?.amount.toString()}");
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
        debugPrint("⚠️ Payment not completed");
        _showDialog("Failed", "Payment was not completed.");
      }
    } catch (e) {
      debugPrint("❌ Verification error: $e");
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
