import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/screens/admin/admin_course_videos_screen.dart';
import 'package:admin_panel/screens/admin/admin_course_management_screen.dart';
import 'package:go_router/go_router.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminCoursesTab extends ConsumerStatefulWidget {
  const AdminCoursesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends ConsumerState<AdminCoursesTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _courseChanges = [];
  Map<String, dynamic>? _selectedCourse;
  bool _showCourseChangesTab = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCourseChanges();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final courses = await adminService.getAllCourses();

      debugPrint('Loaded ${courses.length} courses from API');

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

  Future<void> _loadCourseChanges() async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final courseChanges = await adminService.getPendingCourseChanges();

      setState(() {
        _courseChanges = courseChanges;
        _showCourseChangesTab = courseChanges.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error loading course changes: $e');
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
        // Update the local state immediately to reflect the change
        setState(() {
          for (int i = 0; i < _courses.length; i++) {
            if (_courses[i]['id'] == courseId) {
              _courses[i]['is_approved'] = true;
              _courses[i]['rejection_reason'] = null;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
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
                  final reason = reasonController.text;
                  Navigator.of(context).pop();
                  if (reason.trim().isNotEmpty) {
                    _rejectCourse(courseId, reason);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
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
        // Update the local state immediately to reflect the change
        setState(() {
          for (int i = 0; i < _courses.length; i++) {
            if (_courses[i]['id'] == courseId) {
              _courses[i]['is_approved'] = false;
              _courses[i]['rejection_reason'] = reason;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
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
        : DefaultTabController(
          length: _getTabCount(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tabs
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Courses (${_courses.length})',
                            style: AppTheme.subheadingStyle,
                          ),
                          if (_courseChanges.isNotEmpty) const Spacer(),
                          if (_courseChanges.isNotEmpty)
                            _buildNotificationBadge(
                              'Course Changes',
                              _courseChanges.length,
                              Colors.orange,
                            ),
                        ],
                      ),
                    ),
                    TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textLightColor,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: _buildTabs(),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(child: TabBarView(children: _buildTabViews())),
            ],
          ),
        );
  }

  // Helper method to get tab count
  int _getTabCount() {
    int count = 1; // Always have courses tab
    if (_showCourseChangesTab) count++;
    return count;
  }

  // Helper method to build tabs
  List<Widget> _buildTabs() {
    final List<Widget> tabs = [
      const Tab(icon: Icon(Icons.auto_stories), text: 'Courses'),
    ];

    if (_showCourseChangesTab) {
      tabs.add(
        Tab(
          icon: const Icon(Icons.edit_note),
          text: 'Course Changes (${_courseChanges.length})',
        ),
      );
    }

    return tabs;
  }

  // Helper method to build tab views
  List<Widget> _buildTabViews() {
    final List<Widget> views = [_buildCoursesTab()];

    if (_showCourseChangesTab) {
      views.add(_buildCourseChangesTab());
    }

    return views;
  }

  // Build notification badge for tabs
  Widget _buildNotificationBadge(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Courses tab content
  Widget _buildCoursesTab() {
    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_courses.isEmpty)
              _buildEmptyState('courses')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return _buildCourseCard(course);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Course changes tab content
  Widget _buildCourseChangesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCourseChanges();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_courseChanges.isEmpty)
              _buildEmptyState('course changes')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courseChanges.length,
                itemBuilder: (context, index) {
                  final courseChange = _courseChanges[index];
                  return _buildCourseChangeCard(courseChange);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseChangeCard(Map<String, dynamic> courseChange) {
    // Extract course and course change data
    final courseData = courseChange['course'];
    final courseTitle = courseData?['title'] ?? 'Unknown Course';
    final courseId = courseData?['id'] ?? '';

    // Extract fields that changed
    final String? newTitle = courseChange['title'];
    final String? newDescription = courseChange['description'];
    final String? newCategoryId = courseChange['category_id'];

    // Extract creator data
    final creatorData = courseData?['creator'];
    final String creatorName =
        creatorData != null
            ? '${creatorData['first_name']} ${creatorData['last_name']}'
            : 'Unknown';

    // Check if there's a category change
    String oldCategoryName = 'Unknown';
    String newCategoryName = 'Unknown';

    if (courseData?['course_categories'] != null) {
      oldCategoryName =
          courseData?['course_categories']['name'] ?? 'Uncategorized';
    }

    final DateTime createdAt = DateTime.parse(courseChange['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proposed Changes to: $courseTitle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildInfoChip(
                  Icons.calendar_today,
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  textColor: Colors.orange,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator info
                _buildInfoChip(Icons.person, 'Creator: $creatorName'),

                const SizedBox(height: 16),

                // Changes
                if (newTitle != null)
                  _buildChangeRow(
                    'Title',
                    courseData?['title'] ?? 'None',
                    newTitle,
                  ),

                if (newDescription != null)
                  _buildChangeRow(
                    'Description',
                    courseData?['description'] ?? 'No description',
                    newDescription,
                  ),

                if (newCategoryId != null)
                  _buildChangeRow('Category', oldCategoryName, newCategoryName),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Approve Changes',
                      onPressed: () => _approveCourseChange(courseChange['id']),
                      type: ButtonType.success,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Reject Changes',
                      onPressed:
                          () => _showRejectChangeDialog(
                            courseChange['id'],
                            'course',
                          ),
                      type: ButtonType.danger,
                      height: 40,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(String label, String oldValue, String newValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldValue,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proposed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newValue,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveCourseChange(String changeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveCourseChange(changeId);

      if (success && mounted) {
        // Remove the change from the local state
        setState(() {
          _courseChanges.removeWhere((change) => change['id'] == changeId);
          _showCourseChangesTab = _courseChanges.isNotEmpty;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course changes approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Reload courses to reflect the changes
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve course changes'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving course changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while approving course changes'),
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

  void _showRejectChangeDialog(String changeId, String changeType) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Reject ${changeType.substring(0, 1).toUpperCase()}${changeType.substring(1)} Changes',
            ),
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
                  final reason = reasonController.text;
                  Navigator.of(context).pop();
                  if (reason.trim().isNotEmpty) {
                    if (changeType == 'course') {
                      _rejectCourseChange(changeId, reason);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectCourseChange(String changeId, String reason) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.rejectCourseChange(changeId, reason);

      if (success && mounted) {
        // Remove the change from the local state
        setState(() {
          _courseChanges.removeWhere((change) => change['id'] == changeId);
          _showCourseChangesTab = _courseChanges.isNotEmpty;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course changes rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject course changes'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting course changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while rejecting course changes'),
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

  Widget _buildEmptyState(String contentType) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 64,
            color: AppTheme.textLightColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No $contentType found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Content creators haven\'t submitted any $contentType yet',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final bool isActive = course['is_active'] ?? false;
    final bool? isApproved = course['is_approved'];
    final String? thumbnailUrl = course['thumbnail_url'];
    final String title = course['title'] ?? 'Untitled Course';

    // Extract membership type and difficulty level for the badge
    final String membershipType = course['membership_type'] ?? 'PRO';
    final String difficulty = course['difficulty'] ?? 'medium';

    // Get badge text and color based on approval status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isApproved == true) {
      statusText = 'Approved';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.verified;
    } else if (isApproved == false) {
      statusText = 'Rejected';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel;
    } else {
      statusText = 'Pending Review';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
    }

    return GestureDetector(
      onTap: () => _navigateToCourseManagement(course),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child:
                      thumbnailUrl != null && thumbnailUrl.isNotEmpty
                          ? Image.network(
                            thumbnailUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 140,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            height: 140,
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Thumbnail',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Membership badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          membershipType == 'PRO'
                              ? Colors.purple.withOpacity(0.8)
                              : Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      membershipType == 'PRO' ? 'PRO' : 'FREE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Title and difficulty
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                            difficulty,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 12,
                              color: _getDifficultyColor(difficulty),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              difficulty.substring(0, 1).toUpperCase() +
                                  difficulty.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getDifficultyColor(difficulty),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isApproved != true)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _approveCourse(course['id']),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showRejectDialog(course['id']),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppTheme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _navigateToCourseManagement(Map<String, dynamic> course) {
    final String courseId = course['id'];
    final String courseTitle = course['title'] ?? 'Untitled Course';

    try {
      context.go(
        '/admin/courses/$courseId/management',
        extra: {'courseTitle': courseTitle},
      );
    } catch (e) {
      // Fallback to MaterialPageRoute if GoRouter fails
      debugPrint('Navigation error: $e');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => AdminCourseManagementScreen(
                courseId: courseId,
                courseTitle: courseTitle,
              ),
        ),
      );
    }
  }

  void _navigateToCourseVideosScreen(String courseId, String courseTitle) {
    try {
      context.go(
        '/admin/courses/$courseId/videos',
        extra: {'courseTitle': courseTitle},
      );
    } catch (e) {
      // Fallback to MaterialPageRoute if GoRouter fails
      debugPrint('Navigation error: $e');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => AdminCourseVideosScreen(
                courseId: courseId,
                courseTitle: courseTitle,
              ),
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textLightColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
