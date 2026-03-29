import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../core/utils/biometric_helper.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class TransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String type; // 🔥 airtime | data | transfer
  final Map<String, dynamic>? meta;

  const TransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.type,
    this.meta,
  });

  @override
  ConsumerState<TransactionPin> createState() => _TransactionPinState();
}

class _TransactionPinState extends ConsumerState<TransactionPin> {
  String pin = "";
  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
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
    });

    if (pin.length == 4) {
      _processTransaction(pin);
    }
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      pinController.text = pin;
    });
  }

  Future<void> _processTransaction(String transactionPin) async {
    final controller = ref.read(dashboardControllerProvider.notifier);

    EasyLoading.show(status: "Processing...");

    dynamic response;

    try {
      print("🚀 TYPE: ${widget.type}");
      print("🚀 META: ${widget.meta}");

      if (widget.type == "airtime") {
        final network = widget.meta?['network'];

        if (network == null || network.isEmpty) {
          throw Exception("Network not found");
        }

        response = await controller.buyAirtime(
          context,
          phone: widget.recipientAccount,
          amount: widget.amount.toInt(),
          network: network.toString().toLowerCase(),
          pin: transactionPin,
        );
      }

      else if (widget.type == "data") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];

        if (serviceId == null || variationCode == null) {
          throw Exception("Data plan not selected properly");
        }

        response = await controller.buyData(
          context,
          phone: widget.recipientAccount,
          serviceId: serviceId,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          pin: transactionPin,
        );
      }

      else if (widget.type == "cable") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];
        final packageName = widget.meta?['packageName'];

        print("📦 serviceId: $serviceId");
        print("📦 variationCode: $variationCode");
        print("📦 packageName: $packageName");

        if (serviceId == null || variationCode == null || variationCode.isEmpty) {
          throw Exception("Cable data missing");
        }

        response = await controller.buyCable(
          context,
          serviceId: serviceId,
          smartcard: widget.recipientAccount,
          packageName: packageName ?? variationCode,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          phone: widget.recipientAccount,
          pin: transactionPin,
        );
      }

      else if (widget.type == "electricity") {
        final serviceId = widget.meta?['serviceId'];
        final variationCode = widget.meta?['variationCode'];

        if (serviceId == null || variationCode == null) {
          throw Exception("Electricity data missing");
        }

        response = await controller.buyElectricity(
          context,
          serviceId: serviceId,
          meterNumber: widget.recipientAccount,
          variationCode: variationCode,
          amount: widget.amount.toInt(),
          phone: widget.recipientAccount, // or user phone
          pin: transactionPin,
        );
      }
      else {
        response = await controller.sendMoney(
          context,
          widget.recipientAccount,
          widget.amount.toStringAsFixed(2),
          'Transfer',
          transactionPin,
          save: widget.saveAsBeneficiary,
        );
      }

      EasyLoading.dismiss();

      final isSuccess =
          response?.responseSuccessful == true ||
              response?.responseBody?.status == "SUCCESS";

      context.goNamed(
        RouteList.successScreen,
        extra: {
          "type": isSuccess ? "success" : "failed",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": response?.responseBody?.reference ?? '',
          "channel": widget.type.toUpperCase(),
        },

      );
    } catch (e) {
      EasyLoading.dismiss();

      print("🔥 ERROR: $e");

      context.goNamed(
        RouteList.successScreen,
        extra: {
          "type": "failed",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": '',
          "channel": widget.type.toUpperCase(),
        },
      );
    }
  }  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
        child: Column(
          children: [
            SizedBox(height: 40.h),

            Icon(Icons.lock, size: 40.sp, color: primaryColor),

            SizedBox(height: 20.h),

            Text(
              'Enter Transaction PIN',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 30.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < pin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? primaryColor : Colors.transparent,
                    border: Border.all(color: Colors.grey),
                  ),
                );
              }),
            ),

            SizedBox(height: 60.h),

            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: addDigit,
                leftAction: ActionKey(
                  child: Icon(Icons.check, color: Colors.white),
                  backgroundColor: primaryColor,
                  onTap: () => _processTransaction(pin),
                ),
                rightAction: ActionKey(
                  child: Icon(Icons.backspace, color: primaryColor),
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