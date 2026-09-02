import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/utils/colors.dart';
import '../../../app/utils/router/route_constant.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is Bia AI Assistant?',
      'answer': 'Bia AI Assistant allows you to make voice and text transactions in your local dialect (e.g., Hausa). Simply tap the microphone icon on the homepage to start chatting and transacting.',
      'category': 'AI Assistant',
    },
    {
      'question': 'How do I send money to a bank account?',
      'answer': 'Tap on the "Withdrawal" button on the Action Ribbon of the homepage, select your preferred bank, enter the account details, and authorize the transaction with your PIN.',
      'category': 'Transfers',
    },
    {
      'question': 'How do I upgrade my account tier?',
      'answer': 'Navigate to Settings by tapping your profile picture on the top-left of the homepage. Select "Account Tier" and follow the instructions to upload your required KYC documentation.',
      'category': 'Account',
    },
    {
      'question': 'Is my transaction PIN secure?',
      'answer': 'Yes, your PIN is encrypted and stored locally. Never share your transaction PIN or password with anyone. BIA staff will never ask for your PIN.',
      'category': 'Security',
    },
    {
      'question': 'What should I do if a transfer fails?',
      'answer': 'Failed transfers are typically auto-reversed within 24 hours. If your account is debited and you do not receive a reversal, please raise a support ticket under the "Support Tickets" section.',
      'category': 'Transfers',
    },
    {
      'question': 'Can I change my registered phone number?',
      'answer': 'For security reasons, changing your registered phone number requires identity verification. Please contact our support team directly or open a support ticket.',
      'category': 'Account',
    },
  ];

  final List<String> _categories = ['All', 'Account', 'Transfers', 'Security', 'AI Assistant'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open support link: $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching application: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on search query and category selection
    final filteredFaqs = _faqs.where((faq) {
      final matchesSearch = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium clean off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: lightText, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Help & Support",
          style: TextStyle(
            color: lightText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Description Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, how can we help?",
                    style: TextStyle(
                      color: lightText,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "Search our FAQs or get in touch with our active customer support channels.",
                    style: TextStyle(
                      color: lightSecondaryText,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Support Options Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 24.h, bottom: 12.h),
              child: Text(
                "STILL NEED HELP? CONTACT US",
                style: TextStyle(
                  color: lightSecondaryText.withOpacity(0.7),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Support Channel Grid/List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSupportTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: primaryColor,
                  title: "Raise a Support Ticket",
                  subtitle: "View history & open new support tickets directly",
                  onTap: () => context.pushNamed(RouteList.supportTickets),
                ),
                _buildSupportTile(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF25D366), // WhatsApp Green
                  title: "WhatsApp Chat Support",
                  subtitle: "Instant messaging support with our agents",
                  onTap: () => _launchUrl("https://wa.me/2348000000000"),
                ),
                _buildSupportTile(
                  icon: Icons.mail_outline_rounded,
                  iconColor: Colors.redAccent,
                  title: "Email Support",
                  subtitle: "Send details and attachments to support@bia.com",
                  onTap: () => _launchUrl("mailto:support@bia.com?subject=BIA%20App%20Support%20Inquiry"),
                ),
                _buildSupportTile(
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: Colors.blueAccent,
                  title: "Call Customer Care",
                  subtitle: "Talk to a customer care representative",
                  onTap: () => _launchUrl("tel:02097070004"),
                ),
              ]),
            ),
          ),

          // FAQ Search Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(
                    color: lightText,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search topic, questions, keywords...",
                    hintStyle: TextStyle(
                      color: lightSecondaryText.withOpacity(0.6),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: lightSecondaryText.withOpacity(0.8),
                      size: 22.sp,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: lightSecondaryText, size: 20.sp),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                ),
              ),
            ),
          ),

          // Category Pills
          SliverToBoxAdapter(
            child: Container(
              height: 64.h,
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 10.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : lightSecondaryText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // FAQ Title Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 24.h, bottom: 12.h),
              child: Text(
                "FREQUENTLY ASKED QUESTIONS",
                style: TextStyle(
                  color: lightSecondaryText.withOpacity(0.7),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // FAQ List
          if (filteredFaqs.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 32.h),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, color: lightSecondaryText.withOpacity(0.5), size: 48.sp),
                    SizedBox(height: 12.h),
                    Text(
                      "No matching FAQs found",
                      style: TextStyle(
                        color: lightText,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Try searching for other terms or contact support directly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: lightSecondaryText,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faq = filteredFaqs[index];
                  return _FaqTile(
                    question: faq['question']!,
                    answer: faq['answer']!,
                  );
                },
                childCount: filteredFaqs.length,
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(height: 40.h),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: lightText,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            subtitle,
            style: TextStyle(
              color: lightSecondaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: lightSecondaryText.withOpacity(0.5),
          size: 14.sp,
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          color: lightText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: lightText.withOpacity(0.6),
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
