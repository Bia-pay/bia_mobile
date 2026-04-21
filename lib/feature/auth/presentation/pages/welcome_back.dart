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
import '../../../../core/services/biometric_service.dart';
import '../../../../app/utils/widgets/pin_input_widget.dart';
import '../../../../app/utils/widgets/enhanced_pin_screen.dart';
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

    setState(() {
      phone        = loadedPhone;
      fullname     = effectiveFullname;
      pictureUrl   = loadedPicture;
      savedPassword = savedPwd;
      _hasBiometric    = canCheck;
      _biometricEnabled = canCheck && biometricEnabled && savedPwd != null;
      _showPasswordField = !_biometricEnabled;
      _isLoading = false;
    });

    if (_biometricEnabled) {
      Future.delayed(const Duration(milliseconds: 100), _authenticate);
    }
  }

  Future<void> _performLogin(String loginPhone, String loginPassword, {bool isBiometric = false}) async {
    if (_isAuthenticating) return;

    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _showErrorModal('No Internet Connection', 'Please check your network settings and try again.', onRetry: () => _performLogin(loginPhone, loginPassword, isBiometric: isBiometric));
      return;
    }

    setState(() => _isAuthenticating = true);
    LoadingHelper.show('Logging you in...');

    try {
      final success = await ref.read(authControllerProvider.notifier)
          .logIn(context, loginPhone, loginPassword.trim())
          .timeout(const Duration(seconds: 30));

      LoadingHelper.dismiss();

      if (success && mounted) {
        context.go(RouteList.bottomNavBar);
      } else {
        _showErrorModal('Login Failed', 'Invalid credentials. Please try again.');
        _resetState(isBiometric);
      }
    } catch (e) {
      LoadingHelper.dismiss();
      _showErrorModal('Login Error', 'Something went wrong. Please try again later.');
      _resetState(isBiometric);
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

    return Scaffold(
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
                final isSmall = height < 700;
                final isTiny  = height < 600;
                
                final double logoH = isTiny ? 20.h : (isSmall ? 25.h : 35.h);
                final double avatarR = isTiny ? 20.r : (isSmall ? 26.r : 35.r);
                final double keypadH = isTiny ? 220.h : (isSmall ? 250.h : 350.h);
                final double cardPaddingV = isTiny ? 8.h : 20.h;
                final double innerGap = isTiny ? 4.h : 16.h;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Logo section
                    Padding(
                      padding: EdgeInsets.only(top: isTiny ? 8.h : 20.h),
                      child: Image.asset(appLogoFull, height: logoH,),
                    ),
                    
                    // Middle Card section - using Flexible to prevent overflow
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: cardPaddingV),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: accentColor.withOpacity(0.08), width: 1),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAvatar(avatarR),
                              SizedBox(height: innerGap),
                              Text(_getGreeting(), style: TextStyle(color: primaryColor.withOpacity(0.5), fontSize: 10.sp, fontWeight: FontWeight.w600)),
                              Text(fullname ?? "User", textAlign: TextAlign.center, style: TextStyle(color: accentColor, fontSize: isTiny ? 16.sp : 22.sp, fontWeight: FontWeight.w900)),
                              SizedBox(height: innerGap / 2),
                              
                              if (_showPasswordField || !_biometricEnabled)
                                PinInputWidget(
                                  title: "",
                                  subtitle: _showPasswordField ? "Enter 6-digit Password" : "Protecting your account",
                                  fieldType: InputFieldType.pin,
                                  inputLength: 6,
                                  showKeypad: _showPasswordField || !_biometricEnabled,
                                  textColor: accentColor,
                                  dotColor: accentColor,
                                  keyColor: grey100,
                                  keypadHeight: keypadH,
                                  onPinComplete: (val) => _performLogin(phone!, val),
                                  onBiometricAction: _biometricEnabled ? _authenticate : null,
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
                    
                    // Bottom section
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: TextButton(
                        onPressed: () => context.go(RouteList.loginScreen), 
                        child: Text("Switch Account", style: TextStyle(color: accentColor.withOpacity(0.6), fontSize: 12.sp, fontWeight: FontWeight.w700))
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double radius) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        border: Border.all(color: accentColor.withOpacity(0.1), width: 2),
      ),
      child: CircleAvatar(
        radius: radius, 
        backgroundColor: accentColor.withOpacity(0.05), 
        backgroundImage: (pictureUrl != null && pictureUrl!.isNotEmpty) ? NetworkImage(pictureUrl!) : null, 
        child: pictureUrl == null || pictureUrl!.isEmpty ? Icon(Icons.person_outline, size: radius, color: accentColor) : null
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
            child: Icon(Icons.fingerprint_rounded, size: 36.sp, color: lightBackground),
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
