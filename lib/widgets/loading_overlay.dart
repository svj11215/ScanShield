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
  Timer? _textTimer;
  Timer? _stopwatchTimer;
  int _secondsElapsed = 0;
  String _currentStepText = 'Extracting file...';

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
      _currentStepText = 'Extracting file...';
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
          _updateStepText();
        });
      }
    });
  }

  void _stopTimers() {
    _textTimer?.cancel();
    _stopwatchTimer?.cancel();
  }

  void _updateStepText() {
    if (_secondsElapsed < 5) {
      _currentStepText = 'Extracting file...';
    } else if (_secondsElapsed < 15) {
      _currentStepText = 'Warming up server...';
    } else if (_secondsElapsed < 25) {
      _currentStepText = 'Analyzing file...';
    } else if (_secondsElapsed < 35) {
      _currentStepText = 'Calculating risk score...';
    } else {
      _currentStepText = 'Generating report...';
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

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: Stack(
        children: [
          // Blur backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withAlpha(150),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: AppColors.primary.withAlpha(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(30),
                              blurRadius: 20,
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
                      'Analyzing File...',
                      style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),

                    // Changing steps
                    Text(
                      _currentStepText,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),

                    // Progress bar
                    const LinearProgressIndicator(
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 5,
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
