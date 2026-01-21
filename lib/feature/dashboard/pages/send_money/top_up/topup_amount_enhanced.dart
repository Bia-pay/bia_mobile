// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../../../../../app/utils/widgets/enhanced_pin_screen.dart';
// import '../../../../../app/utils/router/route_constant.dart';
// import '../../../dashboardcontroller/dashboardcontroller.dart';
//
// class TopUpAmountPageEnhanced extends ConsumerWidget {
//   final String title;
//
//   const TopUpAmountPageEnhanced({
//     super.key,
//     this.title = "Top Up",
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: title,
//       subtitle: "Enter Amount",
//       type: PinScreenType.confirm,
//       fieldType: InputFieldType.amount,
//       minAmount: 50,
//       currency: '₦',
//       onPinComplete: (amount) async {
//         final numericAmount = num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
//
//         final controller = ref.read(dashboardControllerProvider.notifier);
//
//         final response = await controller.depositMoney(context, numericAmount.toDouble());
//         if (response != null) {
//           final url = response.data!.authorizationUrl;
//           final reference = response.data!.reference;
//
//           print('Top Up PayStack URL: $url');
//           print('Top Up PayStack REFERENCE: $reference');
//
//           if (context.mounted) {
//             showDialog(
//               context: context,
//               builder: (_) => PaymentWebViewPageEnhanced(
//                 url: url,
//                 reference: reference,
//               ),
//             );
//           }
//         }
//       },
//     );
//   }
// }
//
// class PaymentWebViewPageEnhanced extends ConsumerStatefulWidget {
//   final String url;
//   final String reference;
//
//   const PaymentWebViewPageEnhanced({
//     super.key,
//     required this.url,
//     required this.reference
//   });
//
//   @override
//   ConsumerState<PaymentWebViewPageEnhanced> createState() => _PaymentWebViewPageEnhancedState();
// }
//
// class _PaymentWebViewPageEnhancedState extends ConsumerState<PaymentWebViewPageEnhanced> {
//   late final WebViewController _controller;
//   bool _hasVerified = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onNavigationRequest: (request) {
//             final url = request.url;
//             if (url.contains('https://flutter.dev')) {
//               _verifyPayment(widget.reference);
//               return NavigationDecision.prevent;
//             } else if (url.contains('your-failure-return-url')) {
//               _showDialog("Failed", "Payment was not completed.");
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//           onPageFinished: (url) {
//             print("🌐 Page finished loading: $url");
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }
//
//   Future<void> _verifyPayment(String reference) async {
//     if (_hasVerified) return;
//     _hasVerified = true;
//
//     print("📡 Verifying payment... $reference");
//
//     try {
//       final res = await ref
//           .read(dashboardControllerProvider.notifier)
//           .verifyDeposit(context, reference);
//
//       if (res != null && res.responseSuccessful && res.data?.status == "success") {
//         print("🎉 Payment verified: ${res.responseMessage}");
//
//         if (!mounted) return;
//
//         // Close WebView
//         Navigator.pop(context);
//
//         // Go to success screen
//         context.pushNamed(
//           RouteList.successScreen,
//           extra: {
//             "type": "deposit",
//             "amount": res.data?.amount.toString() ?? "0",
//             "recipientName": "",
//             "recipientAccount": "",
//             "reference": res.data?.reference ?? "",
//             "channel": res.data?.channel ?? "Paystack",
//           },
//         );
//       } else {
//         print("⚠️ Payment not completed");
//         _showDialog("Failed", "Payment was not completed.");
//       }
//     } catch (e) {
//       print("❌ Verification error: $e");
//       _showDialog("Error", "An error occurred while verifying payment.");
//     }
//   }
//
//   void _showDialog(String title, String message) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // close dialog
//               Navigator.pop(context); // close WebView
//             },
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Payment")),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }