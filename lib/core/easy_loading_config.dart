// lib/core/easy_loading_config.dart

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Animated Logo Widget for EasyLoading
class PulsingLogoIndicator extends StatefulWidget {
  final String logoPath;
  final double size;
  final Color? pulseColor;

  const PulsingLogoIndicator({
    super.key,
    required this.logoPath,
    this.size = 10,
    this.pulseColor,
  });

  @override
  State<PulsingLogoIndicator> createState() => _PulsingLogoIndicatorState();
}

class _PulsingLogoIndicatorState extends State<PulsingLogoIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final effectiveSize = isTablet ? widget.size : widget.size.w;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Opacity(
              opacity: _opacityAnimation.value * 0.3,
              child: Transform.scale(
                scale: _scaleAnimation.value * 1.3,
                child: Container(
                  width: effectiveSize,
                  height: effectiveSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.pulseColor ?? Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            // Middle pulse ring
            Opacity(
              opacity: _opacityAnimation.value * 0.5,
              child: Transform.scale(
                scale: _scaleAnimation.value * 1.15,
                child: Container(
                  width: effectiveSize,
                  height: effectiveSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.pulseColor ?? Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            // Logo container
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: effectiveSize,
                height: effectiveSize,
                padding: EdgeInsets.all(isTablet ? 6 : 6.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.pulseColor ?? Colors.blue).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.logoPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class EasyLoadingConfig {
  static void initialize({
    required String logoPath,
    double logoSize = 50.0,
    Color? pulseColor,
    Color maskColor = Colors.black,
    double maskOpacity = 0.7,
    bool dismissOnTap = false,
    bool userInteractions = false,
  }) {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorSize = logoSize
      ..radius = 20.0
      ..progressColor = pulseColor ?? Colors.blue
      ..backgroundColor = Colors.transparent
      ..indicatorColor = Colors.transparent
      ..textColor = Colors.white
      ..maskColor = maskColor.withOpacity(maskOpacity)
      ..userInteractions = userInteractions
      ..dismissOnTap = dismissOnTap
      ..boxShadow = <BoxShadow>[]
      ..customAnimation = CustomAnimation()
      ..indicatorWidget = PulsingLogoIndicator(
        logoPath: logoPath,
        size: logoSize,
        pulseColor: pulseColor,
      );
  }
}

/// Custom Animation for EasyLoading
class CustomAnimation extends EasyLoadingAnimation {
  @override
  Widget buildWidget(
      Widget child,
      AnimationController controller,
      AlignmentGeometry alignment,
      ) {
    return Opacity(
      opacity: controller.value,
      child: child,
    );
  }
}

/// Helper class for showing different loading states
class LoadingHelper {
  /// Show loading with optional message
  static void show([String? status]) {
    EasyLoading.show(
      status: status,
      maskType: EasyLoadingMaskType.custom,
    );
  }

  /// Show success with message
  static void success(String message) {
    EasyLoading.showSuccess(
      message,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show error with message
  static void error(String message) {
    EasyLoading.showError(
      message,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show info toast
  static void info(String message) {
    EasyLoading.showInfo(
      message,
      duration: const Duration(seconds: 2),
    );
  }

  /// Dismiss loading
  static void dismiss() {
    EasyLoading.dismiss();
  }

  /// Show progress (0.0 to 1.0)
  static void showProgress(double progress, {String? status}) {
    EasyLoading.showProgress(
      progress,
      status: status ?? '${(progress * 100).toStringAsFixed(0)}%',
    );
  }
}