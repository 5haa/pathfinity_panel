import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/widgets/custom_button.dart';

class EmptyCoursesState extends StatelessWidget {
  final String selectedFilter;
  final VoidCallback onCreateCourse;

  const EmptyCoursesState({
    Key? key,
    required this.selectedFilter,
    required this.onCreateCourse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            selectedFilter == 'All'
                ? 'No courses yet'
                : 'No $selectedFilter courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'All'
                ? 'Create your first course to get started'
                : 'Try selecting a different filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (selectedFilter == 'All')
            CustomButton(
              text: 'Create New Course',
              onPressed: onCreateCourse,
              icon: Icons.add,
              type: ButtonType.primary,
            ),
        ],
      ),
    );
  }
}
