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
    final isTablet = MediaQuery.of(context).size.width >= 600;

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
              _buildTopHeader(theme, state, isTablet),
              _buildFilters(isTablet),
              if (state.isLoading && state.notifications.isEmpty)
                _buildShimmerList(isTablet)
              else if (filteredNotifications.isEmpty)
                _buildEmptyState(theme, isTablet)
              else
                _buildNotificationList(filteredNotifications, isTablet),
              if (state.isLoadMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20.0 : 20.h),
                    child: const Center(child: CircularProgressIndicator(color: primaryColor)),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: isTablet ? 30.0 : 30.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(ThemeData theme, NotificationState state, bool isTablet) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.0 : 20.w,
              vertical: isTablet ? 12.0 : 12.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 10.0 : 10.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200, width: 0.8),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: isTablet ? 16.0 : 16.sp,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (state.notifications.any((n) => !n.isRead))
                      TextButton(
                        onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Mark all as read",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 15.0 : 14.sp,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isTablet ? 16.0 : 14.h),
                Text(
                  "Notifications",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 30.0 : 26.sp,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isTablet) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.0 : 24.w,
              vertical: isTablet ? 12.0 : 12.h,
            ),
            child: Row(
              children: ['All', 'Has Unread'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: isTablet ? 12.0 : 12.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20.0 : 20.w,
                      vertical: isTablet ? 10.0 : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : accentColor.withOpacity(0.6),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: isTablet ? 13.0 : 13.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items, bool isTablet) {
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
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 24.0 : 24.w,
                      isTablet ? 20.0 : 24.h,
                      isTablet ? 24.0 : 24.w,
                      isTablet ? 10.0 : 12.h,
                    ),
                    child: Text(
                      groupKey,
                      style: TextStyle(
                        color: accentColor.withOpacity(0.4),
                        fontWeight: FontWeight.w800,
                        fontSize: isTablet ? 12.0 : 12.sp,
                        letterSpacing: 1.2,
                      ),
                    ),
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

  Widget _buildShimmerList(bool isTablet) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[100]!,
              highlightColor: Colors.white,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 24.w,
                  vertical: isTablet ? 8.0 : 8.h,
                ),
                height: isTablet ? 90.0 : 90.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
                ),
              ),
            ),
          ),
        ),
        childCount: 6,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isTablet) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: isTablet ? 100.0 : 120.r,
                width: isTablet ? 100.0 : 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.05),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: isTablet ? 44.0 : 50.sp,
                  color: primaryColor.withOpacity(0.3),
                ),
              ),
              SizedBox(height: isTablet ? 20.0 : 24.h),
              Text(
                "All caught up!",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 18.0 : 18.sp,
                ),
              ),
              SizedBox(height: isTablet ? 8.0 : 8.h),
              Text(
                "You have no new notifications at the moment.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor.withOpacity(0.5),
                  fontSize: isTablet ? 13.0 : 13.sp,
                ),
              ),
            ],
          ),
        ),
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
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.0 : 20.w,
              vertical: isTablet ? 6.0 : 6.h,
            ),
            padding: EdgeInsets.all(isTablet ? 16.0 : 16.r),
            decoration: BoxDecoration(
              color: item.isRead ? Colors.white : primaryColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
              border: Border.all(
                color: item.isRead ? Colors.grey.shade100 : primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 10.0 : 10.r),
                  decoration: BoxDecoration(
                    color: item.isRead ? Colors.grey.shade50 : primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(item.title),
                    color: item.isRead ? accentColor.withOpacity(0.3) : primaryColor,
                    size: isTablet ? 20.0 : 20.sp,
                  ),
                ),
                SizedBox(width: isTablet ? 16.0 : 16.w),
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
                                fontSize: isTablet ? 15.0 : 14.sp,
                              ),
                            ),
                          ),
                          if (!item.isRead)
                            Container(
                              width: isTablet ? 8.0 : 8.r,
                              height: isTablet ? 8.0 : 8.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 4.0 : 4.h),
                      Text(
                        item.message,
                        style: TextStyle(
                          color: accentColor.withOpacity(0.6),
                          fontSize: isTablet ? 13.5 : 13.sp,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8.0 : 8.h),
                      Text(
                        DateFormat('hh:mm a').format(item.createdAt),
                        style: TextStyle(
                          color: accentColor.withOpacity(0.3),
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 11.5 : 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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