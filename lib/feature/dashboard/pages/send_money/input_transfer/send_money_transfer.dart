import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_search_field.dart';
import '../../../../../core/easy_loading_config.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../model/favourite_beneficiary.dart';
import '../../../model/recent_transfer.dart';
import '../widget/tabs.dart';

class SendMoneyTransfer extends ConsumerStatefulWidget {
  final int initialIndex;
  const SendMoneyTransfer({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SendMoneyTransfer> createState() => _SendMoneyTransferState();
}

class _SendMoneyTransferState extends ConsumerState<SendMoneyTransfer> {
  int _selectedMethodIndex = 0;

  final TextEditingController accountController = TextEditingController();
  final TextEditingController tagController = TextEditingController();

  String? errorText;
  bool isVerified = false;
  bool isResolving = false;

  String? verifiedName;
  String? verifiedPhone;
  String? verifiedAccount;
  String? verifiedPicture;
  String? verifiedTag;

  @override
  void initState() {
    super.initState();
    _selectedMethodIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    accountController.dispose();
    tagController.dispose();
    super.dispose();
  }

  Future<void> _verifyAccountFromInput(BuildContext context, String accountNumber) async {
    setState(() {
      isResolving = true;
      errorText = null;
      isVerified = false;
    });

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyAccount(context, accountNumber);

    setState(() => isResolving = false);

    if (result?.responseSuccessful == true) {
      final fullname = result?.responseBody?.user?.fullname ?? 'Unknown User';

      setState(() {
        isVerified = true;
        verifiedName = fullname;
        verifiedPhone = accountNumber;
        verifiedAccount = accountNumber;
        verifiedPicture = null;
        verifiedTag = null;
        errorText = null;
      });
    } else {
      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedPhone = null;
        verifiedAccount = null;
        verifiedPicture = null;
        verifiedTag = null;
        errorText = result?.responseMessage ?? "Account not found";
      });
    }
  }

  Future<void> _verifyTagFromInput(BuildContext context, String rawTag) async {
    final cleanTag = rawTag.trim().replaceAll('@', '');
    if (cleanTag.isEmpty) return;

    setState(() {
      isResolving = true;
      errorText = null;
      isVerified = false;
    });

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyTag(context, cleanTag);

    setState(() => isResolving = false);

    if (result?.responseSuccessful == true) {
      final user = result?.responseBody?.user;
      setState(() {
        isVerified = true;
        verifiedName = user?.fullname ?? 'BIA User';
        verifiedPhone = user?.phone ?? '';
        verifiedAccount = cleanTag;
        verifiedPicture = user?.picture;
        verifiedTag = cleanTag;
        errorText = null;
      });
    } else {
      setState(() {
        isVerified = false;
        verifiedName = null;
        verifiedPhone = null;
        verifiedAccount = null;
        verifiedPicture = null;
        verifiedTag = null;
        errorText = result?.responseMessage ?? "Tag not found";
      });
    }
  }

  Future<void> _verifyAccountSilently(BuildContext context, String accountNumber) async {
    setState(() {
      isResolving = true;
      errorText = null;
      isVerified = false;
    });

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final result = await dashboardCtrl.verifyAccount(context, accountNumber);

    setState(() => isResolving = false);

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

  void _clearVerification() {
    setState(() {
      isVerified = false;
      errorText = null;
      verifiedName = null;
      verifiedAccount = null;
      verifiedPhone = null;
      verifiedPicture = null;
      verifiedTag = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 650;
            final isTablet = constraints.maxWidth >= 768;

            final topBar = _buildTopBar(context, theme, isSmall);
            final selectorCard = _buildRecipientSelectorCard(context, theme, isSmall);
            const beneficiariesList = CardThree();

            if (isTablet) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      topBar,
                      SizedBox(height: 24.h),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 10,
                              child: SingleChildScrollView(child: selectorCard),
                            ),
                            SizedBox(width: 48.w),
                            Expanded(
                              flex: 9,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    child: Text(
                                      'Beneficiaries',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: darkBackground,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                      child: beneficiariesList,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topBar,
                    SizedBox(height: isSmall ? 8.h : 16.h),
                    selectorCard,
                    SizedBox(height: isSmall ? 16.h : 24.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        'Beneficiaries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: darkBackground,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: beneficiariesList,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ThemeData theme, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isSmall ? 6.h : 12.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: lightBorderColor.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp,
                color: darkBackground,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Money',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkBackground,
                ),
              ),
              Text(
                'BIA to BIA transfer',
                style: TextStyle(
                  fontSize: 11.sp,
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

  Widget _buildRecipientSelectorCard(BuildContext context, ThemeData theme, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 14.w : 18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Tab Selector
            Container(
              height: 44.h,
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    label: 'Account Number',
                    index: 0,
                    icon: Icons.numbers_rounded,
                  ),
                  SizedBox(width: 4.w),
                  _buildTabButton(
                    label: 'BIA Tag',
                    index: 1,
                    icon: Icons.alternate_email_rounded,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            /// Form Input
            if (_selectedMethodIndex == 0) ...[
              Text(
                'Recipient Account Number',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lightSecondaryText,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              AppField.transparent(
                hintText: 'Enter 10-digit account number',
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
                    errorText = null;
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
            ] else ...[
              Text(
                'Recipient BIA Tag',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lightSecondaryText,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isVerified
                        ? primaryColor.withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 14.w),
                      child: Text(
                        '@',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter BIA Tag',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 14.h,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _verifyTagFromInput(context, value),
                        onChanged: (value) {
                          setState(() {
                            if (errorText != null || isVerified) {
                              errorText = null;
                              isVerified = false;
                            }
                          });
                        },
                      ),
                    ),
                    if (isResolving)
                      Padding(
                        padding: EdgeInsets.only(right: 14.w),
                        child: SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primaryColor,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: tagController.text.trim().isEmpty
                            ? null
                            : () => _verifyTagFromInput(context, tagController.text),
                        child: Container(
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            color: tagController.text.trim().isEmpty
                                ? const Color(0xFFE2E8F0)
                                : primaryColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Verify',
                            style: TextStyle(
                              color: tagController.text.trim().isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            /// Error
            if (errorText != null)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: errorColor, size: 14.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// Verified User Card
            if (isVerified) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: (verifiedPicture != null && verifiedPicture!.isNotEmpty)
                            ? Image.network(verifiedPicture!, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  verifiedName != null && verifiedName!.isNotEmpty
                                      ? verifiedName![0].toUpperCase()
                                      : 'B',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verifiedName ?? '',
                            style: TextStyle(
                              color: darkBackground,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            verifiedTag != null
                                ? '@$verifiedTag'
                                : (verifiedPhone ?? ''),
                            style: TextStyle(
                              color: lightSecondaryText,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _goToAmountPage(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: brandGradient,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isActive = _selectedMethodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedMethodIndex == index) return;
          _clearVerification();
          setState(() => _selectedMethodIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14.sp,
                  color: isActive ? primaryColor : const Color(0xFF94A3B8),
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? primaryColor : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
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
  List<FavouriteBeneficiaryItem> favouriteBeneficiaries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);

    try {
      final recent = await dashboardCtrl.getRecentBeneficiary(context);
      final favourites = await dashboardCtrl.getFavouriteBeneficiary(context);

      if (!mounted) return;

      setState(() {
        recentBeneficiaries = recent;
        favouriteBeneficiaries = favourites;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: PulsingLogoIndicator(
            logoPath: 'assets/svg/logo-b.png',
            size: 40,
            pulseColor: primaryColor,
          ),
        ),
      );
    }

    if (recentBeneficiaries.isEmpty && favouriteBeneficiaries.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 40.sp, color: lightBorderColor),
              SizedBox(height: 10.h),
              Text(
                "No beneficiaries yet",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: lightSecondaryText,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: BeneficiaryTabSection(
        recents: favouriteBeneficiaries
            .map((r) => {
                  "name": r.name,
                  "account": r.phone,
                })
            .toList(),
        favorites: recentBeneficiaries
            .map((r) => {
                  "name": r.fullname,
                  "account": r.phone,
                })
            .toList(),
        showLogo: true,
        showProgress: false,
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