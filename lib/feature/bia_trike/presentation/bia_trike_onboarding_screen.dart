import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/custom_text_field.dart';
import '../../../app/utils/widgets/phone_input_widget.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';
import '../model/bia_trike_model.dart';
import 'bia_trike_booking_screen.dart';

class BiaTrikeOnboardingScreen extends ConsumerStatefulWidget {
  const BiaTrikeOnboardingScreen({super.key});

  @override
  ConsumerState<BiaTrikeOnboardingScreen> createState() =>
      _BiaTrikeOnboardingScreenState();
}

class _BiaTrikeOnboardingScreenState
    extends ConsumerState<BiaTrikeOnboardingScreen> {
  String _selectedLanguage = 'english'; // 'english', 'pidgin', 'hausa'
  bool _showFormView = false; // false = Role Hub, true = Rider Form

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _licenseOrNinCtrl = TextEditingController();

  String _selectedCity = 'Kano';
  String _selectedTrikeModel = 'Bajaj RE 4S';
  bool _isSubmitting = false;

  final List<String> _cities = const [
    'Kano',
    'Kaduna',
    'Abuja',
    'Lagos',
    'Ibadan',
    'Port Harcourt',
    'Jos',
    'Sokoto',
    'Katsina',
    'Maiduguri',
  ];

  final List<String> _trikeModels = const [
    'Bajaj RE 4S',
    'TVS King Deluxe',
    'Piaggio Ape City',
    'Bia EV Eco Trike',
    'Daylong 200cc',
    'Other Trike Model',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRoleSelectionBottomSheet();
    });
  }

  void _loadSavedLanguage() {
    try {
      final box = Hive.box('authBox');
      final savedLang = box.get('bia_trike_language', defaultValue: 'english') as String;
      setState(() {
        _selectedLanguage = savedLang;
      });
    } catch (_) {}
  }

  void _saveLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    try {
      final box = Hive.box('authBox');
      box.put('bia_trike_language', lang);
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateNumberCtrl.dispose();
    _licenseOrNinCtrl.dispose();
    super.dispose();
  }

  void _showLanguageSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      Text(
                        'Bia Trike Language Settings',
                        style: TextStyle(
                          color: darkBackground,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Change your dialect for audio and text prompts.',
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: 12.sp,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      _buildLangSettingTile('english', 'Standard English', '🇬🇧', setModalState),
                      SizedBox(height: 8.h),
                      _buildLangSettingTile('pidgin', 'Nigerian Pidgin', '🇳🇬', setModalState),
                      SizedBox(height: 8.h),
                      _buildLangSettingTile('hausa', 'Hausa Dialect', '🌙', setModalState),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangSettingTile(
      String code, String label, String flag, StateSetter setModalState) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        setModalState(() {});
        _saveLanguage(code);
        Navigator.pop(context);
        ToastHelper.showToast(
          context: context,
          message: "Language updated to $label",
          icon: Icons.language_rounded,
          iconColor: primaryColor,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 20.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: darkBackground,
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showRoleSelectionBottomSheet() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 540 : 600),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 28.0 : 32.r),
                      topRight: Radius.circular(isTablet ? 28.0 : 32.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: isTablet ? 48.0 : 48.w,
                          height: isTablet ? 5.0 : 5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 16.0 : 20.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Welcome to Bia Trike 🛺',
                              style: TextStyle(
                                color: darkBackground,
                                fontSize: isTablet ? 18.0 : 18.sp,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: isTablet ? 8.0 : 8.w),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(modalContext);
                              _showLanguageSettingsSheet();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12.0 : 10.w, vertical: isTablet ? 6.0 : 4.h),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedLanguage == 'hausa'
                                        ? '🌙 Hausa'
                                        : _selectedLanguage == 'pidgin'
                                            ? '🇳🇬 Pidgin'
                                            : '🇬🇧 English',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: isTablet ? 11.0 : 10.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 4.0 : 4.w),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: primaryColor, size: isTablet ? 14.0 : 14.sp),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 6.0 : 4.h),
                      Text(
                        'Select your language and tell us how you want to proceed:',
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: isTablet ? 13.0 : 12.5.sp,
                          height: 1.35,
                        ),
                      ),

                      SizedBox(height: isTablet ? 18.0 : 20.h),

                      Text(
                        'PREFERRED LANGUAGE',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: isTablet ? 11.0 : 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8.0 : 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLangChip(
                                'english', '🇬🇧 English', setModalState),
                          ),
                          SizedBox(width: isTablet ? 8.0 : 8.w),
                          Expanded(
                            child: _buildLangChip(
                                'pidgin', '🇳🇬 Pidgin', setModalState),
                          ),
                          SizedBox(width: isTablet ? 8.0 : 8.w),
                          Expanded(
                            child: _buildLangChip(
                                'hausa', '🌙 Hausa', setModalState),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 20.0 : 24.h),

                      Text(
                        'CHOOSE YOUR SERVICE',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: isTablet ? 11.0 : 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: isTablet ? 10.0 : 10.h),

                      _buildModalRoleCard(
                        title: 'Book a Keke Ride',
                        subtitle: 'Passenger looking for fast, affordable town rides',
                        icon: Icons.hail_rounded,
                        color: primaryColor,
                        onTap: () {
                          Navigator.pop(modalContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BiaTrikeBookingScreen(
                                  language: _selectedLanguage),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isTablet ? 12.0 : 12.h),

                      _buildModalRoleCard(
                        title: 'Register as Trike Rider',
                        subtitle:
                            'Drive your Trike, accept requests & earn daily money',
                        icon: Icons.electric_rickshaw_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(modalContext);
                          setState(() {
                            _showFormView = true;
                          });
                        },
                      ),

                      SizedBox(height: isTablet ? 20.0 : 24.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangChip(
      String code, String label, StateSetter setModalState) {
    final isSelected = _selectedLanguage == code;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onTap: () {
        setModalState(() {});
        _saveLanguage(code);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isTablet ? 10.0 : 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : darkBackground,
            fontSize: isTablet ? 12.5 : 12.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildModalRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.0 : 16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12.0 : 12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isTablet ? 24.0 : 24.sp),
            ),
            SizedBox(width: isTablet ? 14.0 : 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: isTablet ? 15.0 : 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: isTablet ? 3.0 : 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: lightSecondaryText,
                      fontSize: isTablet ? 12.0 : 11.5.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: isTablet ? 16.0 : 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitRider() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final application = BiaTrikeRiderApplication(
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      cityOfOperation: _selectedCity,
      trikeModel: _selectedTrikeModel,
      plateNumber: _plateNumberCtrl.text.trim().toUpperCase(),
      licenseOrNinNumber: _licenseOrNinCtrl.text.trim().toUpperCase(),
      submittedAt: DateTime.now(),
      status: 'PENDING_VERIFICATION',
    );

    final success = await ref
        .read(biaTrikeProvider.notifier)
        .submitApplication(application);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        ToastHelper.showToast(
          context: context,
          message: "Rider application submitted successfully!",
          icon: Icons.check_circle_outline_rounded,
          iconColor: primaryGreenColor,
        );
        context.pushReplacement(RouteList.biaTrikeSuccess);
      } else {
        ToastHelper.showToast(
          context: context,
          message: "Failed to submit application. Please try again.",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(biaTrikeProvider);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: isTablet ? 60.0 : null,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: darkBackground, size: isTablet ? 18.0 : 18.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bia Trike Hub',
          style: TextStyle(
            color: darkBackground,
            fontSize: isTablet ? 16.0 : 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.language_rounded, color: primaryColor, size: isTablet ? 20.0 : 20.sp),
            onPressed: _showLanguageSettingsSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : 650),
            child: appState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error loading state: $err',
                  style: TextStyle(color: darkBackground),
                ),
              ),
              data: (existingApp) {
                if (existingApp != null) {
                  return _buildExistingAppCard(theme, existingApp);
                }
                if (!_showFormView) {
                  return _buildHubOverview(theme);
                }
                return _buildRiderFormView(theme);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubOverview(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24.0 : 24.r),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 420 : double.infinity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 20.0 : 24.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.electric_rickshaw_rounded,
                  color: primaryColor,
                  size: isTablet ? 48.0 : 64.sp,
                ),
              ).animate().scale(duration: 400.ms),

              SizedBox(height: isTablet ? 20.0 : 24.h),

              Text(
                'Bia Trike Mobility',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkBackground,
                  fontSize: isTablet ? 22.0 : 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: isTablet ? 8.0 : 8.h),
              Text(
                'Fast, safe, and commercial Keke transportation powered by Bia Pay.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: isTablet ? 13.0 : 13.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: isTablet ? 24.0 : 32.h),

              SizedBox(
                width: double.infinity,
                height: isTablet ? 48.0 : 52.h,
                child: ElevatedButton(
                  onPressed: _showRoleSelectionBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
                    ),
                  ),
                  child: Text(
                    'Open Service Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 14.0 : 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingAppCard(
      ThemeData theme, BiaTrikeRiderApplication app) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24.0 : 24.r),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 460 : double.infinity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 18.0 : 20.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  size: isTablet ? 44.0 : 54.sp,
                ),
              ).animate().scale(duration: 400.ms),

              SizedBox(height: isTablet ? 18.0 : 24.h),

              Text(
                'Application Under Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkBackground,
                  fontSize: isTablet ? 20.0 : 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: isTablet ? 6.0 : 8.h),
              Text(
                'Your Bia Trike rider application is currently under verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: isTablet ? 13.0 : 13.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: isTablet ? 20.0 : 28.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 16.0 : 20.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Full Name', app.fullName),
                    Divider(color: Colors.grey.shade200),
                    _buildSummaryRow('Phone', app.phoneNumber),
                    Divider(color: Colors.grey.shade200),
                    _buildSummaryRow('City', app.cityOfOperation),
                    Divider(color: Colors.grey.shade200),
                    _buildSummaryRow('Model', app.trikeModel),
                    Divider(color: Colors.grey.shade200),
                    _buildSummaryRow('Plate No.', app.plateNumber),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 20.0 : 28.h),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: isTablet ? 48.0 : null,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(RouteList.biaTrikeSuccess);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
                          ),
                        ),
                        child: Text(
                          'View Digital Rider Pass',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14.0 : 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 12.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: darkBackground,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderFormView(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 24.w,
        vertical: isTablet ? 12.0 : 12.h,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 480 : double.infinity),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rider Registration Form',
                  style: TextStyle(
                    color: darkBackground,
                    fontSize: isTablet ? 20.0 : 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isTablet ? 4.0 : 4.h),
                Text(
                  'Fill in your details below to onboard your trike vehicle to the fleet.',
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: isTablet ? 13.0 : 13.sp,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: isTablet ? 16.0 : 20.h),

                Container(
                  padding: EdgeInsets.all(isTablet ? 16.0 : 20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 20.0 : 24.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextFormField(
                        controller: _fullNameCtrl,
                        label: "Rider Full Name",
                        hintText: "Enter your legal full name",
                        validator: (val) {
                          if (val == null || val.trim().length < 3) {
                            return "Please enter your full name";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isTablet ? 14.0 : 16.h),

                      Text(
                        "Phone Number",
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 13.sp,
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6.0 : 6.h),
                      PhoneInputWidget(
                        controller: _phoneCtrl,
                        hintText: "8012345678",
                        validator: (val) {
                          if (val == null || val.trim().length < 10) {
                            return "Enter a valid 10/11 digit phone number";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isTablet ? 14.0 : 16.h),

                      Text(
                        "City of Operation",
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 13.sp,
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6.0 : 6.h),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: offWhiteBackground,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14.0 : 16.w,
                            vertical: isTablet ? 12.0 : 14.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _cities
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14.0 : 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: darkBackground,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCity = val);
                          }
                        },
                      ),

                      SizedBox(height: isTablet ? 14.0 : 16.h),

                      Text(
                        "Trike Model / Type",
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 13.sp,
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6.0 : 6.h),
                      DropdownButtonFormField<String>(
                        value: _selectedTrikeModel,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: offWhiteBackground,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14.0 : 16.w,
                            vertical: isTablet ? 12.0 : 14.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _trikeModels
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14.0 : 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: darkBackground,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTrikeModel = val);
                          }
                        },
                      ),

                      SizedBox(height: isTablet ? 14.0 : 16.h),

                      CustomTextFormField(
                        controller: _plateNumberCtrl,
                        label: "Vehicle Plate Number",
                        hintText: "e.g. KNC 482 XA",
                        validator: (val) {
                          if (val == null || val.trim().length < 5) {
                            return "Please enter a valid plate number";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isTablet ? 14.0 : 16.h),

                      CustomTextFormField(
                        controller: _licenseOrNinCtrl,
                        label: "Driver's License / NIN Number",
                        hintText: "Enter 11-digit NIN or License No.",
                        keyboardType: TextInputType.text,
                        validator: (val) {
                          if (val == null || val.trim().length < 6) {
                            return "Please enter NIN or Driver's License number";
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isTablet ? 20.0 : 24.h),

                      SizedBox(
                        width: double.infinity,
                        height: isTablet ? 48.0 : 52.h,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmitRider,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: isTablet ? 18.0 : 20.r,
                                      height: isTablet ? 18.0 : 20.r,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 8.0 : 10.w),
                                    Text(
                                      "Submitting Application...",
                                      style: TextStyle(
                                        fontSize: isTablet ? 14.0 : 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Submit Rider Application",
                                      style: TextStyle(
                                        fontSize: isTablet ? 14.0 : 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 8.0 : 8.w),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: isTablet ? 18.0 : 18.sp,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 20.0 : 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
