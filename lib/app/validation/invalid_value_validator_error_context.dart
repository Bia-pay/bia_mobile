import 'package:flutter/material.dart';

import 'validator.dart';

class InvalidValueValidatorErrorContext implements ValidatorErrorContext {
  const InvalidValueValidatorErrorContext(this.fieldName);

  final String? fieldName;

  @override
  String? toInputValidator({BuildContext? context, String? fieldName}) {
    final field = fieldName ?? this.fieldName ?? 'This field';
    return '$field is invalid';
  }
}