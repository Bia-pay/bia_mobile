import 'package:flutter/material.dart';
import '../keyboard_observer.dart';
abstract class RouteAwareState<T extends StatefulWidget> extends State<T>
    with RouteAware {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush() {
    _dismissKeyboard();
  }

  @override
  void didPopNext() {
    _dismissKeyboard();
  }
}