import 'package:bia/core/__core.dart';
import 'package:bia/feature/auth/modal/reponse/response_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/image.dart';
import '../../../app/utils/u_popup.dart';
import '../../dashboard/dashboardcontroller/dashboardcontroller.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  UserResponse? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox('authBox');
    final savedUserJson = box.get('saved_user_profile');
    if (savedUserJson != null) {
      if (mounted) {
        setState(() {
          _user = UserResponse.fromJson(Map<String, dynamic>.from(savedUserJson));
          _isLoading = false;
        });
      }
    }

    try {
      final controller = ref.read(dashboardControllerProvider.notifier);
      final freshUser = await controller.fetchUserProfile(context);
      if (freshUser != null && mounted) {
        setState(() {
          _user = freshUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final controller = ref.read(dashboardControllerProvider.notifier);
    final response = await controller.uploadProfileImage(context, picked.path);
    if (response != null && response.responseSuccessful) {
      _loadProfile();
    }
  }

  void _showEditNameDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final controller = TextEditingController(text: _user?.fullname);
    UPopup.show(
      context,
      type: UPopupType.info,
      title: "Update Name",
      message: "Please enter your full name below.",
      confirmLabel: "Update",
      cancelLabel: "Cancel",
      content: TextField(
        controller: controller,
        style: TextStyle(
          color: lightText,
          fontSize: isTablet ? 14.0 : 15.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: "Full Name",
          hintStyle: TextStyle(
            color: lightSecondaryText,
            fontSize: isTablet ? 13.0 : 14.sp,
          ),
          filled: true,
          fillColor: offWhiteBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14.0 : 16.w,
            vertical: isTablet ? 12.0 : 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 16.r),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
      onConfirm: () async {
        final newName = controller.text.trim();
        if (newName.isEmpty) return;

        final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
        final res = await dashboardCtrl.updateUserProfile(context, newName);
        if (res != null && res.responseSuccessful) {
          _loadProfile();
          if (mounted) {
            UPopup.success(
              context,
              title: "Success",
              message: "Your name has been updated successfully.",
            );
          }
        }
      },
    );
  }

  void _showEditTagDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final controller = TextEditingController(text: _user?.tag);
    UPopup.show(
      context,
      type: UPopupType.info,
      title: "Update BIA Tag",
      message: "Please enter your new BIA Tag below.",
      confirmLabel: "Update",
      cancelLabel: "Cancel",
      content: TextField(
        controller: controller,
        style: TextStyle(
          color: lightText,
          fontSize: isTablet ? 14.0 : 15.sp,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: "BIA Tag",
          hintStyle: TextStyle(
            color: lightSecondaryText,
            fontSize: isTablet ? 13.0 : 14.sp,
          ),
          prefixText: "@",
          prefixStyle: TextStyle(
            color: primaryColor,
            fontSize: isTablet ? 14.0 : 15.sp,
            fontWeight: FontWeight.w700,
          ),
          filled: true,
          fillColor: offWhiteBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14.0 : 16.w,
            vertical: isTablet ? 12.0 : 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 16.r),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
      onConfirm: () async {
        final newTag = controller.text.trim().replaceAll('@', '');
        if (newTag.isEmpty) return;

        final dashboardCtrl = ref.read(dashboardControllerProvider.notifier);
        final res = await dashboardCtrl.updateUserTag(context, newTag);
        if (res != null && res.responseSuccessful) {
          _loadProfile();
          if (mounted) {
            UPopup.success(
              context,
              title: "Success",
              message: "Your BIA Tag has been updated successfully.",
            );
          }
        }
      },
    );
  }

  void _viewProfilePicture() {
    if (_user?.picture == null || _user!.picture!.isEmpty) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => FullscreenImageViewer(
          imageUrl: _user!.picture!,
          heroTag: 'profile_pic_minimal',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final hasPicture = user?.picture != null && user!.picture!.isNotEmpty;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CustomLoader(color: primaryColor))
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 540 : double.infinity),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    /// Integrated Header with Identity Card
                    SliverAppBar(
                      expandedHeight: isTablet ? 300.0 : 340.h,
                      pinned: true,
                      stretch: true,
                      backgroundColor: primaryColor,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [StretchMode.zoomBackground],
                        background: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Solid Primary Header (Background)
                            Container(color: primaryColor),

                            /// Identity Card (Integrated into FlexibleSpace)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: isTablet ? 16.0 : 20.h,
                                left: isTablet ? 16.0 : 20.w,
                                right: isTablet ? 16.0 : 20.w,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 16.0 : 24.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(isTablet ? 20.0 : 24.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: _viewProfilePicture,
                                            child: Hero(
                                              tag: 'profile_pic_minimal',
                                              child: Container(
                                                width: isTablet ? 72.0 : 100.r,
                                                height: isTablet ? 72.0 : 100.r,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: primaryColor, width: 3),
                                                ),
                                                child: ClipOval(
                                                  child: hasPicture
                                                      ? Image.network(user!.picture!, fit: BoxFit.cover)
                                                      : Image.network(getDiceBearAvatar(user?.phone ?? 'default'), fit: BoxFit.cover),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: _pickImage,
                                              child: Container(
                                                padding: EdgeInsets.all(isTablet ? 6.0 : 8.r),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                                child: Icon(Icons.edit_rounded, color: Colors.white, size: isTablet ? 14.0 : 16.sp),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 10.0 : 16.h),
                                    Text(
                                      user?.fullname ?? "User Name",
                                      style: TextStyle(
                                        color: lightText,
                                        fontSize: isTablet ? 18.0 : 22.sp,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 2.0 : 4.h),
                                    Text(
                                      "Tier 1 | Level ${user?.tier ?? '1'}",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: isTablet ? 12.0 : 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 12.0 : 20.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatItem("Phone", user?.phone ?? "N/A"),
                                        Container(width: 1, height: 20, color: offWhiteBackground),
                                        _buildStatItem(
                                          "Status",
                                          user?.status ?? "Active",
                                          color: (user?.status?.toLowerCase() == 'active' || user?.status == null) ? successColor : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// CONTENT SECTION
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 20.w),
                        child: Column(
                          children: [
                            SizedBox(height: isTablet ? 16.0 : 25.h),
                            _buildSectionHeader("User Information"),
                            _buildModernTile(
                              title: "Full Name",
                              subtitle: user?.fullname ?? "N/A",
                              icon: Icons.person_outline_rounded,
                              onTap: _showEditNameDialog,
                            ),
                            _buildModernTile(
                              title: "BIA Tag",
                              subtitle: (user?.tag != null) ? "@${user?.tag}" : "N/A",
                              icon: Icons.alternate_email_rounded,
                              onTap: _showEditTagDialog,
                            ),
                            _buildModernTile(
                              title: "Email Address",
                              subtitle: user?.email ?? "N/A",
                              icon: Icons.alternate_email_rounded,
                            ),
                            _buildModernTile(
                              title: "Phone Number",
                              subtitle: user?.phone ?? "N/A",
                              icon: Icons.phone_android_rounded,
                            ),

                            SizedBox(height: isTablet ? 16.0 : 20.h),

                            _buildSectionHeader("Identity"),
                            _buildModernTile(
                              title: "Account Tier",
                              subtitle:  "Level ${user?.tier ?? '1'}",
                              icon: Icons.verified_user_outlined,
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: isTablet ? 10.0 : 10.w, vertical: isTablet ? 4.0 : 4.h),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(isTablet ? 8.0 : 10.r),
                                ),
                                child: Text(
                                  "Upgrade",
                                  style: TextStyle(color: Colors.white, fontSize: isTablet ? 10.0 : 10.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Upgrade coming soon!")),
                                );
                              },
                            ),
                            SizedBox(height: isTablet ? 30.0 : 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Column(
      children: [
        Text(label, style: TextStyle(color: lightSecondaryText, fontSize: isTablet ? 11.0 : 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: isTablet ? 2.0 : 2.h),
        Text(value, style: TextStyle(color: color ?? lightText, fontSize: isTablet ? 13.0 : 14.sp, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.only(left: isTablet ? 6.0 : 6.w, bottom: isTablet ? 8.0 : 10.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: isTablet ? 10.0 : 10.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 8.0 : 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16.0 : 20.r),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.0 : 16.w,
          vertical: isTablet ? 2.0 : 4.h,
        ),
        leading: Container(
          padding: EdgeInsets.all(isTablet ? 8.0 : 10.r),
          decoration: BoxDecoration(
            color: offWhiteBackground,
            borderRadius: BorderRadius.circular(isTablet ? 10.0 : 12.r),
          ),
          child: Icon(icon, color: primaryColor, size: isTablet ? 20.0 : 22.sp),
        ),
        title: Text(
          title,
          style: TextStyle(color: lightSecondaryText, fontSize: isTablet ? 11.0 : 11.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: lightText, fontSize: isTablet ? 14.0 : 15.sp, fontWeight: FontWeight.w800),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: lightSecondaryText) : null),
      ),
    );
  }
}

/// FULL-SCREEN IMAGE VIEW COMPONENT
class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Hero(
                tag: heroTag,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 50.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
