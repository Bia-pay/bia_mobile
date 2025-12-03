import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 🔹 Quick access to screen size
extension MediaSize on BuildContext {
  Size get mediaSize => MediaQuery.of(this).size;
  double get screenHeight => mediaSize.height;
  double get screenWidth => mediaSize.width;
}

/// 🔹 Responsive padding & margin helpers
EdgeInsets padR(
    BuildContext context, {
      double all = 0,
      double? horizontal,
      double? vertical,
      double? top,
      double? bottom,
      double? left,
      double? right,
    }) {
  final size = MediaQuery.of(context).size;
  return EdgeInsets.only(
    top: (top ?? vertical ?? all) * size.height * 0.001,
    bottom: (bottom ?? vertical ?? all) * size.height * 0.001,
    left: (left ?? horizontal ?? all) * size.width * 0.001,
    right: (right ?? horizontal ?? all) * size.width * 0.001,
  );
}

/// 🔹 Responsive spacing, sizes, radius, text
extension ResponsiveSpace on num {
  SizedBox vSpace(BuildContext context) =>
      SizedBox(height: toDouble() * context.screenHeight * 0.001);

  SizedBox hSpace(BuildContext context) =>
      SizedBox(width: toDouble() * context.screenWidth * 0.001);

  double w(BuildContext context) => toDouble() * context.screenWidth * 0.001;
  double h(BuildContext context) => toDouble() * context.screenHeight * 0.001;

  double sp(BuildContext context) =>
      toDouble() * context.screenWidth * 0.0025; // font scaling

  BorderRadiusGeometry circular(BuildContext context) =>
      BorderRadius.circular(toDouble() * context.screenWidth * 0.002);
}

/// 🔹 Responsive Column
class RCol extends StatelessWidget {
  const RCol({
    super.key,
    required this.children,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// 🔹 Responsive Row
class RRow extends StatelessWidget {
  const RRow({
    super.key,
    required this.children,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> children;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );
  }
}

/// 🔹 Responsive Image
class RImage extends StatelessWidget {
  const RImage(
      this.path, {
        super.key,
        this.width,
        this.height,
        this.fit = BoxFit.contain,
      });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width?.w(context),
      height: height?.h(context),
      fit: fit,
    );
  }
}

/// 🔹 Responsive SVG
class RSvg extends StatelessWidget {
  const RSvg(
      this.path, {
        super.key,
        this.width,
        this.height,
        this.color,
        this.fit = BoxFit.contain,
      });

  final String path;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: width?.w(context),
      height: height?.h(context),
      colorFilter:
      color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      fit: fit,
    );
  }
}
