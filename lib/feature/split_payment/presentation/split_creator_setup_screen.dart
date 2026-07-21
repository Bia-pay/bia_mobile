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

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/custom_text_field.dart';
import '../../../app/utils/widgets/premium_card.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';
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

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Create Split Bill",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkBackground,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _generatedResponse == null
                    ? _buildSetupForm(theme)
                    : _buildQrPresenter(theme),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetupForm(ThemeData theme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
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
                SizedBox(height: 14.h),
                CustomTextFormField(
                  controller: _descController,
                  label: "Description (Optional)",
                  hintText: "What is this division for?",
                  validator: (val) => null,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          SizedBox(height: 18.h),

          // Add Participant Card
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
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
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _participantSearchController,
                        decoration: InputDecoration(
                          hintText: "BIA Tag, Phone, or Account",
                          filled: true,
                          fillColor: offWhiteBackground,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: _isSearching ? null : _verifyAndAddParticipant,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: _isSearching
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
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
                                  fontSize: 13.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          SizedBox(height: 18.h),

          // Participant List
          if (_addedParticipants.isNotEmpty) ...[
            Text(
              "Assigned Shares",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkBackground,
              ),
            ),
            SizedBox(height: 8.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addedParticipants.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final participant = _addedParticipants[index];
                return Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: lightBorderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38.r,
                        height: 38.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            participant['fullname'][0].toString().toUpperCase(),
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              participant['fullname'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: darkBackground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              participant['identifier'],
                              style: TextStyle(
                                color: lightSecondaryText,
                                fontSize: 11.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Amount Input
                      SizedBox(
                        width: 100.w,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            hintText: "₦0",
                            prefixText: "₦",
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: lightBorderColor),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
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
            SizedBox(height: 18.h),
          ],

          // Expiration Pill
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: lightBorderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: primaryColor),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expiration Time",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: darkBackground,
                        ),
                      ),
                      Text(
                        _selectedExpiration == null
                            ? "No expiration limit (Optional)"
                            : _selectedExpiration!
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16),
                        style: TextStyle(
                          color: lightSecondaryText,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _selectExpirationTime,
                  child: Text(
                    _selectedExpiration == null ? "Set" : "Change",
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          SizedBox(height: 24.h),

          // Total Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Bill amount:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: lightSecondaryText,
                ),
              ),
              Text(
                "₦${_totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                  color: darkBackground,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

          SizedBox(height: 24.h),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 55.h,
            child: ElevatedButton(
              onPressed: _submitCreateSplit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                "Generate QR Code",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildQrPresenter(ThemeData theme) {
    final payloadString = jsonEncode(_generatedResponse!.qrPayload);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          Screenshot(
            controller: _screenshotController,
            child: PremiumGlassCard(
              title: _titleController.text.trim().isEmpty
                  ? "Split Bill"
                  : _titleController.text.trim(),
              subtitle:
                  "Total: ₦${_generatedResponse!.totalAmount.toStringAsFixed(2)}",
              child: Container(
                padding: EdgeInsets.all(16.r),
                color: Colors.white,
                child: QrImageView(
                  data: payloadString,
                  version: QrVersions.auto,
                  size: 200.r,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),

          SizedBox(height: 30.h),

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

          SizedBox(height: 40.h),

          // Open Live Dashboard
          SizedBox(
            width: double.infinity,
            height: 55.h,
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
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: const Text(
                "Go to Live Dashboard",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 16.h),
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
            child: const Text(
              "Create Another Bill",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: primaryColor, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              color: darkBackground,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
