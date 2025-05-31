import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/models/course_model.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/course_video_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/services/course_category_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/course/course_card.dart';
import 'package:admin_panel/widgets/course/course_form.dart';
import 'package:admin_panel/widgets/course/empty_state.dart';
import 'package:admin_panel/widgets/course/filter_chips.dart';
import 'package:admin_panel/widgets/course/thumbnail_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

final courseVideoServiceProvider = Provider<CourseVideoService>(
  (ref) => CourseVideoService(),
);

final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class ContentCreatorCoursesTab extends ConsumerStatefulWidget {
  const ContentCreatorCoursesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentCreatorCoursesTab> createState() =>
      _ContentCreatorCoursesTabState();
}

class _ContentCreatorCoursesTabState
    extends ConsumerState<ContentCreatorCoursesTab> {
  final _supabase = Supabase.instance.client;

  ContentCreatorUser? _contentCreatorUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  String _selectedFilter = 'All';
  bool _isCreatingCourse = false;
  List<CourseCategory> _categories = [];
  File? _thumbnailFile;
  String? _currentThumbnailUrl;
  bool _isUploading = false;

  // Form controllers for creating a course
  final _courseFormKey = GlobalKey<FormState>();
  final _courseTitleController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  String? _selectedCategoryId;
  String _selectedMembershipType = MembershipType.pro;
  String _selectedDifficulty = DifficultyLevel.medium;

  @override
  void initState() {
    super.initState();
    _loadContentCreatorProfile();
    _loadCategories();
  }

  @override
  void dispose() {
    _courseTitleController.dispose();
    _courseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categoryService = ref.read(courseCategoryServiceProvider);
      final categories = await categoryService.getAllCategories();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
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
      final contentCreatorService = ref.read(contentCreatorServiceProvider);
      final courseVideoService = ref.read(courseVideoServiceProvider);

      // Get courses from the service
      final courses = await contentCreatorService.getCreatorCourses(
        _contentCreatorUser!.id,
      );

      // Process courses to add additional information
      final List<Map<String, dynamic>> processedCourses = [];

      for (final course in courses) {
        // Get videos for this course to count them
        final videos = await courseVideoService.getCourseVideos(course['id']);

        // Create a processed course with additional information
        final processedCourse = Map<String, dynamic>.from(course);

        // Add video count
        processedCourse['videos_count'] = videos.length;

        // Add student count (in a real app, you would get this from a service)
        processedCourse['students_count'] = 0; // Placeholder

        // Add status based on is_approved
        final bool isApproved = course['is_approved'] ?? false;

        processedCourse['status'] = isApproved ? 'Published' : 'Pending';

        // Add created_at as DateTime
        processedCourse['created_at'] = DateTime.parse(course['created_at']);

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

  List<Map<String, dynamic>> get _filteredCourses {
    if (_selectedFilter == 'All') {
      return _courses;
    } else {
      return _courses
          .where((course) => course['status'] == _selectedFilter)
          .toList();
    }
  }

  Future<void> _selectThumbnail() async {
    final file = await ThumbnailSelector.selectThumbnail(context);
    if (file != null) {
      setState(() {
        _thumbnailFile = file;
      });
    }
  }

  void _createNewCourse() {
    setState(() {
      _isCreatingCourse = true;
      _courseTitleController.clear();
      _courseDescriptionController.clear();
      _selectedCategoryId = null;
      _selectedMembershipType = MembershipType.pro;
      _selectedDifficulty = DifficultyLevel.medium;
      _thumbnailFile = null;
      _currentThumbnailUrl = null;
    });
  }

  void _cancelCreateCourse() {
    setState(() {
      _isCreatingCourse = false;
    });
  }

  Future<void> _submitCreateCourse() async {
    if (!_courseFormKey.currentState!.validate()) {
      return;
    }

    if (_contentCreatorUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile not loaded. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = _thumbnailFile != null;
    });

    try {
      final contentCreatorService = ref.read(contentCreatorServiceProvider);

      // Use the new method that handles thumbnail upload
      final courseId = await contentCreatorService.createCourseWithThumbnail(
        creatorId: _contentCreatorUser!.id,
        title: _courseTitleController.text.trim(),
        description: _courseDescriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        membershipType: _selectedMembershipType,
        difficulty: _selectedDifficulty,
        thumbnailFile: _thumbnailFile,
      );

      if (courseId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        setState(() {
          _isCreatingCourse = false;
          _isUploading = false;
        });

        // Reload courses
        await _loadCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating course: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
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
    // Find the course with this ID
    final course = _courses.firstWhere(
      (c) => c['id'] == courseId,
      orElse: () => {},
    );
    if (course.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course not found'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Populate form fields with existing course data
    _courseTitleController.text = course['title'] as String;
    _courseDescriptionController.text = course['description'] as String? ?? '';
    _selectedCategoryId = course['category_id'] as String?;
    _selectedMembershipType =
        course['membership_type'] as String? ?? MembershipType.pro;
    _selectedDifficulty =
        course['difficulty'] as String? ?? DifficultyLevel.medium;
    _thumbnailFile = null;
    _currentThumbnailUrl = course['thumbnail_url'] as String?;

    // Show the edit form
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: CourseForm(
                    formKey: _courseFormKey,
                    titleController: _courseTitleController,
                    descriptionController: _courseDescriptionController,
                    selectedCategoryId: _selectedCategoryId,
                    selectedMembershipType: _selectedMembershipType,
                    selectedDifficulty: _selectedDifficulty,
                    thumbnailFile: _thumbnailFile,
                    currentThumbnailUrl: _currentThumbnailUrl,
                    categories: _categories,
                    isUploading: _isUploading,
                    isEditing: true,
                    onCategoryChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    onMembershipTypeChanged: (value) {
                      setState(() {
                        _selectedMembershipType = value;
                      });
                    },
                    onDifficultyChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                      });
                    },
                    onSelectThumbnail: () async {
                      final file = await ThumbnailSelector.selectThumbnail(
                        context,
                      );
                      if (file != null) {
                        setState(() {
                          _thumbnailFile = file;
                        });
                      }
                    },
                    onSubmit: () {
                      if (_courseFormKey.currentState!.validate()) {
                        Navigator.pop(context);
                        _updateCourse(courseId);
                      }
                    },
                    onCancel: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateCourse(String courseId) async {
    setState(() {
      _isLoading = true;
      _isUploading = _thumbnailFile != null;
    });

    try {
      final contentCreatorService = ref.read(contentCreatorServiceProvider);

      // Find current course data
      final course = _courses.firstWhere((c) => c['id'] == courseId);
      final currentThumbnailUrl = course['thumbnail_url'] as String?;

      // Use the updated requestCourseChanges method that handles thumbnails
      final success = await contentCreatorService.requestCourseChanges(
        courseId: courseId,
        title: _courseTitleController.text.trim(),
        description: _courseDescriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        thumbnailFile: _thumbnailFile,
        creatorId: _contentCreatorUser?.id,
        currentThumbnailUrl: currentThumbnailUrl,
      );

      // Update membership type and difficulty directly
      if (success) {
        await _supabase
            .from('courses')
            .update({
              'membership_type': _selectedMembershipType,
              'difficulty': _selectedDifficulty,
            })
            .eq('id', courseId);

        // Reload courses instead of manually updating the UI
        await _loadCourses();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course changes submitted for approval'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit course changes'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating course: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteCourse(String courseId) async {
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
                onPressed: () async {
                  Navigator.pop(context);

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // In a real app, you would call a service to delete the course
                    // For now, we'll just simulate the deletion
                    await Future.delayed(const Duration(milliseconds: 500));

                    // Remove the course from the list
                    setState(() {
                      _courses.removeWhere(
                        (course) => course['id'] == courseId,
                      );
                      _isLoading = false;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Course with ID: $courseId deleted'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error deleting course: $e');

                    setState(() {
                      _isLoading = false;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete course'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isCreatingCourse)
            _buildCreateCourseForm()
          else
            CourseFilterChips(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          if (!_isCreatingCourse)
            Expanded(
              child:
                  _filteredCourses.isEmpty
                      ? EmptyCoursesState(
                        selectedFilter: _selectedFilter,
                        onCreateCourse: _createNewCourse,
                      )
                      : _buildCoursesList(),
            ),
          const SizedBox(height: 16), // Add bottom padding for navigation bar
        ],
      ),
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

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return CourseCard(
          course: course,
          onEditTap: _editCourse,
          onDeleteTap: _deleteCourse,
          onVideosTap: _navigateToCourseVideos,
          onGoLiveTap: _navigateToGoLive,
        );
      },
    );
  }

  Widget _buildCreateCourseForm() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CourseForm(
              formKey: _courseFormKey,
              titleController: _courseTitleController,
              descriptionController: _courseDescriptionController,
              selectedCategoryId: _selectedCategoryId,
              selectedMembershipType: _selectedMembershipType,
              selectedDifficulty: _selectedDifficulty,
              thumbnailFile: _thumbnailFile,
              categories: _categories,
              isUploading: _isUploading,
              isLoading: _isLoading,
              onCategoryChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              onMembershipTypeChanged: (value) {
                setState(() {
                  _selectedMembershipType = value;
                });
              },
              onDifficultyChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
              onSelectThumbnail: _selectThumbnail,
              onSubmit: _submitCreateCourse,
              onCancel: _cancelCreateCourse,
            ),
          ),
        ),
      ),
    );
  }
}
