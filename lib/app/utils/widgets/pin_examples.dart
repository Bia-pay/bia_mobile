// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'reusable_pin_screen.dart';
// import 'pin_input_widget.dart';
//
// // Example 1: Set PIN Screen
// class SetPinExample extends ConsumerWidget {
//   const SetPinExample({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ReusablePinScreen(
//       title: "Set Payment PIN",
//       subtitle: "Enter a new PIN",
//       type: PinScreenType.set,
//       onPinConfirmed: (pin) {
//         print("PIN set successfully: $pin");
//         Navigator.pop(context);
//       },
//     );
//   }
// }
//
// // Example 2: Verify PIN Screen
// class VerifyPinExample extends ConsumerWidget {
//   final String existingPin;
//
//   const VerifyPinExample({super.key, required this.existingPin});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ReusablePinScreen(
//       title: "Enter PIN",
//       subtitle: "Enter your PIN to continue",
//       type: PinScreenType.verify,
//       existingPin: existingPin,
//       onPinComplete: (pin) {
//         print("PIN verified successfully");
//         Navigator.pop(context, true);
//       },
//     );
//   }
// }
//
// // Example 3: Change PIN Screen
// class ChangePinExample extends ConsumerWidget {
//   const ChangePinExample({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return ReusablePinScreen(
//       title: "Change PIN",
//       subtitle: "Enter your new PIN",
//       type: PinScreenType.change,
//       onPinConfirmed: (pin) {
//         print("PIN changed successfully: $pin");
//         Navigator.pop(context);
//       },
//     );
//   }
// }
//
// // Example 4: Custom PIN Input Widget (for embedding in other screens)
// class CustomPinInputExample extends StatefulWidget {
//   const CustomPinInputExample({super.key});
//
//   @override
//   State<CustomPinInputExample> createState() => _CustomPinInputExampleState();
// }
//
// class _CustomPinInputExampleState extends State<CustomPinInputExample> {
//   String? errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Custom PIN Input")),
//       body: PinInputWidget(
//         title: "Enter Transaction PIN",
//         subtitle: "Confirm your transaction with PIN",
//         errorMessage: errorMessage,
//         onPinComplete: (pin) {
//           // Validate PIN
//           if (pin == "1234") {
//             print("Transaction approved!");
//             setState(() => errorMessage = null);
//           } else {
//             setState(() => errorMessage = "Invalid PIN. Please try again.");
//           }
//         },
//         onPinChanged: (pin) {
//           // Clear error when user starts typing
//           if (errorMessage != null) {
//             setState(() => errorMessage = null);
//           }
//         },
//       ),
//     );
//   }
// }
//
// // Example 5: PIN Input without keypad (for custom layouts)
// class PinInputWithoutKeypadExample extends StatelessWidget {
//   const PinInputWithoutKeypadExample({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("PIN Input Only")),
//       body: Column(
//         children: [
//           Expanded(
//             child: PinInputWidget(
//               title: "Enter PIN",
//               subtitle: "Use the keypad below",
//               showKeypad: false, // Hide built-in keypad
//               onPinComplete: (pin) {
//                 print("PIN entered: $pin");
//               },
//             ),
//           ),
//
//           // Your custom keypad or other widgets here
//           Container(
//             height: 200,
//             color: Colors.grey[200],
//             child: const Center(
//               child: Text("Custom keypad area"),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Example 6: Different PIN lengths
// class CustomLengthPinExample extends StatelessWidget {
//   const CustomLengthPinExample({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ReusablePinScreen(
//       title: "6-Digit PIN",
//       subtitle: "Enter a 6-digit PIN",
//       type: PinScreenType.set,
//       onPinConfirmed: (pin) {
//         print("6-digit PIN set: $pin");
//         Navigator.pop(context);
//       },
//     );
//   }
// }