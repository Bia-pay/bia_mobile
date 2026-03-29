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
import '../../../../core/services/biometric_service.dart';
import '../../authcontroller/authcontroller.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true;

  String? phone;
  String? fullname;
  String? savedPassword;
  String? pictureUrl;
  // ADD THESE MISSING VARIABLES:
  bool _isLoading = true; // For loading state
  String? _biometricTypeName = 'Biometric';

  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeSettings() async {
    final authBox = await Hive.openBox("authBox");
    final biometricService = BiometricService();

    // Load user data
    final loadedUserId = authBox.get("userId");
    final loadedPhone = authBox.get("phone");
    final loadedFullname = authBox.get("fullname");
    final loadedPicture = authBox.get("picture");

    debugPrint('📦 Raw data from authBox:');
    debugPrint('  userId: $loadedUserId');
    debugPrint('  phone: $loadedPhone');

    // Use phone as fallback if userId is empty
    final effectiveUserId = (loadedUserId?.toString().isNotEmpty == true)
        ? loadedUserId.toString()
        : (loadedPhone?.toString().isNotEmpty == true
        ? loadedPhone.toString()
        : "");

    // Check if we have any identifier
    if (effectiveUserId.isEmpty) {
      debugPrint('⚠️ No user identifier found, redirecting to login');
      if (mounted) {
        context.go(RouteList.loginScreen);
      }
      return;
    }

    // Resolve fullname with fallbacks
    String effectiveFullname = "User";
    if (loadedFullname != null && loadedFullname.toString().isNotEmpty) {
      effectiveFullname = loadedFullname.toString();
    } else {
      final savedProfile = authBox.get('saved_user_profile');
      if (savedProfile != null) {
        try {
          final profileData = Map<String, dynamic>.from(savedProfile);
          final profileName = profileData['fullname'] ?? profileData['name'];
          if (profileName != null && profileName.toString().isNotEmpty) {
            effectiveFullname = profileName.toString();
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing saved profile: $e');
        }
      }
    }

    if (effectiveFullname == "User" && loadedPhone != null) {
      effectiveFullname = loadedPhone.toString();
    }

    // Check biometric settings using new service
    final biometricEnabled = await biometricService.isLoginEnabled(effectiveUserId);
    final savedPwd = await biometricService.getLoginPassword(effectiveUserId);
    final biometricTypeName = await biometricService.getBiometricTypeName();

    setState(() {
      phone = loadedPhone?.toString();
      fullname = effectiveFullname;
      pictureUrl = loadedPicture?.toString();
      savedPassword = savedPwd;
      _hasBiometric = true; // Will update after check
      _biometricEnabled = biometricEnabled && savedPwd != null;
      _biometricTypeName = biometricTypeName;
      _isLoading = false;
    });

    // Check hardware availability
    final canCheck = await biometricService.canCheckBiometrics();

    setState(() {
      _hasBiometric = canCheck;
    });

    debugPrint('✅ WelcomeBack loaded:');
    debugPrint('   fullname: $fullname');
    debugPrint('   phone: $phone');
    debugPrint('   biometricEnabled: $_biometricEnabled');

    // Show appropriate UI
    if (_hasBiometric && _biometricEnabled && savedPwd != null) {
      Future.delayed(const Duration(milliseconds: 600), _authenticate);
    } else {
      setState(() => _showPasswordField = true);
    }
  }

  Future<void> _authenticate() async {
    try {
      setState(() => _isAuthenticating = true);

      final biometricService = BiometricService();
      final didAuthenticate = await biometricService.authenticate(
        reason: 'Authenticate to log in',
        biometricOnly: true,
      );

      if (!didAuthenticate) return;

      final authController = ref.read(authControllerProvider.notifier);

      await authController.logIn(context, phone!, savedPassword!.trim());

      final box = Hive.box("authBox");
      final token = box.get("token");

      if (token != null && token.isNotEmpty && mounted) {
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

    final authState = ref.read(authControllerProvider.notifier);

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final isTablet = maxWidth > 600;
            final isSmallPhone = maxHeight < 700;
            final isVerySmall = maxHeight < 600;

            // Calculate responsive values
            final horizontalPadding = isTablet ? 80.w : 30.w;
            final cardMaxWidth = isTablet ? 400.w : double.infinity;
            final contentScale = isVerySmall
                ? 0.75
                : (isSmallPhone ? 0.85 : 1.0);
            final isCompact = isKeyboardOpen || isSmallPhone || isVerySmall;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500.w : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top spacer - shrinks when keyboard open or small screen
                      if (!isKeyboardOpen)
                        SizedBox(
                          height:
                          (isVerySmall ? 20 : (isSmallPhone ? 30 : 60)) *
                              contentScale.h,
                        )
                      else
                        SizedBox(height: 8.h),

                      /// 🔹 Card Container
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardMaxWidth),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: (isTablet ? 32 : 24).w,
                            vertical: (isCompact ? 16 : 32) * contentScale.h,
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
                              // Logo - scales with screen size
                              Image.asset(
                                appLogoFull,
                                height: (isCompact ? 35 : 50) * contentScale.h,
                              ),
                              SizedBox(
                                height: (isCompact ? 12 : 20) * contentScale.h,
                              ),

                              // Avatar
                              _buildProfileAvatar(contentScale),

                              SizedBox(
                                height: (isCompact ? 10 : 16) * contentScale.h,
                              ),

                              // Welcome text
                              Text(
                                "Welcome Back",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                  (isCompact ? 16 : 22) * contentScale.sp,
                                ),
                              ),

                              SizedBox(height: 4.h),

                              // Username
                              Text(
                                fullname?.toUpperCase() ?? "USER",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                  (isCompact ? 11 : 14) * contentScale.sp,
                                ),
                              ),

                              SizedBox(
                                height: (isCompact ? 16 : 24) * contentScale.h,
                              ),

                              // Biometric or Password section
                              if (_hasBiometric &&
                                  _biometricEnabled &&
                                  !_showPasswordField)
                                _buildBiometricSection(contentScale, isCompact)
                              else
                                _buildPasswordSection(contentScale, isCompact),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: (isCompact ? 16 : 24) * contentScale.h),

                      // Switch Account
                      GestureDetector(
                        onTap: () => context.go(RouteList.loginScreen),
                        child: Text(
                          "Switch Account",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: lightSecondaryText,
                            fontSize: (isCompact ? 10 : 12) * contentScale.sp,
                          ),
                        ),
                      ),

                      // Bottom spacer
                      if (!isKeyboardOpen)
                        SizedBox(
                          height:
                          (isVerySmall ? 16 : (isSmallPhone ? 20 : 40)) *
                              contentScale.h,
                        )
                      else
                        SizedBox(height: 16.h),
                      // In your WelcomeBack build method, temporarily add:
                      // ElevatedButton(
                      //   onPressed: () async {
                      //     final authBox = await Hive.openBox('authBox');
                      //     showDialog(
                      //       context: context,
                      //       builder: (_) => AlertDialog(
                      //         title: const Text('Debug Storage'),
                      //         content: Text('''
                      //           Auth Box:
                      //           - userId: ${authBox.get('userId')}
                      //           - phone: ${authBox.get('phone')}
                      //           - fullname: ${authBox.get('fullname')}
                      //           - picture: ${authBox.get('picture')}
                      //           - token: ${authBox.get('token') != null ? 'EXISTS' : 'null'}
                      //             '''),
                      //         actions: [
                      //           TextButton(
                      //             onPressed: () => Navigator.pop(context),
                      //             child: const Text('OK'),
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //   },
                      //   child: const Text('DEBUG'),
                      // ),
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

  Widget _buildProfileAvatar(double scale) {
    final avatarRadius = (45 * scale).r;

    return Container(
      padding: EdgeInsets.all((3 * scale).r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (pictureUrl != null && pictureUrl!.isNotEmpty)
            ? NetworkImage(pictureUrl!)
            : null,
        child: pictureUrl == null
            ? Icon(Icons.person, size: (32 * scale).sp, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildBiometricSection(double scale, bool isCompact) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isAuthenticating ? null : _authenticate,
          child: Container(
            padding: EdgeInsets.all((isCompact ? 10 : 16) * scale.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.08),
            ),
            child: SvgPicture.asset(
              fingerPrint,
              height: (isCompact ? 24 : 32) * scale.h,
            ),
          ),
        ),
        SizedBox(height: (isCompact ? 8 : 12) * scale.h),
        CustomButton(
          buttonName: "Authenticate",
          buttonColor: primaryColor,
          buttonTextColor: lightBackground,
          onPressed: _isAuthenticating ? null : _authenticate,
        ),
        SizedBox(height: (isCompact ? 4 : 8) * scale.h),
        TextButton(
          onPressed: () => setState(() => _showPasswordField = true),
          child: Text(
            "Use Password Instead",
            style: TextStyle(fontSize: (isCompact ? 10 : 12) * scale.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection(double scale, bool isCompact) {
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
          validator: (value) => value.isEmpty ? "Password is required" : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: (isCompact ? 18 : 22) * scale.sp,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        SizedBox(height: (isCompact ? 4 : 8) * scale.h),
        GestureDetector(
          onTap: () => context.go(RouteList.forgotPassword),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Forget Password?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: lightText,
                fontWeight: FontWeight.w500,
                fontSize: (isCompact ? 9 : 11) * scale.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: (isCompact ? 8 : 12) * scale.h),
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
