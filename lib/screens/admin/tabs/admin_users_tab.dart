import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/services/auth_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _contentCreators = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);

      final admins = await adminService.getAllAdmins();
      final alumni = await adminService.getAllAlumni();
      final companies = await adminService.getAllCompanies();
      final contentCreators = await adminService.getAllContentCreators();

      setState(() {
        _admins = admins.map((user) => user.toJson()).toList();
        _alumni = alumni.map((user) => user.toJson()).toList();
        _companies = companies.map((user) => user.toJson()).toList();
        _contentCreators =
            contentCreators.map((user) => user.toJson()).toList();
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Admins'),
              Tab(text: 'Alumni'),
              Tab(text: 'Companies'),
              Tab(text: 'Content Creators'),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textLightColor,
            indicatorColor: AppTheme.accentColor,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(_admins, 'admin'),
                _buildUsersList(_alumni, 'alumni'),
                _buildUsersList(_companies, 'company'),
                _buildUsersList(_contentCreators, 'content_creator'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users, String userType) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 18, color: AppTheme.textLightColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        String displayName = '';
        String subtitle = '';

        if (userType == 'admin') {
          displayName = '${user['first_name']} ${user['last_name'] ?? ''}';
          subtitle = user['username'];
        } else if (userType == 'alumni' || userType == 'content_creator') {
          displayName = '${user['first_name']} ${user['last_name']}';
          subtitle = user['email'];
        } else if (userType == 'company') {
          displayName = user['company_name'];
          subtitle = user['email'];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing:
                userType == 'admin' && user['is_super_admin'] == true
                    ? const Chip(
                      label: Text('Super Admin'),
                      backgroundColor: AppTheme.accentColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                    : user['is_approved'] == true
                    ? const Chip(
                      label: Text('Approved'),
                      backgroundColor: AppTheme.successColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                    : const Chip(
                      label: Text('Pending'),
                      backgroundColor: AppTheme.warningColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    ),
          ),
        );
      },
    );
  }
}
