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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30.h,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Create Support Ticket",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Submit a ticket and our support team or AI assistant will assist you shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lightSecondaryText,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24.h),

              // Subject Field
              Text(
                "SUBJECT",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _subjectController,
                style: TextStyle(color: lightText, fontSize: 14.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "e.g., Failed Transaction, Card Delay",
                  hintStyle: TextStyle(color: lightSecondaryText.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                  errorStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a subject";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // Description Field
              Text(
                "DESCRIPTION",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: TextStyle(color: lightText, fontSize: 14.sp, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "Explain your issue in detail...",
                  hintStyle: TextStyle(color: lightSecondaryText.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: primaryColor, width: 1.5),
                  ),
                  errorStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter a description of the issue";
                  }
                  return null;
                },
              ),
              SizedBox(height: 30.h),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Submit Ticket",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
