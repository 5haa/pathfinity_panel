import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminContentTab extends ConsumerWidget {
  const AdminContentTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CourseManagementTab();
  }
}

class CourseManagementTab extends ConsumerStatefulWidget {
  const CourseManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CourseManagementTab> createState() =>
      _CourseManagementTabState();
}

class _CourseManagementTabState extends ConsumerState<CourseManagementTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final courses = await adminService.getAllCourses();

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveCourse(String courseId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveCourse(courseId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while approving course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRejectDialog(String courseId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter rejection reason',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectCourse(courseId, reasonController.text);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    ).then((_) => reasonController.dispose());
  }

  Future<void> _rejectCourse(String courseId, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.rejectCourse(courseId, reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while rejecting course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Courses', style: AppTheme.subheadingStyle),
              const SizedBox(height: 16),
              if (_courses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No courses found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textLightColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final bool isActive = course['is_active'] ?? false;
                    final bool isApproved = course['is_approved'] ?? false;
                    final categoryData = course['course_categories'];
                    final String categoryName =
                        categoryData != null
                            ? categoryData['name'] ?? 'Uncategorized'
                            : 'Uncategorized';
                    final creatorData = course['creator'];
                    final String creatorName =
                        creatorData != null
                            ? '${creatorData['first_name']} ${creatorData['last_name']}'
                            : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    course['title'] ?? 'Untitled Course',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        isApproved ? 'Approved' : 'Pending',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          isApproved
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          isActive
                                              ? AppTheme.accentColor
                                              : AppTheme.textLightColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course['description'] ??
                                  'No description provided',
                              style: const TextStyle(color: AppTheme.textColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.category,
                                  size: 16,
                                  color: AppTheme.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Category: $categoryName',
                                  style: const TextStyle(
                                    color: AppTheme.textLightColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Creator: $creatorName',
                                  style: const TextStyle(
                                    color: AppTheme.textLightColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (!isApproved)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButton(
                                      text: 'Approve',
                                      onPressed:
                                          () => _approveCourse(course['id']),
                                      type: ButtonType.success,
                                      height: 36,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      text: 'Reject',
                                      onPressed:
                                          () => _showRejectDialog(course['id']),
                                      type: ButtonType.danger,
                                      height: 36,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
  }
}
