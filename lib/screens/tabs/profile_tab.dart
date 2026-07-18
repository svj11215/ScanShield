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
          title: Text('About ScanShield 🛡️', style: AppTextStyles.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What We Do:',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '• Deep static analysis of APK files using DEX byte-code scanning\n'
                '• PDF document threat inspection for hidden risks\n'
                '• Real-time risk scoring (0–100) across multiple threat vectors\n'
                '• Detection of OTP theft, credential theft, data theft, and screen control exploits\n'
                '• Detailed permission and component-level breakdown',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                'Version: 1.0.0',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Developed with: FFP Android Technologies',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                '© 2026 ScanShield. All rights reserved.',
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

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final currentDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Privacy Policy 🔒', style: AppTextStyles.headingMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated: $currentDate\n\n'
                    'Your privacy is our top priority. This policy explains how ScanShield handles your data.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('1. Data We Collect', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• Account information (email, name) via Firebase Authentication\n'
                    '• Scan metadata (file name, risk score, scan timestamp) stored securely in Firestore\n'
                    '• We do NOT collect personal files, contacts, messages, or browsing history',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('2. File Analysis', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• APK and PDF files you upload are analyzed on our secure servers\n'
                    '• Files are processed in-memory and deleted immediately after analysis\n'
                    '• We never store, share, or retain your uploaded files',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('3. Data Storage', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• Scan reports and history are stored securely in Google Firebase\n'
                    '• Only YOU can access your scan history through your authenticated account\n'
                    '• Data is encrypted in transit (HTTPS) and at rest',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('4. Data Sharing', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• We do NOT sell, rent, or share your data with third parties\n'
                    '• We do NOT use your data for advertising\n'
                    '• Anonymous, aggregated statistics may be used to improve the app',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('5. Third-Party Services', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• Google Firebase (authentication, database)\n'
                    '• Groq AI (chatbot responses — messages are not stored by us)',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('6. Your Rights', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• Access, download, or delete your scan history anytime\n'
                    '• Delete your account permanently from the Profile section\n'
                    '• Contact us for any privacy concerns',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('7. Security', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '• Industry-standard encryption for all data\n'
                    '• Secure authentication via Firebase\n'
                    '• Regular security audits and updates',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('8. Children\'s Privacy', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'ScanShield is not intended for users under 13 years of age.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('9. Changes to This Policy', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'We may update this policy occasionally. Continued use of the app implies acceptance.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text('10. Contact Us', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium,
                      children: [
                        const TextSpan(text: 'For privacy questions or data requests, email: '),
                        TextSpan(
                          text: 'support@scanshield.app',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  Text(
                    'By using ScanShield, you agree to this Privacy Policy.',
                    style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
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
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: Text('Privacy Policy', style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: _showPrivacyPolicyDialog,
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
