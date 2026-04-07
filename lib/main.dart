import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindmate/features/chat/data/models/message_model.dart';
import 'package:mindmate/features/memory/presentation/providers/memory_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/memory/data/models/memory_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(MemoryEntryAdapter());
  Hive.registerAdapter(MessageModelAdapter());

  // Open boxes
  await Hive.openBox<MemoryEntry>('memories');
  await Hive.openBox<MessageModel>('messages');

  runApp(ProviderScope(observers: [], child: const MindMateApp()));
}

class MindMateApp extends ConsumerStatefulWidget {
  const MindMateApp({super.key});

  @override
  ConsumerState<MindMateApp> createState() => _MindMateAppState();
}

class _MindMateAppState extends ConsumerState<MindMateApp> {
  @override
  void initState() {
    super.initState();
    // Load memories as soon as app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryProvider.notifier).loadMemories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
