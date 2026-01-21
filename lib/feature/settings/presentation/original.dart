// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/services.dart';
// import 'package:dio/dio.dart';
// import '../../../../services/auth_service.dart';
// import '../../../../services/biometric_service.dart';
// import '../../../../widgets/logo_loader.dart';
// import '../../../../services/session_manager.dart';
// class WelcomeBackScreen extends StatefulWidget {
//   final String? redirectTo;
//   final String? reason;
//   const WelcomeBackScreen({super.key, this.redirectTo, this.reason});
//   @override
//   State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
// }
// class _WelcomeBackScreenState extends State<WelcomeBackScreen> with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true; // Preserve state when switching apps
//   final AuthService _authService = AuthService();
//   final BiometricService _biometricService = BiometricService();
//
//   // We keep the controller to maintain compatibility with existing logic,
//   // even though we use a custom keypad.
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _canUseBiometrics = false;
//   String _displayName = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _prepareUser();
//
//     // Check biometrics automatically on load if available
//     // Future.delayed(const Duration(milliseconds: 500), () {
//     //   if (_canUseBiometrics) _handleFingerprintLogin();
//     // });
//   }
//   @override
//   void dispose() {
//     _passwordController.dispose();
//     super.dispose();
//   }
//   Future<void> _prepareUser() async {
//     final user = _authService.currentUser;
//     final fullName = user?['name'] ?? user?['username'] ?? '';
//
//     final canBio = await _biometricService.isLoginEnabled() &&
//         await _biometricService.isDeviceSupported() &&
//         await _biometricService.canCheckBiometrics();
//     if (!mounted) return;
//     setState(() {
//       _displayName = (fullName.isNotEmpty ? fullName : 'User').split(' ').first;
//       _canUseBiometrics = canBio;
//     });
//
//     if (widget.reason == 'expired') {
//       // Optional: Show toast or small indicator logic here
//     }
//   }
//   void _onKeyTap(String value) {
//     if (_passwordController.text.length < 4) {
//       setState(() {
//         _passwordController.text += value;
//       });
//       HapticFeedback.lightImpact();
//
//       // Auto-submit on 4th digit
//       if (_passwordController.text.length == 4) {
//         // Tiny delay to show the visual update of the 4th dot before submitting
//         Future.delayed(const Duration(milliseconds: 100), () {
//           _handleLogin();
//         });
//       }
//     }
//   }
//   void _onBackspace() {
//     if (_passwordController.text.isNotEmpty) {
//       setState(() {
//         _passwordController.text = _passwordController.text.substring(0, _passwordController.text.length - 1);
//       });
//       HapticFeedback.lightImpact();
//     }
//   }
//   Future<void> _handleLogin() async {
//     if (_passwordController.text.length != 4) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter your 4-digit PIN')),
//       );
//       return;
//     }
//     final user = _authService.currentUser;
//     final username = user?['email'] ?? user?['phone'] ?? user?['username'] ?? user?['user_name'];
//
//     if (username == null) {
//       if (mounted) context.go('/login');
//       return;
//     }
//     final input = _passwordController.text;
//
//     setState(() => _isLoading = true);
//     // Show premium loader
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.3),
//       builder: (ctx) => const Center(
//         child: LogoLoader(size: 80),
//       ),
//     );
//     try {
//       // ALWAYS try backend verification first to ensure PIN changes are reflected
//       final res = await _authService.login(
//         username.toString(),
//         input,
//       );
//       if (!mounted) return;
//       Navigator.of(context, rootNavigator: true).pop(); // Close loader
//       if (res['status'] == 'success') {
//         AuthService.justVerified = true;
//         await SessionManager.instance.updateLastActiveTime(); // Force session update
//         // RE-OPEN Loader for transition effect
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           barrierColor: Colors.black.withOpacity(0.3),
//           builder: (ctx) => const Center(child: LogoLoader(size: 80)),
//         );
//         await Future.delayed(const Duration(milliseconds: 300));
//         if (!mounted) return;
//         Navigator.of(context, rootNavigator: true).pop();
//         // Navigate to saved location or dashboard
//         var redirect = widget.redirectTo;
//         print('🔍 BACKEND VERIFY - redirectTo = "$redirect"');
//
//         if (redirect != null && redirect.isNotEmpty && redirect != 'null' && redirect != 'splash' && !redirect.contains('welcome-back')) {
//           // If we can pop to the previous screen (state preserved), do it.
//           if (context.canPop()) {
//             print('🔍 BACKEND VERIFY - POPPING STACK');
//             context.pop();
//             return;
//           }
//           if (!redirect.startsWith('/')) {
//             redirect = '/$redirect';
//           }
//           print('🔍 BACKEND VERIFY - NAVIGATING TO: $redirect');
//           context.go(redirect);
//         } else {
//           print('🔍 BACKEND VERIFY - NO VALID REDIRECT, GOING TO DASHBOARD');
//           // If simply unlocking, pop if possible
//           if (context.canPop()) {
//             context.pop();
//           } else {
//             context.go('/dashboard');
//           }
//         }
//       } else if (res['status'] == 'verify') {
//         context.go('/otp', extra: {'email': username.toString()});
//       } else {
//         _showFriendlyErrorDialog('PIN incorrect');
//         _passwordController.clear();
//       }
//     } catch (e) {
//       if (!mounted) return;
//       Navigator.of(context, rootNavigator: true).pop(); // Close loader
//
//       // OFFLINE MODE FALLBACK - for Bluetooth offline features
//       // If network fails, try local PIN verification
//       final storedPin = user?['pin']?.toString();
//       bool offlineVerified = false;
//
//       if (storedPin != null && storedPin.isNotEmpty && input == storedPin) {
//         print('🔌 OFFLINE MODE: Using cached PIN for offline Bluetooth features');
//         offlineVerified = true;
//         AuthService.justVerified = true;
//
//         // Show loader for offline login
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           barrierColor: Colors.black.withOpacity(0.3),
//           builder: (ctx) => const Center(child: LogoLoader(size: 80)),
//         );
//         await Future.delayed(const Duration(milliseconds: 300));
//         if (!mounted) return;
//         Navigator.of(context, rootNavigator: true).pop();
//         // Navigate to saved location or dashboard
//         var redirect = widget.redirectTo;
//         if (redirect != null && redirect.isNotEmpty && redirect != 'null' && redirect != 'splash' && !redirect.contains('welcome-back')) {
//           if (context.canPop()) {
//             context.pop();
//             return;
//           }
//           if (!redirect.startsWith('/')) {
//             redirect = '/$redirect';
//           }
//           context.go(redirect);
//         } else {
//           if (context.canPop()) {
//             context.pop();
//           } else {
//             context.go('/dashboard');
//           }
//         }
//         return; // Exit successfully
//       }
//
//       // Show error if both online and offline verification failed
//       String errorMsg = 'Incorrect PIN. Please try again.';
//
//       if (e is DioException) {
//         if (e.response != null && e.response?.data != null) {
//           final data = e.response?.data;
//           if (data is Map && data.containsKey('message')) {
//             errorMsg = data['message'];
//           } else if (e.response?.statusCode == 401) {
//             errorMsg = 'Incorrect PIN. Please try again.';
//           } else if (e.response?.statusCode == 422) {
//             errorMsg = 'Invalid PIN format.';
//           }
//         } else if (e.type == DioExceptionType.connectionTimeout ||
//             e.type == DioExceptionType.receiveTimeout) {
//           errorMsg = 'Connection timeout. Please check your internet.';
//         } else if (e.type == DioExceptionType.connectionError) {
//           errorMsg = 'No internet connection. Please try again.';
//         }
//       } else if (e.toString().toLowerCase().contains('incorrect')) {
//         errorMsg = 'Incorrect PIN. Please try again.';
//       }
//       _showFriendlyErrorDialog(errorMsg);
//       _passwordController.clear();
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//   void _showFriendlyErrorDialog(String msg) {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         backgroundColor: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 60,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFEF2F2), // Light red bg
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 3),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFFDC2626).withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     )
//                   ],
//                 ),
//                 child: const Icon(Icons.lock, color: Color(0xFFDC2626), size: 30),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Oops!',
//                 style: GoogleFonts.inter(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF1F2937),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 msg, // "PIN incorrect"
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: const Color(0xFF6B7280),
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1F2937),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     'Try Again',
//                     style: GoogleFonts.inter(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   Future<void> _handleFingerprintLogin() async {
//     final ok = await _biometricService.authenticate(
//       reason: 'Login to your Kobopoint account',
//     );
//     if (ok) {
//       AuthService.justVerified = true;
//       await SessionManager.instance.updateLastActiveTime(); // Force session update
//       if (!mounted) return;
//
//       // SHOW PREMIUM LOADER FOR FINGERPRINT
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         barrierColor: Colors.black.withOpacity(0.3),
//         builder: (ctx) => const Center(child: LogoLoader(size: 80)),
//       );
//
//       if (!mounted) return;
//       Navigator.of(context, rootNavigator: true).pop(); // Close loader
//       // Navigate to saved location or dashboard
//       var redirect = widget.redirectTo;
//       if (redirect != null && redirect.isNotEmpty && redirect != 'null' && redirect != 'splash' && !redirect.contains('welcome-back')) {
//         if (context.canPop()) {
//           context.pop();
//           return;
//         }
//         if (!redirect.startsWith('/')) {
//           redirect = '/$redirect';
//         }
//         context.go(redirect);
//       } else {
//         if (context.canPop()) {
//           context.pop();
//         } else {
//           context.go('/dashboard');
//         }
//       }
//     }
//   }
//   Future<void> _handleForgotPin() async {
//     final user = _authService.currentUser;
//     final email = user?['email']?.toString();
//     if (email == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No email found for this account. Contact support.')),
//       );
//       return;
//     }
//     // Confirm Dialog
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Reset Passcode?'),
//         content: Text('We will send a verification code to $email to reset your passcode.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Send Code', style: TextStyle(color: Color(0xFF00A86B))),
//           ),
//         ],
//       ),
//     );
//     if (confirm != true) return;
//     setState(() => _isLoading = true);
//
//     // Show Loader
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => const Center(child: LogoLoader(size: 80)),
//     );
//     try {
//       await _authService.resendOtp(email);
//
//       if (!mounted) return;
//       Navigator.of(context, rootNavigator: true).pop(); // Close loader
//       // Navigate to OTP with Reset Flag
//       context.go('/otp', extra: {'email': email, 'isReset': true});
//     } catch (e) {
//       if (!mounted) return;
//       Navigator.of(context, rootNavigator: true).pop();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // Required for AutomaticKeepAliveClientMixin
//     // Beautiful Gradient Background
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) {
//         if (didPop) return;
//         // SECURITY: Minimize the app instead of going back to the protected screen
//         SystemChannels.platform.invokeMethod('SystemNavigator.pop');
//       },
//       child: Scaffold(
//         body: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               // Soft Light Cream/Greenish Tint similar to image
//               colors: [
//                 Color(0xFFF9FBF6), // Very light mint cream
//                 Color(0xFFEBFAEB), // Light mint
//                 Color(0xFFFEFEF5), // Light cream bottom
//               ],
//               stops: [0.0, 0.5, 1.0],
//             ),
//           ),
//           child: SafeArea(
//             child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   return SingleChildScrollView(
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                       child: IntrinsicHeight(
//                         child: Column(
//                           children: [
//                             const SizedBox(height: 16),
//
//                             // Top Bar: Live Chat & Sign Out
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 24),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   // Live Chat Pill
//                                   GestureDetector(
//                                     onTap: () => context.push('/support/chat'),
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.withOpacity(0.2), // Transparent grey
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF1F2937)),
//                                           const SizedBox(width: 8),
//                                           Text(
//                                             'Live Chat',
//                                             style: GoogleFonts.inter(
//                                               fontWeight: FontWeight.w600,
//                                               fontSize: 12,
//                                               color: const Color(0xFF1F2937),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//
//                                   // Sign Out Pill
//                                   GestureDetector(
//                                     onTap: () async {
//                                       // SECURITY FIX: Must explicitly logout to clear token before navigating
//                                       await _authService.logout();
//                                       if (context.mounted) context.go('/login');
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.withOpacity(0.2), // Transparent grey
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       child: Text(
//                                         'Sign Out',
//                                         style: GoogleFonts.inter(
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: 12,
//                                           color: const Color(0xFF1F2937),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//
//                             const Spacer(flex: 2), // Push content down a bit
//
//                             // Avatar Circle
//                             Container(
//                               width: 80,
//                               height: 80,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFF0FDF4),
//                                 shape: BoxShape.circle,
//                                 border: Border.all(color: Colors.white, width: 3),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: const Color(0xFF00A86B).withOpacity(0.15),
//                                     blurRadius: 20,
//                                     offset: const Offset(0, 10),
//                                   )
//                                 ],
//                               ),
//                               child: ClipOval(
//                                 child: Image.asset(
//                                   'assets/images/male.webp',
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (c, o, s) => const Icon(Icons.person, size: 40, color: Color(0xFF00A86B)),
//                                 ),
//                               ),
//                             ).animate().scale(curve: Curves.easeOutBack),
//
//                             const SizedBox(height: 24),
//
//                             // Greeting
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   'Hello, $_displayName',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 const SizedBox(width: 8),
//                                 // Verification Badge
//                                 const Icon(
//                                   Icons.verified,
//                                   size: 20,
//                                   color: Color(0xFF00A86B),
//                                 )
//                               ],
//                             ).animate().fadeIn().moveY(begin: 10, end: 0),
//
//                             const SizedBox(height: 8),
//                             Text(
//                               'Welcome back, Enter your passcode',
//                               style: GoogleFonts.inter(
//                                 fontSize: 14,
//                                 color: const Color(0xFF00A86B), // Greenish text
//                               ),
//                             ).animate().fadeIn(delay: 100.ms),
//
//                             const SizedBox(height: 32),
//
//                             // PIN Dots
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: List.generate(4, (index) {
//                                 final isFilled = _passwordController.text.length > index;
//                                 return Container(
//                                   width: 16,
//                                   height: 16,
//                                   margin: const EdgeInsets.symmetric(horizontal: 10),
//                                   decoration: BoxDecoration(
//                                     color: isFilled ? Colors.transparent : Colors.white,
//                                     border: Border.all(
//                                       color: isFilled ? Colors.grey.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
//                                       width: 2,
//                                     ),
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ).animate(target: isFilled ? 1 : 0)
//                                     .custom(
//                                     duration: 100.ms,
//                                     builder: (ctx, val, child) {
//                                       return Container(
//                                         width: 16,
//                                         height: 16,
//                                         margin: const EdgeInsets.symmetric(horizontal: 10),
//                                         decoration: BoxDecoration(
//                                           color: val > 0.5 ? const Color(0xFF00A86B) : Colors.transparent, // Fill when active
//                                           border: Border.all(
//                                             color: const Color(0xFFD1D5DB), // Grey 300
//                                             width: 2,
//                                           ),
//                                           shape: BoxShape.circle,
//                                         ),
//                                       );
//                                     }
//                                 );
//                               }),
//                             ),
//
//                             const Spacer(flex: 3),
//
//                             // Custom Keypad
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 40),
//                               child: Column(
//                                 children: [
//                                   _buildKeypadRow(['1', '2', '3']),
//                                   const SizedBox(height: 24),
//                                   _buildKeypadRow(['4', '5', '6']),
//                                   const SizedBox(height: 24),
//                                   _buildKeypadRow(['7', '8', '9']),
//                                   const SizedBox(height: 24),
//
//                                   // Bottom Row: Fingerprint, 0, Backspace
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       // Left: Fingerprint Button
//                                       _buildKeypadButton(
//                                         child: const Icon(Icons.fingerprint, color: Color(0xFF00A86B), size: 32),
//                                         onTap: _handleFingerprintLogin,
//                                         isNumber: false,
//                                       ),
//                                       // Center: 0 Button
//                                       _buildKeypadButton(
//                                         child: Text(
//                                           '0',
//                                           style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
//                                         ),
//                                         onTap: () => _onKeyTap('0'),
//                                         isNumber: true,
//                                       ),
//                                       // Right: Backspace/Delete Button
//                                       _buildKeypadButton(
//                                         child: const Icon(Icons.backspace_outlined, color: Colors.black, size: 24),
//                                         onTap: _onBackspace,
//                                         isNumber: false,
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//
//                             const SizedBox(height: 40),
//
//                             // Forgot Passcode Link
//                             TextButton(
//                               onPressed: _handleForgotPin,
//                               child: Text(
//                                 'Forgot Your Passcode?',
//                                 style: GoogleFonts.inter(
//                                   color: const Color(0xFF00A86B),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//
//                             const SizedBox(height: 20),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//   Widget _buildKeypadRow(List<String> keys) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: keys.map((key) {
//         return _buildKeypadButton(
//           child: Text(
//             key,
//             style: GoogleFonts.poppins(
//               fontSize: 24,
//               fontWeight: FontWeight.w600,
//               color: Colors.black,
//             ),
//           ),
//           onTap: () => _onKeyTap(key),
//           isNumber: true,
//         );
//       }).toList(),
//     );
//   }
//   Widget _buildKeypadButton({required Widget child, required VoidCallback onTap, required bool isNumber}) {
//     return GestureDetector(
//       onTap: () {
//         onTap();
//         HapticFeedback.lightImpact(); // Haptic feedback on tap
//       },
//       behavior: HitTestBehavior.opaque, // Ensure tap area is generous
//       child: Container(
//         width: 65,
//         height: 65,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.transparent, // Transparent background for numbers logic
//           // Optional: Add ripple effect here if InkWell was used, but simple Text is fine for "Clean" look
//         ),
//         child: child,
//       ),
//     );
//   }
// }