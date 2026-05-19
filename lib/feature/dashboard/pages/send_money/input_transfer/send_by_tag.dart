import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/view/widget/app_bar.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';

class SendByTag extends ConsumerStatefulWidget {
  const SendByTag({super.key});

  @override
  ConsumerState<SendByTag> createState() => _SendByTagState();
}

class _SendByTagState extends ConsumerState<SendByTag> {
  final TextEditingController _tagController = TextEditingController();
  bool _isResolving = false;
  bool _isVerified = false;
  String? _resolvedName;
  String? _resolvedPhone;
  String? _resolvedPicture;
  String? _resolvedTag;
  String? _tagError;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _resolveTag(BuildContext context, String tag) async {
    if (tag.isEmpty) return;
    
    setState(() {
      _isResolving = true;
      _tagError = null;
      _isVerified = false;
    });

    final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
    final cleanTag = tag.trim().replaceAll('@', '');
    
    final result = await dashboardCtrl.verifyTag(context, cleanTag);

    setState(() {
      _isResolving = false;
    });

    if (result?.responseSuccessful == true) {
      final user = result?.responseBody?.user;
      setState(() {
        _isVerified = true;
        _resolvedName = user?.fullname ?? 'BIA User';
        _resolvedPhone = user?.phone ?? '';
        _resolvedPicture = user?.picture;
        _resolvedTag = cleanTag;
        _tagError = null;
      });
    } else {
      setState(() {
        _isVerified = false;
        _resolvedName = null;
        _resolvedPhone = null;
        _resolvedPicture = null;
        _resolvedTag = null;
        _tagError = result?.responseMessage ?? "Tag not found";
      });
    }
  }

  void _goToAmountPage(BuildContext context) {
    if (!_isVerified || _resolvedName == null || _resolvedPhone == null) return;

    context.pushNamed(
      RouteList.amountPage,
      extra: {
        'recipientName': _resolvedName,
        'recipientAccount': _resolvedPhone,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomHeader(
                  title: 'Send by BIA Tag',
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: 24.h),

                // Top visual banner/card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alternate_email_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Instant Tag Transfers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Send money directly to other BIA wallets using just their unique username or BIA tag.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                SizedBox(height: 24.h),

                // Tag input card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient BIA Tag',
                        style: TextStyle(
                          color: const Color(0xFF1E293B),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: _isVerified
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
                                controller: _tagController,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'enter_tag',
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
                                onSubmitted: (value) => _resolveTag(context, value),
                                onChanged: (value) {
                                  setState(() {
                                    if (_tagError != null || _isVerified) {
                                      _tagError = null;
                                      _isVerified = false;
                                    }
                                  });
                                },
                              ),
                            ),
                            if (_isResolving)
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
                                onTap: _tagController.text.trim().isEmpty
                                    ? null
                                    : () => _resolveTag(context, _tagController.text),
                                child: Container(
                                  margin: EdgeInsets.only(right: 8.w),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 9.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _tagController.text.trim().isEmpty
                                        ? const Color(0xFFE2E8F0)
                                        : primaryColor,
                                    borderRadius: BorderRadius.circular(10.r),
                                    boxShadow: _tagController.text.trim().isEmpty
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                  ),
                                  child: Text(
                                    'Verify',
                                    style: TextStyle(
                                      color: _tagController.text.trim().isEmpty
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
                      
                      if (_tagError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 10.h, left: 4.w),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: errorColor, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text(
                                _tagError!,
                                style: TextStyle(
                                  color: errorColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),

                // Resolved profile panel
                if (_isVerified) ...[
                  SizedBox(height: 24.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58.r,
                              height: 58.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _resolvedPicture != null && _resolvedPicture!.isNotEmpty
                                    ? Image.network(
                                        _resolvedPicture!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.person,
                                          size: 28.sp,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 28.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _resolvedName ?? '',
                                    style: TextStyle(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    '@${_resolvedTag ?? ""}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20.h),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        SizedBox(height: 20.h),
                        
                        CustomButton(
                          buttonName: 'PROCEED TO TRANSFER',
                          buttonColor: primaryColor,
                          buttonTextColor: Colors.white,
                          onPressed: () => _goToAmountPage(context),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.98, 0.98)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
