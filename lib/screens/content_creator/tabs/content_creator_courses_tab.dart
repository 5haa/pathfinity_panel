import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

class ContentCreatorCoursesTab extends ConsumerStatefulWidget {
  const ContentCreatorCoursesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentCreatorCoursesTab> createState() =>
      _ContentCreatorCoursesTabState();
}

class _ContentCreatorCoursesTabState
    extends ConsumerState<ContentCreatorCoursesTab> {
  ContentCreatorUser? _contentCreatorUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadContentCreatorProfile();
  }

  Future<void> _loadContentCreatorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is ContentCreatorUser) {
        setState(() {
          _contentCreatorUser = userProfile;
        });
        await _loadCourses();
      }
    } catch (e) {
      debugPrint('Error loading content creator profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    if (_contentCreatorUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _courses = [
          {
            'id': '1',
            'title': 'Flutter Development Masterclass',
            'description':
                'Learn Flutter from scratch and build real-world apps',
            'thumbnail': 'https://example.com/flutter.jpg',
            'videos_count': 24,
            'students_count': 156,
            'status': 'Published',
            'created_at': DateTime.now().subtract(const Duration(days: 60)),
          },
          {
            'id': '2',
            'title': 'Advanced React & Redux',
            'description': 'Master React, Redux, and modern JavaScript',
            'thumbnail': 'https://example.com/react.jpg',
            'videos_count': 32,
            'students_count': 218,
            'status': 'Published',
            'created_at': DateTime.now().subtract(const Duration(days: 45)),
          },
          {
            'id': '3',
            'title': 'Python for Data Science',
            'description': 'Learn Python for data analysis and visualization',
            'thumbnail': 'https://example.com/python.jpg',
            'videos_count': 18,
            'students_count': 94,
            'status': 'Draft',
            'created_at': DateTime.now().subtract(const Duration(days: 15)),
          },
          {
            'id': '4',
            'title': 'Machine Learning Fundamentals',
            'description': 'Introduction to machine learning algorithms',
            'thumbnail': 'https://example.com/ml.jpg',
            'videos_count': 0,
            'students_count': 0,
            'status': 'Draft',
            'created_at': DateTime.now().subtract(const Duration(days: 5)),
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredCourses {
    if (_selectedFilter == 'All') {
      return _courses;
    } else {
      return _courses
          .where((course) => course['status'] == _selectedFilter)
          .toList();
    }
  }

  void _createNewCourse() {
    // In a real app, this would navigate to a course creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Create new course functionality would be implemented here',
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _navigateToCourseVideos(String courseId, String courseTitle) {
    GoRouter.of(
      context,
    ).push('/course/$courseId/videos', extra: {'courseTitle': courseTitle});
  }

  void _navigateToGoLive(String courseId, String courseTitle) {
    GoRouter.of(context).push(
      '/content-creator/go-live',
      extra: {'courseId': courseId, 'courseTitle': courseTitle},
    );
  }

  void _editCourse(String courseId) {
    // In a real app, this would navigate to a course edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit course with ID: $courseId'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _deleteCourse(String courseId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Course'),
            content: const Text(
              'Are you sure you want to delete this course? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // In a real app, this would call a service to delete the course
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Course with ID: $courseId deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  // Simulate course deletion
                  setState(() {
                    _courses.removeWhere((course) => course['id'] == courseId);
                  });
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contentCreatorUser == null) {
      return const Center(child: Text('Error loading content creator profile'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildFilterChips(),
        Expanded(
          child:
              _filteredCourses.isEmpty
                  ? _buildEmptyState()
                  : _buildCoursesList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Courses',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          CustomButton(
            text: 'Create New Course',
            onPressed: _createNewCourse,
            icon: Icons.add,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Published'),
            const SizedBox(width: 8),
            _buildFilterChip('Draft'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No courses yet'
                : 'No $_selectedFilter courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Create your first course to get started'
                : 'Try selecting a different filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (_selectedFilter == 'All')
            CustomButton(
              text: 'Create New Course',
              onPressed: _createNewCourse,
              icon: Icons.add,
              type: ButtonType.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final String id = course['id'];
    final String title = course['title'];
    final String description = course['description'];
    final int videosCount = course['videos_count'];
    final int studentsCount = course['students_count'];
    final String status = course['status'];
    final DateTime createdAt = course['created_at'];

    // Determine status color
    Color statusColor;
    switch (status) {
      case 'Published':
        statusColor = Colors.green;
        break;
      case 'Draft':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.video_library, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$videosCount videos',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$studentsCount students',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(createdAt)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToCourseVideos(id, title),
                  icon: const Icon(Icons.video_library),
                  label: const Text('Videos'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _navigateToGoLive(id, title),
                  icon: const Icon(Icons.live_tv),
                  label: const Text('Go Live'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Course',
                  onPressed: () => _editCourse(id),
                  color: Colors.orange,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Course',
                  onPressed: () => _deleteCourse(id),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
