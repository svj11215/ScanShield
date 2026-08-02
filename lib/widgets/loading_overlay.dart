import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';
import '../utils/constants.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.onCancel,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _startTimers();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _secondsElapsed = 0;
      _currentMessageIndex = 0;
      _startTimers();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopTimers();
    }
  }

  void _startTimers() {
    _stopTimers();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
          _updateMessageIndex();
        });
      }
    });
  }

  void _stopTimers() {
    _stopwatchTimer?.cancel();
  }

  void _updateMessageIndex() {
    // Advance through professional status messages based on elapsed time
    final messages = AppConstants.scanStatusMessages;
    if (_secondsElapsed < 3) {
      _currentMessageIndex = 0;
    } else if (_secondsElapsed < 8) {
      _currentMessageIndex = 1;
    } else if (_secondsElapsed < 15) {
      _currentMessageIndex = 2;
    } else if (_secondsElapsed < 20) {
      _currentMessageIndex = 3;
    } else if (_secondsElapsed < 25) {
      _currentMessageIndex = 4;
    } else if (_secondsElapsed < 30) {
      _currentMessageIndex = 5;
    } else if (_secondsElapsed < 35) {
      _currentMessageIndex = 6;
    } else if (_secondsElapsed < 40) {
      _currentMessageIndex = 7;
    } else {
      _currentMessageIndex = messages.length - 1;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final currentMessage = AppConstants.scanStatusMessages[_currentMessageIndex];

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // Blur backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: AppColors.textPrimary.withAlpha(60),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Pulsing animated shield
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLarge * 1.5),
                    
                    // Main title
                    Text(
                      'Analyzing File',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    // Professional status message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        currentMessage,
                        key: ValueKey(currentMessage),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Cancel button
                    if (widget.onCancel != null)
                      TextButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 18),
                        label: Text(
                          'Cancel Analysis',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
