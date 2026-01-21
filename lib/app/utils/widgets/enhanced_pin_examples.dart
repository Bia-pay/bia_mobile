// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'enhanced_pin_screen.dart';
//
// // Example 1: Set PIN Screen (Original use case)
// class SetPinScreen extends ConsumerWidget {
//   const SetPinScreen({super.key, this.title = "Set Payment PIN"});
//   final String title;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: title,
//       subtitle: "Enter a new PIN",
//       type: PinScreenType.set,
//       fieldType: InputFieldType.pin,
//       onPinConfirmed: (pin) {
//         print("PIN set successfully: $pin");
//         // Save PIN logic here
//       },
//     );
//   }
// }
//
// // Example 2: Verify PIN Screen
// class VerifyPinScreen extends ConsumerWidget {
//   final String existingPin;
//
//   const VerifyPinScreen({super.key, required this.existingPin});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Enter PIN",
//       subtitle: "Enter your PIN to continue",
//       type: PinScreenType.verify,
//       fieldType: InputFieldType.pin,
//       existingPin: existingPin,
//       onPinComplete: (pin) {
//         print("PIN verified successfully");
//         Navigator.pop(context, true);
//       },
//     );
//   }
// }
//
// // Example 3: Password Screen (New capability)
// class SetPasswordScreen extends ConsumerWidget {
//   const SetPasswordScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Set Password",
//       subtitle: "Create a secure password",
//       type: PinScreenType.set,
//       fieldType: InputFieldType.password,
//       hintText: "Enter your password",
//       onPinConfirmed: (password) {
//         print("Password set successfully: $password");
//         // Save password logic here
//       },
//     );
//   }
// }
//
// // Example 4: Login Password Screen
// class LoginPasswordScreen extends ConsumerWidget {
//   final String existingPassword;
//
//   const LoginPasswordScreen({super.key, required this.existingPassword});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Login",
//       subtitle: "Enter your password to continue",
//       type: PinScreenType.verify,
//       fieldType: InputFieldType.password,
//       existingPin: existingPassword, // Using existingPin for password too
//       hintText: "Enter your password",
//       onPinComplete: (password) {
//         print("Login successful");
//         Navigator.pop(context, true);
//       },
//     );
//   }
// }
//
// // Example 5: 6-Digit PIN Screen
// class SixDigitPinScreen extends ConsumerWidget {
//   const SixDigitPinScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Set 6-Digit PIN",
//       subtitle: "Enter a 6-digit PIN for extra security",
//       type: PinScreenType.set,
//       fieldType: InputFieldType.pin,
//       inputLength: 6,
//       onPinConfirmed: (pin) {
//         print("6-digit PIN set: $pin");
//       },
//     );
//   }
// }
//
// // Example 6: Transaction PIN (No keypad, custom button)
// class TransactionPinScreen extends ConsumerWidget {
//   final double amount;
//   final String recipient;
//
//   const TransactionPinScreen({
//     super.key,
//     required this.amount,
//     required this.recipient,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Confirm Transaction",
//       subtitle: "Enter PIN to send ₦$amount to $recipient",
//       type: PinScreenType.verify,
//       fieldType: InputFieldType.pin,
//       showKeypad: false, // Use external keypad or different UI
//       existingPin: "1234", // Get from storage
//       onPinComplete: (pin) {
//         // Process transaction
//         print("Transaction confirmed with PIN: $pin");
//       },
//     );
//   }
// }
//
// // Example 7: Change Password Screen
// class ChangePasswordScreen extends ConsumerWidget {
//   const ChangePasswordScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Change Password",
//       subtitle: "Enter your new password",
//       type: PinScreenType.change,
//       fieldType: InputFieldType.password,
//       hintText: "New password",
//       obscureText: true,
//       onPinConfirmed: (newPassword) {
//         print("Password changed successfully");
//         // Update password logic
//       },
//     );
//   }
// }
//
// // Example 8: Custom Styled PIN Screen
// class CustomStyledPinScreen extends ConsumerWidget {
//   const CustomStyledPinScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return EnhancedPinScreen(
//       title: "Custom PIN",
//       subtitle: "Enter your custom PIN",
//       type: PinScreenType.set,
//       fieldType: InputFieldType.pin,
//       backgroundColor: Colors.blue[50],
//       showBackButton: false,
//       onPinConfirmed: (pin) {
//         print("Custom PIN set: $pin");
//       },
//     );
//   }
// }