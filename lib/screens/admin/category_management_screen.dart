import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/services/course_category_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Categories Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go('/admin');
          },
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isAddingCategory || _isEditingCategory)
                            _buildCategoryForm(),
                          if (!_isAddingCategory && !_isEditingCategory) ...[
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'All Categories',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Total: ${_categories.length}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 32),
                                    if (_categories.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.category_outlined,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'No categories found',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      AppTheme.textLightColor,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Add your first category to get started',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _categories.length,
                                        separatorBuilder:
                                            (context, index) =>
                                                const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final category = _categories[index];
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 8,
                                                ),
                                            leading: CircleAvatar(
                                              backgroundColor: AppTheme
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                              child: Text(
                                                category.name.isNotEmpty
                                                    ? category.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              category.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle:
                                                category.description != null &&
                                                        category
                                                            .description!
                                                            .isNotEmpty
                                                    ? Text(
                                                      category.description!,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                    : null,
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: AppTheme.accentColor,
                                                  ),
                                                  tooltip: 'Edit Category',
                                                  onPressed:
                                                      () =>
                                                          _showEditCategoryForm(
                                                            category,
                                                          ),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: AppTheme.errorColor,
                                                  ),
                                                  tooltip: 'Delete Category',
                                                  onPressed:
                                                      () =>
                                                          _showDeleteConfirmation(
                                                            category,
                                                          ),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton:
          !_isAddingCategory && !_isEditingCategory
              ? FloatingActionButton(
                onPressed: _showAddCategoryForm,
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage and organize your course categories',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (!_isAddingCategory && !_isEditingCategory)
                CustomButton(
                  text: 'Add Category',
                  onPressed: _showAddCategoryForm,
                  icon: Icons.add,
                  type: ButtonType.outline,
                  height: 40,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 24),
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
                    height: 42,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: _isAddingCategory ? 'Create' : 'Update',
                    onPressed:
                        _isAddingCategory ? _createCategory : _updateCategory,
                    isLoading: _isLoading,
                    type: ButtonType.primary,
                    height: 42,
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
