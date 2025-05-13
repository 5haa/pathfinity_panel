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

class _AdminUsersTabState extends ConsumerState<AdminUsersTab>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _contentCreators = [];
  String _currentUserType = 'admin';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentUserType = 'admin';
          break;
        case 1:
          _currentUserType = 'alumni';
          break;
        case 2:
          _currentUserType = 'company';
          break;
        case 3:
          _currentUserType = 'content_creator';
          break;
      }
      // Clear search when changing tabs
      _searchController.clear();
      _searchQuery = '';
    });
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

  List<Map<String, dynamic>> _getFilteredUsers(
    List<Map<String, dynamic>> users,
    String userType,
  ) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      if (userType == 'company') {
        return user['company_name']?.toLowerCase().contains(query) == true ||
            user['email']?.toLowerCase().contains(query) == true;
      } else {
        return user['first_name']?.toLowerCase().contains(query) == true ||
            user['last_name']?.toLowerCase().contains(query) == true ||
            user['email']?.toLowerCase().contains(query) == true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentUsers = _getCurrentUsersList();
    final filteredUsers = _getFilteredUsers(currentUsers, _currentUserType);
    final int totalUsers =
        _admins.length +
        _alumni.length +
        _companies.length +
        _contentCreators.length;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Total Users: ',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '$totalUsers',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 16),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Admins'),
                Tab(text: 'Alumni'),
                Tab(text: 'Companies'),
                Tab(text: 'Content Creators'),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textLightColor,
              indicatorColor: AppTheme.accentColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUsersListView(
                          _getFilteredUsers(_admins, 'admin'),
                          'admin',
                        ),
                        _buildUsersListView(
                          _getFilteredUsers(_alumni, 'alumni'),
                          'alumni',
                        ),
                        _buildUsersListView(
                          _getFilteredUsers(_companies, 'company'),
                          'company',
                        ),
                        _buildUsersListView(
                          _getFilteredUsers(
                            _contentCreators,
                            'content_creator',
                          ),
                          'content_creator',
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCurrentUsersList() {
    switch (_currentUserType) {
      case 'admin':
        return _admins;
      case 'alumni':
        return _alumni;
      case 'company':
        return _companies;
      case 'content_creator':
        return _contentCreators;
      default:
        return [];
    }
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textLightColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildUsersListView(
    List<Map<String, dynamic>> users,
    String userType,
  ) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textLightColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No ${userType.replaceAll('_', ' ')} users matching "${_searchQuery}"'
                  : 'No ${userType.replaceAll('_', ' ')} users found',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textLightColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user, userType);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String userType) {
    String displayName = '';
    String email = '';
    String? avatarText;
    Color avatarColor = AppTheme.primaryColor;
    Widget statusWidget;

    if (userType == 'admin') {
      displayName = '${user['first_name']} ${user['last_name'] ?? ''}';
      email = user['email'];
      avatarText =
          displayName.isNotEmpty
              ? displayName.substring(0, 1).toUpperCase()
              : '';
      statusWidget = _buildStatusBadge(
        user['is_super_admin'] == true ? 'Super Admin' : 'Admin',
        user['is_super_admin'] == true ? AppTheme.accentColor : Colors.blueGrey,
      );
    } else if (userType == 'alumni' || userType == 'content_creator') {
      displayName = '${user['first_name']} ${user['last_name']}';
      email = user['email'];
      avatarText =
          displayName.isNotEmpty
              ? displayName.substring(0, 1).toUpperCase()
              : '';
      avatarColor = userType == 'alumni' ? Colors.orange : Colors.green;
      statusWidget = _buildStatusBadge(
        user['is_approved'] == true ? 'Approved' : 'Pending',
        user['is_approved'] == true
            ? AppTheme.successColor
            : AppTheme.warningColor,
      );
    } else {
      // company
      displayName = user['company_name'];
      email = user['email'];
      avatarText =
          displayName.isNotEmpty
              ? displayName.substring(0, 1).toUpperCase()
              : '';
      avatarColor = Colors.blue;
      statusWidget = _buildStatusBadge(
        user['is_approved'] == true ? 'Approved' : 'Pending',
        user['is_approved'] == true
            ? AppTheme.successColor
            : AppTheme.warningColor,
      );
    }

    final createdDate = DateTime.parse(user['created_at']).toLocal();
    final createdDateString =
        '${createdDate.day}/${createdDate.month}/${createdDate.year}';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(user, userType),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 20,
                child: Text(
                  avatarText ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created: $createdDateString',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 100, child: statusWidget),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user, String userType) {
    String displayName =
        userType == 'company'
            ? user['company_name']
            : '${user['first_name']} ${user['last_name'] ?? ''}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                userType == 'admin'
                    ? Icons.admin_panel_settings
                    : userType == 'company'
                    ? Icons.business
                    : userType == 'alumni'
                    ? Icons.school
                    : Icons.person,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Email', user['email'], Icons.email),
                if (userType == 'admin')
                  _buildDetailItem(
                    'Username',
                    user['username'],
                    Icons.account_circle,
                  ),
                if (userType == 'admin')
                  _buildDetailItem(
                    'Super Admin',
                    user['is_super_admin'] ? 'Yes' : 'No',
                    Icons.security,
                  ),
                if (userType != 'admin')
                  _buildDetailItem(
                    'Approved',
                    user['is_approved'] ? 'Yes' : 'No',
                    Icons.verified_user,
                  ),
                _buildDetailItem(
                  'Created',
                  DateTime.parse(
                    user['created_at'],
                  ).toLocal().toString().split('.')[0],
                  Icons.calendar_today,
                ),
                _buildDetailItem(
                  'Updated',
                  DateTime.parse(
                    user['updated_at'],
                  ).toLocal().toString().split('.')[0],
                  Icons.update,
                ),
              ],
            ),
          ),
          actions: [
            if (userType != 'admin' && user['is_approved'] != true)
              OutlinedButton.icon(
                onPressed: () async {
                  final adminService = ref.read(adminServiceProvider);
                  bool success = false;

                  if (userType == 'alumni') {
                    success = await adminService.approveAlumni(user['id']);
                  } else if (userType == 'company') {
                    success = await adminService.approveCompany(user['id']);
                  } else if (userType == 'content_creator') {
                    success = await adminService.approveContentCreator(
                      user['id'],
                    );
                  }

                  if (success) {
                    Navigator.of(context).pop();
                    _loadUsers();
                  }
                },
                icon: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                ),
                label: const Text(
                  'Approve',
                  style: TextStyle(color: AppTheme.successColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.successColor),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
