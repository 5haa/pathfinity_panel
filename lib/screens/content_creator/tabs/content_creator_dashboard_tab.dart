import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/course_video_service.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

final courseVideoServiceProvider = Provider<CourseVideoService>(
  (ref) => CourseVideoService(),
);

final liveSessionServiceProvider = Provider<LiveSessionService>(
  (ref) => LiveSessionService(),
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
      final contentCreatorService = ref.read(contentCreatorServiceProvider);
      final courseVideoService = ref.read(courseVideoServiceProvider);

      // Get courses from the service
      final courses = await contentCreatorService.getCreatorCourses(
        _contentCreatorUser!.id,
      );

      // Process courses to add video counts
      final List<Map<String, dynamic>> processedCourses = [];

      for (final course in courses) {
        // Get videos for this course to count them
        final videos = await courseVideoService.getCourseVideos(course['id']);

        // Create a processed course with additional information
        final processedCourse = Map<String, dynamic>.from(course);

        // Add video count
        processedCourse['videos_count'] = videos.length;

        processedCourses.add(processedCourse);
      }

      setState(() {
        _courses = processedCourses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      setState(() {
        _courses = [];
      });
    }
  }

  Future<void> _loadStatistics() async {
    if (_contentCreatorUser == null) return;

    try {
      final contentCreatorService = ref.read(contentCreatorServiceProvider);
      final courseVideoService = ref.read(courseVideoServiceProvider);

      // Get courses to calculate statistics
      final courses = await contentCreatorService.getCreatorCourses(
        _contentCreatorUser!.id,
      );

      // Calculate total courses
      final totalCourses = courses.length;

      // Initialize counters
      int totalVideos = 0;

      // Get videos for each course to count them
      for (final course in courses) {
        final courseId = course['id'] as String;
        final videos = await courseVideoService.getCourseVideos(courseId);
        totalVideos += videos.length;
      }

      setState(() {
        // Just include Total Courses and Total Videos, removing Live Sessions
        _statistics = [
          {
            'title': 'Total Courses',
            'value': totalCourses.toString(),
            'icon': Icons.book,
            'color': Colors.green,
          },
          {
            'title': 'Total Videos',
            'value': totalVideos.toString(),
            'icon': Icons.video_library,
            'color': Colors.orange,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() {
        _statistics = [
          {
            'title': 'Total Courses',
            'value': '0',
            'icon': Icons.book,
            'color': Colors.green,
          },
          {
            'title': 'Total Videos',
            'value': '0',
            'icon': Icons.video_library,
            'color': Colors.orange,
          },
        ];
      });
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

  void _navigateToCourseWithLive(
    String courseId,
    String courseTitle,
    bool isApproved,
    bool isActive,
  ) {
    if (isApproved && isActive) {
      GoRouter.of(context).push(
        '/content-creator/go-live',
        extra: {'courseId': courseId, 'courseTitle': courseTitle},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only go live with approved and active courses.',
          ),
          backgroundColor: AppTheme.warningColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contentCreatorUser == null) {
      return const Center(child: Text('Error loading content creator profile'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStatisticsGrid(),
                const SizedBox(height: 24),
                _buildCoursesSection(),
                const SizedBox(
                  height: 80,
                ), // Add bottom padding for navigation bar
              ],
            ),
          ),
        ),
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
    return Row(
      children: [
        for (var stat in _statistics)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _buildStatCard(
                title: stat['title'],
                value: stat['value'],
                icon: stat['icon'],
                color: stat['color'],
              ),
            ),
          ),
      ],
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLightColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
            const Flexible(
              child: Text('Your Courses', style: AppTheme.subheadingStyle),
            ),
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
    final String id = course['id'] as String;
    final String title = course['title'] as String;
    final String description =
        course['description'] as String? ?? 'No description';
    final int videosCount =
        course['videos_count'] != null ? (course['videos_count'] as int) : 0;
    final String thumbnailUrl = course['thumbnail_url'] as String? ?? '';
    final bool isApproved = course['is_approved'] ?? false;
    final bool isActive = course['is_active'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCourseVideos(id, title),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course thumbnail
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image:
                    thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
                color: thumbnailUrl.isEmpty ? Colors.grey.shade200 : null,
              ),
              child:
                  thumbnailUrl.isEmpty
                      ? Center(
                        child: Icon(
                          Icons.photo,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      )
                      : null,
            ),
            Padding(
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_library,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$videosCount videos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _navigateToCourseVideos(id, title),
                          icon: const Icon(Icons.video_library, size: 18),
                          label: const Text('Manage Videos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(100, 36),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed:
                              () => _navigateToCourseWithLive(
                                id,
                                title,
                                isApproved,
                                isActive,
                              ),
                          icon: const Icon(Icons.live_tv, size: 18),
                          label: const Text('Go Live'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isApproved && isActive
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(80, 36),
                          ),
                        ),
                      ],
                    ),
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
