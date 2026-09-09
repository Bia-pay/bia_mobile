import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/bia_trike_controller.dart';
import '../model/bia_trike_ride_model.dart';

class BiaTrikeBookingScreen extends ConsumerStatefulWidget {
  final String language;

  const BiaTrikeBookingScreen({
    super.key,
    this.language = 'english',
  });

  @override
  ConsumerState<BiaTrikeBookingScreen> createState() => _BiaTrikeBookingScreenState();
}

class _BiaTrikeBookingScreenState extends ConsumerState<BiaTrikeBookingScreen> {
  final _pickupCtrl = TextEditingController(text: 'Locating current address...');
  final _destCtrl = TextEditingController(text: 'Bayero University Kano New Campus');
  final _cityCtrl = TextEditingController(text: 'Kano');

  GoogleMapController? _mapController;
  final fm.MapController _flutterMapController = fm.MapController();
  ll.LatLng? _userFMLocation;
  bool _isFetchingGPS = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(biaTrikeStateNotifierProvider.notifier).setDialect(widget.language);
      _fetchPreciseLocation();
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    _cityCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'BiaPayApp/1.0 (com.bia.app)',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? address['residential'];
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? address['county'];
          if (road != null && city != null) {
            return '$road, $city';
          } else if (road != null) {
            return road.toString();
          } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
            return data['name'].toString();
          } else if (data['display_name'] != null) {
            final parts = data['display_name'].toString().split(',');
            if (parts.length >= 2) {
              return '${parts[0].trim()}, ${parts[1].trim()}';
            }
            return parts[0].trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return 'My Current Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  Future<void> _fetchPreciseLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _pickupCtrl.text = "GPS Disabled (Tap to set address)";
          });
          ToastHelper.showToast(
            context: context,
            message: "Location services disabled. Please turn on device GPS.",
            icon: Icons.location_off_rounded,
            iconColor: errorColor,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _pickupCtrl.text = "GPS Permission Denied";
          });
          ToastHelper.showToast(
            context: context,
            message: "Location permissions permanently denied. Grant in settings.",
            icon: Icons.location_off_rounded,
            iconColor: errorColor,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 7));

      final latLng = LatLng(position.latitude, position.longitude);
      final fmLatLng = ll.LatLng(position.latitude, position.longitude);

      final realAddress = await _reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userFMLocation = fmLatLng;
          _pickupCtrl.text = realAddress;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
        try {
          _flutterMapController.move(fmLatLng, 16.0);
        } catch (_) {}

        ToastHelper.showToast(
          context: context,
          message: "Locked to your location: $realAddress",
          icon: Icons.my_location_rounded,
          iconColor: primaryGreenColor,
        );
      }
    } catch (e) {
      debugPrint("GPS position error: $e");
      // Fallback to last known position or device location if current position timed out
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          final fmLatLng = ll.LatLng(lastPos.latitude, lastPos.longitude);
          final realAddress = await _reverseGeocode(lastPos.latitude, lastPos.longitude);
          if (mounted) {
            setState(() {
              _userFMLocation = fmLatLng;
              _pickupCtrl.text = realAddress;
            });
            try {
              _flutterMapController.move(fmLatLng, 15.5);
            } catch (_) {}
          }
          return;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _pickupCtrl.text = "Current Location";
        });
        ToastHelper.showToast(
          context: context,
          message: "Unable to retrieve precise GPS. Enter address manually.",
          icon: Icons.location_off_rounded,
          iconColor: errorColor,
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  // Localized dialect strings
  Map<String, Map<String, String>> get _dict => {
        'english': {
          'title': 'Bia Trike (Keke)',
          'subtitle': 'Set your fare offer & negotiate in real time with nearby riders.',
          'pickup': 'Pickup Address',
          'dest': 'Destination Address',
          'selectCategory': 'SELECT RIDE TYPE',
          'standard': 'Standard Keke',
          'shared': 'Shared Keke',
          'cargo': 'Express Cargo',
          'sharedDiscount': 'Save 35% with Commuter Sharing',
          'yourOffer': 'YOUR OFFER FARE',
          'min': 'Minimum',
          'max': 'Maximum',
          'payment': 'Payment Method',
          'wallet': 'Bia Pay Wallet (₦14,250)',
          'cash': 'Cash Payment',
          'findBtn': 'FIND TRIKE / NEMI KEKE',
          'negotiatingTitle': 'Negotiating Fare...',
          'radarText': '4 Riders Nearby Bidding',
          'incomingBids': 'INCOMING BIDS',
          'acceptBtn': 'ACCEPT',
          'bestPrice': 'Best Price',
          'cancelBtn': 'Cancel Negotiation',
          'raiseTip': '💡 Tip: Raise your offer by ₦50 to get faster responses from drivers.',
        },
        'hausa': {
          'title': 'Shiga Keke Trike',
          'subtitle': 'Yi cinikin kudin tafiya kai tsaye da direbobi a Kano/Kaduna.',
          'pickup': 'Wurin Dauka (Pickup)',
          'dest': 'Wurin da Zaka (Destination)',
          'selectCategory': 'ZABI SAMFURIN KEKE',
          'standard': 'Keke Na Daya',
          'shared': 'Keke Na Raba Kudin',
          'cargo': 'Keke Na Kayan Sauri',
          'sharedDiscount': 'Rage 35% na kudin tafiya',
          'yourOffer': 'KUDIN DA KAKE SO A BIYA',
          'min': 'Mafi Karanci',
          'max': 'Mafi Yawa',
          'payment': 'Hanyar Biya',
          'wallet': 'Asusun Bia Wallet (₦14,250)',
          'cash': 'Biyan Tsabar Kudi (Cash)',
          'findBtn': 'NEMI KEKE YANZU',
          'negotiatingTitle': 'Ana Ciniki da Direbobi...',
          'radarText': 'Direbobi 4 na kusa suna kallo',
          'incomingBids': 'TAYIN DIREBOBI DA KE KUSA',
          'acceptBtn': 'AMINCE',
          'bestPrice': 'Mafi Araha',
          'cancelBtn': 'Fasa Neman Keke',
          'raiseTip': '💡 Shawara: Kara ₦50 don samun direba da sauri.',
        },
        'pidgin': {
          'title': 'Bia Trike (Keke)',
          'subtitle': 'Set your price & drag price directly with nearby keke riders.',
          'pickup': 'Pickup Spot',
          'dest': 'Where you dey go?',
          'selectCategory': 'CHOOSE RIDE OPTION',
          'standard': 'Standard Keke',
          'shared': 'Shared Keke',
          'cargo': 'Express Cargo',
          'sharedDiscount': 'Save 35% with Commuter Sharing',
          'yourOffer': 'YOUR PRICE OFFER',
          'min': 'Lowest',
          'max': 'Highest',
          'payment': 'Payment Option',
          'wallet': 'Bia Pay Wallet (₦14,250)',
          'cash': 'Cash Payment',
          'findBtn': 'FIND TRIKE NOW',
          'negotiatingTitle': 'Dey Drag Money with Drivers...',
          'radarText': '4 Riders Nearby',
          'incomingBids': 'INCOMING BIDS FROM DRIVERS',
          'acceptBtn': 'ACCEPT',
          'bestPrice': 'Best Price',
          'cancelBtn': 'Cancel Offer',
          'raiseTip': '💡 Tip: Add ₦50 to make driver come quick.',
        },
      };

  String _t(String key) {
    final state = ref.watch(biaTrikeStateNotifierProvider);
    final lang = state.dialect.toLowerCase();
    final d = _dict[lang] ?? _dict['english']!;
    return d[key] ?? _dict['english']![key] ?? key;
  }

  void _showDialectPicker() {
    final notifier = ref.read(biaTrikeStateNotifierProvider.notifier);
    final state = ref.watch(biaTrikeStateNotifierProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    'Select Dialect / Language',
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Choose language for fare bargaining microcopy.',
                    style: TextStyle(color: lightSecondaryText, fontSize: 12.sp),
                  ),
                  SizedBox(height: 20.h),
                  _buildLangOption('english', 'Standard English', '🇬🇧', state.dialect, notifier),
                  SizedBox(height: 8.h),
                  _buildLangOption('pidgin', 'Nigerian Pidgin', '🇳🇬', state.dialect, notifier),
                  SizedBox(height: 8.h),
                  _buildLangOption('hausa', 'Hausa Dialect', '🌙', state.dialect, notifier),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangOption(
      String code, String label, String flag, String current, BiaTrikeNotifier notifier) {
    final isSelected = current == code;
    return GestureDetector(
      onTap: () {
        notifier.setDialect(code);
        Navigator.pop(context);
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
            if (isSelected) Icon(Icons.check_circle_rounded, color: primaryColor, size: 20.sp),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biaTrikeStateNotifierProvider);
    final notifier = ref.read(biaTrikeStateNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Full-Screen Interactive Live Map Layer (inDrive / Bolt Style)
          Positioned.fill(
            child: fm.FlutterMap(
              mapController: _flutterMapController,
              options: fm.MapOptions(
                initialCenter: _userFMLocation ?? const ll.LatLng(12.0022, 8.5920),
                initialZoom: 13.8,
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bia.app',
                ),
                fm.PolylineLayer(
                  polylines: [
                    fm.Polyline(
                      points: [
                        _userFMLocation ?? const ll.LatLng(12.0022, 8.5920),
                        const ll.LatLng(11.9920, 8.5710),
                        const ll.LatLng(11.9790, 8.5410),
                      ],
                      color: primaryColor,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      point: _userFMLocation ?? const ll.LatLng(12.0022, 8.5920),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primaryGreenColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    fm.Marker(
                      point: const ll.LatLng(11.9790, 8.5410),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    // Nearby Keke Tricycle Markers on Map
                    fm.Marker(
                      point: const ll.LatLng(12.0080, 8.5960),
                      child: const Icon(Icons.electric_rickshaw_rounded, color: Color(0xFFF59E0B), size: 28),
                    ),
                    fm.Marker(
                      point: const ll.LatLng(11.9950, 8.5810),
                      child: const Icon(Icons.electric_rickshaw_rounded, color: Color(0xFFF59E0B), size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Floating Top Header Navigation Bar
          Positioned(
            top: 48.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkBackground, size: 18.sp),
                    onPressed: () {
                      if (state.isSearching) {
                        notifier.cancelActiveRide();
                      } else {
                        context.pop();
                      }
                    },
                  ),
                ),

                // Floating Dialect Picker
                GestureDetector(
                  onTap: _showDialectPicker,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          state.dialect == 'hausa'
                              ? '🌙 Hausa'
                              : state.dialect == 'pidgin'
                                  ? '🇳🇬 Pidgin'
                                  : '🇬🇧 English',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 16.sp),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating GPS Location Target Button on Map
          Positioned(
            right: 16.w,
            top: 110.h,
            child: FloatingActionButton.small(
              heroTag: 'gps_target',
              onPressed: _isFetchingGPS ? null : _fetchPreciseLocation,
              backgroundColor: Colors.white,
              child: _isFetchingGPS
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: primaryGreenColor),
                    )
                  : Icon(Icons.my_location_rounded, color: primaryGreenColor, size: 20.sp),
            ),
          ),

          // 4. Draggable Bottom Booking & Negotiation Sheet (inDrive / Bolt Floating Card)
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    children: [
                      // Sheet Handle Drag Bar
                      Center(
                        child: Container(
                          width: 42.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      state.isSearching
                          ? _buildNegotiationArena(state, notifier)
                          : _buildProposalBookingForm(state, notifier),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Screen 1: Booking & Fare Proposal Form ────────────────────────────────
  Widget _buildProposalBookingForm(BiaTrikeState state, BiaTrikeNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Pickup & Destination Address Input Card with "Use My Location" Button
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Pickup Label + "Use My Location" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: primaryGreenColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _t('pickup').toUpperCase(),
                        style: TextStyle(
                          color: darkBackground,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Starling-Style "Use My Location" Precise GPS Chip
                  InkWell(
                    onTap: _isFetchingGPS ? null : _fetchPreciseLocation,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: primaryGreenColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: primaryGreenColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isFetchingGPS
                              ? SizedBox(
                                  width: 12.r,
                                  height: 12.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryGreenColor,
                                  ),
                                )
                              : Icon(Icons.my_location_rounded, color: primaryGreenColor, size: 13.sp),
                          SizedBox(width: 4.w),
                          Text(
                            '🎯 Use My Location',
                            style: TextStyle(
                              color: primaryGreenColor,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Pickup Text Field
              TextField(
                controller: _pickupCtrl,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkBackground),
                decoration: InputDecoration(
                  hintText: 'Enter Pickup Location...',
                  prefixIcon: Icon(Icons.my_location_rounded, color: primaryGreenColor, size: 18.sp),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              SizedBox(height: 14.h),

              // Destination Header
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _t('dest').toUpperCase(),
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Destination Text Field
              TextField(
                controller: _destCtrl,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: darkBackground),
                decoration: InputDecoration(
                  hintText: 'Enter Destination Address...',
                  prefixIcon: Icon(Icons.location_on_rounded, color: const Color(0xFFEF4444), size: 18.sp),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Ride Category Selector
        Text(
          _t('selectCategory'),
          style: TextStyle(
            color: primaryColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 10.h),

        Row(
          children: [
            Expanded(
              child: _buildCategoryChip(
                'STANDARD_KEKE',
                _t('standard'),
                '🛺',
                '₦1,000',
                state,
                notifier,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCategoryChip(
                'SHARED_KEKE',
                _t('shared'),
                '👥',
                '₦650',
                state,
                notifier,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildCategoryChip(
                'EXPRESS_CARGO',
                _t('cargo'),
                '📦',
                '₦1,400',
                state,
                notifier,
              ),
            ),
          ],
        ),

        if (state.selectedRideType == 'SHARED_KEKE') ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: primaryGreenColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: primaryGreenColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.discount_rounded, color: primaryGreenColor, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _t('sharedDiscount'),
                    style: TextStyle(
                      color: primaryGreenColor,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(duration: 250.ms),
        ],

        SizedBox(height: 20.h),

        // Fare Stepper (`[-]` / `[+]`)
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
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Interactive Stepper',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Minus Button
                  InkWell(
                    onTap: state.currentOffer <= state.minOffer
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            notifier.adjustOffer(-50);
                          },
                    borderRadius: BorderRadius.circular(100.r),
                    child: Opacity(
                      opacity: state.currentOffer <= state.minOffer ? 0.4 : 1.0,
                      child: Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(Icons.remove_rounded, color: darkBackground, size: 22.sp),
                      ),
                    ),
                  ),

                  SizedBox(width: 24.w),

                  Text(
                    '₦${NumberFormat('#,##0').format(state.currentOffer)}',
                    style: TextStyle(
                      color: darkBackground,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  SizedBox(width: 24.w),

                  // Plus Button
                  InkWell(
                    onTap: state.currentOffer >= state.maxOffer
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            notifier.adjustOffer(50);
                          },
                    borderRadius: BorderRadius.circular(100.r),
                    child: Opacity(
                      opacity: state.currentOffer >= state.maxOffer ? 0.4 : 1.0,
                      child: Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 22.sp),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_t('min')}: ₦${NumberFormat('#,##0').format(state.minOffer)}',
                    style: TextStyle(color: lightSecondaryText, fontSize: 11.sp),
                  ),
                  Text(
                    '${_t('max')}: ₦${NumberFormat('#,##0').format(state.maxOffer)}',
                    style: TextStyle(color: lightSecondaryText, fontSize: 11.sp),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Payment Selection
        Text(
          _t('payment'),
          style: TextStyle(
            color: darkBackground,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.paymentMethod,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 24.sp),
              items: [
                DropdownMenuItem(
                  value: 'WALLET',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: primaryGreenColor, size: 18.sp),
                      SizedBox(width: 10.w),
                      Text(_t('wallet'),
                          style: TextStyle(
                              color: darkBackground,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'CASH',
                  child: Row(
                    children: [
                      Icon(Icons.payments_rounded, color: const Color(0xFFF59E0B), size: 18.sp),
                      SizedBox(width: 10.w),
                      Text(_t('cash'),
                          style: TextStyle(
                              color: darkBackground,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) notifier.setPaymentMethod(val);
              },
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // CTA: Find Trike Button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    final success = await notifier.createRideRequest(
                      pickupAddress: _pickupCtrl.text,
                      destinationAddress: _destCtrl.text,
                      city: _cityCtrl.text,
                    );
                    if (!success && mounted && state.errorMessage != null) {
                      ToastHelper.showToast(
                        context: context,
                        message: state.errorMessage!,
                        icon: Icons.error_outline_rounded,
                        iconColor: errorColor,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: state.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _t('findBtn'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.electric_rickshaw_rounded, color: Colors.white, size: 20.sp),
                    ],
                  ),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildCategoryChip(String type, String label, String emoji, String price,
      BiaTrikeState state, BiaTrikeNotifier notifier) {
    final isSelected = state.selectedRideType == type;
    return GestureDetector(
      onTap: () => notifier.selectRideType(type),
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
            Text(emoji, style: TextStyle(fontSize: 22.sp)),
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
            SizedBox(height: 2.h),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : primaryColor,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screen 2: Real-Time Bidding & Negotiation Arena ───────────────────────
  Widget _buildNegotiationArena(BiaTrikeState state, BiaTrikeNotifier notifier) {
    return Column(
      children: [
        SizedBox(height: 10.h),

        // Pulsing Radar Indicator
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

        SizedBox(height: 16.h),

        Text(
          _t('radarText'),
          style: TextStyle(
            color: darkBackground,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16.h),

        // Persistent Stepper on Negotiation Arena
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Offer: ₦${NumberFormat('#,##0').format(state.currentOffer)}',
                style: TextStyle(
                  color: darkBackground,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: darkBackground, size: 24.sp),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.adjustOffer(-50);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_rounded, color: primaryColor, size: 24.sp),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      notifier.adjustOffer(50);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Microcopy tip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _t('raiseTip'),
            style: TextStyle(color: const Color(0xFF92400E), fontSize: 11.5.sp),
          ),
        ),

        SizedBox(height: 24.h),

        // Incoming Driver Bids List Header
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${_t('incomingBids')} (${state.bids.length})',
            style: TextStyle(
              color: primaryColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(height: 10.h),

        if (state.bids.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: Column(
              children: [
                const CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 12.h),
                Text(
                  'Waiting for nearby drivers to respond...',
                  style: TextStyle(color: lightSecondaryText, fontSize: 13.sp),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.bids.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (ctx, idx) {
              final bid = state.bids[idx];
              final isLowest = idx == 0 ||
                  state.bids.every((b) => b.bidAmount >= bid.bidAmount);
              return _buildBidCard(bid, isLowest, notifier);
            },
          ),

        SizedBox(height: 24.h),

        // Cancel Negotiation Button
        OutlinedButton(
          onPressed: () {
            notifier.cancelActiveRide(reason: 'Cancelled by user');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade400),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            _t('cancelBtn'),
            style: TextStyle(color: darkBackground, fontSize: 13.sp),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildBidCard(DriverBid bid, bool isLowest, BiaTrikeNotifier notifier) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isLowest ? primaryGreenColor : const Color(0xFFE2E8F0),
          width: isLowest ? 1.8 : 1.0,
        ),
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
          if (isLowest) ...[
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: primaryGreenColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _t('bestPrice'),
                  style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],

          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Text(
                  bid.driver.name.substring(0, 2).toUpperCase(),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bid.driver.name,
                          style: TextStyle(
                            color: darkBackground,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 14.sp),
                            Text(
                              bid.driver.rating.toString(),
                              style: TextStyle(
                                color: const Color(0xFFF59E0B),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${bid.driver.trikeModel} · ${bid.driver.plateNumber}',
                      style: TextStyle(color: lightSecondaryText, fontSize: 11.5.sp),
                    ),
                    Text(
                      '${bid.etaMinutes} mins away · ${bid.distanceKm} km',
                      style: TextStyle(color: primaryColor, fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(color: Colors.grey.shade200),
          SizedBox(height: 6.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OFFERED FARE',
                      style: TextStyle(color: lightSecondaryText, fontSize: 9.sp, fontWeight: FontWeight.w800)),
                  Text(
                    '₦${NumberFormat('#,##0').format(bid.bidAmount)}',
                    style: TextStyle(color: darkBackground, fontSize: 18.sp, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final ok = await notifier.acceptBid(bid);
                  if (ok && mounted) {
                    context.pushNamed(RouteList.biaTrikeEnRoute);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreenColor,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  _t('acceptBtn'),
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms);
  }
}
