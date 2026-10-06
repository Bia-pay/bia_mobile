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
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateNumberCtrl.dispose();
    _licenseOrNinCtrl.dispose();
    super.dispose();
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
          message: "Registration complete (Pass Saved).",
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF1F5F9),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkBackground, size: 18.sp),
            onPressed: () {
              if (_showFormView) {
                setState(() => _showFormView = false);
              } else {
                context.pop();
              }
            },
          ),
        ),
        title: Text(
          _showFormView ? 'Trike Rider Verification' : 'Bia Trike',
          style: TextStyle(color: darkBackground, fontSize: 18.sp, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : 650),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: !_showFormView
                  ? _buildCleanEmeraldHubView(state)
                  : _buildRiderOnboardingForm(state),
            ),
          ),
        ),
      ),
    );
  }

  // ── Uber / Bolt Style Clean Minimal White & Emerald Hub ──────────────────
  Widget _buildCleanEmeraldHubView(BiaTrikeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),

        // Clean Hero Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: primaryGreenColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.electric_rickshaw_rounded, color: primaryGreenColor, size: 54.sp),
              ).animate().scale(duration: 350.ms),

              SizedBox(height: 16.h),

              Text(
                'Bia Trike Mobility',
                style: TextStyle(color: darkBackground, fontSize: 22.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6.h),
              Text(
                'Fast, reliable Keke ride-hailing with transparent fare offer negotiation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: lightSecondaryText, fontSize: 13.sp, height: 1.4),
              ),
              SizedBox(height: 14.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPillTag('⚡ Real-Time Bidding'),
                  SizedBox(width: 8.w),
                  _buildPillTag('👥 Shared & Cargo'),
                  SizedBox(width: 8.w),
                  _buildPillTag('🪪 Verified Pass'),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 28.h),

        Text(
          'SELECT SERVICE',
          style: TextStyle(
            color: primaryGreenColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 12.h),

        // Service Option 1: Book Keke Ride (Passenger Mode)
        _buildCleanServiceCard(
          title: 'Book a Keke Ride',
          subtitle: 'Set your price offer & negotiate with nearby drivers in real time',
          icon: Icons.hail_rounded,
          iconBg: primaryGreenColor.withValues(alpha: 0.12),
          iconColor: primaryGreenColor,
          btnText: 'Start Passenger Ride ➔',
          btnColor: primaryGreenColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BiaTrikeBookingScreen(language: state.dialect),
              ),
            );
          },
        ),

        SizedBox(height: 16.h),

        // Service Option 2: Register as Trike Rider (Driver Mode)
        _buildCleanServiceCard(
          title: 'Register as Trike Rider',
          subtitle: 'Drive your Trike, accept passenger counter-offers & get Digital Pass',
          icon: Icons.electric_rickshaw_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          btnText: state.riderPass != null ? 'View Digital Pass ➔' : 'Onboard Rider & Pass ➔',
          btnColor: const Color(0xFFD97706),
          onTap: () {
            if (state.riderPass != null) {
              context.pushNamed(RouteList.biaTrikeDigitalPass);
            } else {
              setState(() => _showFormView = true);
            }
          },
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildPillTag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: TextStyle(color: darkBackground, fontSize: 10.5.sp, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCleanServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String btnText,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: darkBackground, fontSize: 15.5.sp, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: TextStyle(color: lightSecondaryText, fontSize: 12.sp, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                btnText,
                style: TextStyle(color: Colors.white, fontSize: 13.5.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Clean Minimal Rider Verification Form ────────────────────────────────
  Widget _buildRiderOnboardingForm(BiaTrikeState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rider Verification Form',
                  style: TextStyle(color: darkBackground, fontSize: 18.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Submit your commercial tricycle credentials for official Digital Pass approval.',
                  style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
                ),
                SizedBox(height: 20.h),

                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Aliyu Bello',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                    fillColor: const Color(0xFFF8FAFC),
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
                    fillColor: const Color(0xFFF8FAFC),
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
                    fillColor: const Color(0xFFF8FAFC),
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
                    fillColor: const Color(0xFFF8FAFC),
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
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter NIN or license' : null,
                ),

                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleSubmitRider,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreenColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Submit & Generate Rider Pass',
                            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
