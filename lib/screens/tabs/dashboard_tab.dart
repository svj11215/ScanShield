import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/scan_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/text_styles.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/scan_card.dart';
import '../report_screen.dart';

class DashboardTab extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  UserModel? _userModel;
  List<ScanModel> _recentScans = [];
  Map<String, int> _stats = {
    'totalScans': 0,
    'maliciousCount': 0,
    'safeCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final userModel = await _firestoreService.getUserData(user.uid);
      final stats = await _firestoreService.getUserStats(user.uid);
      final recentScans = await _firestoreService.getRecentScans(user.uid);

      if (mounted) {
        setState(() {
          _userModel = userModel;
          _stats = stats;
          _recentScans = recentScans;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
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

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final avatarLetter = _userModel?.name.isNotEmpty == true ? _userModel!.name[0].toUpperCase() : 'U';
    final firstName = _userModel?.name != null ? _getFirstName(_userModel!.name) : 'User';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Top AppBar Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withAlpha(40),
                      child: Text(
                        avatarLetter,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Welcome Card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withAlpha(200),
                    AppColors.primary.withAlpha(15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.primary.withAlpha(25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $firstName! 👋',
                          style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep your device safe from threats',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.security_rounded,
                    color: AppColors.secondary,
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

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
            const SizedBox(height: AppSizes.paddingLarge),

            // Quick Action Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => widget.onNavigateToTab(1),
                icon: const Icon(Icons.search_rounded, size: 22),
                label: const Text('Scan APK or PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge * 1.5),

            // Recent Scans Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Scans',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab(2),
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),

            // Recent Scans List or Empty State
            if (_isLoading && _recentScans.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.paddingLarge),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_recentScans.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.textSecondary.withAlpha(80),
                      size: 48,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      'No scans yet. Start by scanning an APK or PDF!',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._recentScans.map(
                (scan) => ScanCard(
                  scan: scan,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReportScreen(scanModel: scan)),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Threat Awareness Card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did you know?',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Over ₹36,000 crore lost to banking fraud in India this year. Keep your banking apps shielded.',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
          ],
        ),
      ),
    );
  }
}
