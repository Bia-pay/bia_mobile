import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive/hive.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/u_popup.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../dashboardcontroller/provider.dart';
import '../../../widgets/transaction.dart';
import 'package:bia/core/services/session_service.dart';

class AddMoney extends ConsumerStatefulWidget {
  const AddMoney({super.key});

  @override
  ConsumerState<AddMoney> createState() => _AddMoneyState();
}

class _AddMoneyState extends ConsumerState<AddMoney> {
  void _showFAQBottomSheet(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 24.0 : 28.r),
                  topRight: Radius.circular(isTablet ? 24.0 : 28.r),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24.0 : 24.w,
                isTablet ? 16.0 : 20.h,
                isTablet ? 24.0 : 24.w,
                isTablet ? 24.0 : 30.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: isTablet ? 40.0 : 40.w,
                      height: isTablet ? 4.0 : 4.h,
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
                      Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: isTablet ? 18.0 : 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 4.0 : 4.r),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: isTablet ? 18.0 : 18.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16.0 : 24.h),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildFAQItem(
                            title: 'How do I fund my wallet via Bank Transfer?',
                            content:
                                'Copy your Bank Transfer Funding account details (the green card) and make a transfer from any banking app. The funds will reflect in your BIA wallet instantly.',
                          ),
                          _buildFAQItem(
                            title: 'Why is Card/Account top-up disabled?',
                            content:
                                'We are currently upgrading our payment gateway interfaces to support more local cards. Card/Account deposits will be enabled shortly.',
                          ),
                          _buildFAQItem(
                            title: 'Are there any fees for funding my account?',
                            content:
                                'BIA does not charge any deposit fees for bank transfers or standard wallet deposits. However, your sending bank may apply standard network charges.',
                          ),
                          _buildFAQItem(
                            title: 'What is a Virtual Funding Account (VC)?',
                            content:
                                'A Virtual Account is a dedicated bank account number mapped directly to your BIA wallet. Any transfer sent to this account is instantly credited to your balance.',
                          ),
                          _buildFAQItem(
                            title:
                                'What should I do if my transfer hasn\'t reflected?',
                            content:
                                'Bank transfers are usually instant. If you experience delays, please wait 10-15 minutes. If it still hasn\'t reflected, please contact our support with the transaction receipt.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem({required String title, required String content}) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: isTablet ? 12.0 : 12.h),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        iconColor: primaryColor,
        collapsedIconColor: Colors.grey,
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 13.0 : 13.sp,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        toolbarHeight: isTablet ? 60.0 : null,
        title: Text(
          'Fund Account',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 16.0 : 16.sp,
          ),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: isTablet ? 18.0 : 18.sp),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isTablet ? 16.0 : 16.w),
            child: TextButton(
              onPressed: () => _showFAQBottomSheet(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 8.0 : 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'FAQ',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 14.0 : 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 24.w,
                      vertical: isTablet ? 20.0 : 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 💳 Modern Premium Balance Card
                        const ModernBankDetailsCard(),

                        SizedBox(height: isTablet ? 24.0 : 32.h),

                        Text(
                          'Other Funding Methods',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lightText,
                            fontSize: isTablet ? 16.0 : 16.sp,
                          ),
                        ),

                        SizedBox(height: isTablet ? 14.0 : 16.h),

                        /// 🏦 Funding Options List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topUp.length,
                          itemBuilder: (context, index) {
                            final tx = topUp[index];

                            IconData iconData;
                            if (tx.name.contains("Card")) {
                              iconData = Icons.credit_card_rounded;
                            } else if (tx.name.contains("Cash")) {
                              iconData = Icons.storefront_rounded;
                            } else if (tx.name.contains("USSD")) {
                              iconData = Icons.dialpad_rounded;
                            } else {
                              iconData = Icons.call_received_rounded;
                            }

                            bool isComingSoon =
                                tx.name.contains("Cash") ||
                                tx.name.contains("USSD") ||
                                tx.name.contains("Card/Account");

                            return Padding(
                              padding: EdgeInsets.only(bottom: isTablet ? 12.0 : 12.h),
                              child: GestureDetector(
                                onTap: () {
                                  if (isComingSoon) {
                                    UPopup.show(
                                      context,
                                      type: UPopupType.info,
                                      title: "Coming Soon",
                                      message:
                                          "This feature will be available shortly!",
                                      confirmLabel: "OK",
                                    );
                                  } else if (tx.name.contains("Card")) {
                                    context.pushNamed(RouteList.depositScreen);
                                  } else if (tx.name.contains("Receive")) {
                                    context.pushNamed(RouteList.qrScreen);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 16.0 : 16.w,
                                    vertical: isTablet ? 14.0 : 16.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isTablet ? 16.0 : 16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: lightBorderColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: isTablet ? 48.0 : 48.h,
                                        width: isTablet ? 48.0 : 48.w,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                                        ),
                                        child: Icon(
                                          iconData,
                                          color: primaryColor,
                                          size: isTablet ? 24.0 : 24.sp,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 14.0 : 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.name,
                                              style: TextStyle(
                                                color: lightText,
                                                fontSize: isTablet ? 15.0 : 15.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: isTablet ? 2.0 : 4.h),
                                            Text(
                                              tx.dateTime,
                                              style: TextStyle(
                                                fontSize: isTablet ? 12.0 : 12.sp,
                                                color: lightSecondaryText,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      isComingSoon
                                          ? Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet ? 8.0 : 8.w,
                                                vertical: isTablet ? 4.0 : 4.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(
                                                  isTablet ? 12.0 : 12.r,
                                                ),
                                              ),
                                              child: Text(
                                                "Coming Soon",
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: isTablet ? 10.0 : 10.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: isTablet ? 16.0 : 16.sp,
                                              color: lightSecondaryText.withValues(alpha: 0.5),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🔹 Modern Bank Details Card Widget
class ModernBankDetailsCard extends ConsumerWidget {
  const ModernBankDetailsCard({super.key});

  String _cleanPhone(String phone) {
    String cleaned = phone.trim().replaceAll('+', '');
    if (cleaned.startsWith('234')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final accountAsync = ref.watch(virtualAccountProvider);
    final box = Hive.box('authBox');

    final String rawPhone =
        userProfile?.phone ?? box.get('phone', defaultValue: '').toString();
    final String biaPhone = _cleanPhone(rawPhone);
    final String biaTag =
        userProfile?.tag ?? box.get('tag', defaultValue: '').toString();
    final String biaName =
        userProfile?.fullname ??
        box.get('fullname', defaultValue: 'Bia User').toString();

    final isTablet = MediaQuery.of(context).size.width > 600;
    final vc = accountAsync.value;

    return Column(
      children: [
        // 💳 Card 1: BIA WALLET CARD
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 20.0 : 20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 6.0 : 6.r),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wallet_rounded,
                          color: primaryColor,
                          size: isTablet ? 14.0 : 14.sp,
                        ),
                      ),
                      SizedBox(width: isTablet ? 8.0 : 8.w),
                      Text(
                        'BIA WALLET',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: isTablet ? 10.0 : 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  if (biaTag.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '@$biaTag'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tag @$biaTag copied!'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10.0 : 10.w,
                          vertical: isTablet ? 4.0 : 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@$biaTag',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 11.0 : 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: isTablet ? 4.0 : 4.w),
                            Icon(
                              Icons.copy_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: isTablet ? 10.0 : 10.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isTablet ? 16.0 : 20.h),
              Text(
                'Account Number',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: isTablet ? 11.0 : 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 4.0 : 4.h),
              Row(
                children: [
                  Text(
                    biaPhone.isEmpty ? 'No Account' : biaPhone,
                    style: TextStyle(
                      fontSize: isTablet ? 22.0 : 24.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (biaPhone.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: biaPhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bia Account Number copied!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 8.0 : 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: isTablet ? 16.0 : 16.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isTablet ? 10.0 : 12.h),
              Text(
                biaName,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 12.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 14.0 : 16.h),

        // 💳 Card 2: VIRTUAL BANK DEPOSIT CARD
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 20.0 : 20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isTablet ? 6.0 : 6.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: isTablet ? 14.0 : 14.sp,
                        ),
                      ),
                      SizedBox(width: isTablet ? 8.0 : 8.w),
                      Text(
                        'BANK TRANSFER DEPOSIT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: isTablet ? 10.0 : 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  if (vc != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10.0 : 10.w,
                        vertical: isTablet ? 4.0 : 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        vc.provider,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 11.0 : 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isTablet ? 16.0 : 20.h),
              Text(
                'Funding Account Number',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: isTablet ? 11.0 : 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 4.0 : 4.h),
              if (accountAsync.isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (vc == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Text(
                    'No virtual bank account available',
                    style: TextStyle(
                      fontSize: isTablet ? 13.0 : 13.sp,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Text(
                      vc.virtualAccountNo,
                      style: TextStyle(
                        fontSize: isTablet ? 22.0 : 24.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: vc.virtualAccountNo),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${vc.provider} account number copied!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 8.0 : 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: isTablet ? 16.0 : 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: isTablet ? 10.0 : 12.h),
              Text(
                vc?.virtualAccountName ?? biaName,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 12.sp,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 20.0 : 24.h),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final details = vc != null
                      ? 'My Bia Account details:\n- Bia Account / Phone: $biaPhone\n- Bia Tag: @$biaTag\n- VC Bank: ${vc.provider}\n- VC Account No: ${vc.virtualAccountNo}\n- VC Account Name: ${vc.virtualAccountName}'
                      : 'My Bia Account details:\n- Bia Account / Phone: $biaPhone\n- Bia Tag: @$biaTag';
                  Share.share(details);
                },
                icon: Icon(
                  Icons.share_rounded,
                  size: isTablet ? 16.0 : 16.sp,
                  color: primaryColor,
                ),
                label: Text(
                  'Share Details',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: isTablet ? 13.0 : 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 12.0 : 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  UPopup.show(
                    context,
                    type: UPopupType.info,
                    title: "Coming Soon",
                    message:
                        "Card funding is currently unavailable and will be active shortly!",
                    confirmLabel: "OK",
                  );
                },
                icon: Icon(
                  Icons.lock_clock_rounded,
                  size: isTablet ? 16.0 : 16.sp,
                  color: Colors.white70,
                ),
                label: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 12.0 : 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentWebViewPage extends ConsumerStatefulWidget {
  final String url;
  final String reference;

  const PaymentWebViewPage({
    super.key,
    required this.url,
    required this.reference,
  });

  @override
  ConsumerState<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends ConsumerState<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _hasVerified = false;

  @override
  void initState() {
    super.initState();
    ref.read(sessionServiceProvider.notifier).setBypassLifecycle(true);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('https://flutter.dev')) {
              _verifyPayment(widget.reference);
              return NavigationDecision.prevent;
            } else if (url.contains('your-failure-return-url')) {
              _showDialog("Failed", "Payment was not completed.");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    ref.read(sessionServiceProvider.notifier).setBypassLifecycle(false);
    super.dispose();
  }

  Future<void> _verifyPayment(String reference) async {
    if (_hasVerified) return;
    _hasVerified = true;

    try {
      final res = await ref
          .read(dashboardControllerProvider.notifier)
          .verifyDeposit(context, reference);

      if (res != null &&
          res.responseSuccessful &&
          res.data != null &&
          (res.data!.status.toLowerCase() == "success" ||
              res.data!.status.toLowerCase() == "successful" ||
              res.data!.description.toLowerCase() == "successful")) {
        if (!mounted) return;

        Navigator.pop(context, {
          "type": "deposit",
          "amount": res.data!.amount.toString(),
          "reference": res.data!.reference,
        });
      } else {
        _hasVerified = false;
        _showDialog("Failed", "Payment was not completed.");
      }
    } catch (e) {
      _hasVerified = false;
      _showDialog("Error", "Verification failed.");
    }
  }



  void _showDialog(String title, String message) {
    if (!mounted) return;

    UPopup.show(
      context,
      type: UPopupType.error,
      title: title,
      message: message,
      confirmLabel: "OK",
      onConfirm: () {
        Navigator.pop(context); // close WebView
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
