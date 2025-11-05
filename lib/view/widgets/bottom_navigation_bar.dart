import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/bottombar_controller.dart';
import '../edit.dart';
import '../homeview.dart';
import '../settings.dart';


class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final BottomBarController controller = Get.put(BottomBarController());

    final List<Widget> screens = [
      const HomeScreen(),
      const Editor(),
      const SettingsScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.edit_outlined),
        activeIcon: Icon(Icons.edit_rounded),
        label: 'Editor',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings_rounded),
        label: 'Settings',
      ),
    ];

    return Obx(() => Scaffold(
      body: SafeArea(child: screens[controller.selectedIndex.value]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          items: navItems,
        ),
      ),
    ));
  }
}
