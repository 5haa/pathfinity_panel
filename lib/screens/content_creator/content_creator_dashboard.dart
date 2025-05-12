import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/models/course_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/course_category_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:intl/intl.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class ContentCreatorDashboard extends ConsumerStatefulWidget {
  const ContentCreatorDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentCreatorDashboard> createState() =>
      _ContentCreatorDashboardState();
}

class _ContentCreatorDashboardState
    extends ConsumerState<ContentCreatorDashboard> {
  ContentCreatorUser? _creatorUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isCreatingCourse = false;
  List<Map<String, dynamic>> _courses = [];
  List<CourseCategory> _categories = [];
  String? _selectedCategoryId;

  final _formKey = GlobalKey<FormState>();
  final _courseFormKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  DateTime? _birthdate;

  // Course form controllers
  final _courseTitleController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  String _selectedMembershipType = MembershipType.pro;
  String _selectedDifficulty = DifficultyLevel.medium;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _loadCreatorProfile();
    _loadCategories();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
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

  Future<void> _loadCreatorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is ContentCreatorUser) {
        setState(() {
          _creatorUser = userProfile;
          _firstNameController.text = userProfile.firstName;
          _lastNameController.text = userProfile.lastName;
          _emailController.text = userProfile.email;
          _bioController.text = userProfile.bio ?? '';
          _phoneController.text = userProfile.phone ?? '';
          _birthdate = userProfile.birthdate;
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
    if (_creatorUser == null) return;

    try {
      final creatorService = ref.read(contentCreatorServiceProvider);
      final courses = await creatorService.getCreatorCourses(_creatorUser!.id);

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final creatorService = ref.read(contentCreatorServiceProvider);
      final success = await creatorService.updateProfile(
        userId: _creatorUser!.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        birthdate: _birthdate,
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadCreatorProfile();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating profile'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  Future<void> _createCourse() async {
    if (!_courseFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final creatorService = ref.read(contentCreatorServiceProvider);
      final courseId = await creatorService.createCourse(
        creatorId: _creatorUser!.id,
        title: _courseTitleController.text.trim(),
        description: _courseDescriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        membershipType: _selectedMembershipType,
        difficulty: _selectedDifficulty,
      );

      if (courseId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _courseTitleController.clear();
        _courseDescriptionController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedMembershipType = MembershipType.pro;
          _selectedDifficulty = DifficultyLevel.medium;
        });

        // Reload courses
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while creating course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isCreatingCourse = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      // Use the auth notifier to sign out
      await ref.read(authProvider.notifier).signOut();

      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Creator Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_creatorUser != null && _creatorUser!.isApproved) ...[
            IconButton(
              icon: const Icon(Icons.video_library),
              onPressed: () {
                GoRouter.of(context).push('/content-creator/live-sessions');
              },
              tooltip: 'My Live Sessions',
            ),
            IconButton(
              icon: const Icon(Icons.live_tv),
              onPressed: () {
                GoRouter.of(context).push('/content-creator/go-live');
              },
              tooltip: 'Go Live',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _creatorUser == null
              ? const Center(child: Text('Error loading creator profile'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 32),
                    _buildApprovalStatus(),
                    const SizedBox(height: 32),
                    _buildCoursesSection(),
                  ],
                ),
              ),
      floatingActionButton:
          _creatorUser != null && _creatorUser!.isApproved
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isCreatingCourse = true;
                  });
                },
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile Information', style: AppTheme.headingStyle),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    tooltip: 'Edit Profile',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _isEditing ? _buildEditForm() : _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add profile picture
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ProfilePictureWidget(
              userId: _creatorUser!.id,
              name: '${_creatorUser!.firstName} ${_creatorUser!.lastName}',
              profilePictureUrl: _creatorUser!.profilePictureUrl,
              userType: UserType.contentCreator,
              size: 120,
              onPictureUpdated: (url) {
                setState(() {
                  _creatorUser = _creatorUser!.copyWith(profilePictureUrl: url);
                });
              },
            ),
          ),
        ),
        // Existing profile info
        _buildInfoRow(
          'Name',
          '${_creatorUser!.firstName} ${_creatorUser!.lastName}',
        ),
        _buildInfoRow('Email', _creatorUser!.email),
        if (_creatorUser!.birthdate != null)
          _buildInfoRow(
            'Birthdate',
            DateFormat('yyyy-MM-dd').format(_creatorUser!.birthdate!),
          ),
        if (_creatorUser!.phone != null && _creatorUser!.phone!.isNotEmpty)
          _buildInfoRow('Phone', _creatorUser!.phone!),
        if (_creatorUser!.bio != null && _creatorUser!.bio!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_creatorUser!.bio!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textLightColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'First Name',
                  controller: _firstNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Birthdate
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birthdate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.secondaryColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _birthdate == null
                            ? 'Select your birthdate'
                            : DateFormat('MMM d, yyyy').format(_birthdate!),
                        style: TextStyle(
                          color:
                              _birthdate == null
                                  ? Colors.grey
                                  : AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Bio',
            controller: _bioController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Phone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    // Reset controllers to original values
                    _firstNameController.text = _creatorUser!.firstName;
                    _lastNameController.text = _creatorUser!.lastName;
                    _emailController.text = _creatorUser!.email;
                    _bioController.text = _creatorUser!.bio ?? '';
                    _phoneController.text = _creatorUser!.phone ?? '';
                    _birthdate = _creatorUser!.birthdate;
                  });
                },
                type: ButtonType.secondary,
              ),
              const SizedBox(width: 16),
              CustomButton(
                text: 'Save',
                onPressed: _updateProfile,
                isLoading: _isLoading,
                type: ButtonType.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStatus() {
    final isApproved = _creatorUser!.isApproved;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Status', style: AppTheme.headingStyle),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isApproved
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isApproved ? 'Approved' : 'Pending Approval',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isApproved
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isApproved
                  ? 'Your account has been approved. You can now create courses and upload videos.'
                  : 'Your account is pending approval by an administrator. You cannot create courses until your account is approved.',
              style: const TextStyle(color: AppTheme.textLightColor),
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
        const Text('Courses', style: AppTheme.headingStyle),
        const SizedBox(height: 16),
        if (_isCreatingCourse) _buildCourseForm(),
        if (!_creatorUser!.isApproved)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Your account needs to be approved before you can create courses.',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_courses.isEmpty && !_isCreatingCourse)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'You haven\'t created any courses yet.',
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ..._courses.map(_buildCourseCard).toList(),
      ],
    );
  }

  Widget _buildCourseForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _courseFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Course',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Title',
                controller: _courseTitleController,
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
                controller: _courseDescriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select a category'),
                        value: _selectedCategoryId,
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Membership Type',
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
                        child: RadioListTile<String>(
                          title: const Text('Free'),
                          value: MembershipType.free,
                          groupValue: _selectedMembershipType,
                          onChanged: (value) {
                            setState(() {
                              _selectedMembershipType = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pro'),
                          value: MembershipType.pro,
                          groupValue: _selectedMembershipType,
                          onChanged: (value) {
                            setState(() {
                              _selectedMembershipType = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty Level',
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
                        child: RadioListTile<String>(
                          title: const Text('Easy'),
                          value: DifficultyLevel.easy,
                          groupValue: _selectedDifficulty,
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Medium'),
                          value: DifficultyLevel.medium,
                          groupValue: _selectedDifficulty,
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Hard'),
                          value: DifficultyLevel.hard,
                          groupValue: _selectedDifficulty,
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () {
                      setState(() {
                        _isCreatingCourse = false;
                      });
                    },
                    type: ButtonType.secondary,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Create',
                    onPressed: _createCourse,
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

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final bool isActive = course['is_active'] ?? false;
    final bool isApproved = course['is_approved'] ?? false;
    final categoryData = course['course_categories'];
    final String categoryName =
        categoryData != null
            ? categoryData['name'] ?? 'Uncategorized'
            : 'Uncategorized';

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
              course['description'] ?? 'No description provided',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
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
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.card_membership,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Membership: ${course['membership_type'] ?? 'PRO'}',
                  style: const TextStyle(
                    color: AppTheme.textLightColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Difficulty: ${course['difficulty'] ?? 'MEDIUM'}',
                  style: const TextStyle(
                    color: AppTheme.textLightColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isApproved && isActive)
                  CustomButton(
                    text: 'Go Live',
                    onPressed: () {
                      GoRouter.of(context).push(
                        '/content-creator/go-live',
                        extra: {
                          'courseId': course['id'],
                          'courseTitle': course['title'] ?? 'Untitled Course',
                        },
                      );
                    },
                    type: ButtonType.primary,
                    height: 36,
                    icon: Icons.live_tv,
                  ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Manage Videos',
                  onPressed: () {
                    // Navigate to video management screen
                    GoRouter.of(context).push(
                      '/course/${course['id']}/videos',
                      extra: {
                        'courseTitle': course['title'] ?? 'Untitled Course',
                      },
                    );
                  },
                  type: ButtonType.primary,
                  height: 36,
                  icon: Icons.video_library,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
