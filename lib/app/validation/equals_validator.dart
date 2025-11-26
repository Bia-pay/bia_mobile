import 'package:flutter/material.dart';

import 'validator.dart';

class EqualsValidator<E> extends _EqualsValidator<E> {
  const EqualsValidator({
    required super.fieldName1,
    required super.fieldName2,
    super.value1,
    super.value2,
    super.customMessage,
  }) : super(equalsIsError: false);
}

class NotEqualsValidator<E> extends _EqualsValidator<E> {
  const NotEqualsValidator({
    required super.fieldName1,
    required super.fieldName2,
    super.value1,
    super.value2,
    super.customMessage,
  }) : super(equalsIsError: true);
}

class _EqualsValidator<E> implements Validator {
  const _EqualsValidator({
    required this.fieldName1,
    required this.fieldName2,
    this.value1,
    this.value2,
    this.equalsIsError = false,
    String? customMessage,
  }) : _customMessage = customMessage;

  final String fieldName1;
  final String fieldName2;
  final E? value1;
  final E? value2;
  final bool equalsIsError;
  final String? _customMessage;

  @override
  List<ValidatorErrorContext> validate() {
    if (value1 == null && value2 == null) {
      return [];
    }

    if (value1 == null || value2 == null) {
      return [
        EqualsValidatorErrorContext(
          fieldName1: fieldName1,
          fieldName2: fieldName2,
          equalsIsError: equalsIsError,
          value1: value1,
          value2: value2,
          customMessage: _customMessage,
        ),
      ];
    }

    final equals = value1 == value2;
    if (equals == equalsIsError) {
      return [
        EqualsValidatorErrorContext(
          fieldName1: fieldName1,
          fieldName2: fieldName2,
          equalsIsError: equalsIsError,
          value1: value1,
          value2: value2,
          customMessage: _customMessage,
        ),
      ];
    }

    return [];
  }
}

class EqualsValidatorErrorContext<E> implements ValidatorErrorContext {
  const EqualsValidatorErrorContext({
    required this.equalsIsError,
    required this.value1,
    required this.value2,
    required this.fieldName1,
    required this.fieldName2,
    this.customMessage,
  });

  final String fieldName1;
  final String fieldName2;
  final String? customMessage;
  final bool equalsIsError;
  final E? value1;
  final E? value2;

  @override
  String? toInputValidator({BuildContext? context, String? fieldName}) {
    if (equalsIsError) {
      return customMessage ?? '$fieldName1 should not equal $fieldName2';
    } else {
      return customMessage ?? '$fieldName1 should equal $fieldName2';
    }
  }
}