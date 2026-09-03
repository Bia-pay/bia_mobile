import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../app/utils/colors.dart';
import '../controller/support_controller.dart';
import '../model/support_ticket_model.dart';

class TicketDetailsPage extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends ConsumerState<TicketDetailsPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await ref
        .read(ticketDetailsProvider(widget.ticketId).notifier)
        .sendMessage(context, text);

    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailsProvider(widget.ticketId));
    final userIdStr = Hive.box('authBox').get('userId', defaultValue: '')?.toString() ?? '';
    final currentUserId = int.tryParse(userIdStr) ?? 0;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // Scroll to bottom when details finish loading initially
    ref.listen<AsyncValue<SupportTicket?>>(ticketDetailsProvider(widget.ticketId), (prev, next) {
      if (next.hasValue && next.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        toolbarHeight: isTablet ? 64.0 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: lightText, size: isTablet ? 18.0 : 20.sp),
          onPressed: () => context.pop(),
        ),
        title: ticketAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (ticket) => ticket == null
              ? const SizedBox.shrink()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: lightText,
                        fontSize: isTablet ? 14.0 : 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: isTablet ? 1.0 : 2.h),
                    Text(
                      "#TCK-${ticket.id} • ${ticket.status.toUpperCase()}",
                      style: TextStyle(
                        color: ticket.status.toLowerCase() == 'open' ? primaryColor : successColor,
                        fontSize: isTablet ? 10.0 : 10.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
        centerTitle: true,
      ),
      body: ticketAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (err, _) => Center(
          child: Text("Error: $err"),
        ),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text("Ticket not found"));
          }

          final messages = ticket.messages;

          Widget mainContent = Column(
            children: [
              // Subject Description banner
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 16.w,
                  vertical: isTablet ? 10.0 : 12.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Issue Description",
                      style: TextStyle(
                        fontSize: isTablet ? 10.0 : 11.sp,
                        fontWeight: FontWeight.w800,
                        color: lightSecondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: isTablet ? 3.0 : 4.h),
                    Text(
                      ticket.description,
                      style: TextStyle(
                        fontSize: isTablet ? 12.0 : 13.sp,
                        color: lightText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24.0 : 16.w,
                    vertical: isTablet ? 14.0 : 16.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId &&
                        message.senderType.toUpperCase() == 'USER';

                    return _buildMessageBubble(message, isMe, isTablet);
                  },
                ),
              ),

              // Input Send Bar (only active if status is open)
              if (ticket.status.toLowerCase() == 'open')
                _buildInputBar(isTablet)
              else
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 14.0 : 16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: successColor, size: isTablet ? 16.0 : 18.sp),
                      SizedBox(width: isTablet ? 6.0 : 8.w),
                      Text(
                        "This ticket has been resolved and closed.",
                        style: TextStyle(
                          fontSize: isTablet ? 12.0 : 13.sp,
                          fontWeight: FontWeight.bold,
                          color: successColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

          if (isTablet) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: mainContent,
              ),
            );
          }
          return mainContent;
        },
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message, bool isMe, bool isTablet) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    final double maxBubbleWidth = isTablet ? 440.0 : MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isTablet ? 8.0 : 12.h),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isMe ? primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 12.0 : 16.r),
            topRight: Radius.circular(isTablet ? 12.0 : 16.r),
            bottomLeft: isMe ? Radius.circular(isTablet ? 12.0 : 16.r) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(isTablet ? 12.0 : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12.0 : 14.w,
          vertical: isTablet ? 8.0 : 10.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Name (if not me)
            if (!isMe) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: isTablet ? 9.0 : 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: isTablet ? 2.0 : 3.h),
            ],
            // Message body text
            Text(
              message.message,
              style: TextStyle(
                fontSize: isTablet ? 12.0 : 13.5.sp,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : lightText,
                height: 1.3,
              ),
            ),
            SizedBox(height: isTablet ? 3.0 : 4.h),
            // Time sent
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: isTablet ? 9.0 : 9.sp,
                  color: isMe ? Colors.white.withOpacity(0.7) : lightSecondaryText.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isTablet) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: isTablet ? 16.0 : 12.w,
        right: isTablet ? 16.0 : 12.w,
        top: isTablet ? 6.0 : 8.h,
        bottom: MediaQuery.of(context).padding.bottom + (isTablet ? 8.0 : 8.h),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(isTablet ? 20.0 : 24.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 14.0 : 16.w),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: lightText,
                  fontSize: isTablet ? 13.0 : 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(
                    color: lightSecondaryText.withOpacity(0.5),
                    fontSize: isTablet ? 13.0 : 14.sp,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 6.0 : 8.w),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: isTablet ? 36.0 : 42.r,
              height: isTablet ? 36.0 : 42.r,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: isTablet ? 16.0 : 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
