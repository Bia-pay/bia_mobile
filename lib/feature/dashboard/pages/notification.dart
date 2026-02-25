import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() =>
      _NotificationPageState();
}

class _NotificationPageState
    extends ConsumerState<NotificationPage> {

  final List<Map<String, dynamic>> notifications = [
    {
      "title": "Wallet Credited",
      "message": "₦20,000 has been added to your wallet.",
      "time": "2 mins ago",
      "isRead": false,
    },
    {
      "title": "Transfer Successful",
      "message": "You sent ₦5,000 to John Doe.",
      "time": "1 hour ago",
      "isRead": true,
    },
  ];

  void markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n["isRead"] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final horizontalPadding =
    size.width < 400 ? 16.w : 24.w;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            child: Column(
              children: [

                /// 🔹 HEADER
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20.h,
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                context.pop(),
                            child: Icon(
                              Icons
                                  .arrow_back_ios_new,
                              size: size.width <
                                  380
                                  ? 14.sp
                                  : 16.sp,
                            ),
                          ),
                          SizedBox(width: 36.w),
                          Text(
                            "Notifications",
                            style: theme
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .w700,
                              fontSize:
                              size.width <
                                  380
                                  ? 18.sp
                                  : 20.sp,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: markAllAsRead,
                        child: Text(
                          "Mark all",
                          style: theme
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color:
                            Colors.blue,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🔹 BODY
                Expanded(
                  child: notifications.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal:
                      horizontalPadding,
                    ),
                    itemCount:
                    notifications.length,
                    itemBuilder:
                        (context, index) {
                      final item =
                      notifications[
                      index];
                      final isRead =
                      item["isRead"];

                      return Container(
                        margin:
                        EdgeInsets.only(
                            bottom:
                            16.h),
                        padding:
                        EdgeInsets.all(
                            18.w),
                        decoration:
                        BoxDecoration(
                          color: isRead
                              ? Colors.white
                              : Colors.blue
                              .withOpacity(
                              .05),
                          borderRadius:
                          BorderRadius
                              .circular(
                              20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                  .03),
                              blurRadius: 20,
                              offset:
                              const Offset(
                                  0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [

                            /// ICON
                            Container(
                              height: size.width <
                                  380
                                  ? 40.w
                                  : 46.w,
                              width: size.width <
                                  380
                                  ? 40.w
                                  : 46.w,
                              decoration:
                              BoxDecoration(
                                shape: BoxShape
                                    .circle,
                                color: isRead
                                    ? Colors
                                    .grey
                                    .shade200
                                    : Colors
                                    .blue
                                    .withOpacity(
                                    .15),
                              ),
                              child: Icon(
                                Icons
                                    .notifications,
                                size: 20.sp,
                                color: isRead
                                    ? Colors
                                    .grey
                                    : Colors
                                    .blue,
                              ),
                            ),

                            SizedBox(width: 14.w),

                            /// CONTENT
                            Expanded(
                              child:
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                        Text(
                                          item[
                                          "title"],
                                          style: theme
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          height:
                                          8.w,
                                          width:
                                          8.w,
                                          decoration:
                                          const BoxDecoration(
                                            shape:
                                            BoxShape.circle,
                                            color:
                                            Colors.blue,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                      6.h),
                                  Text(
                                    item[
                                    "message"],
                                    style: theme
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                      10.h),
                                  Text(
                                    item[
                                    "time"],
                                    style: theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

/// 🔹 EMPTY STATE
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 40.w),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: size.width < 380
                    ? 60.sp
                    : 70.sp,
                color: Colors.grey),
            SizedBox(height: 20.h),
            Text(
              "No notifications yet",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              "When you receive notifications, they will appear here.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}