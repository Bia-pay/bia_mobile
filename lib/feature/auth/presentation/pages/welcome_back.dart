// import 'package:bia/core/__core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hive/hive.dart';
//
// import '../../../../app/utils/colors.dart';
// import '../../../../app/utils/custom_button.dart';
// import '../../../../app/utils/image.dart';
// import '../../../../app/utils/router/route_constant.dart';
// import '../../../../app/utils/widgets/custom_text_field.dart';
// import '../../../../core/utils/biometric_helper.dart';
// import '../../authcontroller/authcontroller.dart';
//
// class WelcomeBackScreen extends ConsumerStatefulWidget {
//   const WelcomeBackScreen({super.key});
//
//   @override
//   ConsumerState<WelcomeBackScreen> createState() =>
//       _WelcomeBackScreenState();
// }
//
// class _WelcomeBackScreenState
//     extends ConsumerState<WelcomeBackScreen> {
//   bool _hasBiometric = false;
//   bool _biometricEnabled = false;
//   bool _isAuthenticating = false;
//   bool _showPasswordField = false;
//   bool _obscurePassword = true;
//
//   String? phone;
//   String? fullname;
//   String? savedPassword;
//   String? biometricTypeName;
//   String? pictureUrl;
//
//   final TextEditingController passwordController =
//   TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeSettings();
//   }
//
//   Future<void> _initializeSettings() async {
//     final authBox = await Hive.openBox("authBox");
//
//     final availability =
//     await BiometricHelper.checkBiometricAvailability();
//     final biometricEnabled =
//     await BiometricHelper.isLoginBiometricEnabled();
//
//     final settingsBox = await Hive.openBox("settingsBox");
//     final savedPwd =
//     settingsBox.get("biometric_login_password");
//
//     final userPhone = authBox.get("phone");
//     final userName = authBox.get("fullname") ?? "User";
//     final picture = authBox.get("picture");
//
//     setState(() {
//       _hasBiometric = availability.isAvailable;
//       _biometricEnabled = biometricEnabled;
//       biometricTypeName = availability.biometricTypeName;
//       phone = userPhone;
//       fullname = userName;
//       savedPassword = savedPwd;
//       pictureUrl = picture;
//     });
//
//     if (!availability.isAvailable) {
//       setState(() => _showPasswordField = true);
//       return;
//     }
//
//     if (availability.isAvailable &&
//         biometricEnabled &&
//         savedPwd != null) {
//       Future.delayed(const Duration(milliseconds: 800), _authenticate);
//     } else {
//       setState(() => _showPasswordField = true);
//     }
//   }
//
//   Future<void> _authenticate() async {
//     try {
//       setState(() => _isAuthenticating = true);
//
//       final didAuthenticate =
//       await BiometricHelper.authenticate(
//         reason: 'Authenticate to log in',
//         biometricOnly: true,
//       );
//
//       // ❗ DO NOT force password on cancel
//       if (!didAuthenticate) {
//         return;
//       }
//
//       final authController =
//       ref.read(authControllerProvider.notifier);
//
//       if (phone == null || savedPassword == null) {
//         _showError(
//             "Missing saved credentials. Please log in manually.");
//         setState(() => _showPasswordField = true);
//         return;
//       }
//
//       await authController.logIn(
//           context, phone!, savedPassword!.trim());
//
//       final box = Hive.box("authBox");
//       final token = box.get("token");
//
//       if (token != null &&
//           token.isNotEmpty &&
//           mounted) {
//         context.go(RouteList.bottomNavBar);
//       } else {
//         _showError("Login failed. Please try again.");
//       }
//     } catch (e) {
//       debugPrint("Biometric error: $e");
//     } finally {
//       if (mounted) {
//         setState(() => _isAuthenticating = false);
//       }
//     }
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   Future<void> _loginWithPassword() async {
//     FocusScope.of(context).unfocus();
//
//     final authState = ref.read(
//       authControllerProvider.notifier,
//     );
//
//     final success = await authState.logIn(
//       context,
//       phone!,
//       passwordController.text.trim(),
//     );
//
//     if (success && mounted) {
//       context.go(RouteList.bottomNavBar);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightBackground,
//       resizeToAvoidBottomInset: false,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Padding(
//               padding: EdgeInsets.fromLTRB(
//                 38.w,
//                 15.h,
//                 38.w,
//                 MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: ConstrainedBox(
//                 constraints:
//                 BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment:
//                     CrossAxisAlignment.center,
//                     children: [
//                       Image.asset(appLogoFull, height: 50.h),
//
//                       Padding(
//                         padding:
//                         EdgeInsets.symmetric(vertical: 10.h),
//                         child: pictureUrl != null &&
//                             pictureUrl!.isNotEmpty
//                             ? CircleAvatar(
//                           radius: 30.r,
//                           backgroundColor:
//                           Colors.grey.shade200,
//                           backgroundImage:
//                           NetworkImage(pictureUrl!),
//                         )
//                             : CircleAvatar(
//                           radius: 50.r,
//                           backgroundColor:
//                           Colors.grey.shade300,
//                           child: Icon(
//                             Icons.person,
//                             size: 40.sp,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//
//                       Text(
//                         'Welcome Back,',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineLarge
//                             ?.copyWith(
//                           fontSize: 26.sp,
//                           color: lightText,
//                         ),
//                       ),
//                       Text(
//                         fullname?.toUpperCase() ?? 'USER',
//                         style: Theme.of(context)
//                             .textTheme
//                             .headlineLarge
//                             ?.copyWith(
//                           color: primaryColor,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18.sp,
//                         ),
//                       ),
//
//                       SizedBox(height: 30.h),
//
//                       if (_hasBiometric &&
//                           _biometricEnabled &&
//                           !_showPasswordField)
//                         Center(
//                           child: Column(
//                             children: [
//                               GestureDetector(
//                                 onTap: _isAuthenticating
//                                     ? null
//                                     : _authenticate,
//                                 child: Column(
//                                   children: [
//                                     SvgPicture.asset(
//                                       fingerPrint,
//                                       height: 50.h,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                   ],
//                                 ),
//                               ),
//
//                               SizedBox(height: 20.h),
//
//                               CustomButton(
//                                 buttonName: 'Try fingerprint again',
//                                 buttonColor: primaryColor,
//                                 buttonTextColor: lightBackground,
//                                 onPressed: _isAuthenticating
//                                     ? null
//                                     : _authenticate,
//                               ),
//
//                               SizedBox(height: 10.h),
//
//                               TextButton(
//                                 onPressed: () => setState(
//                                         () => _showPasswordField = true),
//                                 child: Text(
//                                   'Use Password Instead',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodyMedium
//                                       ?.copyWith(
//                                       color: primaryColor),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       else
//                         Column(
//                           children: [
//                             CustomTextFormField(
//                               label: 'Password',
//                               controller: passwordController,
//                               hintText: 'Enter your password',
//                               obscureText: _obscurePassword,
//                               keyboardType: TextInputType.number,
//                               maxLength: 6,
//                               textInputAction: TextInputAction.done,
//                               onSubmitted: (_) => _loginWithPassword(),
//                               validator: (value) =>
//                               value.isEmpty ? 'Password is required' : null,
//                               suffixIcon: IconButton(
//                                 icon: Icon(
//                                   _obscurePassword
//                                       ? Icons.visibility_off_outlined
//                                       : Icons.visibility_outlined,
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _obscurePassword = !_obscurePassword;
//                                   });
//                                 },
//                               ),
//                             ),
//                             SizedBox(height: 10.h),
//                             GestureDetector(
//                               onTap: () =>
//                                   context.go(RouteList.forgotPassword),
//                               child: Align(
//                                 alignment: Alignment.bottomRight,
//                                 child: Text(
//                                   'Forget Password?',
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodySmall
//                                       ?.copyWith(
//                                     color: lightText,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(height: 20.h),
//                             CustomButton(
//                               buttonName: 'Login',
//                               buttonColor: primaryColor,
//                               buttonTextColor: lightBackground,
//                               onPressed: () async {
//                                 FocusScope.of(context).unfocus();
//
//                                 final authState = ref.read(
//                                   authControllerProvider.notifier,
//                                 );
//
//                                 final success =
//                                 await authState.logIn(
//                                   context,
//                                   phone!,
//                                   passwordController.text.trim(),
//                                 );
//
//                                 if (success && mounted) {
//                                   context.go(
//                                       RouteList.bottomNavBar);
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//
//                       SizedBox(height: 20.h),
//
//                       GestureDetector(
//                         onTap: () =>
//                             context.go(RouteList.loginScreen),
//                         child: Text(
//                           'Switch account',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodyMedium
//                               ?.copyWith(
//                             color: lightSecondaryText,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../app/utils/widgets/custom_text_field.dart';
import '../../../../core/utils/biometric_helper.dart';
import '../../authcontroller/authcontroller.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() =>
      _WelcomeBackScreenState();
}

class _WelcomeBackScreenState
    extends ConsumerState<WelcomeBackScreen> {
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true;

  String? phone;
  String? fullname;
  String? savedPassword;
  String? pictureUrl;

  final TextEditingController passwordController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final authBox = await Hive.openBox("authBox");

    final availability =
    await BiometricHelper.checkBiometricAvailability();
    final biometricEnabled =
    await BiometricHelper.isLoginBiometricEnabled();

    final settingsBox = await Hive.openBox("settingsBox");
    final savedPwd =
    settingsBox.get("biometric_login_password");

    setState(() {
      _hasBiometric = availability.isAvailable;
      _biometricEnabled = biometricEnabled;
      phone = authBox.get("phone");
      fullname = authBox.get("fullname") ?? "User";
      pictureUrl = authBox.get("picture");
      savedPassword = savedPwd;
    });

    if (!availability.isAvailable ||
        !biometricEnabled ||
        savedPwd == null) {
      setState(() => _showPasswordField = true);
    } else {
      Future.delayed(
          const Duration(milliseconds: 600), _authenticate);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);

      final didAuthenticate =
      await BiometricHelper.authenticate(
        reason: 'Authenticate to log in',
        biometricOnly: true,
      );

      if (!didAuthenticate) return;

      final authController =
      ref.read(authControllerProvider.notifier);

      await authController.logIn(
          context, phone!, savedPassword!.trim());

      final box = Hive.box("authBox");
      final token = box.get("token");

      if (token != null &&
          token.isNotEmpty &&
          mounted) {
        context.go(RouteList.bottomNavBar);
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _loginWithPassword() async {
    FocusScope.of(context).unfocus();

    final authState =
    ref.read(authControllerProvider.notifier);

    final success = await authState.logIn(
      context,
      phone!,
      passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go(RouteList.bottomNavBar);
    }
  }



  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  // Grab the bottom padding (keyboard height)
  final bottomInset = MediaQuery.of(context).viewInsets.bottom;

  return Scaffold(
  // Keep this true so the Scaffold pushes content up
  resizeToAvoidBottomInset: true,
  backgroundColor: lightBackground,
  body: SafeArea(
  child: LayoutBuilder(
  builder: (context, constraints) {
  return SingleChildScrollView(
  // This allows the view to bounce and scroll when keyboard is active
  physics: const AlwaysScrollableScrollPhysics(),
  child: Padding(
  padding: EdgeInsets.symmetric(horizontal: 30.w),
  child: ConstrainedBox(
  constraints: BoxConstraints(
  // Ensure the column is at least as tall as the screen
  minHeight: constraints.maxHeight,
  ),
  child: Column(
  children: [
  SizedBox(height: 60.h),

  /// 🔹 Card Container
  Container(
  width: double.infinity,
  padding: EdgeInsets.symmetric(
  horizontal: 24.w,
  vertical: 32.h,
  ),
  decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20.r),
  boxShadow: [
  BoxShadow(
  color: Colors.black.withOpacity(0.02),
  blurRadius: 20,
  offset: const Offset(0, 4),
  ),
  ],
  ),
  child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
  Image.asset(appLogoFull, height: 60.h),
  SizedBox(height: 25.h),
  _buildProfileAvatar(),
  SizedBox(height: 20.h),
  Text(
  "Welcome Back",
  style: theme.textTheme.headlineSmall?.copyWith(
  fontWeight: FontWeight.w600,
  ),
  ),
  SizedBox(height: 6.h),
  Text(
  fullname?.toUpperCase() ?? "USER",
  style: theme.textTheme.titleMedium?.copyWith(
  color: primaryColor,
  fontWeight: FontWeight.bold,
  ),
  ),
  SizedBox(height: 30.h),

  if (_hasBiometric &&
  _biometricEnabled &&
  !_showPasswordField)
  _buildBiometricSection()
  else
  _buildPasswordSection(),
  ],
  ),
  ),

  SizedBox(height: 30.h),

  GestureDetector(
  onTap: () => context.go(RouteList.loginScreen),
  child: Text(
  "Switch Account",
  style: theme.textTheme.bodyMedium?.copyWith(
  color: lightSecondaryText,
  ),
  ),
  ),

  // 🔹 CRITICAL: This adds space at the bottom when keyboard is up
  // so you can scroll the content above the keyboard line.
  SizedBox(height: bottomInset > 0 ? 20.h : 50.h),
  ],
  ),
  ),
  ),
  );
  },
  ),
  ),
  );
  }

  Widget _buildProfileAvatar() {
  return Container(
  padding: EdgeInsets.all(3.r),
  decoration: BoxDecoration(
  shape: BoxShape.circle,
  border: Border.all(color: primaryColor, width: 2),
  ),
  child: CircleAvatar(
  radius: 45.r,
  backgroundColor: Colors.grey.shade200,
  backgroundImage: (pictureUrl != null && pictureUrl!.isNotEmpty)
  ? NetworkImage(pictureUrl!)
      : null,
  child: pictureUrl == null
  ? Icon(Icons.person, size: 40.sp, color: Colors.white)
      : null,
  ),
  );
  }

  Widget _buildBiometricSection() {
    return Column(
      children: [
        GestureDetector(
          onTap:
          _isAuthenticating ? null : _authenticate,
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor
                  .withOpacity(0.08),
            ),
            child: SvgPicture.asset(
              fingerPrint,
              height: 40.h,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        CustomButton(
          buttonName: "Authenticate",
          buttonColor: primaryColor,
          buttonTextColor: lightBackground,
          onPressed:
          _isAuthenticating ? null : _authenticate,
        ),
        SizedBox(height: 10.h),
        TextButton(
          onPressed: () =>
              setState(() =>
              _showPasswordField = true),
          child: const Text("Use Password Instead"),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      children: [
        CustomTextFormField(
          label: "Password",
          controller: passwordController,
          hintText: "Enter your password",
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loginWithPassword(),
          validator: (value) =>
          value.isEmpty
              ? "Password is required"
              : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword =
                !_obscurePassword;
              });
            },
          ),
        ),         SizedBox(height: 10.h),
        GestureDetector(
          onTap: () =>
              context.go(RouteList.forgotPassword),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Forget Password?',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: lightText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        CustomButton(
          buttonName: "Login",
          buttonColor: primaryColor,
          buttonTextColor: lightBackground,
          onPressed: _loginWithPassword,
        ),
      ],
    );
  }
}