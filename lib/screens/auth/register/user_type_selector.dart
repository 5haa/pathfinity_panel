import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/auth_service.dart';

class UserTypeSelector extends StatefulWidget {
  final UserType selectedUserType;
  final Function(UserType) onUserTypeChanged;

  const UserTypeSelector({
    Key? key,
    required this.selectedUserType,
    required this.onUserTypeChanged,
  }) : super(key: key);

  @override
  State<UserTypeSelector> createState() => _UserTypeSelectorState();
}

class _UserTypeSelectorState extends State<UserTypeSelector> {
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // User type option data
  final List<Map<String, dynamic>> _userTypeOptions = [
    {
      'type': UserType.alumni,
      'title': 'Alumni',
      'subtitle': 'Create an alumni account',
      'icon': Icons.school,
      'color': const Color(0xFF4F46E5),
    },
    {
      'type': UserType.company,
      'title': 'Company',
      'subtitle': 'Register your company',
      'icon': Icons.business,
      'color': const Color(0xFF0EA5E9),
    },
    {
      'type': UserType.contentCreator,
      'title': 'Content Creator',
      'subtitle': 'Create and share content',
      'icon': Icons.video_library,
      'color': const Color(0xFFEF4444),
    },
  ];

  // Get the selected type data
  Map<String, dynamic> get _selectedTypeData {
    return _userTypeOptions.firstWhere(
      (option) => option['type'] == widget.selectedUserType,
      orElse: () => _userTypeOptions.first,
    );
  }

  @override
  void dispose() {
    _removeDropdownOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeDropdownOverlay();
    } else {
      _showDropdownOverlay();
    }
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  void _showDropdownOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Invisible layer to detect taps outside dropdown
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _removeDropdownOverlay,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // The actual dropdown
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 5,
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 5),
                  child: Material(
                    elevation: 8,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children:
                              _userTypeOptions
                                  .where(
                                    (option) =>
                                        option['type'] !=
                                        widget.selectedUserType,
                                  )
                                  .map((option) => _buildDropdownOption(option))
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I want to register as',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        CompositedTransformTarget(
          link: _layerLink,
          child: _buildDropdownSelector(),
        ),
      ],
    );
  }

  Widget _buildDropdownSelector() {
    return InkWell(
      onTap: _toggleDropdown,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow:
              _isDropdownOpen
                  ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            // Selected icon with background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedTypeData['color'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _selectedTypeData['icon'],
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Selected text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedTypeData['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _selectedTypeData['subtitle'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Dropdown arrow
            Icon(
              _isDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: AppTheme.accentColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownOption(Map<String, dynamic> option) {
    return InkWell(
      onTap: () {
        widget.onUserTypeChanged(option['type']);
        _removeDropdownOverlay();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon with background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option['color'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option['icon'], color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    option['subtitle'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
