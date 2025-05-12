import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/course_video_service.dart';
import 'package:admin_panel/models/course_video_model.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/video_player_widget.dart';
import 'package:admin_panel/providers/auth_provider.dart';

class CourseVideosScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseVideosScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  ConsumerState<CourseVideosScreen> createState() => _CourseVideosScreenState();
}

class _CourseVideosScreenState extends ConsumerState<CourseVideosScreen> {
  bool _isLoading = true;
  List<CourseVideo> _videos = [];
  bool _isAddingVideo = false;
  bool _isEditingVideo = false;
  CourseVideo? _selectedVideo;
  File? _selectedVideoFile;
  File? _selectedThumbnailFile;
  bool _isUploading = false;
  String? _currentUserId;

  // Form controllers
  final _videoFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isFreePreview = false;
  int _nextSequenceNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _getCurrentUserId();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserId() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
      debugPrint("Current user ID set to: ${user.id}");
    } else {
      debugPrint("Warning: No current user found. User ID remains null.");
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseVideoService = ref.read(courseVideoServiceProvider);
      final videos = await courseVideoService.getCourseVideos(widget.courseId);

      setState(() {
        _videos = videos;
        _nextSequenceNumber =
            videos.isEmpty
                ? 1
                : videos
                        .map<int>((v) => v.sequenceNumber)
                        .reduce((a, b) => a > b ? a : b) +
                    1;
      });
    } catch (e) {
      debugPrint('Error loading videos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedVideoFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting video file'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedThumbnailFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking thumbnail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting thumbnail image'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAddVideoForm() {
    // Clear form
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _isAddingVideo = true;
      _isEditingVideo = false;
      _selectedVideo = null;
      _selectedVideoFile = null;
      _selectedThumbnailFile = null;
      _isFreePreview = false;
    });
  }

  void _showEditVideoForm(CourseVideo video) {
    // Populate form with video data
    _titleController.text = video.title;
    _descriptionController.text = video.description;

    setState(() {
      _isAddingVideo = false;
      _isEditingVideo = true;
      _selectedVideo = video;
      _selectedVideoFile = null;
      _selectedThumbnailFile = null;
      _isFreePreview = video.isFreePreview;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingVideo = false;
      _isEditingVideo = false;
      _selectedVideo = null;
      _selectedVideoFile = null;
      _selectedThumbnailFile = null;
      _isFreePreview = false;
    });
  }

  Future<void> _addVideo() async {
    if (!_videoFormKey.currentState!.validate()) {
      return;
    }

    if (_selectedVideoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final courseVideoService = ref.read(courseVideoServiceProvider);
      final newVideo = await courseVideoService.addCourseVideoWithFile(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        videoFile: _selectedVideoFile!,
        thumbnailFile: _selectedThumbnailFile,
        sequenceNumber: _nextSequenceNumber,
        isFreePreview: _isFreePreview,
        creatorId: _currentUserId!,
      );

      if (newVideo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _cancelForm();
        await _loadVideos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to add video. Please check storage bucket configuration.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding video: $e');
      String errorMessage = 'An error occurred while adding video';

      // Check for common storage errors
      if (e.toString().contains('Bucket not found')) {
        errorMessage =
            'Storage bucket not found. Please ensure storage buckets exist in Supabase.';
      } else if (e.toString().contains('FileNotFoundException')) {
        errorMessage =
            'File not found or inaccessible. Please select a different file.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  Future<void> _updateVideo() async {
    if (!_videoFormKey.currentState!.validate() || _selectedVideo == null) {
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading =
          _selectedVideoFile != null || _selectedThumbnailFile != null;
    });

    try {
      final courseVideoService = ref.read(courseVideoServiceProvider);
      final success = await courseVideoService.updateCourseVideoWithFile(
        videoId: _selectedVideo!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        newVideoFile: _selectedVideoFile,
        newThumbnailFile: _selectedThumbnailFile,
        isFreePreview: _isFreePreview,
        creatorId: _currentUserId!,
        currentVideoUrl: _selectedVideo!.videoUrl,
        currentThumbnailUrl: _selectedVideo!.thumbnailUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _cancelForm();
        await _loadVideos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update video. Please check storage bucket configuration.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating video: $e');
      String errorMessage = 'An error occurred while updating video';

      // Check for common storage errors
      if (e.toString().contains('Bucket not found')) {
        errorMessage =
            'Storage bucket not found. Please ensure storage buckets exist in Supabase.';
      } else if (e.toString().contains('FileNotFoundException')) {
        errorMessage =
            'File not found or inaccessible. Please select a different file.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteVideo(CourseVideo video) async {
    if (_currentUserId == null) {
      // This check might be redundant if delete doesn't need creatorId directly
      // but good for consistency or future needs.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Cannot delete video.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final courseVideoService = ref.read(courseVideoServiceProvider);
      final success = await courseVideoService.deleteCourseVideoWithFile(
        videoId: video.id,
        videoUrl: video.videoUrl,
        thumbnailUrl: video.thumbnailUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadVideos();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete video'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while deleting video'),
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

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final CourseVideo item = _videos.removeAt(oldIndex);
    _videos.insert(newIndex, item);

    setState(() {}); // Optimistic update for UI

    // The sequence numbers in the _videos list are implicitly updated by reordering.
    // The CourseVideo objects themselves retain their original sequenceNumber from the DB
    // until a successful refresh (_loadVideos).
    // The map sent to the service should reflect the new visual order.

    final List<Map<String, dynamic>> videoSequences =
        _videos.asMap().entries.map((entry) {
          int idx = entry.key;
          CourseVideo video = entry.value;
          return {
            'id': video.id,
            'sequence_number':
                idx + 1, // New sequence based on current list order
          };
        }).toList();

    try {
      final courseVideoService = ref.read(courseVideoServiceProvider);
      final success = await courseVideoService.updateVideoSequence(
        widget.courseId,
        videoSequences,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video order updated successfully.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadVideos(); // Refresh from server to get consistent data including new sequence numbers
      } else {
        _loadVideos(); // Revert to server state if update failed
      }
    } catch (e) {
      debugPrint('Error reordering videos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while reordering videos'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        await _loadVideos(); // Reload to get original order
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Videos for ${widget.courseTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Course Videos',
                          style: AppTheme.headingStyle,
                        ),
                        if (!_isAddingVideo && !_isEditingVideo)
                          CustomButton(
                            text: 'Add Video',
                            onPressed: _showAddVideoForm,
                            icon: Icons.add,
                            type: ButtonType.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isAddingVideo || _isEditingVideo) _buildVideoForm(),
                    if (!_isAddingVideo && !_isEditingVideo)
                      _videos.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No videos added to this course yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textLightColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                          : _buildVideosList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildVideoForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _videoFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAddingVideo ? 'Add New Video' : 'Edit Video',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Title',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Video file selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video File',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Text(
                            _selectedVideoFile != null
                                ? _selectedVideoFile!.path.split('/').last
                                : _isEditingVideo
                                ? 'Current video: ${_selectedVideo?.videoUrl?.split('/').last ?? 'Unknown'}'
                                : 'No file selected',
                            style: TextStyle(
                              color:
                                  _selectedVideoFile != null || _isEditingVideo
                                      ? AppTheme.textColor
                                      : Colors.grey,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      CustomButton(
                        text: 'Browse',
                        onPressed: _pickVideo,
                        icon: Icons.upload_file,
                        type: ButtonType.secondary,
                      ),
                    ],
                  ),
                  if (_selectedVideoFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'File size: ${(_selectedVideoFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Thumbnail file selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thumbnail Image (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Text(
                            _selectedThumbnailFile != null
                                ? _selectedThumbnailFile!.path.split('/').last
                                : _isEditingVideo &&
                                    _selectedVideo?.thumbnailUrl != null
                                ? 'Current thumbnail: ${_selectedVideo?.thumbnailUrl?.split('/').last ?? 'Unknown'}'
                                : 'No thumbnail selected',
                            style: TextStyle(
                              color:
                                  _selectedThumbnailFile != null ||
                                          (_isEditingVideo &&
                                              _selectedVideo?.thumbnailUrl !=
                                                  null)
                                      ? AppTheme.textColor
                                      : Colors.grey,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      CustomButton(
                        text: 'Browse',
                        onPressed: _pickThumbnail,
                        icon: Icons.image,
                        type: ButtonType.secondary,
                      ),
                    ],
                  ),
                  if (_selectedThumbnailFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'File size: ${(_selectedThumbnailFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Recommended size: 1280x720 pixels (16:9 ratio)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Free preview toggle
              Row(
                children: [
                  Checkbox(
                    value: _isFreePreview,
                    onChanged: (value) {
                      setState(() {
                        _isFreePreview = value ?? false;
                      });
                    },
                    activeColor: AppTheme.successColor,
                  ),
                  const Text(
                    'Make this video available as a free preview',
                    style: TextStyle(fontSize: 14, color: AppTheme.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text(
                  'Free preview videos can be watched by all users, even if the course requires a pro membership.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Upload progress indicator
              if (_isUploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Uploading...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLightColor,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    onPressed: _cancelForm,
                    type: ButtonType.secondary,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: _isAddingVideo ? 'Add Video' : 'Update Video',
                    onPressed: _isAddingVideo ? _addVideo : _updateVideo,
                    isLoading: _isLoading,
                    type: ButtonType.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _videos.length,
      onReorder: _handleReorder,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final bool isApproved = video.isApproved ?? false;
        final bool isReviewed = video.isReviewed ?? false;

        return Card(
          key: ValueKey(video.id),
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video thumbnail
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: VideoThumbnail(
                      videoUrl: video.videoUrl,
                      thumbnailUrl: video.thumbnailUrl,
                      width: 160,
                      height: 90,
                      isFreePreview: video.isFreePreview,
                      onTap: () => _showVideoPreview(video),
                    ),
                  ),
                  // Video details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title ?? 'Untitled Video',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.description ?? 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  isReviewed
                                      ? (isApproved ? 'Approved' : 'Rejected')
                                      : 'Pending Review',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    isReviewed
                                        ? (isApproved
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor)
                                        : AppTheme.warningColor,
                              ),
                              if (!isReviewed || isApproved)
                                Chip(
                                  label: Text(
                                    'Lesson ${video.sequenceNumber}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.grey[200],
                                ),
                              if (video.isFreePreview)
                                Chip(
                                  label: const Text(
                                    'Free Preview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.successColor,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Video',
                      onPressed: () {
                        _showEditVideoForm(video);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Video',
                      onPressed: () {
                        _showDeleteConfirmation(video);
                      },
                    ),
                  ],
                ),
              ),
              if (video.rejectionReason != null && !isApproved && isReviewed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: AppTheme.errorColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection reason: ${video.rejectionReason}',
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoPreview(CourseVideo video) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title ?? 'Video Preview',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (video.isFreePreview) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Free Preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: VideoPlayerWidget(
                        videoUrl: video.videoUrl ?? '',
                        autoPlay: true,
                        showControls: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(CourseVideo video) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Video'),
            content: const Text(
              'Are you sure you want to delete this video? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteVideo(video);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
