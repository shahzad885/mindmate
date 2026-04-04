import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindmate/core/theme/app_colors.dart';
import 'package:mindmate/features/home/presentation/screens/chat_screen.dart';
import 'package:mindmate/features/home/presentation/widgets/greeting_widget.dart';
import 'package:mindmate/features/home/presentation/widgets/orb_widget.dart';
import 'package:mindmate/shared/widgets/bottom_nav.dart';
import 'package:mindmate/shared/widgets/glass_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  int _navIndex = 0;

  // Fade animation for the orb hint text
  late AnimationController _hintFadeController;
  late Animation<double> _hintFadeAnim;

  @override
  void initState() {
    super.initState();
    _hintFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _hintFadeAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _hintFadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hintFadeController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // Background blobs
          _buildBackgroundBlobs(),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Center orb section (flexible / grows)
                Expanded(child: _buildOrbSection()),

                // Quick action cards
                _buildQuickActions(),

                // Nav bar spacing
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ChatScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        // Top-left purple blob
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom-right amber blob
        Positioned(
          bottom: 60,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Expanded(child: GreetingWidget(userName: 'Friend')),

          // Avatar
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  // ── Orb section ──────────────────────────────────────────────

  Widget _buildOrbSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Radial glow behind orb
        Stack(
          alignment: Alignment.center,
          children: [
            // Soft radial purple behind orb
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),

            // The orb itself
            AnimatedOrb(isListening: _isListening, onTap: _toggleListening),
          ],
        ),

        const SizedBox(height: 28),

        // Animated hint text
        FadeTransition(
          opacity: _isListening
              ? const AlwaysStoppedAnimation(0.0)
              : _hintFadeAnim,
          child: AnimatedOpacity(
            opacity: _isListening ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: Column(
              children: [
                Text(
                  'Tap to talk with MindMate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Listening indicator text
        AnimatedOpacity(
          opacity: _isListening ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Text(
            "I'm listening…",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick actions ────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.mic_rounded,
              label: 'Daily Check-in',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.psychology_rounded,
              label: 'My Memories',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card ─────────────────────────────────────────

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),

              const SizedBox(width: 12),

              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
