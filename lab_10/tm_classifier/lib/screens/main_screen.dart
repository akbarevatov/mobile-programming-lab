import 'package:flutter/material.dart';
import '../services/app_controller.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'model_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(controller: widget.controller),
      HistoryScreen(
        controller: widget.controller,
        onGoToHome: () => setState(() => _currentIndex = 0),
      ),
      ModelScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory_rounded),
            label: 'Model',
          ),
        ],
      ),
    );
  }
}
