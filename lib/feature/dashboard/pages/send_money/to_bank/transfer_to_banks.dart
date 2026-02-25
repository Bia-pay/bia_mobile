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
import '../../../model/bank_model.dart';
import '../../../model/favourite_beneficiary.dart';
import '../../../model/recent_transfer.dart';
import '../widget/tabs.dart';

class SendMoneyToBank extends ConsumerStatefulWidget {
  const SendMoneyToBank({super.key});

  @override
  ConsumerState<SendMoneyToBank> createState() => _SendMoneyToBankState();
}

class _SendMoneyToBankState extends ConsumerState<SendMoneyToBank> {
  final TextEditingController accountController = TextEditingController();

  BankModel? selectedBank;
  List<BankModel> banks = [];
  List<BankModel> filteredBanks = []; // For search
  bool isLoadingBanks = true;

  // Verification state (same pattern as your Bia-to-Bia)
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
    _loadBankBeneficiaries(); // ✅ THIS WAS MISSING
  }

  Future<void> _loadBankBeneficiaries() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    final recents =
    await dashboardCtrl.getRecentBankTransfers(context);

    final beneficiaries =
    await dashboardCtrl.getBankBeneficiaries(context);

    setState(() {
      recentBankTransfers = recents;
      bankBeneficiaries = beneficiaries;
      isLoadingBeneficiaries = false;
    });
  }

  Future<void> _loadBanks() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final loadedBanks = await dashboardCtrl.getBanks(context);
    setState(() {
      banks = loadedBanks;
      filteredBanks = loadedBanks; // Initialize filtered list
      isLoadingBanks = false;
    });
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredBanks = banks;
      } else {
        filteredBanks = banks
            .where((bank) =>
        bank.bankName.toLowerCase().contains(query.toLowerCase()) ||
            bank.bankCode.contains(query))
            .toList();
      }
    });
  }

  Future<void> _verifyAccountFromInput(String accountNumber) async {
    if (selectedBank == null) {
      // Show bank selector first if no bank selected
      _showBankSelector();
      return;
    }

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyBankAccount(
      context,
      accountNumber: accountNumber.trim(),
      bankCode: selectedBank!.bankCode,
    );

    if (result?.responseSuccessful == true && result?.responseBody != null) {
      setState(() {
        isVerified = true;
        verifiedName = result?.responseBody?.accountName;
        verifiedAccount = result?.responseBody?.accountNumber;
        verifiedBankCode = selectedBank?.bankCode;
        verifiedBankName = selectedBank?.bankName;
      });
    } else {
      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedAccount = null;
        verifiedBankCode = null;
        verifiedBankName = null;
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
    // Reset filtered list when opening
    setState(() {
      filteredBanks = banks;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: lightSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: lightBorderColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Text(
                    'Select Bank',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 🔍 Search Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: lightBorderColor),
                    ),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search banks...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
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
                ),

                SizedBox(height: 10.h),

                // Bank List
                Expanded(
                  child: isLoadingBanks
                      ? Center(child: CircularProgressIndicator())
                      : filteredBanks.isEmpty
                      ? Center(
                    child: Text(
                      'No banks found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: filteredBanks.length,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemBuilder: (context, index) {
                      final bank = filteredBanks[index];
                      final isSelected = selectedBank?.bankCode == bank.bankCode;

                      return ListTile(
                        leading: Icon(
                          Icons.account_balance,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        title: Text(
                          bank.bankName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? primaryColor : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: primaryColor)
                            : null,
                        onTap: () {
                          setState(() => selectedBank = bank);
                          Navigator.pop(context);
                          // Auto-verify if account already entered
                          if (accountController.text.length == 10) {
                            _verifyAccountFromInput(accountController.text);
                          }
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header (YOUR ORIGINAL)
              CustomHeader(
                title: 'Transfer to Bank',
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 20.h),
              /// 🔹 Section Title (YOUR ORIGINAL)

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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: lightText,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    /// 🔹 Bank Selector (ADDED - but styled to match your design)
                    InkWell(
                      onTap: _showBankSelector,
                      child: Container(
                        width: double.infinity,
                        height: 60.h,
                        margin: EdgeInsets.only(bottom: 15.h),
                        decoration: BoxDecoration(
                          color: whiteBackground,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: lightBorderColor),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance, color: primaryColor),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                selectedBank?.bankName ?? 'Select Bank',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: selectedBank != null ? lightText : Colors.grey,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
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
                        if (value.length == 10 && selectedBank != null) {
                          _verifyAccountFromInput(value);
                        } else {
                          setState(() => isVerified = false);
                        }
                      },
                    ),   SizedBox(height: 10.h),
                    /// 🔹 Verification Result (YOUR PATTERN - matching Bia-to-Bia style)
                    if (isVerified)
                      InkWell(
                        onTap: () => _goToAmountPage(context, verifiedName!, verifiedAccount!),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: EdgeInsets.all(15.w),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor,
                                child: Text(
                                  (verifiedName ?? '')[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verifiedName ?? '',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${verifiedBankName} • ${verifiedAccount}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),


              SizedBox(height: 30.h),

              /// 🔹 Beneficiary Section (YOUR ORIGINAL - takes remaining space)
              Expanded(
                child: CardThreeBank(
                  onSelectBeneficiary: (name, account, bankCode) {
                    accountController.text = account;

                    verifiedBankCode = bankCode;

                    selectedBank = banks.firstWhere(
                          (b) => b.bankCode == bankCode,
                      orElse: () => selectedBank ?? banks.first,
                    );

                    _verifyAccountFromInput(account);
                  },
                ),
              ),

              SizedBox(height: 20.h),

              /// 🔹 Continue Button (YOUR ORIGINAL)
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isVerified
                      ? () => _goToAmountPage(context, verifiedName!, verifiedAccount!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardThreeBank extends ConsumerStatefulWidget {
  final Function(String name, String account, String bankCode)
  onSelectBeneficiary;

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
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    final recents =
    await dashboardCtrl.getRecentBankTransfers(context);

    final beneficiaries =
    await dashboardCtrl.getBankBeneficiaries(context);

    setState(() {
      recentTransfers = recents;
      bankBeneficiaries = beneficiaries;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: whiteBackground,
        borderRadius: BorderRadius.circular(15.r),
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
        showProgress: true, // 👈 bank has network indicator
        showLogo: true,
        onSelectBeneficiary: (name, account) {
          final selected = [
            ...recentTransfers,
            ...bankBeneficiaries
          ].firstWhere(
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
  }
}