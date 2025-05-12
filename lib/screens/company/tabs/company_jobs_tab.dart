import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';

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
  List<Map<String, dynamic>> _jobs = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
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
        await _loadJobs();
      }
    } catch (e) {
      debugPrint('Error loading company profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadJobs() async {
    if (_companyUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _jobs = [
          {
            'id': '1',
            'title': 'Software Engineer',
            'description':
                'We are looking for a skilled software engineer with experience in Flutter and Dart.',
            'location': 'New York, NY',
            'type': 'Full-time',
            'status': 'Active',
            'applications': 15,
            'created_at': DateTime.now().subtract(const Duration(days: 5)),
          },
          {
            'id': '2',
            'title': 'UX Designer',
            'description':
                'Seeking a creative UX designer to join our product team.',
            'location': 'Remote',
            'type': 'Full-time',
            'status': 'Active',
            'applications': 8,
            'created_at': DateTime.now().subtract(const Duration(days: 3)),
          },
          {
            'id': '3',
            'title': 'Marketing Manager',
            'description':
                'Looking for an experienced marketing manager to lead our marketing efforts.',
            'location': 'San Francisco, CA',
            'type': 'Full-time',
            'status': 'Draft',
            'applications': 0,
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
          },
          {
            'id': '4',
            'title': 'Data Analyst Intern',
            'description':
                'Internship opportunity for a data analyst to work with our data science team.',
            'location': 'Chicago, IL',
            'type': 'Internship',
            'status': 'Closed',
            'applications': 25,
            'created_at': DateTime.now().subtract(const Duration(days: 30)),
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading jobs: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All') {
      return _jobs;
    } else {
      return _jobs.where((job) => job['status'] == _selectedFilter).toList();
    }
  }

  void _createNewJob() {
    // In a real app, this would navigate to a job creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create new job functionality would be implemented here'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _viewJobDetails(String jobId) {
    // In a real app, this would navigate to a job details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View job details for job ID: $jobId'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _editJob(String jobId) {
    // In a real app, this would navigate to a job edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit job with ID: $jobId'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _deleteJob(String jobId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Job'),
            content: const Text(
              'Are you sure you want to delete this job posting?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // In a real app, this would call a service to delete the job
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Job with ID: $jobId deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  // Simulate job deletion
                  setState(() {
                    _jobs.removeWhere((job) => job['id'] == jobId);
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

    if (_companyUser == null) {
      return const Center(child: Text('Error loading company profile'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildFilterChips(),
        Expanded(
          child: _filteredJobs.isEmpty ? _buildEmptyState() : _buildJobsList(),
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
            'Job Postings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          CustomButton(
            text: 'Create New Job',
            onPressed: _createNewJob,
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
            _buildFilterChip('Active'),
            const SizedBox(width: 8),
            _buildFilterChip('Draft'),
            const SizedBox(width: 8),
            _buildFilterChip('Closed'),
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
          Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No job postings yet'
                : 'No $_selectedFilter job postings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Create your first job posting to get started'
                : 'Try selecting a different filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (_selectedFilter == 'All')
            CustomButton(
              text: 'Create New Job',
              onPressed: _createNewJob,
              icon: Icons.add,
              type: ButtonType.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) {
        final job = _filteredJobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final String id = job['id'];
    final String title = job['title'];
    final String description = job['description'];
    final String location = job['location'];
    final String type = job['type'];
    final String status = job['status'];
    final int applications = job['applications'];
    final DateTime createdAt = job['created_at'];

    // Determine status color
    Color statusColor;
    switch (status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Draft':
        statusColor = Colors.orange;
        break;
      case 'Closed':
        statusColor = Colors.red;
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
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.work, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  type,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$applications applications',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Posted ${_formatDate(createdAt)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View Details',
                  onPressed: () => _viewJobDetails(id),
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Job',
                  onPressed: () => _editJob(id),
                  color: Colors.orange,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Job',
                  onPressed: () => _deleteJob(id),
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
