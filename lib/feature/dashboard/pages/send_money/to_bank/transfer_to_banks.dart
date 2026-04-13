import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_bar.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../model/bank_model.dart';
import '../widget/tabs.dart';

class SendMoneyToBank extends ConsumerStatefulWidget {
  const SendMoneyToBank({super.key});

  @override
  ConsumerState<SendMoneyToBank> createState() => _SendMoneyToBankState();
}

class _SendMoneyToBankState extends ConsumerState<SendMoneyToBank> {
  final TextEditingController accountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  BankModel? selectedBank;
  List<BankModel> banks = [];
  List<BankModel> filteredBanks = [];
  bool isLoadingBanks = true;
  String? accountError;

  bool isVerified = false;
  String? verifiedName;
  String? verifiedAccount;
  String? verifiedBankCode;
  String? verifiedBankName;
  List<Map<String, dynamic>> recentBankTransfers = [];
  List<Map<String, dynamic>> bankBeneficiaries = [];
  bool isLoadingBeneficiaries = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _loadBankBeneficiaries();
  }

  @override
  void dispose() {
    accountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBankBeneficiaries() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final recents = await dashboardCtrl.getRecentBankTransfers(context);
    final beneficiaries = await dashboardCtrl.getBankBeneficiaries(context);

    if (mounted) {
      setState(() {
        recentBankTransfers = recents;
        bankBeneficiaries = beneficiaries;
        isLoadingBeneficiaries = false;
      });
    }
  }

  Future<void> _loadBanks() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final loadedBanks = await dashboardCtrl.getBanks(context);

    if (mounted) {
      setState(() {
        banks = loadedBanks;
        filteredBanks = loadedBanks;
        isLoadingBanks = false;
      });
    }
  }

  Future<void> _verifyAccountFromInput(String accountNumber) async {
    final effectiveBankCode = selectedBank?.bankCode ?? verifiedBankCode;
    final effectiveBankName = selectedBank?.bankName ?? verifiedBankName;

    if (effectiveBankCode == null || effectiveBankCode.isEmpty) {
      _showBankSelector();
      return;
    }

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    final result = await dashboardCtrl.verifyBankAccount(
      context,
      accountNumber: accountNumber.trim(),
      bankCode: effectiveBankCode,
      bankName: effectiveBankName ?? '',
    );

    if (result?.responseSuccessful == true && result?.responseBody != null) {
      setState(() {
        isVerified = true;
        verifiedName = result?.responseBody?.accountName;
        verifiedAccount = result?.responseBody?.accountNumber;
        verifiedBankCode = selectedBank?.bankCode;
        verifiedBankName = selectedBank?.bankName;
        accountError = null;
      });
    } else {
      String errorMessage = "Account not found";
      final backendMessage = result?.responseMessage ?? "";

      if (backendMessage.contains("400")) {
        errorMessage = "Account number not found for this bank";
      } else if (backendMessage.toLowerCase().contains("timeout")) {
        errorMessage = "Verification failed. Check your connection.";
      } else if (backendMessage.isNotEmpty) {
        errorMessage = "Unable to verify account";
      }

      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedAccount = null;
        verifiedBankCode = null;
        verifiedBankName = null;
        accountError = errorMessage;
      });
    }
  }

  void _goToAmountPage(BuildContext context, String name, String account) {
    context.pushNamed(
      RouteList.bankAmountPage,
      extra: {
        'recipientName': name,
        'recipientAccount': account,
        'bankCode': verifiedBankCode ?? selectedBank?.bankCode,
        'bankName': verifiedBankName ?? selectedBank?.bankName,
        'transferType': 'bank',
      },
    );
  }

  void _showBankSelector() {
    setState(() {
      filteredBanks = banks;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: lightSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: lightBorderColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'Select Bank',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search banks...',
                          prefixIcon: Icon(Icons.search, color: grey),
                          filled: true,
                          fillColor: grey100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: lightBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: lightBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            if (value.isEmpty) {
                              filteredBanks = banks;
                            } else {
                              filteredBanks = banks
                                  .where((bank) =>
                              bank.bankName.toLowerCase().contains(value.toLowerCase()) ||
                                  bank.bankCode.contains(value))
                                  .toList();
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: isLoadingBanks
                          ? const Center(child: CircularProgressIndicator())
                          : filteredBanks.isEmpty
                          ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Text(
                            'No banks found',
                            style: TextStyle(color: grey),
                          ),
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredBanks.length,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemBuilder: (context, index) {
                          final bank = filteredBanks[index];
                          final isSelected = selectedBank?.bankCode == bank.bankCode;

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 4.h,
                            ),
                            leading: Icon(
                              Icons.account_balance,
                              color: isSelected ? primaryColor : grey,
                              size: 24.sp,
                            ),
                            title: Text(
                              bank.bankName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? primaryColor : darkBackground,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: primaryColor, size: 20.sp)
                                : null,
                            onTap: () {
                              setState(() => selectedBank = bank);
                              Navigator.pop(context);
                              if (accountController.text.length == 10) {
                                _verifyAccountFromInput(accountController.text);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 600;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - bottomPadding - 100.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomHeader(
                            title: 'Transfer to Bank',
                            onBackPressed: () async {
                              FocusScope.of(context).unfocus();
                              await Future.delayed(const Duration(milliseconds: 150));
                              if (context.mounted) context.pop();
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 12.h : 20.h),

                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
                            decoration: BoxDecoration(
                              color: whiteBackground,
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Recipient Account',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: lightText,
                                    fontSize: isSmallScreen ? 14.sp : 16.sp,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 10.h : 15.h),

                                InkWell(
                                  onTap: _showBankSelector,
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: isSmallScreen ? 10.h : 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: whiteBackground,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: lightBorderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance,
                                          color: primaryColor,
                                          size: isSmallScreen ? 20.sp : 24.sp,
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Text(
                                            selectedBank?.bankName ?? 'Select Bank',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: selectedBank != null ? lightText : grey,
                                              fontSize: isSmallScreen ? 13.sp : 14.sp,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down, color: grey, size: 24.sp),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                AppField.transparent(
                                  hintText: 'Enter 10-digit Account Number',
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

                                    if (value.length == 10 && selectedBank != null) {
                                      _verifyAccountFromInput(value);
                                    } else {
                                      setState(() => isVerified = false);
                                    }
                                  },
                                ),

                                if (accountError != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 6.h),
                                    child: Text(
                                      accountError!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: errorColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),

                                SizedBox(height: isSmallScreen ? 8.h : 12.h),

                                if (isVerified)
                                  InkWell(
                                    onTap: () => _goToAmountPage(context, verifiedName!, verifiedAccount!),
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(isSmallScreen ? 12.w : 15.w),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: isSmallScreen ? 16.r : 20.r,
                                            backgroundColor: primaryColor,
                                            child: Text(
                                              (verifiedName ?? '').isNotEmpty
                                                  ? verifiedName![0].toUpperCase()
                                                  : '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  verifiedName ?? '',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: isSmallScreen ? 13.sp : 14.sp,
                                                  ),
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(
                                                  '$verifiedBankName • $verifiedAccount',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 6.w),
                                          Icon(
                                            Icons.check_circle,
                                            color: successColor,
                                            size: isSmallScreen ? 18.sp : 20.sp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 16.h : 24.h),

                          if (!isLandscape || constraints.maxHeight > 500)
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: isSmallScreen ? 200.h : 300.h,
                                  minHeight: 100.h,
                                ),
                                child: CardThreeBank(
                                  onSelectBeneficiary: (name, account, bankCode) {
                                    accountController.text = account;
                                    verifiedBankCode = bankCode;
                                    if (banks.isNotEmpty) {
                                      selectedBank = banks.firstWhere(
                                            (b) => b.bankCode == bankCode,
                                        orElse: () =>
                                        selectedBank ?? BankModel(bankCode: bankCode, bankName: ''),
                                      );
                                    } else {
                                      selectedBank = BankModel(bankCode: bankCode, bankName: '');
                                    }
                                    _verifyAccountFromInput(account);
                                  },
                                ),
                              ),
                            ),

                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 12.h,
                    bottom: bottomPadding + 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: offWhiteBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 44.h : 48.h,
                    child: ElevatedButton(
                      onPressed: isVerified
                          ? () => _goToAmountPage(context, verifiedName!, verifiedAccount!)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14.sp : 16.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CardThreeBank extends ConsumerStatefulWidget {
  final Function(String name, String account, String bankCode) onSelectBeneficiary;

  const CardThreeBank({
    super.key,
    required this.onSelectBeneficiary,
  });

  @override
  ConsumerState<CardThreeBank> createState() => _CardThreeBankState();
}

class _CardThreeBankState extends ConsumerState<CardThreeBank> {
  List<Map<String, dynamic>> recentTransfers = [];
  List<Map<String, dynamic>> bankBeneficiaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => isLoading = true);

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final recents = await dashboardCtrl.getRecentBankTransfers(context);
    final beneficiaries = await dashboardCtrl.getBankBeneficiaries(context);

    if (mounted) {
      setState(() {
        recentTransfers = recents;
        bankBeneficiaries = beneficiaries;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          color: whiteBackground,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsingLogoIndicator(
                logoPath: 'assets/svg/logo-b.png',
                size: 40,
                pulseColor: primaryColor,
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading beneficiaries...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: whiteBackground,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: BeneficiaryTabSection(
            favorites: bankBeneficiaries
                .map<Map<String, String>>(
                  (e) => {
                "name": e['name']?.toString() ?? '',
                "account": e['account']?.toString() ?? '',
              },
            )
                .toList(),
            recents: recentTransfers
                .map<Map<String, String>>(
                  (e) => {
                "name": e['name']?.toString() ?? '',
                "account": e['account']?.toString() ?? '',
              },
            )
                .toList(),
            showProgress: true,
            showLogo: true,
            onSelectBeneficiary: (name, account) {
              final selected = [...recentTransfers, ...bankBeneficiaries].firstWhere(
                    (e) => e['account'] == account,
                orElse: () => {},
              );

              if (selected.isNotEmpty) {
                widget.onSelectBeneficiary(
                  name,
                  account,
                  selected['bankCode'],
                );
              }
            },
          ),
        );
      },
    );
  }
}