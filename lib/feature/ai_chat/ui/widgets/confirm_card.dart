import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/colors.dart';
import '../../../../core/constants.dart';

class ConfirmCard extends StatefulWidget {
  final String name;
  final String account;
  final double amount;
  final double fee;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isCompleted;
  final String? destinationType;

  const ConfirmCard({
    super.key,
    required this.name,
    required this.account,
    required this.amount,
    required this.fee,
    required this.onConfirm,
    required this.onCancel,
    this.isCompleted = false,
    this.destinationType,
  });

  @override
  State<ConfirmCard> createState() => _ConfirmCardState();
}

class _ConfirmCardState extends State<ConfirmCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liftCtrl;
  late final Animation<double> _liftAnim;
  late final Animation<double> _shadowAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _liftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _liftAnim = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _liftCtrl, curve: Curves.easeOutBack),
    );
    _shadowAnim = Tween<double>(begin: 8, end: 24).animate(
      CurvedAnimation(parent: _liftCtrl, curve: Curves.easeOutCubic),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _liftCtrl, curve: Curves.easeOut),
    );

    // If not completed on mount, animate the lift immediately
    if (!widget.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _liftCtrl.forward());
    }
  }

  @override
  void didUpdateWidget(covariant ConfirmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _liftCtrl.reverse(); // Settle back down when completed
    }
  }

  @override
  void dispose() {
    _liftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.amount + widget.fee;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: AnimatedBuilder(
          animation: _liftCtrl,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _liftAnim.value),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05 + (_glowAnim.value * 0.1)),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 + (_glowAnim.value * 0.25)),
                      blurRadius: _shadowAnim.value,
                      offset: Offset(0, 5 + (_glowAnim.value * 7)),
                    ),
                    BoxShadow(
                      color: const Color(0xFF26B4DF).withValues(alpha: _glowAnim.value * 0.25),
                      blurRadius: _glowAnim.value * 50,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            widget.destinationType != null
                                ? "${widget.destinationType} \u2022 ${widget.account}"
                                : "BIA \u2022 ${widget.account}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Amount breakdown ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Row(
                      label: 'Amount',
                      value: '${Constants.nairaCurrencySymbol}${_fmt(widget.amount)}',
                    ),
                    SizedBox(height: 8.h),
                    _Row(
                      label: 'Charges',
                      value: widget.fee > 0 
                        ? '${Constants.nairaCurrencySymbol}${_fmt(widget.fee)}'
                        : 'Free',
                      valueColor: widget.fee > 0 ? Colors.redAccent.withValues(alpha: 0.9) : primaryColor,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                    ),
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${Constants.nairaCurrencySymbol}${_fmt(total)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Action buttons ────────────────────────────────────────
              if (!widget.isCompleted)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2), 
                              width: 1.5
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white.withValues(alpha: 0.9),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
