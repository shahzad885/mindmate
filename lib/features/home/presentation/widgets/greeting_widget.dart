import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/theme/app_colors.dart';

class GreetingWidget extends StatefulWidget {
  final String userName;

  const GreetingWidget({super.key, this.userName = 'Friend'});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _emojiController;
  late Animation<double> _emojiAnim;

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _emojiAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emojiController.dispose();
    super.dispose();
  }

  _GreetingData _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return _GreetingData(text: 'Good morning', emoji: '☀️');
    } else if (hour >= 12 && hour < 17) {
      return _GreetingData(text: 'Good afternoon', emoji: '🌤️');
    } else if (hour >= 17 && hour < 21) {
      return _GreetingData(text: 'Good evening', emoji: '🌙');
    } else {
      return _GreetingData(text: 'Hey, still up?', emoji: '🌟');
    }
  }

  String _formatDate() {
    return DateFormat('EEEE, MMMM d').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting line with emoji
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              greeting.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _emojiAnim,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, _emojiAnim.value),
                child: Text(
                  greeting.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // User name
        Text(
          widget.userName,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 4),

        // Date
        Text(
          _formatDate(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _GreetingData {
  final String text;
  final String emoji;
  _GreetingData({required this.text, required this.emoji});
}
