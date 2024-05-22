import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class Footer extends StatelessWidget {
  final int currentIndex;
  final PageController pageController;
  final Function(int) onTap;

  const Footer({
    Key? key,
    required this.currentIndex,
    required this.pageController,
    required this.onTap,
  }) : super(key: key);

  Widget _buildIcon(IconData icon, int index) {
    return Icon(
      icon,
      color: currentIndex == index ? Colors.white : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      color: const Color.fromARGB(255, 14, 60, 129),
      height: 65,
      index: currentIndex,
      items: <Widget>[
        _buildIcon(Icons.home, 0),
        _buildIcon(Icons.timer, 1),
        _buildIcon(Icons.mail, 2),
        _buildIcon(Icons.assignment, 3),
      ],
      onTap: onTap,
    );
  }
}
