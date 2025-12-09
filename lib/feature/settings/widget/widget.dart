import 'package:flutter/material.dart';

import '../../../app/utils/colors.dart';

Widget _divider(BuildContext context) => Divider(
  color: Theme.of(context).brightness == Brightness.light
      ? lightBorderColor
      : darkBorderColor,
  thickness: 3,
);

