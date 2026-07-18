import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scan_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/date_formatter.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/scan_card.dart';
import 'package:intl/intl.dart';
import 'report_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HistoryScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  // Filter States
  String _selectedQuickFilter = 'All';
  String _sortBy = 'Newest First';
  List<String> _selectedRiskLevels = ['Low', 'Medium', 'High'];
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Selection Mode (Bulk Delete)
  bool _isSelectionMode = false;
  final Set<String> _selectedScanIds = {};

  final List<String> _quickFilters = [
    'All',
    '🚨 High',
    '⚠️ Medium',
    '✅ Low',
    'This Week',
    'This Month',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.trim().toLowerCase();
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  // Client-side filtering & sorting
  List<ScanModel> _filterScans(List<ScanModel> allScans) {
    return allScans.where((scan) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final nameMatch = scan.fileName.toLowerCase().contains(_searchQuery);
        final packageMatch = (scan.packageName ?? '').toLowerCase().contains(_searchQuery);
        if (!nameMatch && !packageMatch) return false;
      }

      // 2. Quick Filter (Level or Timeframe)
      final now = DateTime.now();
      if ((_selectedQuickFilter == '🚨 High' || _selectedQuickFilter == '🚨 Malicious') &&
          (scan.riskLevel.toLowerCase() != 'high' && scan.riskLevel.toLowerCase() != 'malicious')) {
        return false;
      } else if ((_selectedQuickFilter == '⚠️ Medium' || _selectedQuickFilter == '⚠️ Suspicious') &&
          (scan.riskLevel.toLowerCase() != 'medium' && scan.riskLevel.toLowerCase() != 'suspicious')) {
        return false;
      } else if ((_selectedQuickFilter == '✅ Low' || _selectedQuickFilter == '✅ Safe') &&
          (scan.riskLevel.toLowerCase() != 'low' && scan.riskLevel.toLowerCase() != 'safe')) {
        return false;
      } else if (_selectedQuickFilter == 'This Week') {
        if (now.difference(scan.scannedAt).inDays > 7) return false;
      } else if (_selectedQuickFilter == 'This Month') {
        if (now.difference(scan.scannedAt).inDays > 30) return false;
      }

      // 3. Advanced Filter: Risk Levels (Checkboxes)
      final normalizedLevel = scan.riskLevel.toLowerCase();
      bool levelMatch = false;
      for (final selectedLevel in _selectedRiskLevels) {
        final normSelected = selectedLevel.toLowerCase();
        if (normSelected == normalizedLevel ||
            (normSelected == 'low' && normalizedLevel == 'safe') ||
            (normSelected == 'medium' && normalizedLevel == 'suspicious') ||
            (normSelected == 'high' && normalizedLevel == 'malicious') ||
            (normSelected == 'safe' && normalizedLevel == 'low') ||
            (normSelected == 'suspicious' && normalizedLevel == 'medium') ||
            (normSelected == 'malicious' && normalizedLevel == 'high')) {
          levelMatch = true;
          break;
        }
      }
      if (!levelMatch) return false;

      // 4. Advanced Filter: Date range
      if (_dateFrom != null && scan.scannedAt.isBefore(_dateFrom!)) return false;
      if (_dateTo != null && scan.scannedAt.isAfter(_dateTo!.add(const Duration(days: 1)))) return false;

      return true;
    }).toList()
      ..sort((a, b) {
        // 5. Sorting
        switch (_sortBy) {
          case 'Oldest First':
            return a.scannedAt.compareTo(b.scannedAt);
          case 'Highest Risk Score':
            return b.overallRisk.compareTo(a.overallRisk);
          case 'Lowest Risk Score':
            return a.overallRisk.compareTo(b.overallRisk);
          case 'Name (A-Z)':
            return a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
          case 'Newest First':
          default:
            return b.scannedAt.compareTo(a.scannedAt);
        }
      });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Advanced Filters', style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _sortBy = 'Newest First';
                            _selectedRiskLevels = ['Low', 'Medium', 'High'];
                            _dateFrom = null;
                            _dateTo = null;
                          });
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.background),
                  const SizedBox(height: 8),

                  // Sort section
                  Text('SORT BY', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildSortRadioTile('Newest First', setSheetState),
                  _buildSortRadioTile('Oldest First', setSheetState),
                  _buildSortRadioTile('Highest Risk Score', setSheetState),
                  _buildSortRadioTile('Lowest Risk Score', setSheetState),
                  _buildSortRadioTile('Name (A-Z)', setSheetState),
                  const SizedBox(height: 16),

                  // Levels section
                  Text('RISK LEVELS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Low', 'Medium', 'High'].map((lvl) {
                      final active = _selectedRiskLevels.contains(lvl);
                      return Expanded(
                        child: CheckboxListTile(
                          title: Text(lvl, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
                          value: active,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                _selectedRiskLevels.add(lvl);
                              } else {
                                _selectedRiskLevels.remove(lvl);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Dates section
                  Text('DATE RANGE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateFrom ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => _dateFrom = picked);
                            }
                          },
                          child: Text(_dateFrom == null
                              ? 'From'
                              : DateFormat('MMM dd, yyyy').format(_dateFrom!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateTo ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() => _dateTo = picked);
                            }
                          },
                          child: Text(_dateTo == null
                              ? 'To'
                              : DateFormat('MMM dd, yyyy').format(_dateTo!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingLarge * 1.5),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Apply changes to main screen state
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortRadioTile(String value, StateSetter setSheetState) {
    return RadioListTile<String>(
      title: Text(value, style: AppTextStyles.bodyMedium),
      value: value,
      groupValue: _sortBy,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (val) {
        if (val != null) {
          setSheetState(() => _sortBy = val);
        }
      },
    );
  }

  Future<void> _handleDelete(ScanModel scan) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete Scan', style: AppTextStyles.headingMedium),
          content: Text('Are you sure you want to delete the scan for ${scan.fileName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteScan(scan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${scan.fileName} scan deleted.'),
              backgroundColor: AppColors.safe,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () async {
                  // Restore scan
                  await _firestoreService.saveScanResult(scan);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> _handleBulkDelete() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete Selected', style: AppTextStyles.headingMedium),
          content: Text('Are you sure you want to delete ${_selectedScanIds.length} scans permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteMultipleScans(_selectedScanIds.toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedScanIds.length} scans deleted.'),
              backgroundColor: AppColors.safe,
            ),
          );
          setState(() {
            _selectedScanIds.clear();
            _isSelectionMode = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bulk delete failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  void _showContextMenu(ScanModel scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                title: Text('View Report', style: AppTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportScreen(scanModel: scan)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: Text('Delete Scan', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(context);
                  _handleDelete(scan);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedScanIds.length} Selected', style: AppTextStyles.headingMedium.copyWith(fontSize: 18))
            : const Text('Scan History'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedScanIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: _selectedScanIds.isNotEmpty ? _handleBulkDelete : null,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showFilterBottomSheet,
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips (only when not in selection mode)
            if (!_isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: 8),
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search by app name...',
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: 4),
                child: FilterChipRow(
                  filters: _quickFilters,
                  selectedFilter: _selectedQuickFilter,
                  onSelected: (filter) {
                    setState(() {
                      _selectedQuickFilter = filter;
                    });
                  },
                ),
              ),
            ],

            Expanded(
              child: StreamBuilder<List<ScanModel>>(
                stream: _firestoreService.getUserScansStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.danger)),
                    );
                  }

                  final allScans = snapshot.data ?? [];
                  if (allScans.isEmpty) {
                    return EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No scans yet',
                      subtitle: 'Start scanning APK files to see your history',
                      buttonText: 'Scan Now',
                      onButtonPressed: () {
                        if (widget.onNavigateToTab != null) {
                          widget.onNavigateToTab!(1);
                        }
                      },
                    );
                  }

                  final filteredScans = _filterScans(allScans);

                  // Calculate stats based on filtered list
                  final totalCount = filteredScans.length;
                  final maliciousCount = filteredScans.where((s) => s.riskLevel.toLowerCase() == 'malicious').length;
                  final suspiciousCount = filteredScans.where((s) => s.riskLevel.toLowerCase() == 'suspicious').length;
                  final safeCount = filteredScans.where((s) => s.riskLevel.toLowerCase() == 'safe').length;

                  return Column(
                    children: [
                      // Stats Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: $totalCount scans',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                _buildStatsPill('Malicious', maliciousCount, AppColors.danger),
                                const SizedBox(width: 6),
                                _buildStatsPill('Suspicious', suspiciousCount, AppColors.warning),
                                const SizedBox(width: 6),
                                _buildStatsPill('Safe', safeCount, AppColors.safe),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Main Scans List
                      Expanded(
                        child: filteredScans.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No matching scans',
                                subtitle: 'Try adjusting your filters',
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  setState(() {});
                                },
                                color: AppColors.primary,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                                  itemCount: filteredScans.length,
                                  itemBuilder: (context, index) {
                                    final scan = filteredScans[index];
                                    final isSelected = _selectedScanIds.contains(scan.id);

                                    return Dismissible(
                                      key: Key(scan.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                                      ),
                                      confirmDismiss: (dir) async {
                                        _handleDelete(scan);
                                        return false; // Managed manually by confirmation dialogs
                                      },
                                      child: _buildEnhancedScanCard(scan, isSelected),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value',
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildEnhancedScanCard(ScanModel scan, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedScanIds.remove(scan.id);
                if (_selectedScanIds.isEmpty) _isSelectionMode = false;
              } else {
                _selectedScanIds.add(scan.id);
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReportScreen(scanModel: scan)),
            );
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedScanIds.add(scan.id);
            });
          } else {
            _showContextMenu(scan);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Colored vertical bar for risk level
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: scan.riskColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),

              // Selection checkmark or item icon
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedScanIds.add(scan.id);
                              } else {
                                _selectedScanIds.remove(scan.id);
                                if (_selectedScanIds.isEmpty) _isSelectionMode = false;
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scan.riskColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            scan.riskLevel.toLowerCase() == 'high' || scan.riskLevel.toLowerCase() == 'malicious'
                                ? Icons.gpp_bad_rounded
                                : scan.riskLevel.toLowerCase() == 'medium' || scan.riskLevel.toLowerCase() == 'suspicious'
                                    ? Icons.gpp_maybe_rounded
                                    : Icons.verified_user_rounded,
                            color: scan.riskColor,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),

              // Title and metadata details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        scan.fileName,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scan.fileType == 'apk' ? (scan.packageName ?? 'N/A') : 'PDF Document',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scan.riskColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              scan.riskLevel.toUpperCase(),
                              style: TextStyle(color: scan.riskColor, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Score: ${scan.riskScore}%',
                            style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.formatTimeAgo(scan.scannedAt),
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons or chevrons on the right
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                        onPressed: () => _handleDelete(scan),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary.withAlpha(120),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
