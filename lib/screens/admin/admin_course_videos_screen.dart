import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/video_player_widget.dart';

class AdminCourseVideosScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const AdminCourseVideosScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  ConsumerState<AdminCourseVideosScreen> createState() =>
      _AdminCourseVideosScreenState();
}

class _AdminCourseVideosScreenState
    extends ConsumerState<AdminCourseVideosScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseData;
  List<Map<String, dynamic>> _courseVideos = [];
  List<Map<String, dynamic>> _videoChanges = [];
  bool _showVideoChangesTab = false;

  @override
  void initState() {
    super.initState();
    _loadCourseVideos();
    _loadVideoChanges();
  }

  // Load course and its videos
  Future<void> _loadCourseVideos() async {
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
          if (courseWithVideos['course_videos'] != null) {
            _courseVideos = List<Map<String, dynamic>>.from(
              courseWithVideos['course_videos'],
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading course videos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load pending video changes
  Future<void> _loadVideoChanges() async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final videoChanges = await adminService.getPendingVideoChanges();

      // Filter only changes for this course
      final filteredChanges =
          videoChanges.where((change) {
            final videoData = change['course_video'];
            return videoData != null &&
                videoData['course_id'] == widget.courseId;
          }).toList();

      setState(() {
        _videoChanges = filteredChanges;
        _showVideoChangesTab = filteredChanges.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error loading video changes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Videos: ${widget.courseTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // Use GoRouter to navigate back to the course management screen
              context.go(
                '/admin/courses/${widget.courseId}/management',
                extra: {'courseTitle': widget.courseTitle},
              );
            } catch (e) {
              // Fallback navigation in case of routing issues
              debugPrint('Navigation error: $e');
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/admin');
              }
            }
          },
        ),
        actions: [
          if (_showVideoChangesTab)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildNotificationBadge(
                'Video Changes',
                _videoChanges.length,
                Colors.blue,
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                length: _showVideoChangesTab ? 2 : 1,
                child: Column(
                  children: [
                    if (_showVideoChangesTab)
                      TabBar(
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textLightColor,
                        tabs: [
                          const Tab(
                            icon: Icon(Icons.video_library),
                            text: 'Course Videos',
                          ),
                          Tab(
                            icon: const Icon(Icons.edit_note),
                            text: 'Video Changes (${_videoChanges.length})',
                          ),
                        ],
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildVideosTab(),
                          if (_showVideoChangesTab) _buildVideoChangesTab(),
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

  // Videos tab content
  Widget _buildVideosTab() {
    return RefreshIndicator(
      onRefresh: _loadCourseVideos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_courseVideos.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courseVideos.length,
                itemBuilder: (context, index) {
                  final video = _courseVideos[index];
                  return _buildVideoCard(video);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Video changes tab content
  Widget _buildVideoChangesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadVideoChanges();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_videoChanges.isEmpty)
              _buildEmptyState(message: 'No video changes pending')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _videoChanges.length,
                itemBuilder: (context, index) {
                  final videoChange = _videoChanges[index];
                  return _buildVideoChangeCard(videoChange);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final String videoTitle = video['title'] ?? 'Untitled Video';
    final String videoDescription =
        video['description'] ?? 'No description provided';
    final String? videoUrl = video['video_url'];
    final bool isFreePreview = video['is_free_preview'] ?? false;
    final int sequenceNumber = video['sequence_number'] ?? 0;
    final DateTime createdAt = DateTime.parse(video['created_at']);
    final String? thumbnailUrl = video['thumbnail_url'];

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
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    sequenceNumber.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    videoTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFreePreview)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: const Text(
                      'Free Preview',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video preview
          if (videoUrl != null && videoUrl.isNotEmpty)
            Container(
              height: 180,
              width: double.infinity,
              child: VideoThumbnail(
                videoUrl: videoUrl,
                thumbnailUrl: thumbnailUrl,
                width: double.infinity,
                height: 180,
                onTap: () {
                  _showVideoPreview(videoUrl, videoTitle);
                },
                isFreePreview: isFreePreview,
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  videoDescription,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Added on: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: AppTheme.textLightColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoChangeCard(Map<String, dynamic> videoChange) {
    // Extract video data
    final videoData = videoChange['course_video'];
    if (videoData == null) {
      return const SizedBox.shrink(); // Skip if no video data
    }

    final videoTitle = videoData['title'] ?? 'Untitled Video';

    // Extract fields that changed
    final String? newTitle = videoChange['title'];
    final String? newDescription = videoChange['description'];
    final String? newVideoUrl = videoChange['video_url'];

    final DateTime createdAt = DateTime.parse(videoChange['created_at']);

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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_library, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proposed Changes to Video: $videoTitle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(
                    color: Colors.blue.withOpacity(0.8),
                    fontSize: 12,
                  ),
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
                // Changes
                if (newTitle != null)
                  _buildChangeRow(
                    'Title',
                    videoData['title'] ?? 'None',
                    newTitle,
                  ),

                if (newDescription != null)
                  _buildChangeRow(
                    'Description',
                    videoData['description'] ?? 'No description',
                    newDescription,
                  ),

                if (newVideoUrl != null)
                  _buildChangeRow(
                    'Video URL',
                    videoData['video_url'] ?? 'No video',
                    'New video uploaded',
                  ),

                if (videoChange['thumbnail_url'] != null)
                  _buildChangeRow(
                    'Thumbnail',
                    videoData['thumbnail_url'] != null
                        ? 'Current thumbnail'
                        : 'No thumbnail',
                    'New thumbnail uploaded',
                  ),

                if (videoChange['is_free_preview'] != null)
                  _buildChangeRow(
                    'Free Preview',
                    (videoData['is_free_preview'] ?? false) ? 'Yes' : 'No',
                    (videoChange['is_free_preview'] ?? false) ? 'Yes' : 'No',
                  ),

                if (newVideoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildVideoPreviewRow(
                      videoData['video_url'],
                      newVideoUrl,
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Approve Changes',
                      onPressed: () => _approveVideoChange(videoChange['id']),
                      type: ButtonType.success,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: 'Reject Changes',
                      onPressed:
                          () => _showRejectChangeDialog(videoChange['id']),
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

  Widget _buildVideoPreviewRow(String? oldVideoUrl, String newVideoUrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Current Video',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLightColor,
                ),
              ),
              const SizedBox(height: 8),
              oldVideoUrl != null && oldVideoUrl.isNotEmpty
                  ? VideoThumbnail(
                    videoUrl: oldVideoUrl,
                    width: double.infinity,
                    height: 100,
                    onTap: () {
                      _showVideoPreview(oldVideoUrl, 'Current Video');
                    },
                  )
                  : Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'No video',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        const Center(
          child: Icon(Icons.arrow_forward, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'New Video',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              VideoThumbnail(
                videoUrl: newVideoUrl,
                width: double.infinity,
                height: 100,
                onTap: () {
                  _showVideoPreview(newVideoUrl, 'New Video');
                },
                isFreePreview: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({String? message}) {
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
            Icons.video_library,
            size: 64,
            color: AppTheme.textLightColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No videos found for this course',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Videos will appear here once they are added',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCourseVideos,
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

  Future<void> _approveVideoChange(String changeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveVideoChange(changeId);

      if (success && mounted) {
        // Remove the change from the local state
        setState(() {
          _videoChanges.removeWhere((change) => change['id'] == changeId);
          _showVideoChangesTab = _videoChanges.isNotEmpty;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video changes approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Reload videos to reflect the changes
        await _loadCourseVideos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve video changes'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving video changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while approving video changes'),
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
            title: const Text('Reject Video Changes'),
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
                    _rejectVideoChange(changeId, reason);
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

  Future<void> _rejectVideoChange(String changeId, String reason) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.rejectVideoChange(changeId, reason);

      if (success && mounted) {
        // Remove the change from the local state
        setState(() {
          _videoChanges.removeWhere((change) => change['id'] == changeId);
          _showVideoChangesTab = _videoChanges.isNotEmpty;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video changes rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject video changes'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting video changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while rejecting video changes'),
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

  // Video preview dialog
  void _showVideoPreview(String videoUrl, String title) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                          maxWidth: MediaQuery.of(context).size.width,
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: VideoPlayerWidget(
                              videoUrl: videoUrl,
                              autoPlay: true,
                              showControls: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
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
}

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());
