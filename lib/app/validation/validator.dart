import 'package:flutter/material.dart';

abstract interface class Validator<E extends ValidatorErrorContext> {
  List<ValidatorErrorContext> validate();
}

abstract interface class ValidatorErrorContext {
  String? toInputValidator({BuildContext? context, String? fieldName});
}

typedef InputValidator<T> = Validator Function(T? value);
