import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/goal_model.dart';

/// Reusable interactive widget that renders the gamified "painting" mechanics.
/// Rises vertically as funds are added, plays haptic feedback on deposit,
/// and explodes confetti upon reaching 100%.
class PaintableGoalWidget extends StatefulWidget {
  final GoalModel goal;
  final VoidCallback? onDepositTap;
  final Color primaryFillColor;
  final Color secondaryFillColor;
  final double height;
  final double width;

  const PaintableGoalWidget({
    super.key,
    required this.goal,
    this.onDepositTap,
    this.primaryFillColor = const Color(0xFF6C63FF),
    this.secondaryFillColor = const Color(0xFF00D2FF),
    this.height = 360,
    this.width = 240,
  });

  @override
  State<PaintableGoalWidget> createState() => _PaintableGoalWidgetState();
}

class _PaintableGoalWidgetState extends State<PaintableGoalWidget> {
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.goal.isAchieved) {
      _hasTriggeredConfetti = true;
    }
  }

  @override
  void didUpdateWidget(covariant PaintableGoalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger celebration if progress just reached 100%
    if (widget.goal.isAchieved && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      _confettiController.play();
      HapticFeedback.heavyImpact();
    } else if (!widget.goal.isAchieved) {
      _hasTriggeredConfetti = false;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleInteraction() {
    // Immediate tactile feedback
    HapticFeedback.mediumImpact();
    widget.onDepositTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal.progress;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Interactive Container (Jar / Canvas)
          GestureDetector(
            onTap: _handleInteraction,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Base Jar Body / Shadow
                  Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                        bottom: Radius.circular(48),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryFillColor.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                  ),

                  // 2. Animated Vertical Liquid / Color Mask
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                      bottom: Radius.circular(46),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, child) {
                        return SizedBox(
                          width: widget.width,
                          height: widget.height,
                          child: CustomPaint(
                            painter: _LiquidFillPainter(
                              progress: animatedProgress,
                              gradientColors: [
                                widget.secondaryFillColor,
                                widget.primaryFillColor,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Realistic Jar Reflections & Glass Highlights
                  IgnorePointer(
                    child: Container(
                      width: widget.width,
                      height: widget.height,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                          bottom: Radius.circular(48),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2.0,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.35),
                            Colors.transparent,
                            Colors.white.withOpacity(0.05),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 4. Center Metrics (Percentage & Title)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.goal.progressPercentage}%',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: progress > 0.45 ? Colors.white : const Color(0xFF1E293B),
                              shadows: [
                                if (progress > 0.45)
                                  Shadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.goal.isAchieved ? 'META CONCLUÍDA! 🎉' : 'Toque para pintar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: progress > 0.45
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Celebration Confetti Cannon (Top Centered)
          Positioned(
            top: -20,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -math.pi / 2, // Upwards blast
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 25,
              minBlastForce: 10,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFD700), // Gold
                Color(0xFF6C63FF), // Purple
                Color(0xFF00D2FF), // Cyan
                Color(0xFFFF6584), // Coral Pink
                Color(0xFF4CAF50), // Green
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering smooth vertical liquid filling with subtle surface curve.
class _LiquidFillPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _LiquidFillPainter({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final fillHeight = size.height * progress;
    final topY = size.height - fillHeight;

    final rect = Rect.fromLTWH(0, topY, size.width, fillHeight);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: gradientColors,
      ).createShader(rect);

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, topY);

    // Subtle gentle wave curvature at top surface of the liquid
    final waveControlX = size.width / 2;
    final waveOffset = progress < 1.0 ? 4.0 * math.sin(progress * math.pi) : 0.0;
    path.quadraticBezierTo(waveControlX, topY - waveOffset, 0, topY);

    path.close();
    canvas.drawPath(path, paint);

    // Subtle surface highlight line
    if (progress < 1.0 && progress > 0.02) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final highlightPath = Path();
      highlightPath.moveTo(0, topY);
      highlightPath.quadraticBezierTo(waveControlX, topY - waveOffset, size.width, topY);
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradientColors != gradientColors;
  }
}
