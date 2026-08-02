import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../chatbot/draggable_chatbot_overlay.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/profile_tab.dart';
import 'scan_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      DashboardTab(onNavigateToTab: _onTabTapped),
      const ScanScreen(),
      HistoryScreen(onNavigateToTab: _onTabTapped),
      const ProfileTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
            const DraggableChatbotOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_rounded),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
