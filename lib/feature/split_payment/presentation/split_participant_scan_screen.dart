import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../dashboard/widgets/keypad.dart';
import '../../../core/services/security_service.dart';
import '../controller/split_payment_controller.dart';
import '../model/split_models.dart';

class SplitParticipantScanScreen extends ConsumerStatefulWidget {
  final String splitId;
  final String token;

  const SplitParticipantScanScreen({
    super.key,
    required this.splitId,
    required this.token,
  });

  @override
  ConsumerState<SplitParticipantScanScreen> createState() =>
      _SplitParticipantScanScreenState();
}

class _SplitParticipantScanScreenState
    extends ConsumerState<SplitParticipantScanScreen> {
  bool _showPinView = false;
  String _pin = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(scanSplitProvider.notifier)
          .loadScanDetails(
            context: context,
            splitId: widget.splitId,
            token: widget.token,
          );
    });
  }

  void _addDigit(String value) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += value;
    });

    if (_pin.length == 4) {
      _submitPayment();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPayment() async {
    if (_pin.length < 4) return;

    final controller = ref.read(scanSplitProvider.notifier);
    final response = await controller.paySplit(
      context: context,
      splitId: widget.splitId,
      pin: _pin,
    );

    // Clear PIN immediately
    setState(() {
      _pin = "";
    });

    if (response != null && mounted) {
      // Clear security failures
      await SecurityService.clearFailures();

      if (!mounted) return;
      // Navigate to Success screen
      context.goNamed(
        RouteList.successScreen,
        extra: {
          "type": "success",
          "amount": response.amountPaid.toStringAsFixed(2),
          "recipientName": "Split Bill Share",
          "recipientAccount": widget.splitId,
          "reference": response.transactionReference,
          "channel": "Split Pay",
          "message": "Paid successfully!",
        },
      );
    } else {
      // Register security failure (in case wrong PIN)
      await SecurityService.registerFailure();
      setState(() {
        _showPinView = false; // Hide PIN view to let them retry
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanState = ref.watch(scanSplitProvider);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Split Bill Details",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkBackground,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: scanState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              error: (err, stack) => Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: errorColor,
                      size: 64,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Scan Failed",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkBackground,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: lightSecondaryText,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text(
                        "Go Back",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data == null) return const SizedBox.shrink();

                if (_showPinView) {
                  return _buildPinEntryView(theme, data);
                }
                return _buildScanDetailView(theme, data);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanDetailView(ThemeData theme, ScanSplitResponse details) {
    final bool hasPaid = details.paymentStatus == 'PAID';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // BIA Split Header Icon
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call_split_rounded,
              color: primaryColor,
              size: 48.sp,
            ),
          ).animate().scale(duration: 400.ms),

          SizedBox(height: 24.h),

          // Title & Description
          Text(
            details.title ?? "Split Bill Request",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkBackground,
            ),
            textAlign: TextAlign.center,
          ),
          if (details.description != null &&
              details.description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              details.description!,
              style: TextStyle(color: lightSecondaryText, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: 12.h),

          Text(
            "Created by ${details.creatorName}",
            style: TextStyle(
              color: primaryColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Payment Card (Your Share)
          Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: lightBorderColor.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "YOUR ASSIGNED SHARE",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: lightSecondaryText,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "₦${details.assignedAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: darkBackground,
                      ),
                    ),
                    if (hasPaid) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: successColor,
                              size: 16,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "Paid",
                              style: TextStyle(
                                color: successColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.05),

          const Spacer(),

          // Actions
          if (!hasPaid) ...[
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showPinView = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "Pay Now",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  "Done",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildPinEntryView(ThemeData theme, ScanSplitResponse details) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20.h),

          // Secure padlock icon
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),

          SizedBox(height: 20.h),

          Text(
            'Enter Transaction PIN',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Confirm payment of ₦${details.assignedAmount.toStringAsFixed(2)} to Split Bill',
            style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 30.h),

          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final filled = index < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                width: 12.r,
                height: 12.r,
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

          // Keyboard
          CustomGridKeypad(
            onNumberPressed: _addDigit,
            leftAction: ActionKey(
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              backgroundColor: primaryColor,
              onTap: () {
                setState(() {
                  _showPinView = false;
                  _pin = "";
                });
              },
            ),
            rightAction: ActionKey(
              child: const Icon(Icons.backspace_rounded, color: primaryColor),
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              onTap: _removeDigit,
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
