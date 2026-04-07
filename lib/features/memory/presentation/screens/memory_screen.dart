import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/memory_model.dart';
import '../providers/memory_provider.dart';
import '../widgets/memory_card.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'All';
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  final _filters = ['All', 'People', 'Events', 'Emotions', 'Goals'];

  final _filterToType = {
    'People': 'person',
    'Events': 'event',
    'Emotions': 'emotion',
    'Goals': 'goal',
  };

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerController.forward();

    // Load memories on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryProvider.notifier).loadMemories();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  List<MemoryEntry> _filteredMemories(List<MemoryEntry> all) {
    if (_activeFilter == 'All') return all;
    final type = _filterToType[_activeFilter];
    return all.where((m) => m.type == type).toList();
  }

  Future<void> _onRefresh() async {
    await ref.read(memoryProvider.notifier).loadMemories();
  }

  @override
  Widget build(BuildContext context) {
    final memoryState = ref.watch(memoryProvider);
    final filtered = _filteredMemories(memoryState.memories);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(memoryState.memories.length),
                _buildFilterChips(),
                const SizedBox(height: 4),
                Expanded(
                  child: memoryState.isLoading
                      ? _buildLoadingState()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : _buildMemoryList(filtered),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────

  Widget _buildAppBar(int count) {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Memories',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Things MindMate remembers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────

  Widget _buildFilterChips() {
    return FadeTransition(
      opacity: _headerFade,
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final filter = _filters[i];
            final isActive = _activeFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _activeFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Memory list ───────────────────────────────────────────────

  Widget _buildMemoryList(List<MemoryEntry> memories) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        itemCount: memories.length,
        itemBuilder: (context, index) {
          final memory = memories[index];
          return _StaggeredItem(
            index: index,
            child: MemoryCard(
              key: Key(memory.id),
              memory: memory,
              onDelete: () {
                ref
                    .read(memoryProvider.notifier)
                    .deleteMemory(memory.id);
              },
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────

  Widget _buildEmptyState() {
    final messages = {
      'All': (
        icon: Icons.psychology_rounded,
        title: 'No memories yet',
        subtitle: 'Start chatting with MindMate\nand it will remember everything.',
      ),
      'People': (
        icon: Icons.people_rounded,
        title: 'No people yet',
        subtitle: 'Mention someone like\n"my friend Sara" or "my boss Rahul".',
      ),
      'Events': (
        icon: Icons.event_rounded,
        title: 'No events yet',
        subtitle: 'Talk about your day or plans\nand MindMate will remember them.',
      ),
      'Emotions': (
        icon: Icons.favorite_rounded,
        title: 'No emotions yet',
        subtitle: 'Share how you\'re feeling and\nMindMate will track your mood.',
      ),
      'Goals': (
        icon: Icons.flag_rounded,
        title: 'No goals yet',
        subtitle: 'Tell MindMate what you\'re\nworking toward or hoping for.',
      ),
    };

    final msg = messages[_activeFilter] ?? messages['All']!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Icon(
                msg.icon,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              msg.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: 5,
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(5),
                      ),
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

  // ── Background ────────────────────────────────────────────────

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Staggered entrance animation ──────────────────────────────

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Stagger by index, capped so deep items don't wait too long
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
