import 'dart:math';
import 'package:flutter/material.dart';
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

  // Pick a random fact once per session (per state lifecycle)
  late final String _currentFact;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _currentFact = AppConstants.didYouKnowFacts[
      rng.nextInt(AppConstants.didYouKnowFacts.length)
    ];
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserDataStream(user.uid),
      builder: (context, userSnapshot) {
        final userModel = userSnapshot.data;
        final avatarLetter = userModel?.name.isNotEmpty == true
            ? userModel!.name[0].toUpperCase()
            : (user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : 'U');
        final firstName = userModel?.name != null
            ? _getFirstName(userModel!.name)
            : (user.displayName != null ? _getFirstName(user.displayName!) : 'User');

        return StreamBuilder<List<ScanModel>>(
          stream: _firestoreService.getUserScansStream(user.uid),
          builder: (context, scansSnapshot) {
            final isLoading = scansSnapshot.connectionState == ConnectionState.waiting && !scansSnapshot.hasData;
            final scans = scansSnapshot.data ?? [];
            final stats = FirestoreService.calculateStats(scans);
            final recentScans = scans.take(3).toList();

            return RefreshIndicator(
              onRefresh: () async {},
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
                              backgroundColor: AppColors.primary.withAlpha(20),
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
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.surface,
                            AppColors.surfaceTint,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $firstName! 👋',
                                  style: AppTextStyles.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Keep your device safe from threats',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: AppColors.secondary,
                              size: 32,
                            ),
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
                            value: '${stats['totalScans'] ?? 0}',
                            label: 'Total Scans',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.warning_rounded,
                            value: '${stats['maliciousCount'] ?? 0}',
                            label: 'Threats Found',
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.verified_rounded,
                            value: '${stats['safeCount'] ?? 0}',
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
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(25),
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
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.large),
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
                          style: AppTextStyles.titleMedium,
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
                    if (isLoading && recentScans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.paddingLarge),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (recentScans.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingLarge),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.textTertiary,
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
                      ...recentScans.map(
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

                    // Dynamic Did You Know Card
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.primary.withAlpha(25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Did you know?',
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentFact,
                                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
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
          },
        );
      },
    );
  }
}
