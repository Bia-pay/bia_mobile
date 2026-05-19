import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/u_popup.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/transaction.dart';

class AddMoney extends ConsumerStatefulWidget {
  const AddMoney({super.key});

  @override
  ConsumerState<AddMoney> createState() => _AddMoneyState();
}

class _AddMoneyState extends ConsumerState<AddMoney> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          'Fund Account',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: TextButton(
              onPressed: () {
                // Handle FAQ
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'FAQ',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 💳 Modern Premium Balance Card
                const ModernBankDetailsCard(),

                SizedBox(height: 32.h),

                Text(
                  'Other Funding Methods',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: lightText,
                    fontSize: 16.sp,
                  ),
                ),

                SizedBox(height: 16.h),

                /// 🏦 Funding Options List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topUp.length,
                  itemBuilder: (context, index) {
                    final tx = topUp[index];

                    IconData iconData;
                    if (tx.name.contains("Card")) {
                      iconData = Icons.credit_card_rounded;
                    } else if (tx.name.contains("Cash")) {
                      iconData = Icons.storefront_rounded;
                    } else if (tx.name.contains("USSD")) {
                      iconData = Icons.dialpad_rounded;
                    } else {
                      iconData = Icons.call_received_rounded;
                    }

                    bool isComingSoon =
                        tx.name.contains("Cash") || tx.name.contains("USSD");

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: GestureDetector(
                        onTap: () {
                          if (isComingSoon) {
                            UPopup.show(
                              context,
                              type: UPopupType.info,
                              title: "Coming Soon",
                              message:
                                  "This feature will be available shortly!",
                              confirmLabel: "OK",
                            );
                          } else if (tx.name.contains("Card")) {
                            context.pushNamed(RouteList.depositScreen);
                          } else if (tx.name.contains("Receive")) {
                            context.pushNamed(RouteList.qrScreen);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: lightBorderColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 48.h,
                                width: 48.w,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  iconData,
                                  color: primaryColor,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.name,
                                      style: TextStyle(
                                        color: lightText,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      tx.dateTime,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: lightSecondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isComingSoon
                                  ? Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        "Coming Soon",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16.sp,
                                      color: lightSecondaryText.withOpacity(
                                        0.5,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 Modern Bank Details Card Widget
class ModernBankDetailsCard extends ConsumerWidget {
  const ModernBankDetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Account Number',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Bia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                '8037386998',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '8037386998'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: primaryColor,
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'My  Account Number is 8037386998 - Bia',
                    );
                  },
                  icon: Icon(
                    Icons.share_rounded,
                    size: 18.sp,
                    color: primaryColor,
                  ),
                  label: Text(
                    'Share Details',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pushNamed(RouteList.depositScreen);
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Fund with Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
            print("🌐 Page finished loading: $url");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _verifyPayment(String reference) async {
    if (_hasVerified) return;
    _hasVerified = true;

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null &&
          res.responseSuccessful &&
          res.data != null &&
          res.data!.description.toLowerCase() == "successful") {
        if (!mounted) return;

        Navigator.pop(context);

        context.pushNamed(
          RouteList.successScreen,
          extra: {
            "type": "deposit",
            "amount": res.data!.amount.toString(),
            "reference": res.data!.reference,
          },
        );
      } else {
        _hasVerified = false;
        _showDialog("Failed", "Payment was not completed.");
      }
    } catch (e) {
      _hasVerified = false;
      _showDialog("Error", "Verification failed.");
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
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
