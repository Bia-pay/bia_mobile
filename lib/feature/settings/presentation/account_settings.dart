import 'dart:convert';
import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:hive/hive.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/pin_field.dart';
import '../../../app/utils/colors.dart';
import '../../../core/local/localStorage.dart';
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
  final List<Map<String, dynamic>> securityItems = [
    {
      'title': 'Pin Settings',
      'image': 'assets/svg/key.svg',
      'hasDropdown': true,
    },
    {
      'title': 'Login Settings',
      'image': 'assets/svg/l-key.svg',
      'hasDropdown': true,
    },
  ];

  final List<Map<String, dynamic>> othersItems = [
    {'title': 'Help', 'image': 'assets/svg/help.svg', 'hasDropdown': true},
    {'title': 'Generate Qr Code', 'image': 'assets/svg/qr-code-1.svg', 'hasDropdown': false},
    {'title': 'Log Out', 'image': 'assets/svg/logout.svg', 'hasDropdown': false},
  ];

  final Map<String, List<Map<String, String>>> dropdownContent = {
    'Pin Settings': [
      {'title': 'Set Pin', 'image': 'assets/svg/key.svg'},
      {'title': 'Change Payment Pin', 'image': 'assets/svg/key.svg'},
      {'title': 'Forget Payment Pin', 'image': 'assets/svg/key.svg'},
      {'title': 'Pay with Fingerprint', 'image': 'assets/svg/key.svg'},
    ],
    'Login Settings': [
      {'title': 'Change Password', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Forget Password', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Auto Logout Settings', 'image': 'assets/svg/l-key.svg'},
      {'title': 'Login with Fingerprint', 'image': 'assets/svg/l-key.svg'},
    ],
    'Help': [
      {'title': 'Help Center', 'image': 'assets/svg/cancel.svg'},
    ],
  };

  final Map<String, String> routeMap = {
    'Generate Qr Code': RouteList.qrScreen,
    'Help Center': RouteList.helpCenter,
  };

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
    _loadUserProfile();
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
  Future<void> _loadBiometricSetting() async {
    final box = await Hive.openBox('settingsBox');
    setState(() {
      biometricEnabled = box.get('biometric_enabled', defaultValue: false);
      loginBiometricEnabled = box.get('login_biometric_enabled', defaultValue: false);
    });
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      EasyLoading.show(status: "Logging out...");

      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('token', defaultValue: '');
      final biometricEnabled = authBox.get('login_biometric_enabled', defaultValue: false);
      final userId = authBox.get('userId', defaultValue: '');

      // Clear cached transactions for this user
      await TransactionStorage.clearTransactions(userId);

      // Clear any saved profile
      await authBox.delete('saved_user_profile');

      // Clear this user's saved beneficiaries if you have this function
      await clearRecentBeneficiaries(token);

      // Clear token and other Hive data
      if (biometricEnabled) {
        await authBox.delete('token');
        await authBox.delete('refreshToken');
      } else {
        await authBox.clear();
      }

      // Reset providers to initial state
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(dashboardControllerProvider);

      EasyLoading.dismiss();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        biometricEnabled ? RouteList.welcomeBackScreen : RouteList.loginScreen,
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> clearRecentBeneficiaries(String token) async {
    final box = await Hive.openBox('recentBeneficiaries');
    await box.delete(token);
  }
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context, ref );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _handleItemTap(BuildContext context, String title) {
    final route = routeMap[title];
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  /// ✅ NEW SET PIN MODAL
  void _showSetPinModal(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final repo = ref.read(dashboardControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildBottomSheetContainer(
        context,
        title: "Set Transaction PIN",
        message: "Enter and confirm your 4-digit transaction PIN.",
        child: Column(
          children: [
            AppPinCodeField(controller: pinController, length: 4,  fillColor: keyAColor,
              inactiveColor: keyAColor,
              activeColor: primaryColor,
              selectedColor: primaryColor,),
            const SizedBox(height: 15),
            AppPinCodeField(controller: confirmPinController, length: 4,  fillColor: keyAColor,
                inactiveColor: keyAColor,
                activeColor: primaryColor,
                selectedColor: primaryColor),
          ],
        ),
        onConfirm: () async {
          final pin = pinController.text.trim();
          final confirmPin = confirmPinController.text.trim();

          if (pin.isEmpty || confirmPin.isEmpty) {
            _showSnack(context, "Both fields are required", Colors.red);
            return;
          }
          if (pin != confirmPin) {
            _showSnack(context, "PINs do not match", Colors.red);
            return;
          }
          final response = await repo.setPin(context, pin, confirmPin);

          if (response != null && response.responseSuccessful) {
            final box = await Hive.openBox('settingsBox');
            await box.put('saved_pin', pin);
            _showSnack(context, "PIN set successfully", Colors.green);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// ✅ Fingerprint modals preserved
  void _showPinSetupModal(BuildContext context, Box box) {
    final pinController = TextEditingController();
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildBottomSheetContainer(
        context,
        title: "Enable Biometric Payment",
        message: "Enter your 4-digit transaction PIN to link it to your fingerprint.",
        child: AppPinCodeField(controller: pinController, length: 4,  fillColor: keyAColor,
            inactiveColor: keyAColor,
            activeColor: primaryColor,
            selectedColor: primaryColor),
        onConfirm: () async {
          final pin = pinController.text.trim();
          if (pin.length != 4) {
            _showSnack(context, "Please enter a valid 4-digit PIN", Colors.red);
            return;
          }
          await box.put('biometric_enabled', true);
          await box.put('saved_pin', pin);
          Navigator.pop(context);
          setState(() => biometricEnabled = true);
          _showSnack(context, "Fingerprint login enabled successfully", Colors.green);

        },
      ),
    );
  }

  void _showPasswordSetupModal(BuildContext context, Box box) {
    final passwordController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildBottomSheetContainer(
        context,
        title: "Enable Biometric Login",
        message: "Enter your account password to save for fingerprint login.",
        child: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
        ),
        onConfirm: () async {
          final password = passwordController.text.trim();
          if (password.isEmpty) {
            _showSnack(context, "Please enter your password", Colors.red);
            return;
          }

          await box.put('biometric_login_password', password);
          await box.put('login_biometric_enabled', true);

          Navigator.pop(context);
          setState(() => loginBiometricEnabled = true);
          _showSnack(context, "Fingerprint login enabled successfully", Colors.green);
        },
      ),
    );
  }

  Widget _buildBottomSheetContainer(
      BuildContext context, {
        required String title,
        required String message,
        required Widget child,
        required VoidCallback onConfirm,
      }) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
          ),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 15),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 25),
          child,
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),
                    Center(
                      child: Text(
                        'Settings',
                        style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 24.spMin),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    _buildProfileHeader(context),
                    SizedBox(height: 24.h),
                    _divider(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            _buildSection(context, 'Security', securityItems),
            _buildSection(context, 'Others', othersItems),
            SliverToBoxAdapter(child: SizedBox(height: 60.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final name = _user?.fullname ?? 'No Name';
    final username = _user?.phone ?? 'username';
    final avatarUrl = 'https://www.bigfootdigital.co.uk/wp-content/uploads/2020/07/image-optimisation-scaled.jpg'; // Optional: from user if available

    return Column(
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundImage: NetworkImage(avatarUrl),
        ),
        SizedBox(height: 10.h),
        Text(name, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        Text('$username', style: context.textTheme.labelSmall?.copyWith(fontSize: 12.spMin)),
        SizedBox(height: 15.h),
      ],
    );
  }
  Widget _buildSection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(title, style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15.spMin)),
          ...items.map((item) => _buildSettingsTile(context, item)),
          _divider(context),
        ]),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
    color: Theme.of(context).brightness == Brightness.light ? lightBorderColor : darkBorderColor,
    thickness: 2,
  );

  Widget _buildSettingsTile(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'];
    final hasDropdown = item['hasDropdown'];
    final isLogout = title == 'Log Out';
    final isExpanded = _expandedTile == title;

    return Column(
      children: [
        InkWell(
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
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLogout ? Colors.red.shade100 : Colors.grey.shade200,
                  ),
                  child: SvgPicture.asset(
                    item['image'],
                    height: 15.h,
                    colorFilter: ColorFilter.mode(
                      isLogout ? Colors.red : Colors.grey.shade700,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15.spMin,
                      color: isLogout ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (hasDropdown)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700,
                    size: 25.spMin,
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && dropdownContent[title] != null)
          Padding(
            padding: EdgeInsets.only(left: 55.w, top: 5.h),
            child: Column(
              children: dropdownContent[title]!.map((subItem) {
                final subTitle = subItem['title']!;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
                          child: SvgPicture.asset(
                            subItem['image']!,
                            height: 15.h,
                            colorFilter: ColorFilter.mode(Colors.grey.shade700, BlendMode.srcIn),
                          ),
                        ),
                        SizedBox(width: 18.w),
                        GestureDetector(
                          onTap: () async {
                            if (subTitle == 'Set Pin') {
                              _showSetPinModal(context, ref);
                            }
                          },
                          child: Text(
                            subTitle,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.spMin,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ]),
                      if (subTitle == 'Pay with Fingerprint' || subTitle == 'Login with Fingerprint')
                        FutureBuilder(
                          future: Hive.openBox('settingsBox'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const SizedBox(width: 40, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final box = snapshot.data!;
                            final isLoginSwitch = subTitle == 'Login with Fingerprint';
                            final isEnabled = isLoginSwitch
                                ? box.get('login_biometric_enabled', defaultValue: false)
                                : box.get('biometric_enabled', defaultValue: false);

                            return Transform.scale(
                              scale: 0.55,
                              child: Switch(
                                value: isEnabled,
                                onChanged: (value) async {
                                  if (isLoginSwitch) {
                                    if (value) {
                                      _showPasswordSetupModal(context, box);
                                    } else {
                                      await box.put('login_biometric_enabled', false);
                                      await box.delete('biometric_login_password');
                                      setState(() => loginBiometricEnabled = false);
                                    }
                                  } else {
                                    if (value) {
                                      _showPinSetupModal(context, box);
                                    } else {
                                      await box.put('biometric_enabled', false);
                                      await box.delete('saved_pin');
                                      setState(() => biometricEnabled = false);
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}