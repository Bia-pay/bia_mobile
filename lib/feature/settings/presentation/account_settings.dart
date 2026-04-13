import 'dart:io';
import 'package:bia/core/__core.dart';
import 'package:bia/core/easy_loading_config.dart';
import 'package:bia/feature/dashboard/dashboard_repo/repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/image.dart';
import '../../../core/local/transaction_cache.dart';
import '../../../core/services/biometric_service.dart';
import '../../auth/authrepo/repo.dart';
import '../../auth/data/api_constant.dart';
import '../../auth/data/api_data.dart';
import '../../auth/modal/reponse/response_modal.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/dashboardcontroller/provider.dart';


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
  final List<Map<String, dynamic>> securityItems = [
    {
      'title': 'Pin Settings',
      'image': 'assets/svg/key.svg',
      'hasDropdown': true,
    },
    {
      'title': 'Login Settings',
      'image': 'assets/svg/blocked.svg',
      'hasDropdown': true,
    },
    {
      'title': 'Payment Settings',
      'image': 'assets/svg/invoice.svg',
      'hasDropdown': true,
    },
  ];

  final List<Map<String, dynamic>> othersItems = [
    {'title': 'Help', 'image': 'assets/svg/help.svg', 'hasDropdown': true},
    {'title': 'Generate Qr Code', 'image': 'assets/svg/qr-code-1.svg', 'hasDropdown': false},
    {'title': 'Log Out', 'image': 'assets/svg/logout.svg', 'hasDropdown': false},
  ];

  Map<String, List<Map<String, String>>> get dropdownContent => {
    'Pin Settings': [
      {'title': 'Set Pin', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Change Payment Pin', 'image': 'assets/svg/key.svg'},
      {'title': 'Forget Payment Pin', 'image': 'assets/svg/key.svg'},
      {'title': 'Pay with $_biometricTypeName', 'image': 'assets/svg/key.svg'},
    ],
    'Login Settings': [
      {'title': 'Change Password', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Forget Password', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Auto Logout Settings', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Login with $_biometricTypeName', 'image': 'assets/svg/l-key.svg'},
    ],
    'Help': [
      {'title': 'Help Center', 'image': 'assets/svg/cancel.svg'},
    ],
    'Payment Settings': [
      {'title': 'Enable Scan to Receive', 'image': 'assets/svg/qr-code-1.svg'},
    ],
  };

  final Map<String, String> routeMap = {
    'Set Pin': RouteList.setTransactionPin,
    'Change Payment Pin': RouteList.changePaymentPin,
    'Generate Qr Code': RouteList.qrScreen,
    'Help Center': RouteList.helpCenter,
    //'Forget Payment Pin': RouteList.forgetPaymentPin,
  };

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
    setState(() {
      _biometricTypeName = typeName;
    });
  }

  Future<void> _loadUserProfile() async {
    final controller = ref.read(dashboardControllerProvider.notifier);

    // Step 1: Load cached user immediately
    final box = await Hive.openBox('authBox');
    final savedUserJson = box.get('saved_user_profile');
    if (savedUserJson != null) {
      final cachedUser = UserResponse.fromJson(Map<String, dynamic>.from(savedUserJson));
      setState(() {
        _user = cachedUser;
        _isLoadingProfile = false; // we have something to show
      });
    }

    // Step 2: Fetch fresh profile in the background
    try {
      final freshUser = await controller.fetchUserProfile(context);
      if (freshUser != null) {
        setState(() {
          _user = freshUser;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      setState(() => _isLoadingProfile = false);
    }
  }

  void _showEditAvatarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Change photo"),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadAvatar(context);
            },
          ),
          if (_user?.picture != null)
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text("View photo"),
              onTap: () {
                Navigator.pop(context);
                _previewAvatar(context);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _loadBiometricSetting() async {
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId');
    final phone = authBox.get('phone');

    final effectiveUserId = userId?.toString() ?? phone?.toString() ?? '';

    if (effectiveUserId.isEmpty) {
      setState(() {
        biometricEnabled = false;
        loginBiometricEnabled = false;
      });
      return;
    }

    final biometricService = BiometricService();
    final loginEnabled = await biometricService.isLoginEnabled(effectiveUserId);
    final paymentEnabled = await biometricService.isPaymentEnabled(effectiveUserId);

    setState(() {
      loginBiometricEnabled = loginEnabled;
      biometricEnabled = paymentEnabled;
    });
  }

  void _previewAvatar(BuildContext context) {
    final image = _user?.picture;
    if (image == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Image.network(image),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked == null) return;

    // ✅ INSTANT PREVIEW
    setState(() {
      _user = _user?.copyWith(picture: picked.path);
    });

    final controller =
    ref.read(dashboardControllerProvider.notifier);

    final response = await controller.uploadProfileImage(
      context,
      picked.path,
    );

    if (response != null && response.responseSuccessful) {
      // 🔄 replace local path with backend URL
      await _loadUserProfile();
    }
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

      // 🔥 CRITICAL: Clear transaction cache FIRST
      await TransactionCache.clearAllTransactions();

      // Clear beneficiaries
      if (effectiveUserId.isNotEmpty) {
        await clearRecentBeneficiaries(effectiveUserId);
      }

      // Call API logout
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();

      // 🔹 Save user data BEFORE any clearing (for welcome back screen)
      final userDataToKeep = {
        'userId': userId,
        'phone': phone,
        'fullname': fullname,
        'picture': picture,
      };

      // Step 1: Delete sensitive data only
      await authBox.delete('token');
      await authBox.delete('refreshToken');
      await authBox.delete('balance');
      await authBox.delete('saved_user_profile');

      // Step 2: Restore user identification data
      for (var entry in userDataToKeep.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          await authBox.put(entry.key, entry.value);
        }
      }

      debugPrint('🔐 Logout complete. Kept user data: $userDataToKeep');

      EasyLoading.dismiss();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 🔹 ALWAYS go to welcome back
      if (mounted) {
        context.go(RouteList.welcomeBackScreen);
      }
    } catch (e) {
      LoadingHelper.dismiss();
      debugPrint('❌ Logout error: $e');
      // Even on error, go to welcome back
      if (mounted) {
        context.go(RouteList.welcomeBackScreen);
      }
    }
  }
  Future<void> clearRecentBeneficiaries(String userId) async {
    final box = await Hive.openBox('recentBeneficiaries');
    await box.delete('beneficiaries_$userId');
    debugPrint('🗑️ Cleared beneficiaries for user $userId');
  }

  void _confirmLogout(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Logout",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * animation.value),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  return Container(
                    width: width > 600 ? 360 : width * 0.88,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// Title
                        Text(
                          "Confirm Logout",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        SizedBox(height: 10.h),

                        /// Message
                        Text(
                          "Are you sure you want to log out?",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),

                        SizedBox(height: 20.h),

                        /// Buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // 🔹 Call logout directly - no need for microtask
                                  _logout(this.context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: errorColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: const Text(
                                  "Logout",
                                  style:
                                  TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleItemTap(BuildContext context, String title) {
    final route = routeMap[title];
    if (route != null) {
      context.pushNamed(route);
    }
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // New: Show confirmation dialog with scale animation before enabling scan
  Future<bool?> _showScanConfirmation(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Allow scan payments?',
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = Curves.easeOut.transform(anim.value);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.8 + 0.2 * curved,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: offWhite, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Allow scan payments?', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Other users will be able to scan your QR to send you money. Proceed?', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                              child: const Text('Allow', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  // Handle toggling of scan receive. Checks PIN presence and shows modal/animation.
  Future<void> _handleScanToggle(Box settingsBox, bool value) async {
    final hasPin = settingsBox.get('saved_pin', defaultValue: null) != null;
    if (!hasPin) {
      // Pin not set — don't toggle, prompt user to set PIN
      _showSnack(context, 'You must set a transaction PIN before enabling Scan to Receive.', pendingColor);
      return;
    }

    if (value) {
      // Show confirmation modal with animation
      final allowed = await _showScanConfirmation(context);
      if (allowed == true) {
        await settingsBox.put('scan_to_receive', true);
        // Navigate to QR scanner screen
        context.pushNamed(RouteList.qrScannerScreen);
        setState(() {});
      }
    } else {
      // user turning off
      await settingsBox.put('scan_to_receive', false);
      setState(() {});
    }
  }

  Future<void> _handleForgotPin() async {
    try {
      EasyLoading.show(status: "Sending OTP...");

      final controller =
      ref.read(dashboardControllerProvider.notifier);

      final result =
      await controller.forgotPaymentPin(context);

      EasyLoading.dismiss();

      if (!mounted) return;

      // ✅ PROPER NULL CHECK
      if (result != null && result.responseSuccessful == true) {
        context.pushNamed(RouteList.forgotPin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.responseMessage ?? "Failed to send OTP"),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 600, // 🔥 prevents stretch on tablets
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.04),

                        /// TITLE
                        Text(
                          "Settings",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22.spMin,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.04),

                        /// PROFILE
                        _buildPremiumProfile(),

                        SizedBox(height: screenHeight * 0.04),

                        /// SECURITY
                        _buildGroupedSection(securityItems),

                        SizedBox(height: screenHeight * 0.03),

                        /// OTHERS
                        _buildGroupedSection(othersItems),

                        SizedBox(height: screenHeight * 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumProfile() {
    final theme = Theme.of(context);
    final user = _user;

    return GestureDetector(
      onTap: () => _showEditAvatarSheet(context),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 65.w,
                    height: 65.w,
                    child: _buildAvatarImage(user?.picture),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 14.spMin,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 16.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullname ?? "Loading...",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user?.phone ?? "",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, size: 22.spMin),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedSection(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildModernTile(item),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60.w,
                  color: Colors.grey.shade200,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildModernTile(Map<String, dynamic> item) {
    final title = item['title'];
    final hasDropdown = item['hasDropdown'];
    final isLogout = title == 'Log Out';
    final isExpanded = _expandedTile == title;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () {
            if (isLogout) {
              _confirmLogout(context);
            } else if (hasDropdown && dropdownContent.containsKey(title)) {
              setState(() => _expandedTile = isExpanded ? '' : title);
            } else {
              _handleItemTap(context, title);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: isLogout
                        ? errorColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      item['image'],
                      height: 18.h,
                      colorFilter: ColorFilter.mode(
                        isLogout ? errorColor : Colors.black87,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.spMin,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? errorColor : Colors.black87,
                    ),
                  ),
                ),
                if (hasDropdown)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20.spMin,
                  )
                else
                  Icon(Icons.chevron_right, size: 20.spMin),
              ],
            ),
          ),
        ),

        /// 🔥 DROPDOWN CONTENT (THIS WAS MISSING)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded && dropdownContent[title] != null
              ? Padding(
            padding: EdgeInsets.only(left: 20.w, right: 16.w, bottom: 12.h),
            child: Column(
              children: dropdownContent[title]!.map((subItem) {
                final subTitle = subItem['title']!;
                final subIcon = subItem['image']!;

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      /// ICON
                      Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            subIcon,
                            height: 14.h,
                            colorFilter: const ColorFilter.mode(
                              Colors.black87,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 14.w),

                      /// TITLE
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (subTitle == 'Set Pin') {
                              context.pushNamed(RouteList.setTransactionPin);
                            } else if (subTitle == 'Change Payment Pin') {
                              context.pushNamed(RouteList.changePaymentPin);
                            } else if (subTitle == 'Forget Payment Pin') {
                              _handleForgotPin();
                            }
                          },
                          child: Text(
                            subTitle,
                            style: TextStyle(
                              fontSize: 14.spMin,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      /// SWITCHES (if needed)
                      if (subTitle.startsWith('Pay with ') ||
                          subTitle.startsWith('Login with ') ||
                          subTitle == 'Enable Scan to Receive')
                        FutureBuilder<Box>(
                          future: Hive.openBox('settingsBox'),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            final box = snapshot.data!;
                            final isLoginSwitch =
                            subTitle.startsWith('Login with ');

                            return FutureBuilder<String>(
                              future: Hive.openBox('authBox').then((authBox) =>
                                  authBox.get('userId', defaultValue: '')),
                              builder: (context, userIdSnapshot) {
                                if (!userIdSnapshot.hasData) {
                                  return SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                }

                                final userId = userIdSnapshot.data!;

                                // Get enabled state based on switch type
                                Future<bool> getEnabledState() async {
                                  if (subTitle == 'Enable Scan to Receive') {
                                    return box.get('scan_to_receive', defaultValue: false);
                                  } else if (isLoginSwitch) {
                                    final biometricService = BiometricService();
                                    return await biometricService.isLoginEnabled(userId);
                                  } else {
                                    final biometricService = BiometricService();
                                    return await biometricService.isPaymentEnabled(userId);
                                  }
                                }

                                return FutureBuilder<bool>(
                                  future: getEnabledState(),
                                  builder: (context, enabledSnapshot) {
                                    if (!enabledSnapshot.hasData) {
                                      return SizedBox(
                                        width: 24.w,
                                        height: 24.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    final isEnabled = enabledSnapshot.data!;

                                    return Transform.scale(
                                      scale: 0.75,
                                      child: Switch(
                                        value: isEnabled,
                                        onChanged: (value) async {
                                          if (subTitle ==
                                              'Enable Scan to Receive') {
                                            await _handleScanToggle(box, value);
                                            return;
                                          }

                                          if (isLoginSwitch) {
                                            if (value) {
                                              final result = await context.pushNamed(
                                                RouteList.enableLoginFingerprint,
                                              );
                                              if (result == true) {
                                                await _loadBiometricSetting();
                                              }
                                            } else {
                                              // Disable login biometric using service
                                              final biometricService = BiometricService();
                                              await biometricService.disableLoginBiometric(userId);
                                              setState(() => loginBiometricEnabled = false);
                                            }
                                          }
                                          else {
                                            if (value) {
                                              final result = await context.pushNamed(
                                                RouteList
                                                    .enableTransactionPinFingerprint,
                                              );
                                              if (result == true) {
                                                await _loadBiometricSetting();
                                              }
                                            } else {
                                              // Disable payment biometric using service
                                              final biometricService = BiometricService();
                                              await biometricService.disablePaymentBiometric(userId);
                                              setState(() => biometricEnabled = false);
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
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


  Widget _buildAvatarImage(String? picture) {
    if (picture == null || picture.isEmpty) {
      return Image.asset(appLogoPng, fit: BoxFit.cover);
    }

    if (picture.startsWith('http')) {
      return Image.network(
        picture,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => Image.asset(appLogoPng, fit: BoxFit.cover),
      );
    }

    return Image.file(File(picture), fit: BoxFit.cover);
  }

}