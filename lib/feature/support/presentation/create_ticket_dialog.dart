import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/utils/colors.dart';
import '../controller/support_controller.dart';

class CreateTicketDialog extends ConsumerStatefulWidget {
  const CreateTicketDialog({super.key});

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(supportTicketsProvider.notifier).createTicket(
            context,
            _subjectController.text,
            _descriptionController.text,
          );
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final hPad = isTablet ? 24.0 : 20.w;
    final vTop = isTablet ? 16.0 : 20.h;

    // On tablet, constrain width and centre the sheet
    Widget sheet = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: hPad,
        right: hPad,
        top: vTop,
        bottom: MediaQuery.of(context).viewInsets.bottom + (isTablet ? 20.0 : 30.h),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: isTablet ? 40.0 : 48.w,
                  height: isTablet ? 4.0 : 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 14.0 : 20.h),

              // Title
              Text(
                "Create Support Ticket",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightText,
                  fontSize: isTablet ? 16.0 : 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isTablet ? 6.0 : 8.h),

              // Subtitle
              Text(
                "Submit a ticket and our support team or AI assistant will assist you shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: isTablet ? 12.0 : 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 18.0 : 24.h),

              // Subject label
              Text(
                "SUBJECT",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: isTablet ? 10.0 : 10.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: isTablet ? 6.0 : 8.h),

              // Subject field
              TextFormField(
                controller: _subjectController,
                style: TextStyle(
                  color: lightText,
                  fontSize: isTablet ? 13.0 : 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "e.g., Failed Transaction, Card Delay",
                  hintStyle: TextStyle(
                    color: lightSecondaryText.withOpacity(0.5),
                    fontSize: isTablet ? 13.0 : 14.sp,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14.0 : 16.w,
                    vertical: isTablet ? 11.0 : 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                  errorStyle: TextStyle(
                    fontSize: isTablet ? 11.0 : 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a subject";
                  }
                  return null;
                },
              ),
              SizedBox(height: isTablet ? 14.0 : 20.h),

              // Description label
              Text(
                "DESCRIPTION",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: isTablet ? 10.0 : 10.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: isTablet ? 6.0 : 8.h),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: isTablet ? 4 : 5,
                style: TextStyle(
                  color: lightText,
                  fontSize: isTablet ? 13.0 : 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "Explain your issue in detail...",
                  hintStyle: TextStyle(
                    color: lightSecondaryText.withOpacity(0.5),
                    fontSize: isTablet ? 13.0 : 14.sp,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14.0 : 16.w,
                    vertical: isTablet ? 11.0 : 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                  errorStyle: TextStyle(
                    fontSize: isTablet ? 11.0 : 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a description of the issue";
                  }
                  return null;
                },
              ),
              SizedBox(height: isTablet ? 20.0 : 30.h),

              // Submit button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 12.0 : 14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Submit Ticket",
                  style: TextStyle(
                    fontSize: isTablet ? 13.0 : 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isTablet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: sheet,
        ),
      );
    }
    return sheet;
  }
}
