import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/utils/colors.dart';
import '../../../../app/utils/u_popup.dart';
import '../../ai_chat/controller/ai_chat_controller.dart';
import '../../../../core/providers/locale_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  Future<void> _handleConfirm(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await UPopup.confirm(
      context,
      title: title,
      message: content,
      confirmLabel: "Confirm",
      cancelLabel: "Cancel",
    );

    if (confirmed == true) {
      onConfirm();
      if (context.mounted) {
        UPopup.success(
          context,
          title: "Language Updated",
          message: "The application language has been successfully updated.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocale = ref.watch(appLocaleProvider);
    final aiChatState = ref.watch(aiChatControllerProvider);
    final aiLanguage = aiChatState.language;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: lightText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Language Settings",
          style: TextStyle(
            color: lightText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SECTION 1: APP INTERFACE
            _buildSectionHeader("App Interface Language"),
            _buildLanguagePanel(
              ref: ref,
              currentValue: appLocale.languageCode,
              options: [
                _LangOption(code: 'en', label: 'English', desc: 'System default'),
                _LangOption(code: 'ha', label: 'Hausa', desc: 'Harshen Hausa'),
                _LangOption(code: 'pcm', label: 'Pidgin', desc: 'Nigerian Pidgin'),
              ],
              onChanged: (code) {
                _handleConfirm(
                  context,
                  ref,
                  title: "Change App Language",
                  content: "Are you sure you want to change the app interface language?",
                  onConfirm: () {
                    ref.read(appLocaleProvider.notifier).setLocale(code);
                    final aiLang = code == 'ha'
                        ? 'hausa'
                        : (code == 'pcm' ? 'pidgin' : 'english');
                    ref.read(aiChatControllerProvider.notifier).updateLanguage(aiLang);
                  },
                );
              },
            ),

            SizedBox(height: 35.h),

            /// SECTION 2: BIA AI PERSONALITY
            _buildSectionHeader("BIA AI Voice & Personality"),
            _buildLanguagePanel(
              ref: ref,
              currentValue: aiLanguage,
              options: [
                _LangOption(code: 'english', label: 'English', desc: 'Polite & Professional'),
                _LangOption(code: 'pidgin', label: 'Pidgin', desc: 'Friendly & Casual'),
                _LangOption(code: 'hausa', label: 'Hausa', desc: 'Traditional & Warm'),
              ],
              onChanged: (code) {
                _handleConfirm(
                  context,
                  ref,
                  title: "Change BIA AI Voice",
                  content: "Do you want BIA AI to speak in this language? This will reset your current chat session.",
                  onConfirm: () => ref.read(aiChatControllerProvider.notifier).updateLanguage(code),
                );
              },
              isAI: true,
            ),

            SizedBox(height: 40.h),
            
            /// INFO CARD
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                   Icon(Icons.info_outline_rounded, color: primaryColor, size: 22.sp),
                   SizedBox(width: 14.w),
                   Expanded(
                     child: Text(
                       "Changing BIA AI's language will reset the current chat session to apply the new personality.",
                       style: TextStyle(
                         color: primaryColor.withOpacity(0.8),
                         fontSize: 12.sp,
                         fontWeight: FontWeight.w500,
                         height: 1.4,
                       ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 11.sp,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLanguagePanel({
    required WidgetRef ref,
    required String currentValue,
    required List<_LangOption> options,
    required Function(String) onChanged,
    bool isAI = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(options.length, (index) {
          final opt = options[index];
          final isSelected = currentValue == opt.code;
          final isLast = index == options.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => onChanged(opt.code),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? Radius.circular(24.r) : Radius.zero,
                  bottom: isLast ? Radius.circular(24.r) : Radius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.all(18.r),
                  child: Row(
                    children: [
                      /// SELECTOR INDICATOR
                      Container(
                        width: 22.w,
                        height: 22.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                          color: isSelected ? primaryColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: lightText,
                              ),
                            ),
                            Text(
                              opt.desc,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: lightSecondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAI)
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                          size: 18.sp,
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  final String desc;

  _LangOption({required this.code, required this.label, required this.desc});
}
