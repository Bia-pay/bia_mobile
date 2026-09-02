import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/u_popup.dart';
import '../../../app/utils/image.dart';
import '../../../core/local/transaction_cache.dart';
import '../../../core/services/biometric_service.dart';
import '../../auth/authrepo/repo.dart';
import '../../auth/modal/reponse/response_modal.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../auth/authcontroller/authcontroller.dart';
import '../../../core/providers/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UProfile extends ConsumerStatefulWidget {
  const UProfile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UProfileState();
}

class _UProfileState extends ConsumerState<UProfile> {
  String _expandedTile = '';
  bool biometricEnabled = false;
  bool loginBiometricEnabled = false;
  UserResponse? _user;
  bool _isLoadingProfile = true;
  String _biometricTypeName = 'Biometric';
  IconData _biometricIcon = Icons.fingerprint_rounded;

  List<Map<String, dynamic>> get preferencesItems {
    final t = ref.watch(appLocaleProvider.notifier);
    return [
      {'id': 'bia_tag', 'title': 'BIA Tag', 'icon': Icons.alternate_email_rounded, 'hasDropdown': false},
      {'id': 'referrals', 'title': t.translate('refer_and_earn'), 'icon': Icons.card_giftcard_rounded, 'hasDropdown': false},
      {'id': 'generate_qr', 'title': t.translate('generate_qr'), 'icon': Icons.qr_code_2_rounded, 'hasDropdown': false},
      {'id': 'language', 'title': t.translate('language'), 'icon': Icons.language_rounded, 'hasDropdown': false},
      {'id': 'help', 'title': t.translate('help'), 'icon': Icons.help_outline_rounded, 'hasDropdown': true},
    ];
  }

  List<Map<String, dynamic>> get securityItems {
    final t = ref.watch(appLocaleProvider.notifier);
    return [
      {'id': 'pin', 'title': t.translate('pin_settings'), 'icon': Icons.lock_outline_rounded, 'hasDropdown': true},
      {'id': 'login', 'title': t.translate('login_settings'), 'icon': _biometricIcon, 'hasDropdown': true},
      {'id': 'payment', 'title': t.translate('payment_settings'), 'icon': Icons.payment_rounded, 'hasDropdown': true},
    ];
  }

  List<Map<String, dynamic>> get othersItems {
    final t = ref.watch(appLocaleProvider.notifier);
    return [
      {'id': 'privacy', 'title': 'Privacy Policy', 'icon': Icons.shield_outlined, 'hasDropdown': false},
      {'id': 'logout', 'title': t.translate('log_out'), 'icon': Icons.logout_rounded, 'hasDropdown': false},
    ];
  }

  Map<String, List<Map<String, dynamic>>> get dropdownContent {
    final t = ref.watch(appLocaleProvider.notifier);
    return {
      'pin': [
        {'title': t.translate('set_pin'), 'icon': Icons.lock_rounded},
        {'title': t.translate('change_payment_pin'), 'icon': Icons.lock_reset_rounded},
        {'title': t.translate('forget_payment_pin'), 'icon': Icons.lock_open_rounded},
        {'title': '${t.translate('pay_with')} $_biometricTypeName', 'icon': _biometricIcon},
      ],
      'login': [
        {'title': t.translate('auto_logout_settings'), 'icon': Icons.timer_outlined},
        {'title': '${t.translate('login_with')} $_biometricTypeName', 'icon': _biometricIcon},
      ],
      'help': [
        {'title': t.translate('help_center'), 'icon': Icons.support_agent_rounded},
      ],
      'payment': [
        {'title': t.translate('enable_scan_to_receive'), 'icon': Icons.qr_code_scanner_rounded},
      ],
    };
  }

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
    _loadUserProfile();
    _loadBiometricTypeName();
  }

  Future<void> _loadBiometricTypeName() async {
    final biometricService = BiometricService();
    final typeName = await biometricService.getBiometricTypeName();
    final icon = await biometricService.getBiometricIcon();
    setState(() {
      _biometricTypeName = typeName;
      _biometricIcon = icon;
    });
  }

  Future<void> _loadUserProfile() async {
    final controller = ref.read(dashboardControllerProvider.notifier);
    final box = await Hive.openBox('authBox');
    final savedUserJson = box.get('saved_user_profile');
    if (savedUserJson != null) {
      if (mounted) {
        setState(() {
          _user = UserResponse.fromJson(Map<String, dynamic>.from(savedUserJson));
          _isLoadingProfile = false;
        });
      }
    }

    try {
      final freshUser = await controller.fetchUserProfile(context);
      if (freshUser != null && mounted) {
        setState(() {
          _user = freshUser;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadBiometricSetting() async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId')?.toString() ?? authBox.get('phone')?.toString() ?? '';
    if (userId.isEmpty) return;

    final biometricService = BiometricService();
    final loginEnabled = await biometricService.isLoginEnabled(userId);
    final paymentEnabled = await biometricService.isPaymentEnabled(userId);

    setState(() {
      loginBiometricEnabled = loginEnabled;
      biometricEnabled = paymentEnabled;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      LoadingHelper.show();
      final authBox = await Hive.openBox('authBox');
      final userId = authBox.get('userId', defaultValue: '');
      final phone = authBox.get('phone', defaultValue: '');
      final fullname = authBox.get('fullname', defaultValue: '');
      final picture = authBox.get('picture');
      final effectiveUserId = userId.isNotEmpty ? userId : phone;

      await TransactionCache.clearAllTransactions();
      if (effectiveUserId.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).clearRecentBeneficiaries(effectiveUserId);
      }

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();

      final userDataToKeep = {
        'userId': userId,
        'phone': phone,
        'fullname': fullname,
        'picture': picture,
      };

      await authBox.delete('token');
      await authBox.delete('refreshToken');
      await authBox.delete('balance');
      await authBox.delete('saved_user_profile');

      for (var entry in userDataToKeep.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          await authBox.put(entry.key, entry.value);
        }
      }

      EasyLoading.dismiss();
      if (mounted) context.goNamed(RouteList.welcomeBackScreen);
    } catch (e) {
      EasyLoading.dismiss();
    }
  }

  void _confirmLogout(BuildContext context) {
    UPopup.confirm(
      context,
      title: "Log Out",
      message: "Are you sure you want to log out of your account?",
      confirmLabel: "Log Out",
      cancelLabel: "Cancel",
      onConfirm: () => _logout(context),
    );
  }

  Future<void> _handleScanToggle(Box box, bool value) async {
    if (value) {
      final allowed = await _showScanConfirmation(context);
      if (allowed == true) {
        await box.put('scan_to_receive', true);
        if (mounted) context.pushNamed(RouteList.scannerOnboarding);
        setState(() {});
      }
    } else {
      await box.put('scan_to_receive', false);
      setState(() {});
    }
  }

  Future<bool?> _showScanConfirmation(BuildContext context) async {
    return await UPopup.confirm(
      context,
      title: "Enable Scan to Receive",
      message: "This allows other users to scan your QR code to send you funds. Setup your QR now?",
      confirmLabel: "Setup Now",
      cancelLabel: "Later",
    );
  }

  Future<void> _handleForgotPin() async {
    try {
      EasyLoading.show(status: "Sending OTP...");
      final controller = ref.read(dashboardControllerProvider.notifier);
      final result = await controller.forgotPaymentPin(context);
      EasyLoading.dismiss();
      if (result != null && result.responseSuccessful == true && mounted) {
        context.pushNamed(RouteList.forgotPin);
      }
    } catch (e) {
      EasyLoading.dismiss();
    }
  }

  void _showEditTagDialog() {
    final controller = TextEditingController(text: _user?.tag);
    UPopup.show(
      context,
      type: UPopupType.info,
      title: "Update BIA Tag",
      message: "Please enter your new BIA Tag below.",
      confirmLabel: "Update",
      cancelLabel: "Cancel",
      content: TextField(
        controller: controller,
        style: TextStyle(color: lightText, fontSize: 16.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "BIA Tag",
          hintStyle: TextStyle(color: lightSecondaryText),
          prefixText: "@",
          prefixStyle: TextStyle(color: primaryColor, fontSize: 16.sp, fontWeight: FontWeight.w700),
          filled: true,
          fillColor: offWhiteBackground,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
      onConfirm: () async {
        final newTag = controller.text.trim().replaceAll('@', '');
        if (newTag.isEmpty) return;

        final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
        final res = await dashboardCtrl.updateUserTag(context, newTag);
        if (res != null && res.responseSuccessful) {
          _loadUserProfile();
          if (mounted) {
            UPopup.success(
              context,
              title: "Success",
              message: "Your BIA Tag has been updated successfully.",
            );
          }
        }
      },
    );
  }

  void _handleItemTap(BuildContext context, String id) {
    if (id == 'generate_qr') {
      context.pushNamed(RouteList.qrScreen);
    } else if (id == 'language') {
      context.pushNamed(RouteList.languageSettings);
    } else if (id == 'privacy') {
      final Uri url = Uri.parse('https://bia.com.ng/privacy');
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (id == 'bia_tag') {
      _showEditTagDialog();
    } else if (id == 'referrals') {
      context.pushNamed(RouteList.referrals);
    }
  }

  // 🧊 UI COMPONENTS (ULTRA PREMIUM REDESIGN)
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appLocaleProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra Premium Light Gray
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),

                /// HEADER
                Text(
                  t.translate('hub_settings'),
                  style: TextStyle(
                    color: lightText,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  t.translate('hub_desc'),
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 30.h),

                /// IDENTITY HUB CARD
                _buildPremiumProfile(),

                SizedBox(height: 35.h),

                /// PREFERENCES & SUPPORT SECTION
                _buildHubHeader(t.translate('prefs_support')),
                _buildGroupedSection(preferencesItems),

                SizedBox(height: 30.h),

                /// SECURITY SECTION
                _buildHubHeader(t.translate('security_login')),
                _buildGroupedSection(securityItems),

                SizedBox(height: 30.h),

                /// OTHERS SECTION
                _buildHubHeader(t.translate('more_options')),
                _buildGroupedSection(othersItems),

                SizedBox(height: 140.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPremiumProfile() {
    final user = _user;

    return GestureDetector(
      onTap: () => context.pushNamed(RouteList.userSettings),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal:12.r, vertical: 10.h),
        decoration: BoxDecoration(
          color: lightBackground,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            /// AVATAR WITH RING
            Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 58.w,
                  height: 58.w,
                  child: _buildAvatarImage(user?.picture),
                ),
              ),
            ),

            SizedBox(width: 18.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullname ?? "Account Hub",
                    style: TextStyle(
                      color: lightText,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: successColor, size: 12.sp),
                      SizedBox(width: 3.w),
                      Text(
                        ref.read(appLocaleProvider.notifier).translate('verified_account'),
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FA),
                shape: BoxShape.circle,
              ),
              child:  Icon(Icons.keyboard_arrow_right_rounded, color: primaryColor, size: 20.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildModernTile(item),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const Divider(height: 1, color: lightBackground),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildModernTile(Map<String, dynamic> item) {
    final t = ref.watch(appLocaleProvider.notifier);
    final String id = item['id'] ?? '';
    final String title = item['title'] ?? '';
    final bool hasDropdown = item['hasDropdown'] ?? false;
    final bool isLogout = id == 'logout';
    final bool isExpanded = _expandedTile == id;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24.r),
          onTap: () {
            if (isLogout) {
              _confirmLogout(context);
            } else if (hasDropdown && dropdownContent.containsKey(id)) {
              setState(() => _expandedTile = isExpanded ? '' : id);
            } else {
              _handleItemTap(context, id);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(18.r),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isLogout ? errorColor.withOpacity(0.08) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(
                      item['icon'],
                      size: 20.sp,
                      color: isLogout ? errorColor : primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isLogout ? errorColor : lightText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (hasDropdown)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 24),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: const Color(0xFF94A3B8).withOpacity(0.5), size: 22),
              ],
            ),
          ),
        ),

        /// MODERN DROPDOWN CONTENT
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          child: isExpanded && dropdownContent[id] != null
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 60.w, right: 18.w, bottom: 20.h),
                  child: Column(
                    children: dropdownContent[id]!.map((subItem) {
                      final subTitle = subItem['title']!;
                      final subIcon = subItem['icon'] as IconData;

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9).withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: Center(
                                child: Icon(
                                  subIcon,
                                  size: 14.sp,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (subTitle == 'Set Pin') {
                                    context.pushNamed(RouteList.setTransactionPin);
                                  } else if (subTitle == 'Change Payment Pin') {
                                    context.pushNamed(RouteList.changePaymentPin);
                                  } else if (subTitle == 'Forget Payment Pin') {
                                    _handleForgotPin();
                                  } else if (subTitle == t.translate('auto_logout_settings')) {
                                    context.pushNamed(RouteList.autoLogoutSettings);
                                  } else if (subTitle == t.translate('help_center')) {
                                    context.pushNamed(RouteList.helpCenter);
                                  }
                                  // Add other sub-item routes here as needed
                                },
                                child: Text(
                                  subTitle,
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                                ),
                              ),
                            ),

                            /// SWITCHES
                            if (subTitle.startsWith('Pay with ') ||
                                subTitle.startsWith('Login with ') ||
                                subTitle == 'Enable Scan to Receive')
                              _buildSubItemSwitch(subTitle),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubItemSwitch(String subTitle) {
    return FutureBuilder<Box>(
      future: Hive.openBox('settingsBox'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final box = snapshot.data!;
        final isLoginSwitch = subTitle.startsWith('Login with ');

        return FutureBuilder<String>(
          future: Hive.openBox('authBox').then((authBox) => authBox.get('userId', defaultValue: '')),
          builder: (context, userIdSnapshot) {
            if (!userIdSnapshot.hasData) return const SizedBox.shrink();
            final userId = userIdSnapshot.data!;

            return FutureBuilder<bool>(
              future: _getBiometricState(subTitle, box, userId),
              builder: (context, enabledSnapshot) {
                final isEnabled = enabledSnapshot.data ?? false;
                return Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isEnabled,
                    activeColor: primaryColor,
                    onChanged: (value) async {
                      if (subTitle == 'Enable Scan to Receive') {
                        await _handleScanToggle(box, value);
                      } else if (isLoginSwitch) {
                        if (value) {
                          final result = await context.pushNamed(RouteList.enableLoginFingerprint);
                          if (result == true) await _loadBiometricSetting();
                        } else {
                          await BiometricService().disableLoginBiometric(userId);
                          setState(() => loginBiometricEnabled = false);
                        }
                      } else {
                        if (value) {
                          final result = await context.pushNamed(RouteList.enableTransactionPinFingerprint);
                          if (result == true) await _loadBiometricSetting();
                        } else {
                          await BiometricService().disablePaymentBiometric(userId);
                          setState(() => biometricEnabled = false);
                        }
                      }
                      setState(() {});
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _getBiometricState(String subTitle, Box settingsBox, String userId) async {
    if (subTitle == 'Enable Scan to Receive') {
      return settingsBox.get('scan_to_receive', defaultValue: false);
    } else if (subTitle.startsWith('Login with ')) {
      return await BiometricService().isLoginEnabled(userId);
    } else {
      return await BiometricService().isPaymentEnabled(userId);
    }
  }

  Widget _buildAvatarImage(String? picture) {
    if (picture == null || picture.isEmpty) {
      return Image.network(getDiceBearAvatar('default'), fit: BoxFit.cover);
    }
    return Image.network(
      picture,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.network(getDiceBearAvatar(picture), fit: BoxFit.cover),
    );
  }
}