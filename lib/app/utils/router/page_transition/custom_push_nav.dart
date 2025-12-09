import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void namedNav(BuildContext context, String route) {
  context.pushNamed(route);
}
void popNav(BuildContext context) {
  Navigator.pop(context);
}
void namedNavRemoveUntil(BuildContext context, String route){
  context.goNamed(route);
}