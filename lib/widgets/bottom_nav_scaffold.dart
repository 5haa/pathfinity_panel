import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';

class BottomNavItem {
  final String label;
  final dynamic
  icon; // Can be either IconData or Widget or String for image path
  final Widget screen;
  final bool
  isIconData; // If true, icon is IconData; if false, icon could be Widget or String
  final bool isImagePath; // If true, icon is a string path to an image

  const BottomNavItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.isIconData = true,
    this.isImagePath = false,
  });
}

class BottomNavScaffold extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final List<BottomNavItem> items;
  final int initialIndex;
  final Function(int)? onTabChanged; // Callback for tab changes

  const BottomNavScaffold({
    Key? key,
    required this.title,
    this.actions,
    required this.items,
    this.initialIndex = 0,
    this.onTabChanged,
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
  void didUpdateWidget(BottomNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
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
          if (widget.onTabChanged != null) {
            widget.onTabChanged!(index);
          }
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items:
            widget.items.map((item) {
              Widget iconWidget;

              if (item.isIconData) {
                iconWidget = Icon(item.icon as IconData);
              } else if (item.isImagePath) {
                iconWidget = Image.asset(
                  item.icon as String,
                  width: 24,
                  height: 24,
                  color:
                      _currentIndex == widget.items.indexOf(item)
                          ? AppTheme.primaryColor
                          : Colors.grey,
                );
              } else {
                iconWidget = item.icon as Widget;
              }

              return BottomNavigationBarItem(
                icon: iconWidget,
                label: item.label,
              );
            }).toList(),
      ),
    );
  }
}
