// lib/app/utils/widgets/contact_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bia/core/services/session_service.dart';

import '../colors.dart';

class ContactsPickerSuffix extends ConsumerWidget {
  final Function(String phoneNumber, String? name) onContactSelected;
  final Color? iconColor;
  final double? iconSize;

  const ContactsPickerSuffix({
    super.key,
    required this.onContactSelected,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = iconSize ?? 36.sp;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _pickContact(context, ref),
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_rounded,
            color: iconColor ?? primaryColor,
            size: size * 0.85, // Icon slightly smaller than touch target
          ),
        ),
      ),
    );
  }

  Future<void> _pickContact(BuildContext context, WidgetRef ref) async {
    try {
      ref.read(sessionServiceProvider.notifier).setBypassLifecycle(true);
      final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
      final Contact? contact = await contactPicker.selectContact();

      if (contact != null && contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
        String phoneNumber = contact.phoneNumbers!.first;
        phoneNumber = _cleanPhoneNumber(phoneNumber);

        onContactSelected(phoneNumber, contact.fullName);
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access contacts')),
      );
    } finally {
      ref.read(sessionServiceProvider.notifier).setBypassLifecycle(false);
    }
  }

  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+234')) {
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('234') && cleaned.length > 10) {
      cleaned = '0${cleaned.substring(3)}';
    }

    if (!cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '0$cleaned';
    }

    return cleaned;
  }

}