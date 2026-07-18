import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/text_styles.dart';
import '../../widgets/stat_card.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  UserModel? _userModel;
  Map<String, int> _stats = {
    'totalScans': 0,
    'maliciousCount': 0,
    'safeCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final userModel = await _firestoreService.getUserData(user.uid);
      final stats = await _firestoreService.getUserStats(user.uid);

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _stats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Logout', style: AppTextStyles.headingMedium),
          content: Text(
            'Are you sure you want to logout of ScanShield?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('About ScanShield', style: AppTextStyles.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ScanShield checks installed and downloaded applications for permissions, behaviors, and indicators matching malwares.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                'Developed with 💙 using Flutter & Firebase.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarLetter = _userModel?.name.isNotEmpty == true ? _userModel!.name[0].toUpperCase() : 'U';
    final name = _userModel?.name ?? 'User Name';
    final email = _userModel?.email ?? 'user@email.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.paddingMedium),
          // User Info Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    avatarLetter,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.background,
                      fontSize: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  name,
                  style: AppTextStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge * 1.5),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.document_scanner_rounded,
                  value: '${_stats['totalScans']}',
                  label: 'Total Scans',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.warning_rounded,
                  value: '${_stats['maliciousCount']}',
                  label: 'Threats Found',
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.verified_rounded,
                  value: '${_stats['safeCount']}',
                  label: 'Safe Apps',
                  color: AppColors.safe,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingLarge * 1.5),

          // Menu Options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: Text('About ScanShield', style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: _showAboutDialog,
                ),
                const Divider(color: AppColors.background, height: 1),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                  title: Text('Share App', style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {},
                ),
                const Divider(color: AppColors.background, height: 1),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded, color: AppColors.primary),
                  title: Text('Rate App', style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {},
                ),
                const Divider(color: AppColors.background, height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: Text('Privacy Policy', style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge),

          // Logout Button
          ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.paddingLarge * 1.5),

          // App Version
          Text(
            'ScanShield v1.0.0',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
        ],
      ),
    );
  }
}
