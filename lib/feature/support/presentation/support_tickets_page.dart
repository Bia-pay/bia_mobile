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

class _SupportTicketsPageState extends ConsumerState<SupportTicketsPage> with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra premium clean background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: lightText, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Help & Support Center",
          style: TextStyle(
            color: lightText,
            fontSize: 18.sp,
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
              indicatorWeight: 3.h,
              labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Active Tickets"),
                Tab(text: "Resolved"),
              ],
            ),
          ),
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: errorColor, size: 48.sp),
                      SizedBox(height: 16.h),
                      Text(
                        "Unable to load tickets",
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: lightText),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: lightSecondaryText),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => ref.read(supportTicketsProvider.notifier).fetchTickets(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                      tickets.where((t) => t.status.toLowerCase() == 'open').toList(),
                      true,
                    ),
                    _buildTicketsList(
                      tickets.where((t) => t.status.toLowerCase() != 'open').toList(),
                      false,
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
        icon: Icon(Icons.add_rounded, size: 20.sp, color: Colors.white),
        label: Text(
          "New Ticket",
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<SupportTicket> list, bool isActive) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72.r,
                height: 72.r,
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
                  isActive ? Icons.support_agent_rounded : Icons.check_circle_outline_rounded,
                  color: isActive ? primaryColor : successColor,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                isActive ? "No Active Tickets" : "No Resolved Tickets",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: lightText),
              ),
              SizedBox(height: 8.h),
              Text(
                isActive
                    ? "If you have any issues or inquiries, create a ticket and our support team will help you."
                    : "Resolved and closed support tickets will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: lightSecondaryText, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(supportTicketsProvider.notifier).fetchTickets(),
      color: primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 90.h),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final ticket = list[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(ticket.createdAt);
    final isOpen = ticket.status.toLowerCase() == 'open';

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteList.ticketDetails,
          pathParameters: {'id': ticket.id.toString()},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ticket ID
                  Text(
                    "#TCK-${ticket.id}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isOpen ? primaryColor.withOpacity(0.08) : successColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: isOpen ? primaryColor : successColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              // Subject
              Text(
                ticket.subject,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: lightText,
                ),
              ),
              SizedBox(height: 6.h),
              // Description preview
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: lightSecondaryText,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(height: 1, color: lightBorderColor),
              SizedBox(height: 10.h),
              // Date and AI Escalation status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: lightSecondaryText.withOpacity(0.8),
                    ),
                  ),
                  if (ticket.aiEscalated)
                    Row(
                      children: [
                        Icon(Icons.psychology_rounded, color: primaryColor, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          "AI Assisted",
                          style: TextStyle(
                            fontSize: 10.sp,
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
