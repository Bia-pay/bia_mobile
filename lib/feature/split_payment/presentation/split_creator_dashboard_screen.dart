import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/split_payment_controller.dart';
import '../model/split_models.dart';

class SplitCreatorDashboardScreen extends ConsumerStatefulWidget {
  final String splitId;

  const SplitCreatorDashboardScreen({super.key, required this.splitId});

  @override
  ConsumerState<SplitCreatorDashboardScreen> createState() =>
      _SplitCreatorDashboardScreenState();
}

class _SplitCreatorDashboardScreenState
    extends ConsumerState<SplitCreatorDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(splitDetailsProvider(widget.splitId));

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkBackground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteList.bottomNavBar);
            }
          },
        ),
        title: Text(
          "Split Bill Status",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: () {
              ref
                  .read(splitDetailsProvider(widget.splitId).notifier)
                  .fetchDetails();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: detailsState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              error: (err, stack) => Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: errorColor,
                      size: 64,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Failed to Load Status",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkBackground,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: lightSecondaryText,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(splitDetailsProvider(widget.splitId).notifier)
                          .fetchDetails(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data == null) return const SizedBox.shrink();
                return _buildDashboardContent(theme, data);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(ThemeData theme, SplitDetailsResponse details) {
    final collected = details.collectedAmount;
    final total = details.totalAmount;
    final remaining = details.remainingAmount;
    final pct = details.completionPercentage / 100.0;

    return RefreshIndicator(
      onRefresh: () => ref
          .read(splitDetailsProvider(widget.splitId).notifier)
          .fetchDetails(),
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          details.title ?? "Split Bill Collection",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: darkBackground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(details.status),
                    ],
                  ),
                  if (details.description != null &&
                      details.description!.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      details.description!,
                      style: TextStyle(
                        color: lightSecondaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        color: primaryColor,
                        size: 16,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Split ID: ${details.splitId}",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            SizedBox(height: 18.h),

            // Statistics Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(
                        "Total Split",
                        "₦${total.toStringAsFixed(2)}",
                        accentColor,
                      ),
                      Container(
                        width: 1,
                        height: 40.h,
                        color: lightBorderColor,
                      ),
                      _buildStatColumn(
                        "Collected",
                        "₦${collected.toStringAsFixed(2)}",
                        successColor,
                      ),
                      Container(
                        width: 1,
                        height: 40.h,
                        color: lightBorderColor,
                      ),
                      _buildStatColumn(
                        "Remaining",
                        "₦${remaining.toStringAsFixed(2)}",
                        pendingColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: offWhiteBackground,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              successColor,
                            ),
                            minHeight: 8.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Text(
                        "${details.completionPercentage.toInt()}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: successColor,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            SizedBox(height: 24.h),

            // Participants Title
            Text(
              "Participants List (${details.participants.length})",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkBackground,
              ),
            ),
            SizedBox(height: 8.h),

            // Participants List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.participants.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final p = details.participants[index];
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
                            p.fullname.isNotEmpty
                                ? p.fullname[0].toUpperCase()
                                : 'P',
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
                              p.fullname,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                                color: darkBackground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Share: ₦${p.amountAssigned.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: lightSecondaryText,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildParticipantStatus(p),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            SizedBox(height: 30.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: OutlinedButton.icon(
                      onPressed: collected > 0
                          ? () {
                              ToastHelper.showToast(
                                context: context,
                                message:
                                    "Cannot cancel split bill after payments are received.",
                                icon: Icons.info_outline,
                                iconColor: errorColor,
                              );
                            }
                          : () async {
                              final success = await ref
                                  .read(
                                    splitDetailsProvider(
                                      widget.splitId,
                                    ).notifier,
                                  )
                                  .cancelSplit(context);
                              if (success && mounted) {
                                context.pop();
                              }
                            },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text("Cancel Split"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: collected > 0
                            ? disabledTextColor
                            : errorColor,
                        side: BorderSide(
                          color: collected > 0
                              ? disabledBorderColor
                              : errorColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton.icon(
                      onPressed: remaining <= 0
                          ? null
                          : () => ref
                                .read(
                                  splitDetailsProvider(widget.splitId).notifier,
                                )
                                .sendReminders(context),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text("Remind All"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: lightSecondaryText,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = pendingColor.withValues(alpha: 0.1);
    Color fg = pendingColor;
    String text = "Pending";

    if (status == "COMPLETED") {
      bg = successColor.withValues(alpha: 0.1);
      fg = successColor;
      text = "Completed";
    } else if (status == "CANCELLED") {
      bg = errorColor.withValues(alpha: 0.1);
      fg = errorColor;
      text = "Cancelled";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Widget _buildParticipantStatus(SplitParticipant p) {
    if (p.paymentStatus == "PAID") {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: successColor, size: 10),
            SizedBox(width: 4.w),
            Text(
              "Paid",
              style: TextStyle(
                color: successColor,
                fontWeight: FontWeight.bold,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      );
    } else if (p.paymentStatus == "CANCELLED") {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          "Cancelled",
          style: TextStyle(
            color: errorColor,
            fontWeight: FontWeight.bold,
            fontSize: 10.sp,
          ),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: pendingColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          "Pending",
          style: TextStyle(
            color: pendingColor,
            fontWeight: FontWeight.bold,
            fontSize: 10.sp,
          ),
        ),
      );
    }
  }
}
