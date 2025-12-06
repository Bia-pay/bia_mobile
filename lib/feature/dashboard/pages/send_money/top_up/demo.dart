import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../app/utils/colors.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

class PaymentWebViewPage extends ConsumerStatefulWidget {
  final PaymentWebViewPageParams params;
  final void Function()? onSuccess;
  final void Function()? onFailure;

  const PaymentWebViewPage({
    super.key,
    required this.params,
    this.onSuccess,
    this.onFailure,
  });

  @override
  ConsumerState<PaymentWebViewPage> createState() =>
      _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends ConsumerState<PaymentWebViewPage> {
  late final WebViewController _controller;
  final ValueNotifier<String> _pageTitle = ValueNotifier<String>('');

  late String url, reference;
  double _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    url = widget.params.url;
    reference = widget.params.reference;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (String url) async {
            final title = await _controller.getTitle();
            _pageTitle.value = title ?? url;
            setState(() => _isLoading = false);

            // Handle generic close URLs
            if (url == 'https://standard.paystack.co/close' ||
                url == 'https://hello.pstk.xyz/callback') {
              Navigator.pop(context);
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final requestUrl = request.url;
            print("🔗 Navigating to: $requestUrl");

            // Example: success/failure detection
            if (requestUrl.contains("payment/success")) {
              await _verifyPayment(reference, true);
              return NavigationDecision.prevent;
            } else if (requestUrl.contains("payment/failure")) {
              await _verifyPayment(reference, false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _verifyPayment(String reference, bool success) async {
    if (!mounted) return;

    if (!success) {
      widget.onFailure?.call();
      _showDialog("Failed", "Payment was not completed.");
      return;
    }

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null && res.responseSuccessful && res.data?.status == "success") {
        widget.onSuccess?.call();
        _showDialog("Success", "Payment verified successfully!");
      } else {
        widget.onFailure?.call();
        _showDialog("Failed", "Payment verification failed.");
      }
    } catch (e) {
      widget.onFailure?.call();
      _showDialog("Error", "An error occurred while verifying payment.");
    }
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
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, size: 20.sp),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: ValueListenableBuilder<String>(
            valueListenable: _pageTitle,
            builder: (_, title, __) => RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: title,
               // style: TextStyles.normalMedium14(context),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoading)
                LinearProgressIndicator(
                  backgroundColor: accentColor,
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                  value: _progress,
                ),
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentWebViewPageParams {
  final String url;
  final String reference;

  PaymentWebViewPageParams({
    required this.url,
    required this.reference,
  });
}