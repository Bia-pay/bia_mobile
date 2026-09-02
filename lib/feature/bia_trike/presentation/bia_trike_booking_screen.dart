import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';

class BiaTrikeBookingScreen extends ConsumerStatefulWidget {
  final String language; // 'english', 'hausa', 'pidgin'

  const BiaTrikeBookingScreen({
    super.key,
    required this.language,
  });

  @override
  ConsumerState<BiaTrikeBookingScreen> createState() =>
      _BiaTrikeBookingScreenState();
}

class _BiaTrikeBookingScreenState
    extends ConsumerState<BiaTrikeBookingScreen> {
  late String _currentLanguage;
  final _pickupCtrl = TextEditingController(text: 'Current Location');
  final _destinationCtrl = TextEditingController();

  String _selectedRideType = 'Standard';
  double _passengerOfferFare = 500.0;
  bool _isSearchingDriver = false;
  bool _driverAssigned = false;
  Timer? _searchTimer;
  int _selectedDriverOfferIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
  }

  void _changeLanguage(String newLang) {
    setState(() {
      _currentLanguage = newLang;
    });
    try {
      final box = Hive.box('authBox');
      box.put('bia_trike_language', newLang);
    } catch (_) {}
  }

  void _adjustFare(double delta) {
    setState(() {
      _passengerOfferFare = (_passengerOfferFare + delta).clamp(200.0, 10000.0);
    });
  }

  void _showLanguageSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
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
                    'Select Dialect / Language',
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Choose your preferred language for prompts and ride booking.',
                    style: TextStyle(
                      color: lightSecondaryText,
                      fontSize: 12.sp,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  _buildLangTile('english', 'Standard English', '🇬🇧', setModalState),
                  SizedBox(height: 8.h),
                  _buildLangTile('pidgin', 'Nigerian Pidgin', '🇳🇬', setModalState),
                  SizedBox(height: 8.h),
                  _buildLangTile('hausa', 'Hausa Dialect', '🌙', setModalState),

                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLangTile(
      String code, String label, String flag, StateSetter setModalState) {
    final isSelected = _currentLanguage == code;
    return GestureDetector(
      onTap: () {
        setModalState(() {});
        _changeLanguage(code);
        Navigator.pop(context);
        ToastHelper.showToast(
          context: context,
          message: "Language set to $label",
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

  // Localized dictionary
  Map<String, Map<String, String>> get _localized => {
        'english': {
          'title': 'Book Your Keke Ride',
          'subtitle': 'Negotiate fare directly with nearby trike riders.',
          'pickup': 'Pickup Location',
          'pickupHint': 'Where are you starting from?',
          'destination': 'Destination',
          'destinationHint': 'Where are you going?',
          'rideType': 'Select Ride Option',
          'standard': 'Standard Keke',
          'shared': 'Shared Keke',
          'express': 'Express Cargo',
          'yourOffer': 'YOUR FARE OFFER',
          'negotiateHint': 'Tap + or - to adjust your offer price',
          'bookBtn': 'Offer Fare & Find Riders',
          'searchingTitle': 'Negotiating with Drivers...',
          'searchingDesc':
              'Receiving live counter-offers from nearby Bia Trike riders.',
          'assignedTitle': 'Fare Negotiated & Accepted!',
          'assignedDesc': 'Driver Mallam Garba agreed to your fare (3 mins away).',
          'plate': 'Plate No: KNC 772 YK',
          'cancelBtn': 'Cancel Offer',
          'homeBtn': 'Back to Dashboard',
        },
        'hausa': {
          'title': 'Shiga Keke Trike',
          'subtitle': 'Yi cinikin kudin tafiya kai tsaye da direbobi.',
          'pickup': 'Wurin Dauka (Pickup)',
          'pickupHint': 'Daga ina kake so a dauke ka?',
          'destination': 'Wurin da Zaka (Destination)',
          'destinationHint': 'Ina ne zaku tafi?',
          'rideType': 'Zabi Samfurin Keke',
          'standard': 'Keke Na Daya',
          'shared': 'Keke Na Raba Kudin',
          'express': 'Keke Na Kayan Sauri',
          'yourOffer': 'KUDIN DA KAKE SO A BIYA',
          'negotiateHint': 'Latsa + ko - don kara ko rage kudin',
          'bookBtn': 'Talla Farashi & Nemi Keke',
          'searchingTitle': 'Ana Ciniki da Direbobi...',
          'searchingDesc':
              'Muna karbar tayin kudi daga direbobi da ke kusa.',
          'assignedTitle': 'An Kamala Ciniki!',
          'assignedDesc': 'Direba Mallam Garba ya yarda da kudin (Minti 3).',
          'plate': 'Lamba: KNC 772 YK',
          'cancelBtn': 'Fasa Neman Keke',
          'homeBtn': 'Koma Shafi Na Fari',
        },
        'pidgin': {
          'title': 'Book Your Keke Ride',
          'subtitle': 'Drag price directly with nearby keke riders.',
          'pickup': 'Pickup Spot',
          'pickupHint': 'Where you dey start from?',
          'destination': 'Destination',
          'destinationHint': 'Where you wan go?',
          'rideType': 'Choose Ride Option',
          'standard': 'Standard Keke',
          'shared': 'Shared Keke',
          'express': 'Express Cargo',
          'yourOffer': 'YOUR PRICE OFFER',
          'negotiateHint': 'Tap + or - to change money offer',
          'bookBtn': 'Offer Price & Find Driver',
          'searchingTitle': 'Dey Drag Money with Drivers...',
          'searchingDesc':
              'Receiving counter-price from nearby Bia Trike riders.',
          'assignedTitle': 'Price Don Agreed!',
          'assignedDesc': 'Driver Mallam Garba agree to your price (3 mins away).',
          'plate': 'Plate No: KNC 772 YK',
          'cancelBtn': 'Cancel Offer',
          'homeBtn': 'Go Back Home',
        },
      };

  String _t(String key) {
    final lang = _currentLanguage.toLowerCase();
    final dict = _localized[lang] ?? _localized['english']!;
    return dict[key] ?? _localized['english']![key] ?? key;
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destinationCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startRideSearch() {
    if (_destinationCtrl.text.trim().isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: _t('destinationHint'),
        icon: Icons.info_outline,
        iconColor: primaryColor,
      );
      return;
    }

    setState(() {
      _isSearchingDriver = true;
      _driverAssigned = false;
    });

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isSearchingDriver = false;
          _driverAssigned = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: darkBackground, size: 18.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _t('title'),
          style: TextStyle(
            color: darkBackground,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showLanguageSwitcher,
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Row(
                children: [
                  Text(
                    _currentLanguage == 'hausa'
                        ? '🌙 Hausa'
                        : _currentLanguage == 'pidgin'
                            ? '🇳🇬 Pidgin'
                            : '🇬🇧 English',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: primaryColor, size: 14.sp),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('subtitle'),
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 20.h),

              if (_isSearchingDriver)
                _buildSearchingCard()
              else if (_driverAssigned)
                _buildDriverAssignedCard()
              else
                _buildBookingForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Preview Simulation Card
        Container(
          height: 130.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 90.sp,
                ),
              ),
              Positioned(
                top: 16.h,
                left: 20.w,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 14.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Kano City Hub',
                      style: TextStyle(
                        color: darkBackground,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16.h,
                right: 20.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryGreenColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '14 Drivers Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Pickup & Destination Inputs
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
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
              Text(
                _t('pickup'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: darkBackground,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _pickupCtrl,
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.trip_origin_rounded, color: primaryColor),
                  hintText: _t('pickupHint'),
                  filled: true,
                  fillColor: offWhiteBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Text(
                _t('destination'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: darkBackground,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: _destinationCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_rounded,
                      color: Color(0xFFEF4444)),
                  hintText: _t('destinationHint'),
                  filled: true,
                  fillColor: offWhiteBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Ride Option Types
        Text(
          _t('rideType'),
          style: TextStyle(
            color: darkBackground,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.h),

        Row(
          children: [
            Expanded(
                child: _buildOptionChip('Standard', _t('standard'), '🛺')),
            SizedBox(width: 8.w),
            Expanded(child: _buildOptionChip('Shared', _t('shared'), '👥')),
            SizedBox(width: 8.w),
            Expanded(child: _buildOptionChip('Express', _t('express'), '📦')),
          ],
        ),

        SizedBox(height: 20.h),

        // Interactive Fare Negotiation / Offer Widget
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t('yourOffer'),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Negotiable Fare',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus Button
                  InkWell(
                    onTap: () => _adjustFare(-50),
                    borderRadius: BorderRadius.circular(100.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(Icons.remove_rounded,
                          color: darkBackground, size: 20.sp),
                    ),
                  ),

                  SizedBox(width: 24.w),

                  // Offer Amount Display
                  Text(
                    '₦${NumberFormat('#,##0').format(_passengerOfferFare)}',
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  SizedBox(width: 24.w),

                  // Plus Button
                  InkWell(
                    onTap: () => _adjustFare(50),
                    borderRadius: BorderRadius.circular(100.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          color: Colors.white, size: 20.sp),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),
              Text(
                _t('negotiateHint'),
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24.h),

        // Book Button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: _startRideSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _t('bookBtn'),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_rounded, size: 18.sp),
              ],
            ),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildOptionChip(String key, String label, String emoji) {
    final isSelected = _selectedRideType == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedRideType = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 20.sp)),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : darkBackground,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingCard() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3.5,
            ),
          ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 800.ms,
              ),

          SizedBox(height: 20.h),

          Text(
            _t('searchingTitle'),
            style: TextStyle(
              color: darkBackground,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _t('searchingDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 13.sp,
            ),
          ),

          SizedBox(height: 24.h),

          // Live Bidding Offers Card Simulation
          Text(
            'LIVE DRIVER COUNTER-OFFERS',
            style: TextStyle(
              color: primaryColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 10.h),

          _buildDriverBiddingCard(
            0,
            'Mallam Garba Ibrahim',
            '₦${NumberFormat('#,##0').format(_passengerOfferFare)} (Accepted your offer!)',
            '3 mins away',
            '★ 4.9',
            primaryGreenColor,
          ),
          SizedBox(height: 8.h),
          _buildDriverBiddingCard(
            1,
            'Sani Abubakar Keke',
            '₦${NumberFormat('#,##0').format(_passengerOfferFare + 100)} (Counter Offer)',
            '1 min away',
            '★ 5.0',
            const Color(0xFFF59E0B),
          ),

          SizedBox(height: 30.h),

          OutlinedButton(
            onPressed: () {
              _searchTimer?.cancel();
              setState(() => _isSearchingDriver = false);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              _t('cancelBtn'),
              style: TextStyle(color: darkBackground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverBiddingCard(int index, String name, String offerText,
      String eta, String rating, Color badgeColor) {
    final isSelected = _selectedDriverOfferIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDriverOfferIndex = index),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              child: Text(
                name.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    offerText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rating,
                  style: TextStyle(
                    color: const Color(0xFFF59E0B),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  eta,
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAssignedCard() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: primaryGreenColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: primaryGreenColor,
              size: 54.sp,
            ),
          ).animate().scale(duration: 400.ms),

          SizedBox(height: 16.h),

          Text(
            _t('assignedTitle'),
            style: TextStyle(
              color: darkBackground,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _t('assignedDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 13.sp,
            ),
          ),

          SizedBox(height: 24.h),

          // Driver details card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
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
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        'MG',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mallam Garba Ibrahim',
                            style: TextStyle(
                              color: darkBackground,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _t('plate'),
                            style: TextStyle(
                              color: lightSecondaryText,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: const Color(0xFFF59E0B), size: 14.sp),
                          SizedBox(width: 3.w),
                          Text(
                            '4.9',
                            style: TextStyle(
                              color: const Color(0xFFF59E0B),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(color: Colors.grey.shade200),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Negotiated Fare Total',
                      style: TextStyle(
                        color: lightSecondaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      '₦${NumberFormat('#,##0.00').format(_passengerOfferFare)}',
                      style: TextStyle(
                        color: darkBackground,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          ElevatedButton(
            onPressed: () {
              context.go(RouteList.bottomNavBar);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Text(
              _t('homeBtn'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
