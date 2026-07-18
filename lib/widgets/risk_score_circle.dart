import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/text_styles.dart';

class RiskScoreCircle extends StatefulWidget {
  final int score;
  final String level;

  const RiskScoreCircle({
    super.key,
    required this.score,
    required this.level,
  });

  @override
  State<RiskScoreCircle> createState() => _RiskScoreCircleState();
}

class _RiskScoreCircleState extends State<RiskScoreCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant RiskScoreCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    final s = widget.score;
    if (s <= 30) return AppColors.safe;
    if (s <= 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final finalColor = _color;

    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedValue = _animation.value;
          return SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              children: [
                // Glow effect background
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: finalColor.withAlpha(20),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                // Custom Paint Progress
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CircleProgressPainter(
                      percentage: animatedValue,
                      color: finalColor,
                    ),
                  ),
                ),
                // Texts in the center
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${animatedValue.toInt()}',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 48,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'RISK SCORE',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _CircleProgressPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = (percentage / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at the top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
