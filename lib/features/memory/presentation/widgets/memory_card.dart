import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../data/models/memory_model.dart';

class MemoryCard extends StatefulWidget {
  final MemoryEntry memory;
  final VoidCallback onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onDelete,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.12, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Type config ───────────────────────────────────────────────

  _TypeConfig get _typeConfig {
    switch (widget.memory.type) {
      case 'person':
        return _TypeConfig(
          icon: Icons.person_rounded,
          color: AppColors.secondary, // amber
          label: 'Person',
        );
      case 'event':
        return _TypeConfig(
          icon: Icons.event_rounded,
          color: AppColors.primary, // purple
          label: 'Event',
        );
      case 'emotion':
        return _TypeConfig(
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE91E8C), // pink
          label: 'Emotion',
        );
      case 'goal':
        return _TypeConfig(
          icon: Icons.flag_rounded,
          color: AppColors.success, // green
          label: 'Goal',
        );
      default:
        return _TypeConfig(
          icon: Icons.circle_rounded,
          color: AppColors.textSecondary,
          label: 'Memory',
        );
    }
  }

  Color get _sentimentColor {
    switch (widget.memory.sentiment) {
      case 'positive':
        return AppColors.success;
      case 'negative':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dismissible(
          key: Key(widget.memory.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDelete(),
          background: _buildSwipeBackground(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  _buildTypeIcon(config),
                  const SizedBox(width: 14),

                  // Content
                  Expanded(child: _buildContent(config)),

                  const SizedBox(width: 10),

                  // Right column: mentions + sentiment
                  _buildRightColumn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: AppColors.error, size: 22),
          const SizedBox(height: 4),
          Text(
            'Delete',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(_TypeConfig config) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: config.color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Icon(config.icon, color: config.color, size: 20),
    );
  }

  Widget _buildContent(_TypeConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type label
        Text(
          config.label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: config.color,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),

        // Content
        Text(
          widget.memory.content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),

        // Date
        Text(
          DateFormat('MMM d, yyyy').format(widget.memory.createdAt),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mentions badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 10,
                color: AppColors.primary,
              ),
              const SizedBox(width: 3),
              Text(
                '${widget.memory.mentions}x',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Sentiment dot
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _sentimentColor,
            boxShadow: [
              BoxShadow(
                color: _sentimentColor.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  _TypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
