  import 'package:bia/core/__core.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
  import 'package:flutter_svg/svg.dart';
  import 'package:go_router/go_router.dart';
  import '../../../../../app/utils/image.dart';
  import '../../../../../app/view/widget/quick_access_app_bar.dart';

  class CableTvSimpleSkeleton extends StatelessWidget {
    const CableTvSimpleSkeleton({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: lightBackground,
        appBar: CustomAppBar(
          title: 'TV Cable',
          onBackPressed: () async {
            FocusScope.of(context).unfocus();
            await Future.delayed(Duration(milliseconds: 150));
            if (!context.mounted) return;
            if (context.canPop()) {
              context.pop();
            }
          },
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 18.w),
              child: SvgPicture.asset(bell),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Card Skeleton
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16.r)),
                      color: Colors.grey.shade200,
                    ),
                    child: Column(
                      children: [
                        // Provider Dropdown + Input Row
                        Row(
                          children: [
                            Container(
                              width: 140.w,
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Container(
                                height: 48.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Container(width: double.infinity, height: 1.h, color: Colors.grey.shade300),
                        SizedBox(height: 24.h),
                        // Tab Bar Skeleton
                        Row(
                          children: [
                            _buildSimpleTab(80.w),
                            SizedBox(width: 12.w),
                            _buildSimpleTab(80.w),
                            SizedBox(width: 12.w),
                            _buildSimpleTab(80.w),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Grid Cards Skeleton
                        MasonryGridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.h,
                          crossAxisSpacing: 16.w,
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return Container(
                              height: index.isEven ? 250.h : 290.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildSimpleTab(double width) {
      return Container(
        width: width,
        height: 32.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
        ),
      );
    }
  }