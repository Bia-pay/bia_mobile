import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';
import 'bia_trike_booking_screen.dart';

class BiaTrikeOnboardingScreen extends ConsumerStatefulWidget {
  const BiaTrikeOnboardingScreen({super.key});

  @override
  ConsumerState<BiaTrikeOnboardingScreen> createState() =>
      _BiaTrikeOnboardingScreenState();
}

class _BiaTrikeOnboardingScreenState
    extends ConsumerState<BiaTrikeOnboardingScreen> {
  bool _showFormView = false;
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _licenseOrNinCtrl = TextEditingController();

  String _selectedCity = 'Kano';
  String _selectedTrikeModel = 'Bajaj RE 4S Yellow';

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
    'Bajaj RE 4S Yellow',
    'TVS King Deluxe Blue',
    'Piaggio Ape City Green',
    'Bia EV Eco Trike',
    'Daylong 200cc Red',
    'Other Trike Model',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRoleSelectionBottomSheet();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateNumberCtrl.dispose();
    _licenseOrNinCtrl.dispose();
    super.dispose();
  }

  void _showRoleSelectionBottomSheet() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final state = ref.watch(biaTrikeStateNotifierProvider);

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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'Welcome to Bia Trike 🛺',
                        style: TextStyle(
                          color: darkBackground,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Commercial Tricycle / Keke Ride-Hailing & Bargaining Platform.',
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: 12.5.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      Text(
                        'CHOOSE YOUR SERVICE',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      _buildModalRoleCard(
                        title: 'Book a Keke Ride (Passenger)',
                        subtitle: 'Set your price offer & negotiate with nearby drivers',
                        icon: Icons.hail_rounded,
                        color: primaryColor,
                        onTap: () {
                          Navigator.pop(modalContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BiaTrikeBookingScreen(language: state.dialect),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 12.h),

                      _buildModalRoleCard(
                        title: 'Register as Trike Rider (Driver Mode)',
                        subtitle: 'Drive your Trike, accept counter-offers & digital pass',
                        icon: Icons.electric_rickshaw_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(modalContext);
                          if (state.riderPass != null) {
                            context.pushNamed(RouteList.biaTrikeDigitalPass);
                          } else {
                            setState(() {
                              _showFormView = true;
                            });
                          }
                        },
                      ),
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

  Widget _buildModalRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: lightSecondaryText,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitRider() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(biaTrikeStateNotifierProvider.notifier);

    final success = await notifier.submitRiderOnboarding(
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      city: _selectedCity,
      trikeModel: _selectedTrikeModel,
      plateNumber: _plateNumberCtrl.text.trim().toUpperCase(),
      licenseOrNin: _licenseOrNinCtrl.text.trim().toUpperCase(),
    );

    if (mounted) {
      if (success) {
        ToastHelper.showToast(
          context: context,
          message: "Rider pass generated successfully!",
          icon: Icons.check_circle_outline_rounded,
          iconColor: primaryGreenColor,
        );
        context.pushReplacementNamed(RouteList.biaTrikeDigitalPass);
      } else {
        ToastHelper.showToast(
          context: context,
          message: "Registration complete (Offline Pass Saved).",
          icon: Icons.info_outline_rounded,
          iconColor: primaryColor,
        );
        context.pushReplacementNamed(RouteList.biaTrikeDigitalPass);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biaTrikeStateNotifierProvider);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkBackground, size: 18.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bia Trike Hub',
          style: TextStyle(color: darkBackground, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : 650),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: !_showFormView
                  ? _buildHubOverview(state)
                  : _buildRiderOnboardingForm(state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubOverview(BiaTrikeState state) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 30.h),
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.electric_rickshaw_rounded, color: primaryColor, size: 64.sp),
          ).animate().scale(duration: 400.ms),

          SizedBox(height: 24.h),
          Text(
            'Bia Trike Commercial Mobility',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkBackground, fontSize: 22.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8.h),
          Text(
            'Fast, safe, commercial Keke ride-hailing and real-time negotiation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: lightSecondaryText, fontSize: 13.sp),
          ),

          SizedBox(height: 32.h),

          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _showRoleSelectionBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text(
                'Open Service Menu',
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (state.riderPass != null) ...[
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: () => context.pushNamed(RouteList.biaTrikeDigitalPass),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryGreenColor),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('View Digital Rider Pass',
                  style: TextStyle(color: primaryGreenColor, fontWeight: FontWeight.bold, fontSize: 13.sp)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderOnboardingForm(BiaTrikeState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rider Verification & Onboarding',
            style: TextStyle(color: darkBackground, fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4.h),
          Text(
            'Register your commercial tricycle to receive digital pass credentials.',
            style: TextStyle(color: lightSecondaryText, fontSize: 12.5.sp),
          ),
          SizedBox(height: 20.h),

          TextFormField(
            controller: _fullNameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Aliyu Bello',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter full name' : null,
          ),
          SizedBox(height: 14.h),

          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+2348031234501',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
          ),
          SizedBox(height: 14.h),

          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: InputDecoration(
              labelText: 'City of Operation',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCity = v!),
          ),
          SizedBox(height: 14.h),

          DropdownButtonFormField<String>(
            initialValue: _selectedTrikeModel,
            decoration: InputDecoration(
              labelText: 'Trike Model',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            items: _trikeModels.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _selectedTrikeModel = v!),
          ),
          SizedBox(height: 14.h),

          TextFormField(
            controller: _plateNumberCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Plate Number',
              hintText: 'KMC-482-XA',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter plate number' : null,
          ),
          SizedBox(height: 14.h),

          TextFormField(
            controller: _licenseOrNinCtrl,
            decoration: InputDecoration(
              labelText: 'NIN / License Number',
              hintText: 'NIN-29481920491',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter NIN or license' : null,
          ),

          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _handleSubmitRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Submit & Generate Rider Pass',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
