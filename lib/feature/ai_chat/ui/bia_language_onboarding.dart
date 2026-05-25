import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

import '../controller/ai_chat_controller.dart';
import '../../../../app/utils/router/route_constant.dart';

/// An ultra-premium Light and Friendly onboarding setup screen for BIA AI.
class BiaLanguageOnboarding extends ConsumerStatefulWidget {
  const BiaLanguageOnboarding({super.key});

  @override
  ConsumerState<BiaLanguageOnboarding> createState() => _BiaLanguageOnboardingState();
}

class _BiaLanguageOnboardingState extends ConsumerState<BiaLanguageOnboarding>
    with TickerProviderStateMixin {
  String? _selected;
  
  // Animation controllers
  late AnimationController _entryCtrl;
  late AnimationController _fluidCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _waveCtrl;

  // Entry animations
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<_LangOption> _langs = const [
    _LangOption(
      code: 'english',
      label: 'English Profile',
      emoji: '🇬🇧',
      desc: 'Standard Nigerian English speaking',
      subtitle: '"How can I help you today?"',
      badge: 'PROFESSIONAL',
      badgeColor: Color(0xFF0891B2), // Cyan-600
      accentColor: Color(0xFF06B6D4), // Cyan-500
      lightBgColor: Color(0xFFECFEFF), // Cyan-50
    ),
    _LangOption(
      code: 'pidgin',
      label: 'Pidgin Profile',
      emoji: '🇳🇬',
      desc: 'Nigerian Pidgin English personality',
      subtitle: '"How I fit help you today?"',
      badge: 'POPULAR / FRIENDLY',
      badgeColor: Color(0xFF059669), // Green-600
      accentColor: Color(0xFF10B981), // Green-500
      lightBgColor: Color(0xFFECFDF5), // Green-50
    ),
    _LangOption(
      code: 'hausa',
      label: 'Hausa Profile',
      emoji: '🌙',
      desc: 'Hausa Native voice personality',
      subtitle: '"Yaya zan iya taimaka maka?"',
      badge: 'NATURAL AUDIO',
      badgeColor: Color(0xFFD97706), // Amber-600
      accentColor: Color(0xFFF59E0B), // Amber-500
      lightBgColor: Color(0xFFFFFBEB), // Amber-50
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // 1. Entry Animation
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    // 2. Continuous Fluid Background Animation
    _fluidCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // 3. Central Orb Pulse & Rotate Animation
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 4. CTA Sweeping Shimmer Animation
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 5. Audio Waveform Pulse Animation
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _fluidCtrl.dispose();
    _orbCtrl.dispose();
    _shimmerCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    
    // 1. Save and apply language via controller
    await ref.read(aiChatControllerProvider.notifier).updateLanguage(_selected!);
    
    final authBox = await Hive.openBox('authBox');
    final userId = authBox.get('userId')?.toString() ?? '';
    final phone = authBox.get('phone')?.toString() ?? '';
    final effectiveUserId = userId.isNotEmpty ? userId : phone;

    final box = await Hive.openBox('appPrefs');
    await box.put('biaAiLanguageSelected_$effectiveUserId', true);

    if (mounted) {
      context.pushNamed(RouteList.aiChat);
    }
  }

  // Get current active color scheme
  Color _getActiveColor() {
    if (_selected == null) return const Color(0xFF818CF8); // Soft Lavender Indigo
    final match = _langs.firstWhere((e) => e.code == _selected);
    return match.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getActiveColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra clean, light background
      body: Stack(
        children: [
          // ── Background Shaders & Liquid Mesh ─────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fluidCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FluidMeshPainter(
                    animationValue: _fluidCtrl.value,
                    selectedColor: activeColor,
                  ),
                );
              },
            ),
          ),

          // High-end frosted white glass overlay for ambient pastel depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),

          // ── Main Interaction Content ─────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 15.h),
                      
                      // ── Custom Setup Appbar ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32.r,
                                height: 32.r,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: activeColor,
                                    size: 15.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'BIA AI',
                                style: TextStyle(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.6), // Slate-900
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Setup',
                              style: TextStyle(
                                color: const Color(0xFF475569), // Slate-600
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 25.h),

                              // ── Glowing Interactive Core AI Orb ──────────────────────────────
                              _BiaCoreOrb(
                                orbCtrl: _orbCtrl,
                                themeColor: activeColor,
                                isSelected: _selected != null,
                              ),

                              SizedBox(height: 25.h),

                              // ── Header Text ──────────────────────────────────────────────────
                              Text(
                                'Select Your AI Voice Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A), // Slate-900
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  'Choose how your intelligent BIA assistant sounds and expresses personality when replying to you.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF475569), // Slate-600
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ),

                              SizedBox(height: 30.h),

                              // ── Staggered Language Cards ─────────────────────────────────────
                              ...List.generate(_langs.length, (index) {
                                final lang = _langs[index];
                                final isSelected = _selected == lang.code;
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 500 + (index * 120)),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  builder: (context, val, child) {
                                    return Opacity(
                                      opacity: val,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1.0 - val)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildLangCard(lang, isSelected),
                                );
                              }),

                              // ── Voice Preview Speech Bubble ──────────────────────────────────
                              _buildSpeechBubble(activeColor),
                              
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),

                      // ── Continue Floating CTA ─────────────────────────────────────────
                      _buildCTAButton(activeColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Option Card Builder ──────────────────────────────────────────
  Widget _buildLangCard(_LangOption lang, bool isSelected) {
    return AnimatedScale(
      scale: isSelected ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selected = lang.code;
                  });
                },
                splashColor: lang.accentColor.withValues(alpha: 0.1),
                highlightColor: lang.accentColor.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? lang.lightBgColor.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: isSelected
                          ? lang.accentColor.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.05),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? lang.accentColor.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: isSelected ? 16 : 8,
                        spreadRadius: isSelected ? 0 : -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Emoji core
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? lang.accentColor.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          lang.emoji,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
                      SizedBox(width: 14.w),

                      // Text description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  lang.label,
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A), // Slate-900
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? lang.badgeColor.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? lang.badgeColor.withValues(alpha: 0.2)
                                          : Colors.black.withValues(alpha: 0.04),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    lang.badge,
                                    style: TextStyle(
                                      color: isSelected ? lang.badgeColor : const Color(0xFF64748B),
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              lang.desc,
                              style: TextStyle(
                                color: const Color(0xFF475569), // Slate-600
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selection Ring
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? lang.accentColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check_rounded, color: Colors.white, size: 13.sp)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Preview Speech Bubble ─────────────────────────────────────────────────
  Widget _buildSpeechBubble(Color activeColor) {
    if (_selected == null) return const SizedBox.shrink();
    final option = _langs.firstWhere((e) => e.code == _selected);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: EdgeInsets.only(top: 15.h, bottom: 5.h),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AudioWaveform(
                  waveCtrl: _waveCtrl,
                  activeColor: activeColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'VOICE PREVIEW ACTIVE',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TweenAnimationBuilder<double>(
              key: ValueKey(option.code),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2.w),
                    child: Text(
                      option.subtitle,
                      style: TextStyle(
                        color: const Color(0xFF0F172A), // Slate-900
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Glowing Shimmer CTA Button ────────────────────────────────────────────
  Widget _buildCTAButton(Color activeColor) {
    final showBtn = _selected != null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: showBtn
          ? Container(
              margin: EdgeInsets.only(bottom: 20.h),
              width: double.infinity,
              height: 54.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27.r),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.r),
                  child: Stack(
                    children: [
                      // Gradient body
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                activeColor,
                                activeColor.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      // Shimmer sweeping gloss overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (context, child) {
                            return FractionalTranslation(
                              translation: Offset((_shimmerCtrl.value * 3.0) - 1.5, 0.0),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.35),
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Click action trigger
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _confirm,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Initialize BIA Companion',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SizedBox(height: 20.h),
    );
  }
}

// ── Fluid Living Mesh Painter ────────────────────────────────────────────────
class _FluidMeshPainter extends CustomPainter {
  final double animationValue;
  final Color selectedColor;

  _FluidMeshPainter({
    required this.animationValue,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Fluid mesh centers calculations (sine/cosine orbital paths)
    final angle = animationValue * 2 * math.pi;

    // Blob 1: Dynamically changes size and glows in the active soft theme color
    final double bx1 = size.width * 0.15 + (40 * math.cos(angle));
    final double by1 = size.height * 0.15 + (35 * math.sin(angle));
    final double radius1 = 200.r + (20 * math.sin(angle * 2));
    final rect1 = Rect.fromCircle(center: Offset(bx1, by1), radius: radius1);

    paint.shader = RadialGradient(
      colors: [
        selectedColor.withValues(alpha: 0.18),
        selectedColor.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect1);
    canvas.drawCircle(Offset(bx1, by1), radius1, paint);

    // Blob 2: Pastel soft blue orbit contrast
    final double bx2 = size.width * 0.85 + (50 * math.sin(angle));
    final double by2 = size.height * 0.75 + (45 * math.cos(angle));
    final double radius2 = 240.r + (25 * math.cos(angle * 1.5));
    final rect2 = Rect.fromCircle(center: Offset(bx2, by2), radius: radius2);

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF93C5FD).withValues(alpha: 0.16), // Soft sky pastel
        const Color(0xFFDBEAFE).withValues(alpha: 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect2);
    canvas.drawCircle(Offset(bx2, by2), radius2, paint);

    // Blob 3: Warm yellow/amber soft accent ambient orb
    final double bx3 = size.width * 0.5 + (35 * math.cos(angle + math.pi));
    final double by3 = size.height * 0.5 + (25 * math.sin(angle + math.pi));
    final double radius3 = 160.r;
    final rect3 = Rect.fromCircle(center: Offset(bx3, by3), radius: radius3);

    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFDE68A).withValues(alpha: 0.12), // Soft warm amber pastel
        Colors.transparent,
      ],
    ).createShader(rect3);
    canvas.drawCircle(Offset(bx3, by3), radius3, paint);
  }

  @override
  bool shouldRepaint(covariant _FluidMeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedColor != selectedColor;
  }
}

// ── BIA Concentric Sparkle Orb ──────────────────────────────────────────────
class _BiaCoreOrb extends StatelessWidget {
  final AnimationController orbCtrl;
  final Color themeColor;
  final bool isSelected;

  const _BiaCoreOrb({
    required this.orbCtrl,
    required this.themeColor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140.r,
      height: 140.r,
      child: AnimatedBuilder(
        animation: orbCtrl,
        builder: (context, child) {
          final pulseVal = 0.96 + (0.08 * math.sin(orbCtrl.value * 2 * math.pi));
          final rotationVal1 = orbCtrl.value * 2 * math.pi;
          final rotationVal2 = -orbCtrl.value * 2 * math.pi * 1.5;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Soft Glow
              Transform.scale(
                scale: pulseVal,
                child: Container(
                  width: 110.r,
                  height: 110.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                        blurRadius: isSelected ? 30 : 20,
                        spreadRadius: isSelected ? 8 : 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Concentric Ring 1 (Spinning Clockwise)
              Transform.rotate(
                angle: rotationVal1,
                child: CustomPaint(
                  size: Size(130.r, 130.r),
                  painter: _OrbRingPainter(
                    color: themeColor.withValues(alpha: 0.35),
                    strokeWidth: 1.5,
                    dashCount: 8,
                  ),
                ),
              ),

              // Concentric Ring 2 (Spinning Counter-Clockwise)
              Transform.rotate(
                angle: rotationVal2,
                child: CustomPaint(
                  size: Size(106.r, 106.r),
                  painter: _OrbRingPainter(
                    color: themeColor.withValues(alpha: 0.5),
                    strokeWidth: 2.0,
                    dashCount: 5,
                  ),
                ),
              ),

              // Central Solid Core Sphere (Frosted White theme)
              Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: themeColor,
                  size: 26.sp,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Concentric Dashed Ring Painter
class _OrbRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _OrbRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final double dashAngle = (2 * math.pi) / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * 2 * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pulsing Voice Waveform Indicator ──────────────────────────────────────────
class _AudioWaveform extends StatelessWidget {
  final AnimationController waveCtrl;
  final Color activeColor;

  const _AudioWaveform({
    required this.waveCtrl,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveCtrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            // Distinct math formulas create dynamic natural wave effects
            double multiplier = 0.4;
            if (index == 0 || index == 4) multiplier = 0.5;
            if (index == 1 || index == 3) multiplier = 0.8;
            if (index == 2) multiplier = 1.0;

            final double height = 3.h +
                (14.h * waveCtrl.value * multiplier) +
                (2.h * math.sin(index + (waveCtrl.value * math.pi)));

            return Container(
              width: 3.w,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Language Struct ──────────────────────────────────────────────────────────
class _LangOption {
  final String code;
  final String label;
  final String emoji;
  final String desc;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final Color accentColor;
  final Color lightBgColor;

  const _LangOption({
    required this.code,
    required this.label,
    required this.emoji,
    required this.desc,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.lightBgColor,
  });
}
