import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/u_popup.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../app/utils/widgets/pin_input_widget.dart';
import '../../../../app/utils/widgets/enhanced_pin_screen.dart';
import '../../authcontroller/authcontroller.dart';
import '../../interceptor/interceptor.dart';
import '../../../dashboard/dashboardcontroller/provider.dart';

class WelcomeBackScreen extends ConsumerStatefulWidget {
  final bool isSessionLock;
  final bool forceHome;

  const WelcomeBackScreen({
    super.key,
    this.isSessionLock = false,
    this.forceHome = false,
  });

  @override
  ConsumerState<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends ConsumerState<WelcomeBackScreen> {
  bool _hasBiometric = false;
  bool _biometricEnabled = false;
  bool _isAuthenticating = false;
  bool _showPasswordField = false;
  bool _allowPop = false;
  IconData _biometricIcon = Icons.fingerprint_rounded;

  String? phone;
  String? fullname;
  String? savedPassword;
  String? pictureUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  void _showErrorModal(String title, String message, {bool isNetworkError = false, VoidCallback? onRetry}) {
    if (onRetry != null) {
      UPopup.confirm(context, title: title, message: message, confirmLabel: 'Retry', cancelLabel: 'OK', onConfirm: onRetry);
    } else {
      UPopup.error(context, title: title, message: message, confirmLabel: 'OK');
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final results = await Future.wait([
        InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5)),
        InternetAddress.lookup('cloudflare.com').timeout(const Duration(seconds: 5)),
      ], eagerError: true).catchError((_) => <List<InternetAddress>>[]);
      return results.isNotEmpty && results.any((r) => r.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializeSettings() async {
    final authBox = Hive.box("authBox");
    final biometricService = BiometricService();

    final loadedUserId = authBox.get("userId")?.toString() ?? '';
    final loadedPhone  = authBox.get("phone")?.toString() ?? '';
    final loadedFullname = authBox.get("fullname")?.toString() ?? '';
    final loadedPicture  = authBox.get("picture")?.toString();

    final effectiveUserId = loadedUserId.isNotEmpty ? loadedUserId : loadedPhone;
    if (effectiveUserId.isEmpty) {
      if (mounted) context.go(RouteList.loginScreen);
      return;
    }

    String effectiveFullname = loadedFullname.isNotEmpty ? loadedFullname : loadedPhone;
    if (effectiveFullname.isEmpty) effectiveFullname = 'User';

    final biometricEnabled = await biometricService.isLoginEnabled(effectiveUserId);
    final savedPwd        = await biometricService.getLoginPassword(effectiveUserId);
    final canCheck        = await biometricService.canCheckBiometrics();
    final icon            = await biometricService.getBiometricIcon();

    setState(() {
      phone        = loadedPhone;
      fullname     = effectiveFullname;
      pictureUrl   = loadedPicture;
      savedPassword = savedPwd;
      _hasBiometric    = canCheck;
      _biometricEnabled = canCheck && biometricEnabled && savedPwd != null;
      _showPasswordField = !_biometricEnabled;
      _biometricIcon   = icon;
      _isLoading = false;
    });

    if (_biometricEnabled) {
      Future.delayed(const Duration(milliseconds: 100), _authenticate);
    }
  }

  Future<void> _performLogin(String loginPhone, String loginPassword, {bool isBiometric = false}) async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    LoadingHelper.show('Logging in...');

    try {
      final success = await ref.read(authControllerProvider.notifier)
          .logIn(context, loginPhone, loginPassword.trim())
          .timeout(const Duration(seconds: 30));

      LoadingHelper.dismiss();
      debugPrint('🔑 _performLogin: success=$success, mounted=$mounted');

      if (success) {
        ref.read(sessionServiceProvider.notifier).clearLockState();
        setState(() => _allowPop = true);
        // Use post-frame callback to navigate AFTER EasyLoading dismiss settles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (widget.isSessionLock && !widget.forceHome && context.canPop()) {
              context.pop();
            } else {
              context.go(RouteList.bottomNavBar);
            }
          } else {
            // Fallback: widget was unmounted (e.g. during overlay teardown)
            // Use the global navigator key to still perform navigation
            debugPrint('⚠️ WelcomeBack unmounted after login — using navigatorKey fallback');
            navigatorKey.currentContext?.go(RouteList.bottomNavBar);
          }
        });
      } else {
        if (mounted) {
          _showErrorModal('Login Failed', 'Invalid credentials. Please try again.');
          _resetState(isBiometric);
        }
      }
    } catch (e, stackTrace) {
      LoadingHelper.dismiss();
      debugPrint('❌ Login process failed with exception: $e');
      debugPrint('Stack trace: $stackTrace');
      
      String title = 'Login Error';
      String message = 'Something went wrong. Please try again later.';
      if (e is TimeoutException || e.toString().toLowerCase().contains('timeout')) {
        title = 'Connection Timeout';
        message = 'Request timed out. Network too slow or disconnected.';
      } else if (e is SocketException || e.toString().toLowerCase().contains('socket')) {
        title = 'Network Error';
        message = 'Connection lost during login. Please check your network.';
      }
      
      if (mounted) {
        _showErrorModal(
          title, 
          message, 
          onRetry: () => _performLogin(loginPhone, loginPassword, isBiometric: isBiometric),
        );
        _resetState(isBiometric);
      }
    }
  }

  void _resetState(bool isBiometric) {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      if (isBiometric) _showPasswordField = true;
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    if (phone == null || savedPassword == null) {
      setState(() => _showPasswordField = true);
      return;
    }

    final biometricService = BiometricService();
    final didAuthenticate = await biometricService.authenticate(reason: 'Authenticate to log in', biometricOnly: true);

    if (didAuthenticate) {
      await _performLogin(phone!, savedPassword!, isBiometric: true);
    } else {
      setState(() => _showPasswordField = true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final effectivePictureUrl = userProfile?.picture ?? pictureUrl;
    final effectiveFullname = userProfile?.fullname ?? fullname ?? "User";

    return PopScope(
      canPop: !widget.isSessionLock || _allowPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Subtle accent wash at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300.h,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withOpacity(0.08),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final isTablet = MediaQuery.of(context).size.width > 600;
                  final isSmall = height < 780;
                  final isTiny  = height < 640;
                  
                  final double logoH = isTablet ? 30.0 : (isTiny ? 20.h : (isSmall ? 25.h : 35.h));
                  final double avatarR = isTablet ? 36.0 : (isTiny ? 20.r : (isSmall ? 26.r : 35.r));
                  final double keypadH = isTablet ? 260.0 : (isTiny ? 260.h : (isSmall ? 300.h : 350.h));
                  final double cardPaddingV = isTablet ? 20.0 : (isTiny ? 8.h : (isSmall ? 12.h : 20.h));
                  final double innerGap = isTablet ? 12.0 : (isTiny ? 4.h : (isSmall ? 8.h : 16.h));
  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Logo section
                      Padding(
                        padding: EdgeInsets.only(top: isTablet ? 16 : (isTiny ? 8.h : 20.h)),
                        child: Image.asset(appLogoFull, height: logoH),
                      ),
                      
                      // Middle Card section - centered box on tablet
                      Flexible(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 420 : double.infinity,
                            ),
                            child: Padding(
                              padding: isTablet
                                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                                  : EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                              child: Container(
                                width: double.infinity,
                                padding: isTablet
                                    ? const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
                                    : EdgeInsets.symmetric(horizontal: 20.w, vertical: cardPaddingV),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.06),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(color: lightBorderColor, width: 1),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildAvatar(avatarR, effectivePictureUrl, effectiveFullname),
                                      SizedBox(height: innerGap),
                                      Text(
                                        _getGreeting(),
                                        style: TextStyle(
                                          color: lightSecondaryText,
                                          fontSize: isTablet ? 12.0 : 10.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        effectiveFullname,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: lightText,
                                          fontSize: isTablet ? 22.0 : (isTiny ? 16.sp : 22.sp),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: innerGap / 2),
                                      
                                      if (_showPasswordField || !_biometricEnabled)
                                        PinInputWidget(
                                          title: "",
                                          subtitle: _showPasswordField ? "Enter 6-digit Passcode" : "Protecting your account",
                                          fieldType: InputFieldType.pin,
                                          inputLength: 6,
                                          showKeypad: _showPasswordField || !_biometricEnabled,
                                          textColor: lightText,
                                          dotColor: primaryColor,
                                          keyColor: offWhite,
                                          keypadHeight: keypadH,
                                          onPinComplete: (val) => _performLogin(phone!, val),
                                          onBiometricAction: _biometricEnabled ? _authenticate : null,
                                          biometricIcon: _biometricIcon,
                                          onForgotPin: () => context.go(RouteList.forgotPassword),
                                        ),
                                      
                                      if (_hasBiometric && _biometricEnabled && !_showPasswordField) ...[
                                        SizedBox(height: innerGap * 1.5),
                                        _buildBiometricPrompt(),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Bottom section - Sleek outlined pill button
                      Padding(
                        padding: EdgeInsets.only(bottom: isTablet ? 16 : 8.h),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor.withOpacity(0.25), width: 1.2),
                            shape: const StadiumBorder(),
                            padding: isTablet
                                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                                : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.04),
                          ),
                          onPressed: () {
                            ref.read(authControllerProvider.notifier).logout(context: context, isManual: true);
                          }, 
                          icon: Icon(
                            Icons.swap_horiz_rounded,
                            size: isTablet ? 18 : 16.sp,
                            color: primaryColor,
                          ),
                          label: Text(
                            "Switch Account",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: isTablet ? 13.0 : 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double radius, String? imgUrl, String name) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double sz = isTablet ? 72.0 : radius * 2;
    
    // Generate initials (e.g. "SG" for "Salma Gambo")
    String initials = "U";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      initials = parts.first[0].toUpperCase();
      if (parts.length > 1 && parts.last.isNotEmpty) {
        initials += parts.last[0].toUpperCase();
      }
    }

    bool isValidPhotoUrl = imgUrl != null &&
        imgUrl.isNotEmpty &&
        imgUrl.startsWith('http') &&
        (imgUrl.endsWith('.png') ||
         imgUrl.endsWith('.jpg') ||
         imgUrl.endsWith('.jpeg') ||
         imgUrl.endsWith('.webp') ||
         imgUrl.contains('avatar'));

    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        gradient: brandGradient,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: isValidPhotoUrl
            ? Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 22.0 : 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22.0 : 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        GestureDetector(
          onTap: _authenticate,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor, border: Border.all(color: accentColor.withOpacity(0.1))),
            child: Icon(_biometricIcon, size: 36.sp, color: lightBackground),
          ),
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: () => setState(() => _showPasswordField = true), 
          child: Text("Use Password Instead", style: TextStyle(color: accentColor, fontSize: 13.sp, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }
}

