import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/utils/colors.dart';
import '../../../app/utils/widgets/toast_helper.dart';
import '../controller/referral_controller.dart';
import '../model/referral_models.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(referralStatsProvider);
    ref.invalidate(referralHistoryProvider);
    await ref.read(referralStatsProvider.future);
    await ref.read(referralHistoryProvider.future);
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ToastHelper.showToast(
      context: context,
      message: 'Referral code copied!',
    );
  }

  void _shareReferralLink(String code) {
    Share.share(
      'Join BIA today and earn rewards! Use my referral code: $code\nSign up here: https://bia.com.ng/signup?ref=$code',
      subject: 'BIA Referral Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(referralStatsProvider);
    final historyAsync = ref.watch(referralHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium off-white/grey bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: lightText, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Refer & Earn',
          style: TextStyle(
            color: lightText,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),

              // Banner / Hero Illustration placeholder
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, Color(0xFF1D93B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spread the Word',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Share your referral code with friends and earn ₦500.00 on every successful sign up!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              SizedBox(height: 25.h),

              // Code and Stats cards
              statsAsync.when(
                data: (stats) {
                  if (stats == null) {
                    return _buildErrorState('No referral details found.');
                  }
                  return Column(
                    children: [
                      // Referral Code Card
                      _buildReferralCodeCard(stats.referralCode),
                      SizedBox(height: 25.h),

                      // Metrics Row
                      _buildMetricsGrid(stats),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
                error: (err, stack) => _buildErrorState(err.toString()),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              SizedBox(height: 30.h),

              // Referral History Header
              Text(
                'REFERRAL HISTORY',
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 12.h),

              // Referral History List
              historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return _buildEmptyHistoryState();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _buildHistoryItem(item)
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 250.ms);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
                error: (err, stack) => _buildErrorState(err.toString()),
              ),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(String code) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: offWhiteBackground,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: lightBorderColor, width: 1),
            ),
            child: Text(
              code,
              style: TextStyle(
                color: lightText,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(code),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copy Code',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareReferralLink(code),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    'Share Link',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ReferralStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Earnings',
                value: '₦${NumberFormat('#,##0.00').format(stats.totalEarnings)}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: primaryColor,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Completed',
                value: stats.completedReferrals.toString(),
                icon: Icons.check_circle_outline_rounded,
                iconColor: successColor,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildMetricCard(
                title: 'Pending',
                value: stats.pendingReferrals.toString(),
                icon: Icons.hourglass_empty_rounded,
                iconColor: pendingColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            style: TextStyle(
              color: lightText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ReferralHistoryItem item) {
    final name = item.referredUser?.fullname.isNotEmpty == true
        ? item.referredUser!.fullname
        : _maskPhone(item.referredUser?.phone ?? '');
    final date = _formatDate(item.createdAt);
    final isCompleted = item.status == 'COMPLETED';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: offWhiteBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: lightText, size: 20),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: lightText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCompleted
                    ? '+₦${NumberFormat('#,##0.00').format(item.bonusAmount)}'
                    : '₦0.00',
                style: TextStyle(
                  color: isCompleted ? successColor : lightSecondaryText,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              _buildStatusBadge(item.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isCompleted = status == 'COMPLETED';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isCompleted ? successColor.withValues(alpha: 0.08) : pendingColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isCompleted ? successColor : pendingColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: lightSecondaryText.withValues(alpha: 0.3),
            size: 48,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Referrals Yet',
            style: TextStyle(
              color: lightText,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Share your code above to start inviting friends.',
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          style: const TextStyle(color: errorColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}
