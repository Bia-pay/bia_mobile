import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/view/widget/app_button.dart';
import '../../../../app/view/widget/app_textfield.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/toast_helper.dart';
import '../controller/qr_payment_controller.dart';

class QrAmountEntryScreen extends ConsumerStatefulWidget {
  final String receiverAccount;
  final bool isCollectMode;

  const QrAmountEntryScreen({
    super.key,
    required this.receiverAccount,
    this.isCollectMode = false,
  });

  @override
  ConsumerState<QrAmountEntryScreen> createState() => _QrAmountEntryScreenState();
}

class _QrAmountEntryScreenState extends ConsumerState<QrAmountEntryScreen> {
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0 || amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount of at least ₦50')),
      );
      return;
    }

    if (widget.isCollectMode) {
      // In collect mode, we skip API initiation and go straight to deduction PIN screen
      context.push(RouteList.qrDeductionPinScreen, extra: {
        'ownerAccount': widget.receiverAccount,
        'amount': amount,
        'narration': _narrationController.text,
      });
      return;
    }

    final controller = ref.read(qrPaymentControllerProvider.notifier);
    final response = await controller.initiateQrPayment(
      context: context,
      receiverAccount: widget.receiverAccount,
      amount: amount,
      narration: _narrationController.text,
    );

    if (response != null && response.responseSuccessful) {
      final responseBody = response.responseBody;
      if (responseBody != null) {
        final requestId = responseBody.requestId ?? '';
        final receiverName = responseBody.receiverName ?? widget.receiverAccount;
        
        if (mounted) {
          context.push(RouteList.qrPaymentReviewScreen, extra: {
            'requestId': requestId,
            'receiverName': receiverName,
            'amount': amount,
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(qrPaymentControllerProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCollectMode ? 'Collect via QR' : 'Pay via QR', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isCollectMode ? 'Collecting From' : 'Paying To',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                SizedBox(height: 5.h),
                Text(
                  widget.receiverAccount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30.h),
                AppTextField(
                  controller: _amountController,
                  labelText: 'Amount (₦)',
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter amount';
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  controller: _narrationController,
                  labelText: 'Narration (Optional)',
                  hintText: 'What is this for?',
                ),
                const Spacer(),
                AppButton(
                  text: isLoading ? 'Processing...' : (widget.isCollectMode ? 'Collect Payment' : 'Continue'),
                  enabled: !isLoading,
                  onPressed: _onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
