import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_block.dart';
import '../widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(
          () => _appVersion = 'v${info.version} • Build ${info.buildNumber}');
    }
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final emailCtrl = TextEditingController(text: auth.user?.email ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 20),
              _editField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _editField(emailCtrl, 'Email Address', Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      await auth.updateProfile(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      borderColor: AppColors.primary.withOpacity(0.3),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: Stack(
          children: [
            // Glow blobs
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.07),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () => auth.refreshProfile(),
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Header ───────────────────────────────────────
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Text('Profile',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.8)),
                      ),
                    ),

                    // ── Avatar Card ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: auth.isLoading
                            ? const _AvatarSkeleton()
                            : Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: _AvatarCard(user: user),
                                  ),
                                  const SizedBox(height: 12),
                                  // #5 Edit Profile button
                                  GestureDetector(
                                    onTap: () =>
                                        _showEditProfile(context, auth),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.gradientPrimary,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4))
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_outlined,
                                              color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit Profile',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Info Card ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: auth.isLoading
                            ? const SkeletonCard(
                                padding: EdgeInsets.all(16),
                                child: Column(children: [
                                  ShimmerBlock(
                                      width: double.infinity, height: 20),
                                  SizedBox(height: 16),
                                  ShimmerBlock(
                                      width: double.infinity, height: 20),
                                  SizedBox(height: 16),
                                  ShimmerBlock(
                                      width: double.infinity, height: 20),
                                  SizedBox(height: 16),
                                  ShimmerBlock(
                                      width: double.infinity, height: 20),
                                ]))
                            : SizedBox(
                                width: double.infinity,
                                child: GlassCard(
                                  borderRadius: 20,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 20),
                                  child: Column(
                                    children: [
                                      _profileRow(Icons.person_outline_rounded,
                                          'Full Name', user?.name ?? 'Not set'),
                                      _divider(),
                                      _profileRow(Icons.phone_outlined, 'Phone',
                                          user?.phone ?? 'Not set'),
                                      _divider(),
                                      _profileRow(Icons.email_outlined, 'Email',
                                          user?.email ?? 'Not set'),
                                      _divider(),
                                      _profileRow(
                                          Icons.verified_user_outlined,
                                          'Verification',
                                          (user?.verificationStatus ?? 'none')
                                              .toUpperCase()),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Menu Tiles ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: auth.isLoading
                            ? const Column(children: [
                                SkeletonCard(
                                    padding: EdgeInsets.all(28),
                                    child: SizedBox(width: double.infinity)),
                                SizedBox(height: 10),
                                SkeletonCard(
                                    padding: EdgeInsets.all(28),
                                    child: SizedBox(width: double.infinity)),
                              ])
                            : Column(
                                children: [
                                  _menuTile(
                                    context,
                                    icon: Icons.verified_user_outlined,
                                    title: 'ID Verification',
                                    subtitle: _verificationSubtitle(
                                        user?.verificationStatus),
                                    color: _verificationColor(
                                        user?.verificationStatus),
                                    gradient: _verificationGradient(
                                        user?.verificationStatus),
                                    onTap: () => Navigator.pushNamed(
                                        context, '/verification'),
                                  ),
                                  const SizedBox(height: 10),
                                  _menuTile(
                                    context,
                                    icon: Icons.logout_rounded,
                                    title: 'Logout',
                                    subtitle: 'Sign out of your account',
                                    color: AppColors.error,
                                    gradient: const LinearGradient(colors: [
                                      AppColors.error,
                                      Color(0xFFFF8A80)
                                    ]),
                                    onTap: () => _confirmLogout(context, auth),
                                  ),
                                  const SizedBox(height: 10),
                                  _menuTile(
                                    context,
                                    icon: Icons.delete_forever_rounded,
                                    title: 'Delete Account',
                                    subtitle: 'Permanently delete your profile',
                                    color: AppColors.error,
                                    gradient: const LinearGradient(colors: [
                                      AppColors.error,
                                      Color(0xFFEF5350)
                                    ]),
                                    onTap: () => _confirmDeleteAccount(context, auth),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // #13 App version
                    if (_appVersion.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: Center(
                            child: Text(
                              _appVersion,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _verificationSubtitle(String? status) {
    switch (status) {
      case 'approved':
        return 'Verification complete';
      case 'pending':
        return 'Under review — please wait';
      case 'rejected':
        return 'Rejected — tap to resubmit';
      default:
        return 'Complete identity verification';
    }
  }

  Color _verificationColor(String? status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gold;
    }
  }

  Gradient _verificationGradient(String? status) {
    switch (status) {
      case 'approved':
        return AppColors.gradientSuccess;
      case 'pending':
        return const LinearGradient(
            colors: [AppColors.warning, Color(0xFFFFCC80)]);
      case 'rejected':
        return const LinearGradient(
            colors: [AppColors.error, Color(0xFFFF8A80)]);
      default:
        return AppColors.gradientGold;
    }
  }

  Widget _divider() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.border.withOpacity(0.5));

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return _PressableMenuTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      gradient: gradient,
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.error, Color(0xFFFF8A80)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                }
              },
              child: const Text('Logout',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account?',
            style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3)),
        content: const Text(
            'Warning: Deleting your account will permanently clear your profile details. This action cannot be undone. Are you sure you want to proceed?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textPrimary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.error, Color(0xFFEF5350)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                );

                final res = await auth.deleteAccount();
                
                if (context.mounted) {
                  Navigator.pop(context); // close loading indicator
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? 'Failed to delete account'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar Card ────────────────────────────────────────────────────────────
class _AvatarCard extends StatelessWidget {
  final dynamic user;
  const _AvatarCard({required this.user});

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientNavratri,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4),
                  ],
                ),
              ),
              Container(
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientPrimary,
                ),
                child: Center(
                  child: Text(
                    _initials(user?.name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => AppColors.gradientNavratri.createShader(b),
            child: Text(
              user?.name ?? 'Guest',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(user?.phone ?? '',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          if (user?.isVerified == true) ...[
            const SizedBox(height: 10),
            const StatusBadge(
                label: '✓ Verified', color: AppColors.success, animate: true),
          ] else if (user?.verificationStatus == 'pending') ...[
            const SizedBox(height: 10),
            const StatusBadge(
                label: '⏳ Under Review', color: AppColors.warning),
          ] else if (user?.verificationStatus == 'rejected') ...[
            const SizedBox(height: 10),
            const StatusBadge(
                label: '❌ Action Required', color: AppColors.error),
          ],
        ],
      ),
    );
  }
}

class _AvatarSkeleton extends StatelessWidget {
  const _AvatarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          ShimmerBlock(width: 90, height: 90, borderRadius: 45),
          SizedBox(height: 16),
          ShimmerBlock(width: 140, height: 24),
          SizedBox(height: 6),
          ShimmerBlock(width: 100, height: 16),
        ],
      ),
    );
  }
}

// ── Pressable Menu Tile ────────────────────────────────────────────────────
class _PressableMenuTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PressableMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PressableMenuTile> createState() => _PressableMenuTileState();
}

class _PressableMenuTileState extends State<_PressableMenuTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          borderColor: widget.color.withOpacity(0.25),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withOpacity(0.35), blurRadius: 12)
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: widget.color, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
