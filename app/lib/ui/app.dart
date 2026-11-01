import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';
import 'about_screen.dart';
import 'daily_log_screen.dart';
import 'dashboard_screen.dart';
import 'food_list_screen.dart';
import 'help_screen.dart';

class OpenGlTrackerApp extends StatelessWidget {
  const OpenGlTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF4FC3F7),       // light blue
      onPrimary: Colors.black,
      secondary: const Color(0xFFEF5350),     // red
      onSecondary: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0F0F0F),
      surfaceContainer: const Color(0xFF1A1A1A),
      surfaceContainerHigh: const Color(0xFF242424),
      surfaceContainerHighest: const Color(0xFF2E2E2E),
      outline: const Color(0xFF444444),
    );

    return MaterialApp(
      title: 'OpenGLTracker',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: const Color(0xFF4FC3F7),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF4FC3F7),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerColor: const Color(0xFF333333),
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends ConsumerStatefulWidget {
  const _Shell();

  @override
  ConsumerState<_Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<_Shell> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // index 0 = Today's Log (default), index 1 = Foods
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
  }

  void _navigateToDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
    _tabController.animateTo(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenGLTracker'),
        bottom: TabBar(
          controller: _tabController,
          // Five equal-width tabs truncate "Dashboard" on phones. On narrow
          // screens size tabs to their labels instead (scrolling only if a
          // very small screen still can't fit them).
          isScrollable: narrow,
          tabAlignment: narrow ? TabAlignment.center : null,
          labelPadding:
              narrow ? const EdgeInsets.symmetric(horizontal: 12) : null,
          tabs: const [
            Tab(text: 'Log'),
            Tab(text: 'Foods'),
            Tab(text: 'Dashboard'),
            Tab(text: 'Help'),
            Tab(text: 'About'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            const DailyLogScreen(),
            const FoodListScreen(),
            DashboardScreen(onDateSelected: _navigateToDate),
            const HelpScreen(),
            const AboutScreen(),
          ],
        ),
      ),
    );
  }
}
