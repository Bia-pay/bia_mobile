// // ignore_for_file: unnecessary_raw_strings


// import '../../domain/utils/number_extension.dart';
// import 'required_validator.dart';
// import 'validator.dart';

// part 'password_validator.freezed.dart';

// class PasswordValidator extends RequiredValidator<String> {
//   const PasswordValidator({super.fieldName, super.value});

//   static const minPasswordLength = 8;
//   static const maxPasswordLength = 20;

//   @override
//   List<ValidatorErrorContext> validate() {
//     final validation = super.validate();
//     if (validation.isNotEmpty) {
//       return validation;
//     }

//     final rules = <ValidatorErrorContext>[];

//     final password = value!.trim();

//     //TODO('AY'): Add special char validation to password later

//     // if (!RegExp(r'[!@#$%^&*]').hasMatch(password)) {
//     //   rules.add(const OneSpecialCharValidationRule());
//     // }
//     if (!RegExp(r'[A-Z]').hasMatch(password)) {
//       rules.add(const OneUppercaseLetterValidationRule());
//     }
//     if (!RegExp(r'[a-z]').hasMatch(password)) {
//       rules.add(const OneLowercaseLetterValidationRule());
//     }
//     // if (!RegExp(r'\d').hasMatch(password)) {
//     //   rules.add(const OneNumericCharValidationRule());
//     // }
//     if (password.length.isNotBetween(minPasswordLength, maxPasswordLength)) {
//       rules.add(const EightToTwentyFiveCharsValidationRule());
//     }

//     return rules;
//   }
// }

// @freezed
// sealed class PasswordValidationRule with _$PasswordValidationRule implements ValidatorErrorContext {
//   @Implements<ValidatorErrorContext>()
//   const factory PasswordValidationRule.oneSpecialChar() = OneSpecialCharValidationRule;
//   @Implements<ValidatorErrorContext>()
//   const factory PasswordValidationRule.oneUppercaseLetter() = OneUppercaseLetterValidationRule;
//   @Implements<ValidatorErrorContext>()
//   const factory PasswordValidationRule.oneLowercaseLetter() = OneLowercaseLetterValidationRule;
//   @Implements<ValidatorErrorContext>()
//   const factory PasswordValidationRule.oneNumericChar() = OneNumericCharValidationRule;
//   @Implements<ValidatorErrorContext>()
//   const factory PasswordValidationRule.eightToTwentyFiveChars() = EightToTwentyFiveCharsValidationRule;

//   const PasswordValidationRule._();

//   @override
//   String? toInputValidator({BuildContext? context, String? fieldName}) {
//     final tr = context?.t ?? t;
//     return switch (this) {
//       OneSpecialCharValidationRule() => tr.validation.password.oneSpecialChar,
//       OneUppercaseLetterValidationRule() => tr.validation.password.oneUppercaseLetter,
//       OneLowercaseLetterValidationRule() => tr.validation.password.oneLowercaseLetter,
//       OneNumericCharValidationRule() => tr.validation.password.oneNumericChar,
//       EightToTwentyFiveCharsValidationRule() => tr.validation.password.eightToTwentyFiveChars,
//     };
//   }
// }
