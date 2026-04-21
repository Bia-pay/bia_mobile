import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../dashboardcontroller/notification_notifier.dart';
import '../model/notification_model.dart';
import '../../../../app/utils/colors.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  String _selectedFilter = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);

    // Filter notifications locally
    final filteredNotifications = _selectedFilter == 'All'
        ? state.notifications
        : state.notifications.where((n) => !n.isRead).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
          color: primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(theme, state),
              _buildFilters(),
              if (state.isLoading && state.notifications.isEmpty)
                _buildShimmerList()
              else if (filteredNotifications.isEmpty)
                _buildEmptyState(theme)
              else
                _buildNotificationList(filteredNotifications),
              if (state.isLoadMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(child: CircularProgressIndicator(color: primaryColor)),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 30.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, NotificationState state) {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leadingWidth: 70.w,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade50,
          ),
          child: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: accentColor),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (state.notifications.any((n) => !n.isRead))
          TextButton(
            onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
            child: Text(
              "Mark all as read",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13.sp),
            ),
          ),
        SizedBox(width: 10.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 24.w, bottom: 16.h),
        title: Text(
          "Notifications",
          style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 22.sp),
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: ['All', 'Has Unread'].map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : accentColor.withOpacity(0.6),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items) {
    // Group items by date
    final Map<String, List<NotificationItem>> grouped = {};
    for (var item in items) {
      final dateStr = _getDateLabel(item.createdAt);
      grouped.putIfAbsent(dateStr, () => []).add(item);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final groupKey = grouped.keys.elementAt(index);
          final groupItems = grouped[groupKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
                child: Text(
                  groupKey,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.4),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...groupItems.map((n) => _NotificationTile(
                    item: n,
                    onTap: () => ref.read(notificationNotifierProvider.notifier).markAsRead(n.id),
                  )),
            ],
          );
        },
        childCount: grouped.length,
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "TODAY";
    if (checkDate == yesterday) return "YESTERDAY";
    return DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
  }

  Widget _buildShimmerList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[100]!,
          highlightColor: Colors.white,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            height: 90.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
          ),
        ),
        childCount: 6,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 120.r,
            width: 120.r,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.05)),
            child: Icon(Icons.notifications_none_rounded, size: 50.sp, color: primaryColor.withOpacity(0.3)),
          ),
          SizedBox(height: 24.h),
          Text(
            "All caught up!",
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            "You have no new notifications at the moment.",
            textAlign: TextAlign.center,
            style: TextStyle(color: accentColor.withOpacity(0.5), fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: item.isRead ? Colors.grey.shade100 : primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: item.isRead ? Colors.grey.shade50 : primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(item.title),
                color: item.isRead ? accentColor.withOpacity(0.3) : primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: primaryColor),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.message,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.6),
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    DateFormat('hh:mm a').format(item.createdAt),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.3),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
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

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('money') || t.contains('credit') || t.contains('received')) return Icons.account_balance_wallet_rounded;
    if (t.contains('transfer') || t.contains('debit') || t.contains('sent')) return Icons.send_rounded;
    if (t.contains('security') || t.contains('login')) return Icons.security_rounded;
    return Icons.notifications_active_rounded;
  }
}