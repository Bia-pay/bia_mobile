import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_bar.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../model/favourite_beneficiary.dart';
import '../../../model/recent_transfer.dart';
import '../widget/tabs.dart';

class SendMoneyTransfer extends ConsumerStatefulWidget {
  const SendMoneyTransfer({super.key});

  @override
  ConsumerState<SendMoneyTransfer> createState() => _SendMoneyTransferState();
}

class _SendMoneyTransferState extends ConsumerState<SendMoneyTransfer> {
  final TextEditingController accountController = TextEditingController();
  String? accountError;
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
        accountError = null;
      });
    } else {
      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedPhone = null;
        verifiedAccount = null;
        accountError = result?.responseMessage ?? "Account not found";
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

    context.pushNamed(
      RouteList.amountPage,
      extra: {
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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

              /// 🔹 Account Input Card (FIXED)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: whiteBackground,
                  borderRadius: BorderRadius.circular(15.r),
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
                    AppField.transparent(
                      hintText: 'Enter Account Number',
                      width: double.infinity,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      initialValue: verifiedAccount,
                      withClearButton: true,
                      onChanged: (value) {
                        setState(() {
                          accountError = null;
                        });

                        if (value.length == 10) {
                          _verifyAccountFromInput(context, value.trim());
                        } else {
                          setState(() {
                            isVerified = false;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10.h),if (accountError != null)
                      Container(
                        padding: EdgeInsets.all(13.w),
                        child: Text(
                          accountError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (isVerified)
                      InkWell(
                        onTap: () => _goToAmountPage(context),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: EdgeInsets.all(15.w),
                          child: Row(
                            children: [
                              const CircleAvatar(),
                              SizedBox(width: 10.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    verifiedName ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    verifiedPhone ?? '',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

              SizedBox(height: 15.h),

              /// 🔥 ONLY THIS PART SCROLLS
              Expanded(
                child: CardThree(),
              ),
            ],
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
  List<FavouriteBeneficiaryItem> favouriteBeneficiaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    final recent =
    await dashboardCtrl.getRecentBeneficiary(context);

    final favourites =
    await dashboardCtrl.getFavouriteBeneficiary(context);

    setState(() {
      recentBeneficiaries = recent;
      favouriteBeneficiaries = favourites;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: whiteBackground,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: BeneficiaryTabSection(
        favorites: favouriteBeneficiaries
            .map((r) => {
          "name": r.name,
          "account": r.phone, // IN_APP has no account number
        })
            .toList(),
        recents: recentBeneficiaries
            .map((r) => {
          "name": r.fullname,
          "account": r.phone,
        })
            .toList(),
        showLogo: true,
        showProgress: false,
        onSelectBeneficiary: (name, account) {
          final parent =
          context.findAncestorStateOfType<_SendMoneyTransferState>();
          if (parent != null) {
            parent._verifyAccountSilently(context, account);
          }
        },
      ),
    );
  }
}