import 'package:flutter/material.dart';
import 'package:ironcreze_vendor/views/auth/newscreen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/profile_provider.dart'; // ✅ NEW
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  void _loadStats() {
    final vendorId = Provider.of<VendorProvider>(
      context,
      listen: false,
    ).vendor?.uid;
    if (vendorId != null) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).fetchProfileStats(vendorId);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<VendorProvider, ProfileProvider>(
        builder: (context, vendorProvider, profileProvider, child) {
          final vendor = vendorProvider.vendor;

          if (vendor == null) {
            return const Center(child: Text('No vendor data'));
          }

          return CustomScrollView(
            slivers: [
              // ── Profile Header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildProfileHeader(context, vendor, profileProvider),
              ),

              // ── Menu Items ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Profile'),
                      const SizedBox(height: 8),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.work_outline,
                          title: 'My Services',
                          subtitle: 'Manage your services & pricing',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.myServices,
                          ),
                          showDivider: false,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionTitle('App'),
                      const SizedBox(height: 8),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.notifications,
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About Us',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewLoginPage(),
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {},
                          showDivider: false,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          textColor: AppColors.error,
                          showDivider: false,
                          onTap: () => _handleLogout(context),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic vendor,
    ProfileProvider profileProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: AppColors.white),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Profile Picture ──────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: vendor.profileImage != null
                        ? CachedNetworkImage(
                            imageUrl: vendor.profileImage!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primaryBackground,
                            child: Center(
                              child: Text(
                                Helpers.getInitials(vendor.name),
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Name & Shop ──────────────────────────────────────────
            Text(
              vendor.name,
              style: AppTextStyles.heading5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              vendor.shopName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // ── Stats Row ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Rating (from vendor_reviews) ──────────────────
                  Expanded(
                    child: profileProvider.isLoading
                        ? _buildLoadingStatItem(label: 'Rating')
                        : _buildRatingStatItem(profileProvider),
                  ),

                  _buildDivider(),

                  // ── Current Month Orders ──────────────────────────
                  Expanded(
                    child: profileProvider.isLoading
                        ? _buildLoadingStatItem(
                            label: '${profileProvider.currentMonthName} Orders',
                          )
                        : _buildStatItem(
                            value: profileProvider.monthlyCompletedOrders
                                .toString(),
                            label: '${profileProvider.currentMonthName} Orders',
                            icon: Icons.receipt_long,
                            color: AppColors.primary,
                          ),
                  ),

                  _buildDivider(),

                  // ── Current Month Earnings — tappable ─────────────
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.earnings),
                      child: profileProvider.isLoading
                          ? _buildLoadingStatItem(
                              label:
                                  '${profileProvider.currentMonthName} Earning',
                            )
                          : _buildEarningStatItem(profileProvider),
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

  // ═══════════════════════════════════════════════════════════════
  // RATING STAT ITEM — from vendor_reviews
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRatingStatItem(ProfileProvider provider) {
    final hasRating = provider.totalReviews > 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            hasRating ? provider.rating.toStringAsFixed(1) : '0.0',
            style: AppTextStyles.heading6,
          ),
        ),
        const SizedBox(height: 2),
        // Show total reviews count
        Text(
          hasRating ? '${provider.totalReviews} reviews' : 'No reviews',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Rating',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EARNINGS STAT ITEM — tappable
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEarningStatItem(ProfileProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: AppColors.success,
              size: 24,
            ),
            Positioned(
              right: -6,
              top: -4,
              child: Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.success,
                size: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Helpers.formatCurrency(provider.monthlyEarnings),
            style: AppTextStyles.heading6.copyWith(color: AppColors.success),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${provider.currentMonthName} Earning',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOADING SHIMMER STAT ITEM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLoadingStatItem({required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REGULAR STAT ITEM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: AppTextStyles.heading6),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIVIDER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: AppColors.border);
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU ITEM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final color = textColor ?? AppColors.primary;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: textColor ?? AppColors.grey400,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: AppColors.border,
          ),
      ],
    );
  }
}
