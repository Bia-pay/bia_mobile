// lib/app/utils/widgets/contact_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../colors.dart';

class ContactsPickerSuffix extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final size = iconSize ?? 36.sp;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _pickContact(context),
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

  Future<void> _pickContact(BuildContext context) async {
    try {
      // ✅ USE NATIVE PICKER: Per Play Store policy, we delegate to the system picker.
      // This DOES NOT require broad READ_CONTACTS permission.
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null && contact.phones.isNotEmpty) {
        String phoneNumber = contact.phones.first.number;
        phoneNumber = _cleanPhoneNumber(phoneNumber);

        onContactSelected(phoneNumber, contact.displayName);
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access contacts')),
      );
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