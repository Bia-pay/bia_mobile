import 'package:flutter/material.dart';

import 'validator.dart';

class RequiredValidator<E> implements Validator {
  const RequiredValidator({this.fieldName, this.value, this.customMessage});

  final String? fieldName;
  final E? value;
  final String? customMessage;

  @override
  List<ValidatorErrorContext> validate() {
    if (value == null || value!.toString().trim().isEmpty) {
      return [RequiredValidatorErrorContext(fieldName, customMessage: customMessage)];
    }

    return [];
  }
}

class RequiredValidatorErrorContext implements ValidatorErrorContext {
  const RequiredValidatorErrorContext(this.fieldName, {this.customMessage});

  final String? fieldName;
  final String? customMessage;

  @override
  String? toInputValidator({BuildContext? context, String? fieldName}) {
    final field = fieldName ?? this.fieldName ?? 'This field';
    return customMessage ?? '$field is required';
  }
}