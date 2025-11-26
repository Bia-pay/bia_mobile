import 'package:flutter/material.dart';

class PageSlideTransition extends PageRouteBuilder {
  // @override
  final WidgetBuilder page;
  // @override
  @override
  final RouteSettings settings;

  PageSlideTransition({required this.page, required this.settings})
      : super(
            pageBuilder: (context, animation, secondaryAnimation) => page(context),
            transitionDuration: const Duration(microseconds: 3),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
                  position: Tween(
                          begin: const Offset(1.0, 0.0),
                          end: const Offset(0.0, 0.0))
                      .animate(animation),
                  child: child,
                ),
            settings: settings);
}
