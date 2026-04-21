import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

import '../controller/ai_chat_controller.dart';

import '../../../../app/utils/colors.dart';
import '../../../../app/utils/router/route_constant.dart';

/// Shown only the FIRST time a user taps "BIA AI".
/// Saves the chosen language to Hive so it never shows again.
class BiaLanguageOnboarding extends ConsumerStatefulWidget {
  const BiaLanguageOnboarding({super.key});

  @override
  ConsumerState<BiaLanguageOnboarding> createState() => _BiaLanguageOnboardingState();
}

class _BiaLanguageOnboardingState extends ConsumerState<BiaLanguageOnboarding>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_LangOption> _langs = const [
    _LangOption(
      code: 'english',
      label: 'English',
      emoji: '🇬🇧',
      desc: 'Standard Nigerian English',
      subtitle: '"How can I help you today?"',
    ),
    _LangOption(
      code: 'pidgin',
      label: 'Pidgin',
      emoji: '🇳🇬',
      desc: 'Nigerian Pidgin English',
      subtitle: '"How I fit help you today?"',
    ),
    _LangOption(
      code: 'hausa',
      label: 'Hausa',
      emoji: '🌙',
      desc: 'Hausa Language',
      subtitle: '"Yaya zan iya taimaka maka?"',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    
    // 1. Save and apply language via controller
    await ref.read(aiChatControllerProvider.notifier).updateLanguage(_selected!);
    
    // 2. Also save to a global flag so HomePage knows to skip onboarding next time
    final box = await Hive.openBox('appPrefs');
    await box.put('biaAiLanguageSelected', true);

    if (mounted) {
      context.pushNamed(RouteList.aiChat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIA AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            'Your Banking Assistant',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 48.h),

                  // ── Prompt ──────────────────────────────────────────────
                  Text(
                    'Choose your language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'BIA AI will speak with you in the language you feel most comfortable.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 36.h),

                  // ── Language Cards ──────────────────────────────────────
                  ...List.generate(_langs.length, (i) {
                    final lang = _langs[i];
                    final isSelected = _selected == lang.code;
                    return _buildLangCard(lang, isSelected, i);
                  }),

                  const Spacer(),

                  // ── CTA Button ──────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: GestureDetector(
                      onTap: _confirm,
                      child: Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 24.h),
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF26B4DF), Color(0xFF1E90B2)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Start Chatting  →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangCard(_LangOption lang, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selected = lang.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(lang.emoji, style: TextStyle(fontSize: 28.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    lang.desc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lang.subtitle,
                    style: TextStyle(
                      color: primaryColor.withValues(alpha: 0.8),
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 13.sp)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  final String emoji;
  final String desc;
  final String subtitle;

  const _LangOption({
    required this.code,
    required this.label,
    required this.emoji,
    required this.desc,
    required this.subtitle,
  });
}
