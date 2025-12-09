import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/view/widget/app_bar.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../model/recent_transfer.dart';
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
        isVerified = true;
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
    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  title: 'Send Money',
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Make new transfer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: whiteBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient Account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    Container(
                      height: 55.h,
                      decoration: BoxDecoration(
                        color: whiteBackground,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: AppField.transparent(
                        hintText: 'Enter Account Number',
                        width: double.infinity,
                        initialValue: verifiedAccount,
                        withClearButton: true,
                        onChanged: (value) {
                          if (value.length == 10) {
                            _verifyAccountFromInput(context, value.trim());
                          } else {
                            setState(() => isVerified = false);
                          }
                        },
                      ),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isVerified
                          ? InkWell(
                            onTap: () => _goToAmountPage(context),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: double.infinity,
                              key: ValueKey("verified_card"),
                              padding: EdgeInsets.all(15.w),
                              child: Row(
                                children: [
                                  CircleAvatar(),
                                  SizedBox(width: 10.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Name: $verifiedName",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: lightText,
                                        ),
                                      ),
                                      Text(
                                        "Account: $verifiedPhone",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: lightSecondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          : SizedBox.shrink(),
                    )
                  ],
                ),
              ),
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

    recentBeneficiaries = await dashboardCtrl.getRecentBeneficiary(context);
    setState(() => isLoading = false);

    final freshList = await dashboardCtrl.getRecentBeneficiary(context);
    setState(() => recentBeneficiaries = freshList);
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (recentBeneficiaries.isEmpty) return const Center(child: Text("No recent transfers found"));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: whiteBackground,
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