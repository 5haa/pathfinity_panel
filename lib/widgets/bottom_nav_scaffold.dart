import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

class BottomNavScaffold extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final List<BottomNavItem> items;
  final int initialIndex;

  const BottomNavScaffold({
    Key? key,
    required this.title,
    this.actions,
    required this.items,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: widget.actions,
        elevation: 2,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: widget.items.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items:
            widget.items
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                )
                .toList(),
      ),
    );
  }
}
