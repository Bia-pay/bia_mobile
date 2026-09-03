import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';
import '../controller/support_controller.dart';
import '../model/support_ticket_model.dart';
import 'create_ticket_dialog.dart';

class SupportTicketsPage extends ConsumerStatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  ConsumerState<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends ConsumerState<SupportTicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: lightText, size: isTablet ? 18.0 : 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Help & Support Center",
          style: TextStyle(
            color: lightText,
            fontSize: isTablet ? 16.0 : 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab bar filter
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: lightSecondaryText,
              indicatorColor: primaryColor,
              indicatorWeight: isTablet ? 2.0 : 3.h,
              labelStyle: TextStyle(
                  fontSize: isTablet ? 13.0 : 14.sp,
                  fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(
                  fontSize: isTablet ? 13.0 : 14.sp,
                  fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Active Tickets"),
                Tab(text: "Resolved"),
              ],
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: primaryColor)),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40.0 : 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: errorColor, size: isTablet ? 36.0 : 48.sp),
                      SizedBox(height: isTablet ? 12.0 : 16.h),
                      Text(
                        "Unable to load tickets",
                        style: TextStyle(
                            fontSize: isTablet ? 14.0 : 16.sp,
                            fontWeight: FontWeight.bold,
                            color: lightText),
                      ),
                      SizedBox(height: isTablet ? 6.0 : 8.h),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: isTablet ? 12.0 : 12.sp,
                            color: lightSecondaryText),
                      ),
                      SizedBox(height: isTablet ? 12.0 : 16.h),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(supportTicketsProvider.notifier)
                            .fetchTickets(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  isTablet ? 10.0 : 12.r)),
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
              data: (tickets) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketsList(
                      tickets
                          .where((t) => t.status.toLowerCase() == 'open')
                          .toList(),
                      true,
                      isTablet,
                    ),
                    _buildTicketsList(
                      tickets
                          .where((t) => t.status.toLowerCase() != 'open')
                          .toList(),
                      false,
                      isTablet,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTicketBottomSheet(context),
        backgroundColor: primaryColor,
        icon: Icon(Icons.add_rounded,
            size: isTablet ? 18.0 : 20.sp, color: Colors.white),
        label: Text(
          "New Ticket",
          style: TextStyle(
              fontSize: isTablet ? 13.0 : 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTicketsList(
      List<SupportTicket> list, bool isActive, bool isTablet) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 60.0 : 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 56.0 : 72.r,
                height: isTablet ? 56.0 : 72.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isActive
                      ? Icons.support_agent_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isActive ? primaryColor : successColor,
                  size: isTablet ? 24.0 : 32.sp,
                ),
              ),
              SizedBox(height: isTablet ? 14.0 : 20.h),
              Text(
                isActive ? "No Active Tickets" : "No Resolved Tickets",
                style: TextStyle(
                    fontSize: isTablet ? 14.0 : 16.sp,
                    fontWeight: FontWeight.bold,
                    color: lightText),
              ),
              SizedBox(height: isTablet ? 6.0 : 8.h),
              Text(
                isActive
                    ? "If you have any issues or inquiries, create a ticket and our support team will help you."
                    : "Resolved and closed support tickets will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: isTablet ? 12.0 : 13.sp,
                    color: lightSecondaryText,
                    height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    final listView = RefreshIndicator(
      onRefresh: () =>
          ref.read(supportTicketsProvider.notifier).fetchTickets(),
      color: primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: isTablet ? 0 : 16.w,
          right: isTablet ? 0 : 16.w,
          top: isTablet ? 14.0 : 16.h,
          bottom: isTablet ? 70.0 : 90.h,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final ticket = list[index];
          return _buildTicketCard(ticket, isTablet);
        },
      ),
    );

    if (isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: listView,
        ),
      );
    }
    return listView;
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isTablet) {
    final dateStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(ticket.createdAt);
    final isOpen = ticket.status.toLowerCase() == 'open';

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteList.ticketDetails,
          pathParameters: {'id': ticket.id.toString()},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 8.0 : 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 14.0 : 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "#TCK-${ticket.id}",
                    style: TextStyle(
                      fontSize: isTablet ? 11.0 : 12.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 7.0 : 8.w,
                      vertical: isTablet ? 2.0 : 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? primaryColor.withOpacity(0.08)
                          : successColor.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(isTablet ? 5.0 : 6.r),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: isTablet ? 9.0 : 9.sp,
                        fontWeight: FontWeight.w800,
                        color: isOpen ? primaryColor : successColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 8.0 : 10.h),
              Text(
                ticket.subject,
                style: TextStyle(
                  fontSize: isTablet ? 13.0 : 15.sp,
                  fontWeight: FontWeight.bold,
                  color: lightText,
                ),
              ),
              SizedBox(height: isTablet ? 4.0 : 6.h),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isTablet ? 11.0 : 13.sp,
                  color: lightSecondaryText,
                  height: 1.3,
                ),
              ),
              SizedBox(height: isTablet ? 10.0 : 12.h),
              const Divider(height: 1, color: lightBorderColor),
              SizedBox(height: isTablet ? 8.0 : 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: isTablet ? 10.0 : 11.sp,
                      color: lightSecondaryText.withOpacity(0.8),
                    ),
                  ),
                  if (ticket.aiEscalated)
                    Row(
                      children: [
                        Icon(Icons.psychology_rounded,
                            color: primaryColor,
                            size: isTablet ? 12.0 : 14.sp),
                        SizedBox(width: isTablet ? 3.0 : 4.w),
                        Text(
                          "AI Assisted",
                          style: TextStyle(
                            fontSize: isTablet ? 9.0 : 10.sp,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTicketBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTicketDialog(),
    );
  }
}
