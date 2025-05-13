import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/internship_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

class CompanyJobsTab extends ConsumerStatefulWidget {
  const CompanyJobsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyJobsTab> createState() => _CompanyJobsTabState();
}

class _CompanyJobsTabState extends ConsumerState<CompanyJobsTab> {
  CompanyUser? _companyUser;
  bool _isLoading = true;
  List<Internship> _internships = [];
  bool _isCreatingInternship = false;
  bool _isEditingInternship = false;
  String _selectedFilter = 'All';
  Internship? _internshipToEdit;

  final _internshipFormKey = GlobalKey<FormState>();

  // Internship form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _skillsController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is CompanyUser) {
        setState(() {
          _companyUser = userProfile;
        });
        await _loadInternships();
      }
    } catch (e) {
      debugPrint('Error loading company profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInternships() async {
    if (_companyUser == null) return;

    try {
      final companyService = ref.read(companyServiceProvider);
      final internships = await companyService.getCompanyInternships(
        _companyUser!.id,
      );

      setState(() {
        _internships = internships;
      });
    } catch (e) {
      debugPrint('Error loading internships: $e');
    }
  }

  Future<void> _createInternship() async {
    if (!_internshipFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);

      // Convert comma-separated skills to a list
      final skillsList =
          _skillsController.text
              .split(',')
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList();

      final success = await companyService.createInternship(
        companyId: _companyUser!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        duration: _durationController.text.trim(),
        skills: skillsList,
        isPaid: _isPaid,
        city:
            _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _resetInternshipForm();

        // Reload internships
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while creating internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isCreatingInternship = false;
      });
    }
  }

  void _resetInternshipForm() {
    _titleController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _skillsController.clear();
    _cityController.clear();
    setState(() {
      _isPaid = false;
      _internshipToEdit = null;
    });
  }

  void _prepareInternshipForEdit(Internship internship) {
    // Set the internship to edit
    setState(() {
      _internshipToEdit = internship;
      _isEditingInternship = true;

      // Pre-fill form fields
      _titleController.text = internship.title;
      _descriptionController.text = internship.description;
      _durationController.text = internship.duration;
      _skillsController.text = internship.skills.join(', ');
      if (internship.city != null) {
        _cityController.text = internship.city!;
      } else {
        _cityController.clear();
      }
      _isPaid = internship.isPaid;
    });
  }

  Future<void> _updateInternship() async {
    if (!_internshipFormKey.currentState!.validate() ||
        _internshipToEdit == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);

      // Convert comma-separated skills to a list
      final skillsList =
          _skillsController.text
              .split(',')
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList();

      final success = await companyService.updateInternship(
        internshipId: _internshipToEdit!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        duration: _durationController.text.trim(),
        skills: skillsList,
        isPaid: _isPaid,
        city:
            _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _resetInternshipForm();

        // Reload internships
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isEditingInternship = false;
      });
    }
  }

  Future<void> _deleteInternship(String internshipId) async {
    // Show a confirmation dialog before deleting
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Internship'),
            content: const Text(
              'Are you sure you want to delete this internship? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);
      final success = await companyService.deleteInternship(internshipId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while deleting internship'),
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

  Future<void> _toggleInternshipStatus(
    String internshipId,
    bool currentStatus,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);
      final success = await companyService.updateInternshipStatus(
        internshipId: internshipId,
        isActive: !currentStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Internship deactivated successfully'
                  : 'Internship activated successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update internship status'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating internship status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating internship status'),
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

  List<Internship> get _filteredInternships {
    if (_selectedFilter == 'All') {
      return _internships;
    } else if (_selectedFilter == 'Active') {
      return _internships
          .where((internship) => internship.isActive == true)
          .toList();
    } else if (_selectedFilter == 'Inactive') {
      return _internships
          .where((internship) => internship.isActive == false)
          .toList();
    } else if (_selectedFilter == 'Approved') {
      return _internships
          .where((internship) => internship.isApproved == true)
          .toList();
    } else if (_selectedFilter == 'Pending') {
      return _internships
          .where((internship) => internship.isApproved == false)
          .toList();
    } else if (_selectedFilter == 'Paid') {
      return _internships
          .where((internship) => internship.isPaid == true)
          .toList();
    } else if (_selectedFilter == 'Unpaid') {
      return _internships
          .where((internship) => internship.isPaid == false)
          .toList();
    }
    return _internships;
  }

  // New helper method
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textLightColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textLightColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companyUser == null) {
      return const Center(child: Text('Error loading company profile'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (!_companyUser!.isApproved) _buildNotApprovedBanner(),
          if (_isCreatingInternship || _isEditingInternship)
            _buildInternshipForm(),
          _buildFilterChips(),
          _filteredInternships.isEmpty
              ? _buildEmptyState()
              : _buildInternshipsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Manage Internships', style: AppTheme.subheadingStyle),
              Text(
                '${_internships.length} total internships',
                style: const TextStyle(
                  color: AppTheme.textLightColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_companyUser!.isApproved)
            CustomButton(
              text: 'Create New',
              onPressed: () {
                setState(() {
                  _isCreatingInternship = true;
                });
              },
              icon: Icons.add,
              type: ButtonType.primary,
              height: 40.0,
              borderRadius: 8.0,
            ),
        ],
      ),
    );
  }

  Widget _buildNotApprovedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your account needs to be approved before you can post internships.',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Active'),
            const SizedBox(width: 8),
            _buildFilterChip('Inactive'),
            const SizedBox(width: 8),
            _buildFilterChip('Approved'),
            const SizedBox(width: 8),
            _buildFilterChip('Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('Paid'),
            const SizedBox(width: 8),
            _buildFilterChip('Unpaid'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (value) {
        if (value) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_off_outlined,
              size: 64,
              color: AppTheme.textLightColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No internships found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _companyUser!.isApproved
                  ? 'Create your first internship to get started'
                  : 'Your account needs to be approved before you can post internships',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textLightColor),
            ),
            if (_companyUser!.isApproved)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: CustomButton(
                  text: 'Create Internship',
                  onPressed: () {
                    setState(() {
                      _isCreatingInternship = true;
                    });
                  },
                  icon: Icons.add,
                  type: ButtonType.primary,
                  height: 40.0,
                  borderRadius: 8.0,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternshipsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredInternships.length,
      itemBuilder: (context, index) {
        return _buildInternshipCard(_filteredInternships[index]);
      },
    );
  }

  Widget _buildInternshipForm() {
    final isEditing = _isEditingInternship;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _internshipFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Internship' : 'Create New Internship',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          isEditing
                              ? _isEditingInternship = false
                              : _isCreatingInternship = false;
                          _resetInternshipForm();
                        });
                      },
                      tooltip: 'Close',
                      color: AppTheme.textLightColor,
                      iconSize: 20,
                    ),
                  ],
                ),
                const Divider(height: 32),
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
                CustomTextField(
                  label: 'Duration',
                  controller: _durationController,
                  hint: 'e.g., 3 months, Summer 2025',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Skills (comma-separated)',
                  controller: _skillsController,
                  hint: 'e.g., Flutter, Dart, Firebase',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one skill';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'City (optional)',
                  controller: _cityController,
                  hint: 'e.g., New York, Remote',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Paid Internship'),
                  value: _isPaid,
                  onChanged: (value) {
                    setState(() {
                      _isPaid = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomButton(
                      text: 'Cancel',
                      onPressed: () {
                        setState(() {
                          isEditing
                              ? _isEditingInternship = false
                              : _isCreatingInternship = false;
                          _resetInternshipForm();
                        });
                      },
                      type: ButtonType.secondary,
                      height: 40.0,
                      borderRadius: 8.0,
                    ),
                    const SizedBox(width: 16),
                    CustomButton(
                      text: isEditing ? 'Update' : 'Create',
                      onPressed:
                          isEditing ? _updateInternship : _createInternship,
                      isLoading: _isLoading,
                      type: ButtonType.primary,
                      height: 40.0,
                      borderRadius: 8.0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInternshipCard(Internship internship) {
    final bool isActive = internship.isActive;
    final bool isApproved = internship.isApproved ?? false;
    final List<String> skills = internship.skills;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    internship.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusIndicator(isApproved, isActive),
              ],
            ),
            const Divider(height: 24),
            Text(
              internship.description,
              style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, internship.duration),
            if (internship.city != null && internship.city!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildInfoRow(Icons.location_on, internship.city!),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppTheme.textLightColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    internship.isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      color:
                          internship.isPaid
                              ? AppTheme.successColor
                              : AppTheme.textLightColor,
                      fontWeight:
                          internship.isPaid
                              ? FontWeight.bold
                              : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (skills.isNotEmpty) ...[
              const Text(
                'Skills:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    skills.map((skill) => _buildSkillChip(skill)).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomButton(
                      text: 'Edit',
                      onPressed: () => _prepareInternshipForEdit(internship),
                      type: ButtonType.secondary,
                      icon: Icons.edit,
                      height: 32.0,
                      borderRadius: 6.0,
                    ),
                    const SizedBox(width: 6),
                    CustomButton(
                      text: 'Delete',
                      onPressed: () => _deleteInternship(internship.id),
                      type: ButtonType.danger,
                      icon: Icons.delete,
                      height: 32.0,
                      borderRadius: 6.0,
                    ),
                  ],
                ),
                // Toggle switch for active/inactive
                Row(
                  children: [
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isActive
                                ? AppTheme.infoColor
                                : AppTheme.textLightColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isActive,
                      onChanged:
                          (value) =>
                              _toggleInternshipStatus(internship.id, isActive),
                      activeColor: AppTheme.infoColor,
                      activeTrackColor: AppTheme.infoColor.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isApproved, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                isApproved ? 'Status: Approved' : 'Status: Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isApproved
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isApproved ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                isActive ? 'Availability: Active' : 'Availability: Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isActive ? AppTheme.infoColor : AppTheme.textLightColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.infoColor : AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
