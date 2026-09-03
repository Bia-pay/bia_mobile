import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:hive/hive.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/custom_text_field.dart';
import '../../../app/utils/widgets/premium_card.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
import '../../dashboard/dashboardcontroller/provider.dart';
import '../controller/split_payment_controller.dart';
import '../model/split_models.dart';

import '../../auth/modal/reponse/response_modal.dart';
import '../../dashboard/dashboard_repo/repo.dart';

class SplitCreatorSetupScreen extends ConsumerStatefulWidget {
  const SplitCreatorSetupScreen({super.key});

  @override
  ConsumerState<SplitCreatorSetupScreen> createState() =>
      _SplitCreatorSetupScreenState();
}

class _SplitCreatorSetupScreenState
    extends ConsumerState<SplitCreatorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _participantSearchController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime? _selectedExpiration;
  final List<Map<String, dynamic>> _addedParticipants = [];
  bool _isSearching = false;
  CreateSplitResponse? _generatedResponse;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userSplitPaymentsProvider.notifier).fetchSplitPayments(type: 'all');
      ref.read(splitStatsProvider.notifier).fetchStats();
    });
  }

  Future<void> _saveCreatedSplitToCache(CreateSplitResponse response) async {
    try {
      final userProfile = ref.read(userProfileProvider);
      final userId = userProfile?.id?.toString() ?? 'anonymous';
      final box = Hive.box('appBox');
      final key = 'created_splits_$userId';
      
      final List<dynamic> rawList = box.get(key, defaultValue: []);
      final List<Map<String, dynamic>> splits = List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      final title = _titleController.text.trim().isEmpty 
          ? "Split Bill" 
          : _titleController.text.trim();

      // Check if it already exists to avoid duplicates
      if (!splits.any((element) => element['splitId'] == response.splitId)) {
        splits.insert(0, {
          'splitId': response.splitId,
          'title': title,
          'totalAmount': response.totalAmount,
          'createdAt': DateTime.now().toIso8601String(),
        });

        if (splits.length > 50) {
          splits.removeRange(50, splits.length);
        }

        await box.put(key, splits);
      }
    } catch (e) {
      debugPrint("❌ Failed to save split to local cache: $e");
    }
  }

  List<Map<String, dynamic>> _getCreatedSplits() {
    try {
      final userProfile = ref.read(userProfileProvider);
      final userId = userProfile?.id?.toString() ?? 'anonymous';
      final box = Hive.box('appBox');
      final key = 'created_splits_$userId';
      final List<dynamic> rawList = box.get(key, defaultValue: []);
      return List<Map<String, dynamic>>.from(
        rawList.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (e) {
      return [];
    }
  }

  Future<void> _confirmDeleteSplit(String splitId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove from History"),
        content: Text("Are you sure you want to remove '$title' from your tracking list? This does not cancel the bill, but you will not be able to track it here unless you scan it or get the link."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final userProfile = ref.read(userProfileProvider);
        final userId = userProfile?.id?.toString() ?? 'anonymous';
        final box = Hive.box('appBox');
        final key = 'created_splits_$userId';
        
        final List<dynamic> rawList = box.get(key, defaultValue: []);
        final List<Map<String, dynamic>> splits = List<Map<String, dynamic>>.from(
          rawList.map((e) => Map<String, dynamic>.from(e as Map)),
        );

        splits.removeWhere((element) => element['splitId'] == splitId);
        await box.put(key, splits);
        setState(() {}); // refresh UI
      } catch (e) {
        debugPrint("❌ Failed to delete split: $e");
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _participantSearchController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _addedParticipants.fold(0.0, (sum, p) => sum + (p['amount'] ?? 0.0));
  }

  Future<void> _verifyAndAddParticipant() async {
    final identifier = _participantSearchController.text.trim();
    if (identifier.isEmpty) return;

    // Check if already added
    if (_addedParticipants.any(
      (p) =>
          p['identifier'].toString().toLowerCase() == identifier.toLowerCase(),
    )) {
      ToastHelper.showToast(
        context: context,
        message: "Participant already added.",
        icon: Icons.info_outline,
        iconColor: errorColor,
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
      final repo = ref.read(dashboardRepositoryProvider);

      final clean = identifier.trim().replaceAll('@', '');
      final isTag = RegExp(r'[a-zA-Z]').hasMatch(clean);

      ResponseModel? response;
      if (isTag) {
        response = await dashboardCtrl.verifyTag(context, clean);
      } else {
        if (clean.length == 10) {
          response = await dashboardCtrl.verifyAccount(context, clean);
        } else {
          // It's all digits but not 10 digits (e.g. 11 digit phone number).
          // We bypass the controller's length checks by calling the repository directly.
          try {
            response = await repo.verifyAccount({"account": clean});
          } catch (_) {}

          // Fallback to tag resolution if verifyAccount failed
          if (response == null || !response.responseSuccessful) {
            try {
              response = await dashboardCtrl.verifyTag(context, clean);
            } catch (_) {}
          }
        }
      }

      if (!mounted) return;

      if (response != null && response.responseSuccessful) {
        final fullname = response.responseBody?.user?.fullname ?? "Bia User";
        final resolvedIdentifier =
            response.responseBody?.user?.phone ??
            response.responseBody?.user?.tag ??
            identifier;

        setState(() {
          _addedParticipants.add({
            'identifier': resolvedIdentifier,
            'fullname': fullname,
            'amount': 0.0,
          });
          _participantSearchController.clear();
        });
      } else {
        ToastHelper.showToast(
          context: context,
          message: "Unable to verify user identifier.",
          icon: Icons.error_outline_rounded,
          iconColor: errorColor,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(
        context: context,
        message: "Search failed: $e",
        icon: Icons.error_outline_rounded,
        iconColor: errorColor,
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectExpirationTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedExpiration = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitCreateSplit() async {
    if (_addedParticipants.isEmpty) {
      ToastHelper.showToast(
        context: context,
        message: "Please add at least one participant.",
        icon: Icons.info_outline,
        iconColor: errorColor,
      );
      return;
    }

    if (_addedParticipants.any((p) => (p['amount'] ?? 0.0) <= 0.0)) {
      ToastHelper.showToast(
        context: context,
        message: "Please assign a valid amount (> ₦0) to all participants.",
        icon: Icons.warning_amber_rounded,
        iconColor: errorColor,
      );
      return;
    }

    final participantsPayload = _addedParticipants.map((p) {
      return ParticipantPayload(
        identifier: p['identifier'],
        amount: p['amount'],
      );
    }).toList();

    final response = await ref
        .read(splitCreatorProvider.notifier)
        .createSplit(
          context: context,
          title: _titleController.text,
          description: _descController.text,
          expiresAt: _selectedExpiration,
          participants: participantsPayload,
        );

    if (response != null && mounted) {
      await _saveCreatedSplitToCache(response);
      setState(() {
        _generatedResponse = response;
      });
    }
  }

  Future<void> _saveQrToGallery() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("QR Card saved to gallery!"),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save: $e"),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _shareQrCode() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/split_qr_card.png').create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Scan to pay your share of the split bill on Bia!');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share: $e"),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: offWhiteBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: darkBackground),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _generatedResponse == null ? "Split Bill" : "Create Split Bill",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: darkBackground,
              fontSize: isTablet ? 18.0 : null,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 540 : 600),
              child: _generatedResponse == null
                  ? Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16.0 : 16.w,
                            vertical: isTablet ? 6.0 : 4.h,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                              border: Border.all(
                                color: lightBorderColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: TabBar(
                              labelColor: primaryColor,
                              unselectedLabelColor: lightSecondaryText,
                              indicatorColor: primaryColor,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14.0 : 13.sp,
                              ),
                              tabs: const [
                                Tab(text: "Create New"),
                                Tab(text: "Track History"),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildSetupForm(theme),
                              _buildTrackHistoryView(theme),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildQrPresenter(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackHistoryView(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final statsState = ref.watch(splitStatsProvider);
    final paymentsState = ref.watch(userSplitPaymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(userSplitPaymentsProvider.notifier).fetchSplitPayments(type: _selectedType),
          ref.read(splitStatsProvider.notifier).fetchStats(),
        ]);
      },
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 20.w,
          vertical: isTablet ? 12.0 : 16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats ─────────────────────────────────────────────────────
            statsState.when(
              loading: () => _buildStatsShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return _buildStatsCards(theme, stats);
              },
            ),

            SizedBox(height: isTablet ? 20.0 : 28.h),

            // ── Filter + Label ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Transactions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: darkBackground,
                    letterSpacing: -0.2,
                    fontSize: isTablet ? 14.0 : null,
                  ),
                ),
                _buildFilterToggle(),
              ],
            ),

            SizedBox(height: isTablet ? 10.0 : 14.h),

            // ── History List ──────────────────────────────────────────────
            paymentsState.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
                ),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Failed to load split bills',
                    style: TextStyle(color: errorColor, fontSize: isTablet ? 13.0 : 13.sp),
                  ),
                ),
              ),
              data: (payments) {
                final list = payments?.data ?? [];
                if (list.isEmpty) return _buildEmptyHistoryState(theme);
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: isTablet ? 10.0 : 10.h),
                  itemBuilder: (_, i) => _buildHistoryItem(theme, list[i]),
                );
              },
            ),
            SizedBox(height: isTablet ? 16.0 : 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsShimmer() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      height: isTablet ? 120.0 : 130.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme, SplitDashboardStats stats) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F3A), Color(0xFF12284E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1F3A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Incoming row ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 16.0 : 18.w,
              isTablet ? 14.0 : 18.h,
              isTablet ? 16.0 : 18.w,
              isTablet ? 10.0 : 12.h,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 6.0 : 7.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
                  ),
                  child: Icon(Icons.south_rounded, color: const Color(0xFF9D97FF), size: isTablet ? 14.0 : 14.sp),
                ),
                SizedBox(width: isTablet ? 8.0 : 8.w),
                Text(
                  'Incoming · To Pay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: isTablet ? 11.5 : 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 16.0 : 18.w,
              0,
              isTablet ? 16.0 : 18.w,
              isTablet ? 14.0 : 16.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    label: 'Pending',
                    count: stats.incoming.pendingCount,
                    amount: stats.incoming.pendingAmount,
                    chipColor: const Color(0xFFF59E0B),
                    accentBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  ),
                ),
                SizedBox(width: isTablet ? 10.0 : 10.w),
                Expanded(
                  child: _buildStatChip(
                    label: 'Paid',
                    count: stats.incoming.paidCount ?? 0,
                    amount: stats.incoming.paidAmount ?? 0,
                    chipColor: successColor,
                    accentBg: successColor.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          // ── Divider ──────────────────────────────────────────────────
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
            indent: isTablet ? 16.0 : 18.w,
            endIndent: isTablet ? 16.0 : 18.w,
          ),
          // ── Outgoing row ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 16.0 : 18.w,
              isTablet ? 10.0 : 12.h,
              isTablet ? 16.0 : 18.w,
              isTablet ? 10.0 : 12.h,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 6.0 : 7.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
                  ),
                  child: Icon(Icons.north_rounded, color: const Color(0xFF34D399), size: isTablet ? 14.0 : 14.sp),
                ),
                SizedBox(width: isTablet ? 8.0 : 8.w),
                Text(
                  'Outgoing · To Collect',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: isTablet ? 11.5 : 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 16.0 : 18.w,
              0,
              isTablet ? 16.0 : 18.w,
              isTablet ? 14.0 : 18.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    label: 'Pending',
                    count: stats.outgoing.pendingCount,
                    amount: stats.outgoing.pendingAmount,
                    chipColor: const Color(0xFFF59E0B),
                    accentBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  ),
                ),
                SizedBox(width: isTablet ? 10.0 : 10.w),
                Expanded(
                  child: _buildStatChip(
                    label: 'Collected',
                    count: stats.outgoing.completedCount ?? 0,
                    amount: stats.outgoing.completedAmount ?? 0,
                    chipColor: successColor,
                    accentBg: successColor.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required double amount,
    required Color chipColor,
    required Color accentBg,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10.0 : 12.w,
        vertical: isTablet ? 8.0 : 10.h,
      ),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: isTablet ? 10.0 : 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 4.0 : 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₦${NumberFormat('#,##0.00').format(amount)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 13.5 : 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 3.0 : 3.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 6.0 : 6.w,
              vertical: isTablet ? 2.0 : 2.h,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isTablet ? 6.0 : 6.r),
            ),
            child: Text(
              '$count split${count == 1 ? '' : 's'}',
              style: TextStyle(
                color: chipColor,
                fontSize: isTablet ? 9.0 : 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
      ),
      padding: EdgeInsets.all(isTablet ? 3.0 : 3.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('all', 'All'),
          _buildFilterChip('pending', 'Pending'),
          _buildFilterChip('history', 'Done'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedType = type);
        ref.read(userSplitPaymentsProvider.notifier).fetchSplitPayments(type: type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 10.0 : 12.w,
          vertical: isTablet ? 5.0 : 5.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : lightSecondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTablet ? 11.0 : 11.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, UserSplitPaymentItem item) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isIncoming = item.isPendingPayment;

    // ── status resolution ───────────────────────────────────────────────
    Color statusFg = const Color(0xFFF59E0B);
    Color statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
    String statusText = isIncoming ? 'Pending Pay' : 'Pending';
    IconData statusIcon = Icons.schedule_rounded;

    if (item.status == 'COMPLETED' || item.paymentStatus == 'PAID') {
      statusFg = successColor;
      statusBg = successColor.withValues(alpha: 0.1);
      statusText = 'Paid';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (item.status == 'CANCELLED') {
      statusFg = errorColor;
      statusBg = errorColor.withValues(alpha: 0.1);
      statusText = 'Cancelled';
      statusIcon = Icons.cancel_outlined;
    }

    // ── direction colors ─────────────────────────────────────────────────
    const incomingColor = Color(0xFF6C63FF);
    const outgoingColor = Color(0xFF10B981);
    final directionColor = isIncoming ? incomingColor : outgoingColor;

    return GestureDetector(
      onTap: () {
        if (isIncoming) {
          context.pushNamed(
            RouteList.splitScanView,
            extra: {'splitId': item.splitId, 'token': ''},
          );
        } else {
          context.pushNamed(
            RouteList.splitCreatorDashboard,
            pathParameters: {'splitId': item.splitId},
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar ───────────────────────────────────
                Container(
                  width: isTablet ? 4.0 : 4.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        directionColor,
                        directionColor.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // ── Content ───────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12.0 : 14.w,
                      vertical: isTablet ? 10.0 : 12.h,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: isTablet ? 38.0 : 40.r,
                          height: isTablet ? 38.0 : 40.r,
                          decoration: BoxDecoration(
                            color: directionColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                          ),
                          child: Icon(
                            isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: directionColor,
                            size: isTablet ? 18.0 : 18.sp,
                          ),
                        ),
                        SizedBox(width: isTablet ? 10.0 : 12.w),
                        // Text block
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title?.isNotEmpty == true ? item.title! : 'Split Bill',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTablet ? 13.5 : 14.sp,
                                  color: darkBackground,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTablet ? 2.0 : 3.h),
                              Text(
                                isIncoming
                                    ? 'From ${item.creatorName}'
                                    : 'You created',
                                style: TextStyle(
                                  fontSize: isTablet ? 11.5 : 11.sp,
                                  color: lightSecondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: isTablet ? 2.0 : 2.h),
                              Text(
                                _formatDateTime(item.createdAt),
                                style: TextStyle(
                                  fontSize: isTablet ? 10.0 : 10.sp,
                                  color: lightSecondaryText.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isTablet ? 8.0 : 8.w),
                        // Right — amount + badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₦${NumberFormat('#,##0.00').format(isIncoming ? item.assignedAmount : item.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isTablet ? 13.5 : 14.sp,
                                color: darkBackground,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: isTablet ? 4.0 : 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8.0 : 8.w,
                                vertical: isTablet ? 3.0 : 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(isTablet ? 8.0 : 8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusFg, size: isTablet ? 9.0 : 9.sp),
                                  SizedBox(width: isTablet ? 3.0 : 3.w),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusFg,
                                      fontSize: isTablet ? 9.0 : 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: isTablet ? 4.0 : 4.w),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade300,
                          size: isTablet ? 18.0 : 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 32.0 : 48.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 20.0 : 22.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.call_split_rounded,
              color: Colors.white,
              size: isTablet ? 32.0 : 36.sp,
            ),
          ),
          SizedBox(height: isTablet ? 16.0 : 20.h),
          Text(
            'No split bills yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: darkBackground,
              letterSpacing: -0.3,
              fontSize: isTablet ? 16.0 : null,
            ),
          ),
          SizedBox(height: isTablet ? 8.0 : 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 32.w),
            child: Text(
              'Split bills you create or are invited to will show up here so you can track payments easily.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: lightSecondaryText,
                fontSize: isTablet ? 13.0 : 13.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildSetupForm(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20.0 : 20.w,
        vertical: isTablet ? 10.0 : 10.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
              border: Border.all(
                color: lightBorderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                CustomTextFormField(
                  controller: _titleController,
                  label: "Bill Title",
                  hintText: "e.g., Friday Dinner",
                  validator: (val) => null,
                ),
                SizedBox(height: isTablet ? 14.0 : 14.h),
                CustomTextFormField(
                  controller: _descController,
                  label: "Description (Optional)",
                  hintText: "What is this division for?",
                  validator: (val) => null,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          SizedBox(height: isTablet ? 16.0 : 18.h),

          // Add Participant Card
          Container(
            padding: EdgeInsets.all(isTablet ? 16.0 : 18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
              border: Border.all(
                color: lightBorderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Participants",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 14.0 : null,
                  ),
                ),
                SizedBox(height: isTablet ? 8.0 : 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _participantSearchController,
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 13.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: "BIA Tag, Phone, or Account",
                          hintStyle: TextStyle(
                            fontSize: isTablet ? 13.0 : 13.sp,
                            color: lightSecondaryText,
                          ),
                          filled: true,
                          fillColor: offWhiteBackground,
                          contentPadding: isTablet
                              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                              : EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 12.h,
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 10.0 : 10.w),
                    GestureDetector(
                      onTap: _isSearching ? null : _verifyAndAddParticipant,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20.0 : 16.w,
                          vertical: isTablet ? 12.0 : 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                        ),
                        child: _isSearching
                            ? SizedBox(
                                width: isTablet ? 20.0 : 20.w,
                                height: isTablet ? 20.0 : 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "Add",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 14.0 : 13.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          SizedBox(height: isTablet ? 16.0 : 18.h),

          // Participant List
          if (_addedParticipants.isNotEmpty) ...[
            Text(
              "Assigned Shares",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkBackground,
                fontSize: isTablet ? 14.0 : null,
              ),
            ),
            SizedBox(height: isTablet ? 8.0 : 8.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addedParticipants.length,
              separatorBuilder: (context, index) => SizedBox(height: isTablet ? 10.0 : 10.h),
              itemBuilder: (context, index) {
                final participant = _addedParticipants[index];
                return Container(
                  padding: EdgeInsets.all(isTablet ? 12.0 : 14.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
                    border: Border.all(
                      color: lightBorderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isTablet ? 38.0 : 38.r,
                        height: isTablet ? 38.0 : 38.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            participant['fullname'][0].toString().toUpperCase(),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14.0 : null,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 12.0 : 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant['fullname'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 13.0 : 13.sp,
                                color: darkBackground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              participant['identifier'],
                              style: TextStyle(
                                color: lightSecondaryText,
                                fontSize: isTablet ? 11.0 : 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isTablet ? 90.0 : 90.w,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: isTablet ? 13.0 : 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixText: "₦",
                            isDense: true,
                            contentPadding: isTablet
                                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                                : EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 8.h,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 8.0 : 8.r),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              participant['amount'] =
                                  double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: errorColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _addedParticipants.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
            SizedBox(height: isTablet ? 16.0 : 18.h),
          ],

          // Expiration Pill
          Container(
            padding: EdgeInsets.all(isTablet ? 14.0 : 16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
              border: Border.all(
                color: lightBorderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: primaryColor,
                  size: isTablet ? 20.0 : 20.sp,
                ),
                SizedBox(width: isTablet ? 12.0 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expiration Time",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 13.5 : 13.sp,
                          color: darkBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedExpiration == null
                            ? "No expiration limit (Optional)"
                            : _selectedExpiration!
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16),
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: isTablet ? 11.5 : 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _selectExpirationTime,
                  child: Text(
                    _selectedExpiration == null ? "Set" : "Change",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 13.0 : 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          SizedBox(height: isTablet ? 18.0 : 24.h),

          // Total Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Bill amount:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 14.0 : 14.sp,
                  color: lightSecondaryText,
                ),
              ),
              Text(
                "₦${NumberFormat('#,##0.00').format(_totalAmount)}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 20.0 : 18.sp,
                  color: darkBackground,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

          SizedBox(height: 24.h),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: isTablet ? 48.0 : 52.h,
            child: ElevatedButton(
              onPressed: _submitCreateSplit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
                ),
                elevation: 2,
              ),
              child: Text(
                "Generate QR Code",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 14.0 : 14.sp,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildQrPresenter(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final payloadString = jsonEncode(_generatedResponse!.qrPayload);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 24.w,
        vertical: isTablet ? 20.0 : 20.h,
      ),
      child: Column(
        children: [
          Screenshot(
            controller: _screenshotController,
            child: PremiumGlassCard(
              title: _titleController.text.trim().isEmpty
                  ? "Split Bill"
                  : _titleController.text.trim(),
              subtitle:
                  "Total: ₦${NumberFormat('#,##0.00').format(_generatedResponse!.totalAmount)}",
              child: Container(
                padding: EdgeInsets.all(isTablet ? 16.0 : 16.r),
                color: Colors.white,
                child: QrImageView(
                  data: payloadString,
                  version: QrVersions.auto,
                  size: isTablet ? 180.0 : 200.r,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

          SizedBox(height: isTablet ? 20.0 : 30.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularAction(
                Icons.download_rounded,
                "Save Card",
                _saveQrToGallery,
              ),
              _buildCircularAction(
                Icons.share_rounded,
                "Share QR",
                _shareQrCode,
              ),
            ],
          ),

          SizedBox(height: isTablet ? 24.0 : 40.h),

          // Open Live Dashboard
          SizedBox(
            width: double.infinity,
            height: isTablet ? 48.0 : 52.h,
            child: ElevatedButton(
              onPressed: () {
                context.pushReplacementNamed(
                  RouteList.splitCreatorDashboard,
                  pathParameters: {'splitId': _generatedResponse!.splitId},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 14.0 : 16.r),
                ),
                elevation: 2,
              ),
              child: Text(
                "Go to Live Dashboard",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 14.0 : 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 14.0 : 16.h),
          TextButton(
            onPressed: () {
              ref.read(splitCreatorProvider.notifier).reset();
              setState(() {
                _generatedResponse = null;
                _addedParticipants.clear();
                _titleController.clear();
                _descController.clear();
              });
            },
            child: Text(
              "Create Another Bill",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 13.5 : 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularAction(IconData icon, String label, VoidCallback onTap) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12.0 : 12.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: primaryColor, size: isTablet ? 22.0 : 24.sp),
          ),
          SizedBox(height: isTablet ? 6.0 : 8.h),
          Text(
            label,
            style: TextStyle(
              color: darkBackground,
              fontSize: isTablet ? 12.0 : 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
