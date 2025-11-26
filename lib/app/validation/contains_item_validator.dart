// import 'package:flutter/material.dart';
//
// import '../../domain/utils/types.dart';
// import 'required_validator.dart';
// import 'validator.dart';
//
// class ContainsValidator<E> extends _ContainsItemValidator<E> {
//   const ContainsValidator({
//     required super.items,
//     super.fieldName,
//     super.value,
//     super.isRequired,
//     super.customMessage,
//     super.toStringTransformer,
//   }) : super(containsIsError: false);
// }
//
// class NotContainsValidator<E> extends _ContainsItemValidator<E> {
//   const NotContainsValidator({
//     required super.items,
//     super.fieldName,
//     super.value,
//     super.isRequired,
//     super.customMessage,
//     super.toStringTransformer,
//   }) : super(containsIsError: true);
// }
//
// class _ContainsItemValidator<E> extends RequiredValidator<E> {
//   const _ContainsItemValidator({
//     required this.items,
//     super.fieldName,
//     super.value,
//     this.isRequired = true,
//     this.containsIsError = false,
//     this.toStringTransformer,
//     String? customMessage,
//   }) : _customMessage = customMessage;
//
//   final List<E> items;
//   final bool isRequired;
//   final bool containsIsError;
//   final ToStringTransformer<E>? toStringTransformer;
//   final String? _customMessage;
//
//   @override
//   List<ValidatorErrorContext> validate() {
//     if ((value == null || (toStringTransformer?.call(value as E) ?? value!.toString()).trim().isEmpty) && !isRequired) {
//       return [];
//     }
//
//     final validation = super.validate();
//     if (validation.isNotEmpty) {
//       return validation;
//     }
//
//     final contains = items.contains(value as E);
//     if (contains == containsIsError) {
//       return [
//         ContainsValidatorErrorContext(
//           fieldName: fieldName,
//           containsIsError: containsIsError,
//           value: value as E,
//           customMessage: _customMessage,
//           toStringTransformer: toStringTransformer,
//         ),
//       ];
//     }
//
//     return [];
//   }
// }
//
// class ContainsValidatorErrorContext<E> implements ValidatorErrorContext {
//   const ContainsValidatorErrorContext({
//     required this.containsIsError,
//     required this.value,
//     this.fieldName,
//     this.customMessage,
//     this.toStringTransformer,
//   });
//
//   final String? fieldName;
//   final String? customMessage;
//   final bool containsIsError;
//   final ToStringTransformer<E>? toStringTransformer;
//   final E value;
//
//   @override
//   String? toInputValidator({BuildContext? context, String? fieldName}) {
//     final field = fieldName ?? this.fieldName ?? 'This field';
//     final valueString = toStringTransformer?.call(value) ?? value?.toString() ?? 'null';
//
//     return customMessage ??
//         (containsIsError
//             ? '$field cannot contain $valueString'
//             : '$field should contain $valueString');
//   }
// }