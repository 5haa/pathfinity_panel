import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

class ContentCreatorDashboardTab extends ConsumerStatefulWidget {
  const ContentCreatorDashboardTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentCreatorDashboardTab> createState() =>
      _ContentCreatorDashboardTabState();
}

class _ContentCreatorDashboardTabState
    extends ConsumerState<ContentCreatorDashboardTab> {
  ContentCreatorUser? _contentCreatorUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _statistics = [];

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
        await _loadStatistics();
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
          },
          {
            'id': '2',
            'title': 'Advanced React & Redux',
            'description': 'Master React, Redux, and modern JavaScript',
            'thumbnail': 'https://example.com/react.jpg',
            'videos_count': 32,
            'students_count': 218,
          },
          {
            'id': '3',
            'title': 'Python for Data Science',
            'description': 'Learn Python for data analysis and visualization',
            'thumbnail': 'https://example.com/python.jpg',
            'videos_count': 18,
            'students_count': 94,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  Future<void> _loadStatistics() async {
    if (_contentCreatorUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _statistics = [
          {
            'title': 'Total Students',
            'value': '468',
            'icon': Icons.people,
            'color': Colors.blue,
          },
          {
            'title': 'Total Courses',
            'value': '3',
            'icon': Icons.book,
            'color': Colors.green,
          },
          {
            'title': 'Total Videos',
            'value': '74',
            'icon': Icons.video_library,
            'color': Colors.orange,
          },
          {
            'title': 'Live Sessions',
            'value': '12',
            'icon': Icons.live_tv,
            'color': Colors.purple,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  void _navigateToCourseVideos(String courseId, String courseTitle) {
    GoRouter.of(
      context,
    ).push('/course/$courseId/videos', extra: {'courseTitle': courseTitle});
  }

  void _navigateToGoLive() {
    GoRouter.of(context).push('/content-creator/go-live');
  }

  void _navigateToLiveSessions() {
    GoRouter.of(context).push('/content-creator/live-sessions');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contentCreatorUser == null) {
      return const Center(child: Text('Error loading content creator profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildLiveSessionSection(),
          const SizedBox(height: 24),
          _buildCoursesSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_contentCreatorUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfilePictureWidget(
            userId: _contentCreatorUser!.id,
            name:
                '${_contentCreatorUser!.firstName} ${_contentCreatorUser!.lastName ?? ''}',
            profilePictureUrl: _contentCreatorUser!.profilePictureUrl ?? '',
            userType: UserType.contentCreator,
            size: 60,
            onPictureUpdated: (url) {
              setState(() {
                _contentCreatorUser = _contentCreatorUser!.copyWith(
                  profilePictureUrl: url,
                );
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_contentCreatorUser!.firstName} ${_contentCreatorUser!.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _contentCreatorUser!.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'Content Creator',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: _statistics.length,
      itemBuilder: (context, index) {
        final stat = _statistics[index];
        return _buildStatCard(
          title: stat['title'],
          value: stat['value'],
          icon: stat['icon'],
          color: stat['color'],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textLightColor,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSessionSection() {
    return Card(
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
                const Text('Live Sessions', style: AppTheme.subheadingStyle),
                TextButton(
                  onPressed: _navigateToLiveSessions,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Go Live Now',
                    onPressed: _navigateToGoLive,
                    icon: Icons.live_tv,
                    type: ButtonType.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Schedule Session',
                    onPressed: _navigateToLiveSessions,
                    icon: Icons.schedule,
                    type: ButtonType.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Courses', style: AppTheme.subheadingStyle),
            TextButton(
              onPressed: () {
                // Navigate to all courses
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _courses.isEmpty
            ? _buildEmptyCoursesState()
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return _buildCourseCard(course);
              },
            ),
      ],
    );
  }

  Widget _buildEmptyCoursesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No courses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Course',
            onPressed: () {
              // Navigate to course creation
            },
            icon: Icons.add,
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final String id = course['id'];
    final String title = course['title'];
    final String description = course['description'];
    final int videosCount = course['videos_count'];
    final int studentsCount = course['students_count'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCourseVideos(id, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _navigateToCourseVideos(id, title),
                    icon: const Icon(Icons.video_library),
                    label: const Text('Manage Videos'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _navigateToGoLive(),
                    icon: const Icon(Icons.live_tv),
                    label: const Text('Go Live'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
