import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../app/utils/colors.dart';
import '../../model/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 480.0 : MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: isTablet ? 6.0 : 6.h,
            bottom: isTablet ? 6.0 : 6.h,
            left: _isUser ? (isTablet ? 24.0 : 32.w) : 0,
            right: _isUser ? 0 : (isTablet ? 24.0 : 32.w),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16.0 : 16.w,
            vertical: isTablet ? 12.0 : 12.h,
          ),
          decoration: BoxDecoration(
            gradient: _isUser 
              ? const LinearGradient(
                  colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
            color: _isUser ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isTablet ? 16.0 : 20.r),
              topRight: Radius.circular(isTablet ? 16.0 : 20.r),
              bottomLeft: Radius.circular(_isUser ? (isTablet ? 16.0 : 20.r) : (isTablet ? 6.0 : 6.r)),
              bottomRight: Radius.circular(_isUser ? (isTablet ? 6.0 : 6.r) : (isTablet ? 16.0 : 20.r)),
            ),
            border: _isUser ? null : Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: isTablet ? 14.0 : 14.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: isTablet ? 6.0 : 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (!_isUser) ...[
                    Icon(
                      Icons.auto_awesome,
                      color: primaryColor.withValues(alpha: 0.8),
                      size: isTablet ? 12.0 : 10.sp,
                    ),
                    SizedBox(width: isTablet ? 4.0 : 4.w),
                  ],
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: _isUser ? 0.7 : 0.4),
                      fontSize: isTablet ? 11.0 : 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isUser) ...[
                    SizedBox(width: isTablet ? 4.0 : 4.w),
                    Icon(
                      message.status == MessageStatus.failed
                          ? Icons.error_outline
                          : message.status == MessageStatus.sending
                              ? Icons.access_time
                              : Icons.done_all,
                      size: isTablet ? 14.0 : 14.sp,
                      color: message.status == MessageStatus.failed
                          ? Colors.redAccent.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated three-dot typing indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 150)),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150),
          () => _controllers[i].repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTablet ? 4.0 : 4.h),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.0 : 14.w,
          vertical: isTablet ? 10.0 : 12.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 14.0 : 20.r),
            topRight: Radius.circular(isTablet ? 14.0 : 20.r),
            bottomRight: Radius.circular(isTablet ? 14.0 : 20.r),
            bottomLeft: Radius.circular(isTablet ? 4.0 : 6.r),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _anims[i],
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _anims[i].value),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 3.0 : 2.w),
                  width: isTablet ? 6.0 : 6.w,
                  height: isTablet ? 6.0 : 6.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
