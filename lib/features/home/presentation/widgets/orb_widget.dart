import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';

class AnimatedOrb extends StatefulWidget {
  final bool isListening;
  final VoidCallback? onTap;

  const AnimatedOrb({super.key, required this.isListening, this.onTap});

  @override
  State<AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<AnimatedOrb>
    with TickerProviderStateMixin {
  // Breathing pulse controller — slow idle
  late AnimationController _breathController;
  late Animation<double> _breathAnim;

  // Ripple controller — active listening
  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;

  // Shimmer rotate
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    if (widget.isListening) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedOrb old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _rippleController.repeat();
    } else if (!widget.isListening && old.isListening) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rippleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ambient glow
            _buildAmbientGlow(),

            // Ripple rings when listening
            if (widget.isListening) ...[
              _buildRippleRing(delay: 0.0, maxScale: 1.6),
              _buildRippleRing(delay: 0.4, maxScale: 1.9),
            ],

            // Orb body with breathing scale
            AnimatedBuilder(
              animation: _breathAnim,
              builder: (_, _) => Transform.scale(
                scale: widget.isListening ? 1.08 : _breathAnim.value,
                child: _buildOrbBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientGlow() {
    return AnimatedBuilder(
      animation: _breathAnim,
      builder: (_, _) {
        final glowScale = widget.isListening ? 1.15 : _breathAnim.value;
        return Transform.scale(
          scale: glowScale,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(
                    widget.isListening ? 0.45 : 0.25,
                  ),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRippleRing({required double delay, required double maxScale}) {
    return AnimatedBuilder(
      animation: _rippleAnim,
      builder: (_, _) {
        final t = (_rippleAnim.value - delay).clamp(0.0, 1.0);
        final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;
        final scale = 0.8 + (maxScale - 0.8) * t;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(opacity),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbBody() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (_, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: _rotateController.value * 2 * math.pi,
              colors: const [
                Color(0xFF9C8CF8),
                Color(0xFF7C6CF8),
                Color(0xFF6A5ACD),
                Color(0xFF8B7CF8),
                Color(0xFF9C8CF8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF9C8CF8).withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Inner highlight
          Positioned(
            top: 22,
            left: 28,
            child: Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          // Center sparkle
          Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
