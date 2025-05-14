import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminCourseManagementScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const AdminCourseManagementScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  ConsumerState<AdminCourseManagementScreen> createState() =>
      _AdminCourseManagementScreenState();
}

class _AdminCourseManagementScreenState
    extends ConsumerState<AdminCourseManagementScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseData;
  List<Map<String, dynamic>> _courseChanges = [];
  bool _showCourseChangesTab = false;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    _loadCourseChanges();
  }

  // Load course data
  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final courseWithVideos = await adminService.getCourseWithVideos(
        widget.courseId,
      );

      if (courseWithVideos != null) {
        setState(() {
          _courseData = courseWithVideos;
          // We no longer need to process videos here
        });
      }
    } catch (e) {
      debugPrint('Error loading course data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load pending course changes
  Future<void> _loadCourseChanges() async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final courseChanges = await adminService.getPendingCourseChanges();

      // Filter only changes for this course
      final filteredChanges =
          courseChanges.where((change) {
            final courseData = change['course'];
            return courseData != null && courseData['id'] == widget.courseId;
          }).toList();

      setState(() {
        _courseChanges = filteredChanges;
        _showCourseChangesTab = filteredChanges.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error loading course changes: $e');
    }
  }

  Future<void> _approveCourse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveCourse(widget.courseId);

      if (success && mounted) {
        // Update the local state immediately to reflect the change
        setState(() {
          if (_courseData != null) {
            _courseData!['is_approved'] = true;
            _courseData!['rejection_reason'] = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
        await _loadCourseData();
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

  void _showRejectDialog() {
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
                    _rejectCourse(reason);
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

  Future<void> _rejectCourse(String reason) async {
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
      final success = await adminService.rejectCourse(widget.courseId, reason);

      if (success && mounted) {
        // Update the local state immediately to reflect the change
        setState(() {
          if (_courseData != null) {
            _courseData!['is_approved'] = false;
            _courseData!['rejection_reason'] = reason;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
        await _loadCourseData();
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

        // Reload course to reflect the changes
        await _loadCourseData();
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

  void _showRejectChangeDialog(String changeId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Course Changes'),
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
                    _rejectCourseChange(changeId, reason);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course: ${widget.courseTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              context.go('/admin');
            } catch (e) {
              // Fallback navigation in case of routing issues
              debugPrint('Navigation error: $e');
              Navigator.of(context).canPop()
                  ? Navigator.of(context).pop()
                  : context.go('/admin');
            }
          },
        ),
        actions: [
          if (_showCourseChangesTab)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildNotificationBadge(
                'Course Changes',
                _courseChanges.length,
                Colors.orange,
              ),
            ),
          Tooltip(
            message: 'Manage Course Videos',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.video_library),
                onPressed: () {
                  context.go(
                    '/admin/courses/${widget.courseId}/videos',
                    extra: {'courseTitle': widget.courseTitle},
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _courseData == null
              ? const Center(child: Text('Course not found'))
              : DefaultTabController(
                length: _showCourseChangesTab ? 2 : 1,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textLightColor,
                      tabs: [
                        const Tab(
                          icon: Icon(Icons.info),
                          text: 'Course Details',
                        ),
                        if (_showCourseChangesTab)
                          Tab(
                            icon: const Icon(Icons.edit_note),
                            text: 'Changes (${_courseChanges.length})',
                          ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCourseDetailsTab(),
                          if (_showCourseChangesTab) _buildChangesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Build notification badge for tabs
  Widget _buildNotificationBadge(String label, int count, Color color) {
    return Container(
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

  // Course details tab
  Widget _buildCourseDetailsTab() {
    if (_courseData == null) {
      return const Center(child: Text('Course data not available'));
    }

    final bool isActive = _courseData!['is_active'] ?? false;
    final bool? isApproved = _courseData!['is_approved'];
    final String rejectionReason =
        _courseData!['rejection_reason'] ?? 'No reason provided';
    final categoryData = _courseData!['course_categories'];
    final String categoryName =
        categoryData != null
            ? categoryData['name'] ?? 'Uncategorized'
            : 'Uncategorized';
    final creatorData = _courseData!['creator'];
    final String creatorName =
        creatorData != null
            ? '${creatorData['first_name']} ${creatorData['last_name']}'
            : 'Unknown';
    final String creatorEmail =
        creatorData != null ? creatorData['email'] ?? 'No email' : 'No email';
    final String membershipType = _courseData!['membership_type'] ?? 'PRO';
    final String difficulty = _courseData!['difficulty'] ?? 'medium';
    final DateTime createdAt = DateTime.parse(_courseData!['created_at']);
    final DateTime updatedAt = DateTime.parse(_courseData!['updated_at']);
    final String? thumbnailUrl = _courseData!['thumbnail_url'];

    // Get status text and color based on approval status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isApproved == true) {
      statusText = 'Approved';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else if (isApproved == false) {
      statusText = 'Rejected';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel;
    } else {
      statusText = 'Pending Review';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course thumbnail
          Center(
            child: Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child:
                  thumbnailUrl != null && thumbnailUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No thumbnail available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),

          // Status badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(statusText, statusColor, statusIcon),
              _buildStatusBadge(
                isActive ? 'Active' : 'Inactive',
                isActive ? AppTheme.accentColor : Colors.grey,
                isActive ? Icons.toggle_on : Icons.toggle_off,
              ),
              _buildInfoChip(
                Icons.card_membership,
                membershipType == 'PRO' ? 'Pro Content' : 'Free Content',
                backgroundColor:
                    membershipType == 'PRO'
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                textColor:
                    membershipType == 'PRO' ? Colors.purple : Colors.green,
              ),
              _buildInfoChip(
                Icons.signal_cellular_alt,
                'Difficulty: ${difficulty.substring(0, 1).toUpperCase()}${difficulty.substring(1)}',
                backgroundColor: _getDifficultyColor(
                  difficulty,
                ).withOpacity(0.1),
                textColor: _getDifficultyColor(difficulty),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Course title and description
          Text(
            _courseData!['title'] ?? 'Untitled Course',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _courseData!['description'] ?? 'No description provided',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textColor,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Manage Videos button
          Center(
            child: CustomButton(
              text: 'Manage Course Videos',
              onPressed: () {
                context.go(
                  '/admin/courses/${widget.courseId}/videos',
                  extra: {'courseTitle': widget.courseTitle},
                );
              },
              type: ButtonType.primary,
              icon: Icons.video_library,
              height: 48,
              width: 220,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Creator information
          const Text(
            'Creator Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.person, 'Creator', creatorName),
          _buildDetailRow(Icons.email, 'Email', creatorEmail),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Course metadata
          const Text(
            'Course Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.category, 'Category', categoryName),
          _buildDetailRow(
            Icons.calendar_today,
            'Created At',
            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
          ),
          _buildDetailRow(
            Icons.update,
            'Last Updated',
            '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}',
          ),

          // Rejection reason if applicable
          if (isApproved == false) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Rejection Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.comment, 'Rejection Reason', rejectionReason),
          ],

          // Action buttons for pending or rejected courses
          if (isApproved != true) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  text: 'Approve Course',
                  onPressed: _approveCourse,
                  type: ButtonType.success,
                  height: 48,
                  width: 160,
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Reject Course',
                  onPressed: _showRejectDialog,
                  type: ButtonType.danger,
                  height: 48,
                  width: 160,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Changes tab
  Widget _buildChangesTab() {
    return RefreshIndicator(
      onRefresh: _loadCourseChanges,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_courseChanges.isEmpty)
              _buildEmptyState('No pending changes for this course')
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

    // Extract fields that changed
    final String? newTitle = courseChange['title'];
    final String? newDescription = courseChange['description'];
    final String? newCategoryId = courseChange['category_id'];
    final String? newThumbnailUrl = courseChange['thumbnail_url'];

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

                // Thumbnail change
                if (newThumbnailUrl != null) ...[
                  _buildThumbnailChangeRow(
                    courseData?['thumbnail_url'],
                    newThumbnailUrl,
                  ),
                  const SizedBox(height: 12),
                ],

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
                          () => _showRejectChangeDialog(courseChange['id']),
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

  Widget _buildThumbnailChangeRow(
    String? oldThumbnailUrl,
    String newThumbnailUrl,
  ) {
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
          const Text(
            'Thumbnail',
            style: TextStyle(
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
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          oldThumbnailUrl != null && oldThumbnailUrl.isNotEmpty
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  oldThumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              )
                              : const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
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
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          newThumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.blue,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _buildEmptyState(String message) {
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
            Icons.info_outline,
            size: 64,
            color: AppTheme.textLightColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Content will appear here when available',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourseData,
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
}
