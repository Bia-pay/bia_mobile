import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../app/view/widget/app_bar.dart';
import '../../../../app/view/widget/app_search_field.dart';
import '../../dashboardcontroller/dashboardcontroller.dart';
import '../../model/recent_transfer.dart';
import '../../pages/vtu/airtime/airtime.dart';
import '../widget/tabs.dart';

class SendMoneyTransfer extends ConsumerStatefulWidget {
  const SendMoneyTransfer({super.key});

  @override
  ConsumerState<SendMoneyTransfer> createState() => _SendMoneyTransferState();
}

class _SendMoneyTransferState extends ConsumerState<SendMoneyTransfer> {
  final TextEditingController accountController = TextEditingController();

  bool isVerified = false;
  String? verifiedName;
  String? verifiedPhone;
  String? verifiedAccount;


  @override
  void dispose() {
    accountController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccountFromInput(BuildContext context, String accountNumber) async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyAccount(context, accountNumber);

    if (result?.responseSuccessful == true) {
      final fullname = result?.responseBody?.user?.fullname ?? 'Unknown User';

      setState(() {
        isVerified = true;            // SHOW CONTAINER
        verifiedName = fullname;
        verifiedPhone = accountNumber;
        verifiedAccount = accountNumber;
      });
    } else {
      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedPhone = null;
        verifiedAccount = null;
      });
    }
  }

  Future<void> _verifyAccountSilently(BuildContext context, String accountNumber) async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyAccount(context, accountNumber);

    if (result?.responseSuccessful == true) {
      final fullname = result?.responseBody?.user?.fullname ?? 'Unknown User';

      // ❌ DO NOT SET isVerified = true
      setState(() {
        verifiedName = fullname;
        verifiedPhone = accountNumber;
        verifiedAccount = accountNumber;
      });

      _goToAmountPage(context);
    }
  }
  void _goToAmountPage(BuildContext context) {
    if (verifiedName == null || verifiedAccount == null) return;

    Navigator.pushNamed(
      context,
      '/amountPage',
      arguments: {
        'controller': TextEditingController(),
        'recipientName': verifiedName,
        'recipientAccount': verifiedAccount,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeContext = context.themeContext;

    return Scaffold(
      backgroundColor: themeContext.grayWhiteBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  title: 'Money Transfer',
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: 10.h),

                Text(
                  'Make new transfer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: themeContext.pinfieldTextColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: AppField.transparent(
                    hintText: 'Enter Account Number',
                    onChanged: (value) {
                      if (value.length == 10) {
                        _verifyAccountFromInput(context, value.trim());
                      } else {
                        setState(() => isVerified = false);
                      }
                    },
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(height: 15.h),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: themeContext.offWhiteBg,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: themeContext.kPrimary, size: 22.sp),
                            SizedBox(width: 8.w),
                            Text(
                              "Account Verified",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: themeContext.kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          "Name: $verifiedName",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Account: $verifiedPhone",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: themeContext.secondaryTextColor,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeContext.kPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _goToAmountPage(context),
                            child: Text(
                              "Send Money",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 25.h),

                Text(
                  'Beneficiaries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                CardThree(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CardThree extends ConsumerStatefulWidget {
  const CardThree({super.key});

  @override
  ConsumerState<CardThree> createState() => _CardThreeState();
}

class _CardThreeState extends ConsumerState<CardThree> {
  List<RecentBeneficiaryItem> recentBeneficiaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    // Load cached first
    recentBeneficiaries = await dashboardCtrl.getRecentBeneficiary(context);
    setState(() => isLoading = false);

    // Fetch fresh list in background
    final freshList = await dashboardCtrl.getRecentBeneficiary(context);
    setState(() => recentBeneficiaries = freshList);
  }

  @override
  Widget build(BuildContext context) {
    final themeContext = context.themeContext;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (recentBeneficiaries.isEmpty) return const Center(child: Text("No recent transfers found"));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: themeContext.tertiaryBackgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: BeneficiaryTabSection(
        favorites: const [],
        recents: recentBeneficiaries
            .map((r) => {"name": r.fullname, "account": r.phone})
            .toList(),
        showLogo: true,
        showProgress: false,
        key: UniqueKey(),
        onSelectBeneficiary: (name, account) {
          final parent = context.findAncestorStateOfType<_SendMoneyTransferState>();
          if (parent != null) {
            parent._verifyAccountSilently(context, account);
          }
        },
      ),
    );
  }
}