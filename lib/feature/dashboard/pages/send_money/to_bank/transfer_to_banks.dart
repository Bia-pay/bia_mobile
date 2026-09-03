import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../model/bank_model.dart';
import '../../../../../app/utils/custom_loader.dart';
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
  List<BankModel> suggestedBanks = [];
  bool isLoadingBanks = true;
  String? accountError;

  bool isBankDropdownOpen = false;
  final TextEditingController bankSearchController = TextEditingController();

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
    bankSearchController.dispose();
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

    // Sort banks A-Z
    loadedBanks.sort((a, b) => a.bankName.toLowerCase().compareTo(b.bankName.toLowerCase()));

    // Filter popular/suggested banks
    final popularKeys = ['opay', 'moniepoint', 'palmpay', 'kuda', 'access', 'gtbank', 'guaranty trust', 'zenith', 'uba', 'united bank', 'first bank'];
    final matched = <String, BankModel>{};
    for (final key in popularKeys) {
      for (final bank in loadedBanks) {
        final name = bank.bankName.toLowerCase();
        if (name.contains(key)) {
          matched[bank.bankCode] = bank;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        banks = loadedBanks;
        filteredBanks = loadedBanks;
        suggestedBanks = matched.values.toList();
        isLoadingBanks = false;
      });
    }
  }

  Future<void> _verifyAccountFromInput(String accountNumber) async {
    final effectiveBankCode = selectedBank?.bankCode ?? verifiedBankCode;
    final effectiveBankName = selectedBank?.bankName ?? verifiedBankName;

    if (effectiveBankCode == null || effectiveBankCode.isEmpty) {
      setState(() => isBankDropdownOpen = true);
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
                    _buildSuggestedBanksGrid(context, setModalState),
                    Expanded(
                      child: isLoadingBanks
                          ? const Center(child: CustomLoader(color: primaryColor))
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
                            leading: bank.logoUrl != null && bank.logoUrl!.isNotEmpty
                                ? Container(
                                    width: 32.r,
                                    height: 32.r,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        bank.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.account_balance,
                                          color: isSelected ? primaryColor : grey,
                                          size: 24.sp,
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(
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

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isSmallScreen = constraints.maxHeight < 600;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            final isSmall = constraints.maxHeight < 650;
            final topBar = _buildTopBar(context, theme, isSmall);
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 20.w,
                      vertical: isTablet ? 16.0 : 16.h,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 640 : double.infinity,
                          minHeight: constraints.maxHeight - bottomPadding - (isTablet ? 90.0 : 100.h),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            topBar,
                            SizedBox(height: isTablet ? 12.0 : (isSmall ? 8.h : 16.h)),
                            SizedBox(height: isTablet ? 12.0 : (isSmallScreen ? 12.h : 20.h)),

                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isTablet ? 16.0 : (isSmallScreen ? 12.w : 16.w)),
                              decoration: BoxDecoration(
                                color: whiteBackground,
                                borderRadius: BorderRadius.circular(isTablet ? 16.0 : 15.r),
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
                                      fontSize: isTablet ? 15.0 : (isSmallScreen ? 14.sp : 16.sp),
                                    ),
                                  ),
                                SizedBox(height: isSmallScreen ? 10.h : 15.h),

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
                                    accountController.text = value;
                                    setState(() {
                                      accountError = null;
                                    });

                                    if (value.length == 10) {
                                      if (selectedBank != null) {
                                        _verifyAccountFromInput(value);
                                      } else {
                                        _showBankSelector();
                                      }
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

                                _buildSuggestedBanksRow(),

                                SizedBox(height: 12.h),

                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      isBankDropdownOpen = !isBankDropdownOpen;
                                      if (isBankDropdownOpen) {
                                        filteredBanks = banks;
                                        bankSearchController.clear();
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12.0 : 12.w,
                                      vertical: isTablet ? 12.0 : (isSmallScreen ? 10.h : 12.h),
                                    ),
                                    decoration: BoxDecoration(
                                      color: whiteBackground,
                                      borderRadius: BorderRadius.circular(isTablet ? 10.0 : 10.r),
                                      border: Border.all(color: isBankDropdownOpen ? primaryColor : lightBorderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        selectedBank?.logoUrl != null && selectedBank!.logoUrl!.isNotEmpty
                                            ? Container(
                                                width: isTablet ? 22.0 : (isSmallScreen ? 20.r : 24.r),
                                                height: isTablet ? 22.0 : (isSmallScreen ? 20.r : 24.r),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: ClipOval(
                                                  child: Image.network(
                                                    selectedBank!.logoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Icon(
                                                      Icons.account_balance,
                                                      color: primaryColor,
                                                      size: isTablet ? 20.0 : (isSmallScreen ? 20.sp : 24.sp),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.account_balance,
                                                color: primaryColor,
                                                size: isTablet ? 20.0 : (isSmallScreen ? 20.sp : 24.sp),
                                              ),
                                        SizedBox(width: isTablet ? 10.0 : 10.w),
                                        Expanded(
                                          child: Text(
                                            selectedBank?.bankName ?? 'Select Bank',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: selectedBank != null ? lightText : grey,
                                              fontSize: isTablet ? 14.0 : (isSmallScreen ? 13.sp : 14.sp),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          isBankDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                          color: grey,
                                          size: isTablet ? 22.0 : 24.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // --- Inline Searchable Dropdown ---
                                if (isBankDropdownOpen) ...[
                                  SizedBox(height: 8.h),
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 250.h),
                                    decoration: BoxDecoration(
                                      color: whiteBackground,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: lightBorderColor),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Inline Search Bar
                                        Padding(
                                          padding: EdgeInsets.all(8.w),
                                          child: TextField(
                                            controller: bankSearchController,
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: 'Search bank...',
                                              prefixIcon: const Icon(Icons.search, size: 20),
                                              filled: true,
                                              fillColor: grey100,
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8.r),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                if (value.isEmpty) {
                                                  filteredBanks = banks;
                                                } else {
                                                  filteredBanks = banks
                                                      .where((b) => b.bankName.toLowerCase().contains(value.toLowerCase()))
                                                      .toList();
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        // Bank List
                                        Expanded(
                                          child: isLoadingBanks
                                              ? const Center(child: CustomLoader(color: primaryColor))
                                              : ListView.separated(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: filteredBanks.length,
                                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
                                                  itemBuilder: (context, index) {
                                                    final bank = filteredBanks[index];
                                                    final isCurrentSelected = selectedBank?.bankCode == bank.bankCode;
                                                    return ListTile(
                                                      dense: true,
                                                      leading: bank.logoUrl != null && bank.logoUrl!.isNotEmpty
                                                          ? Container(
                                                              width: 24.r,
                                                              height: 24.r,
                                                              decoration: const BoxDecoration(
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: ClipOval(
                                                                child: Image.network(
                                                                  bank.logoUrl!,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (_, __, ___) => Icon(
                                                                    Icons.account_balance,
                                                                    color: isCurrentSelected ? primaryColor : grey,
                                                                    size: 16.sp,
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          : Icon(
                                                              Icons.account_balance,
                                                              color: isCurrentSelected ? primaryColor : grey,
                                                              size: 16.sp,
                                                            ),
                                                      title: Text(
                                                        bank.bankName,
                                                        style: TextStyle(
                                                          fontSize: 13.sp,
                                                          color: darkBackground,
                                                          fontWeight: isCurrentSelected ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          selectedBank = bank;
                                                          isBankDropdownOpen = false;
                                                          bankSearchController.clear();
                                                        });
                                                        if (accountController.text.length == 10) {
                                                          _verifyAccountFromInput(accountController.text);
                                                        }
                                                      },
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(height: isSmallScreen ? 8.h : 12.h),

                                if (isVerified)
                                  InkWell(
                                    onTap: () => _goToAmountPage(context, verifiedName!, verifiedAccount!),
                                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(isTablet ? 14.0 : (isSmallScreen ? 12.w : 15.w)),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                                        border: Border.all(
                                          color: primaryColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: isTablet ? 20.0 : (isSmallScreen ? 16.r : 20.r),
                                            backgroundColor: primaryColor,
                                            child: Text(
                                              (verifiedName ?? '').isNotEmpty
                                                  ? verifiedName![0].toUpperCase()
                                                  : '',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isTablet ? 13.0 : (isSmallScreen ? 12.sp : 14.sp),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 12.0 : 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  verifiedName ?? '',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: isTablet ? 15.0 : (isSmallScreen ? 13.sp : 14.sp),
                                                  ),
                                                ),
                                                SizedBox(height: isTablet ? 2.0 : 2.h),
                                                Text(
                                                  '$verifiedBankName • $verifiedAccount',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: isTablet ? 12.0 : 11.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 8.0 : 6.w),
                                          Icon(
                                            Icons.check_circle,
                                            color: successColor,
                                            size: isTablet ? 22.0 : (isSmallScreen ? 18.sp : 20.sp),
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
                            ),                          SizedBox(height: isTablet ? 24.0 : 80.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: isTablet ? 24.0 : 20.w,
                  right: isTablet ? 24.0 : 20.w,
                  top: isTablet ? 12.0 : 12.h,
                  bottom: bottomPadding + (isTablet ? 12.0 : 12.h),
                ),
                decoration: BoxDecoration(
                  color: offWhiteBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
                    child: SizedBox(
                      width: double.infinity,
                      height: isTablet ? 48.0 : (isSmallScreen ? 44.h : 48.h),
                      child: ElevatedButton(
                        onPressed: isVerified
                            ? () => _goToAmountPage(context, verifiedName!, verifiedAccount!)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 12.h),
                        ),
                        child: Text(
                          'Continue',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 15.0 : (isSmallScreen ? 14.sp : 16.sp),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  String _getShortBankName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.contains('access')) return 'Access';
    if (lower.contains('guaranty') || lower.contains('gtbank') || lower.contains('gtb')) return 'GTBank';
    if (lower.contains('zenith')) return 'Zenith';
    if (lower.contains('united bank') || lower.contains('uba')) return 'UBA';
    if (lower.contains('first bank') || lower.contains('fbn')) return 'First Bank';
    if (lower.contains('kuda')) return 'Kuda';
    if (lower.contains('opay')) return 'OPay';
    if (lower.contains('moniepoint')) return 'Moniepoint';
    if (lower.contains('palmpay')) return 'PalmPay';
    if (lower.contains('union')) return 'Union';
    if (lower.contains('wema')) return 'Wema';
    if (lower.contains('polaris')) return 'Polaris';
    if (lower.contains('stanbic')) return 'Stanbic';
    if (lower.contains('fidelity')) return 'Fidelity';
    if (lower.contains('sterling')) return 'Sterling';
    return fullName.split(' ')[0];
  }

  Widget _buildSuggestedBanksRow() {
    if (suggestedBanks.isEmpty) return const SizedBox.shrink();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isTablet ? 8.0 : 8.h, bottom: isTablet ? 6.0 : 6.h),
          child: Text(
            'Suggested Banks',
            style: TextStyle(
              fontSize: isTablet ? 12.0 : 12.sp,
              fontWeight: FontWeight.w600,
              color: grey,
            ),
          ),
        ),
        SizedBox(
          height: isTablet ? 38.0 : 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suggestedBanks.length,
            itemBuilder: (context, index) {
              final bank = suggestedBanks[index];
              final isSelected = selectedBank?.bankCode == bank.bankCode;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBank = bank;
                    isBankDropdownOpen = false;
                  });
                  if (accountController.text.length == 10) {
                    _verifyAccountFromInput(accountController.text);
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: isTablet ? 8.0 : 8.w),
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 10.0 : 10.w),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : whiteBackground,
                    borderRadius: BorderRadius.circular(isTablet ? 18.0 : 20.r),
                    border: Border.all(
                      color: isSelected ? primaryColor : lightBorderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bank.logoUrl != null && bank.logoUrl!.isNotEmpty) ...[
                        ClipOval(
                          child: Image.network(
                            bank.logoUrl!,
                            width: isTablet ? 18.0 : 18.r,
                            height: isTablet ? 18.0 : 18.r,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance,
                              color: isSelected ? primaryColor : grey,
                              size: isTablet ? 14.0 : 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 4.0 : 4.w),
                      ],
                      Text(
                        _getShortBankName(bank.bankName),
                        style: TextStyle(
                          fontSize: isTablet ? 11.0 : 11.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryColor : lightText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedBanksGrid(BuildContext context, StateSetter setModalState) {
    if (suggestedBanks.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Banks',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: grey,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: suggestedBanks.map((bank) {
              final isSelected = selectedBank?.bankCode == bank.bankCode;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedBank = bank);
                  setModalState(() {});
                  Navigator.pop(context);
                  if (accountController.text.length == 10) {
                    _verifyAccountFromInput(accountController.text);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : grey100,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bank.logoUrl != null && bank.logoUrl!.isNotEmpty) ...[
                        ClipOval(
                          child: Image.network(
                            bank.logoUrl!,
                            width: 16.r,
                            height: 16.r,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.account_balance,
                              color: isSelected ? primaryColor : grey,
                              size: 12.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        _getShortBankName(bank.bankName),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryColor : darkBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8.h),
          const Divider(color: lightBorderColor),
        ],
      ),
    );
  }

}
Widget _buildTopBar(BuildContext context, ThemeData theme, bool isSmall) {
  final isTablet = MediaQuery.of(context).size.width > 600;

  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 16.0 : 16.w,
      vertical: isTablet ? 10.0 : (isSmall ? 6.h : 12.h),
    ),
    child: Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 10.0 : 10.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
              border: Border.all(
                color: lightBorderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: isTablet ? 16.0 : 16.sp,
              color: darkBackground,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 14.0 : 14.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Money',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: darkBackground,
                fontSize: isTablet ? 16.0 : null,
              ),
            ),
            Text(
              'BIA to Bank transfer',
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 11.sp,
                color: lightSecondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
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
  List<BankModel> banks = [];
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
    final banksList = await dashboardCtrl.getBanks(context);

    if (mounted) {
      setState(() {
        recentTransfers = recents;
        bankBeneficiaries = beneficiaries;
        banks = banksList;
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
                  (e) {
                    final bCode = e['bankCode']?.toString() ?? '';
                    final matchingBank = banks.firstWhere(
                      (b) => b.bankCode == bCode,
                      orElse: () => BankModel(bankCode: '', bankName: ''),
                    );
                    return {
                      "name": e['name']?.toString() ?? '',
                      "account": e['account']?.toString() ?? '',
                      "logoUrl": matchingBank.logoUrl ?? '',
                    };
                  },
                )
                .toList(),
            recents: recentTransfers
                .map<Map<String, String>>(
                  (e) {
                    final bCode = e['bankCode']?.toString() ?? '';
                    final matchingBank = banks.firstWhere(
                      (b) => b.bankCode == bCode,
                      orElse: () => BankModel(bankCode: '', bankName: ''),
                    );
                    return {
                      "name": e['name']?.toString() ?? '',
                      "account": e['account']?.toString() ?? '',
                      "logoUrl": matchingBank.logoUrl ?? '',
                    };
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