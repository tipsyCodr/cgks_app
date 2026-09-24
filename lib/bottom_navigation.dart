import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import 'package:cgks/screens/home_screen.dart';
import 'package:cgks/screens/anouncements_screen.dart';
import 'package:cgks/screens/achievement_screen.dart';
import 'package:cgks/screens/news_screen.dart';
import 'package:cgks/screens/search_screen.dart';
import 'package:cgks/constants.dart';

class BottomNav extends StatefulWidget {
  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _index = 0;

  final PageController _pageController = PageController();

  final labels = ["होम", "घोषणा", "समाचार", "ढूंढे"];
  final iconList = [
    Icons.home_rounded,
    Icons.campaign_rounded,
    Icons.article_rounded,
    Icons.search_rounded,
  ];

  final pages = [
    HomeScreen(),
    AnouncementsScreen(),
    NewsScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          ...pages,
          AchievementScreen(), // index for FAB jump
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        elevation: 10,
        shape: const CircleBorder(),
        child: const Icon(Icons.emoji_events, size: 30, color: Colors.white),
        onPressed: () {
          setState(() => _index = 4);
          _pageController.jumpToPage(4);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: AnimatedBottomNavigationBar.builder(
            itemCount: iconList.length,
            tabBuilder: (int i, bool active) {
              return navItem(iconList[i], labels[i], active);
            },
            backgroundColor: Constants.navBarColor,
            activeIndex: _index,
            gapLocation: GapLocation.center,
            notchSmoothness: NotchSmoothness.smoothEdge,
            onTap: (i) {
              setState(() => _index = i);
              _pageController.animateToPage(
                i,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: active ? 28 : 24,
          color: active ? Colors.red : Colors.white70,
        ),
        if (active)
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
      ],
    );
  }
}
