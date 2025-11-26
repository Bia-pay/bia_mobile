import 'validator.dart';

class SequentialValidator implements Validator {
  SequentialValidator(this.validators);

  final List<Validator> validators;

  @override
  List<ValidatorErrorContext> validate() {
    for (final validator in validators) {
      final errorContexts = validator.validate();
      if (errorContexts.isNotEmpty) {
        return errorContexts;
      }
    }
    return [];
  }
}
