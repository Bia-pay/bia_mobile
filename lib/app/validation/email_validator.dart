// import 'package:get/get.dart';


// import 'invalid_value_validator_error_context.dart';
// import 'required_validator.dart';
// import 'validator.dart';

// class EmailValidator extends RequiredValidator<String> {
//   const EmailValidator({super.fieldName, super.value});

//   @override
//   List<ValidatorErrorContext> validate() {
//     final validation = super.validate();
//     if (validation.isNotEmpty) {
//       return validation;
//     }

//     if (!value!.trim().toLowerCase().isEmail) {
//       return [InvalidValueValidatorErrorContext(fieldName ?? 'Email')];
//     }

//     return [];
//   }
// }
