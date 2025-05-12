import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/services/course_category_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/screens/admin/gift_card_management_tab.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class AdminContentTab extends ConsumerStatefulWidget {
  const AdminContentTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends ConsumerState<AdminContentTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Course Categories'),
            Tab(text: 'Courses'),
            Tab(text: 'Gift Cards'),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLightColor,
          indicatorColor: AppTheme.accentColor,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CategoryManagementTab(),
              CourseManagementTab(),
              GiftCardManagementTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryManagementTab extends ConsumerStatefulWidget {
  const CategoryManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagementTab> createState() =>
      _CategoryManagementTabState();
}

class _CategoryManagementTabState extends ConsumerState<CategoryManagementTab> {
  List<CourseCategory> _categories = [];
  bool _isLoading = true;
  bool _isAddingCategory = false;
  bool _isEditingCategory = false;
  CourseCategory? _selectedCategory;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = ref.read(courseCategoryServiceProvider);
      final categories = await categoryService.getAllCategories();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddCategoryForm() {
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _isAddingCategory = true;
      _isEditingCategory = false;
      _selectedCategory = null;
    });
  }

  void _showEditCategoryForm(CourseCategory category) {
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    setState(() {
      _isAddingCategory = false;
      _isEditingCategory = true;
      _selectedCategory = category;
    });
  }

  void _cancelForm() {
    setState(() {
      _isAddingCategory = false;
      _isEditingCategory = false;
      _selectedCategory = null;
    });
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = ref.read(courseCategoryServiceProvider);
      final newCategory = await categoryService.createCategory(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (newCategory != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _cancelForm();
        await _loadCategories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create category'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while creating category'),
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

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = ref.read(courseCategoryServiceProvider);
      final success = await categoryService.updateCategory(
        categoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _cancelForm();
        await _loadCategories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update category'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating category'),
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

  Future<void> _deleteCategory(CourseCategory category) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = ref.read(courseCategoryServiceProvider);
      final success = await categoryService.deleteCategory(category.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadCategories();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete category'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while deleting category'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Course Categories',
                    style: AppTheme.subheadingStyle,
                  ),
                  if (!_isAddingCategory && !_isEditingCategory)
                    CustomButton(
                      text: 'Add Category',
                      onPressed: _showAddCategoryForm,
                      icon: Icons.add,
                      type: ButtonType.primary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isAddingCategory || _isEditingCategory) _buildCategoryForm(),
              if (!_isAddingCategory && !_isEditingCategory) ...[
                if (_categories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No categories found.',
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
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              category.description != null &&
                                      category.description!.isNotEmpty
                                  ? Text(category.description!)
                                  : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Category',
                                onPressed:
                                    () => _showEditCategoryForm(category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete Category',
                                onPressed:
                                    () => _showDeleteConfirmation(category),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
  }

  Widget _buildCategoryForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAddingCategory ? 'Add New Category' : 'Edit Category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
              ),
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
                    text: _isAddingCategory ? 'Create' : 'Update',
                    onPressed:
                        _isAddingCategory ? _createCategory : _updateCategory,
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

  void _showDeleteConfirmation(CourseCategory category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'Are you sure you want to delete the category "${category.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteCategory(category);
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
