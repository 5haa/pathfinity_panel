import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/student_profile_model.dart';
import 'package:admin_panel/services/student_service.dart';
import 'package:admin_panel/services/chat_service.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/services/auth_service.dart';

final studentServiceProvider = Provider<StudentService>(
  (ref) => StudentService(),
);
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class AlumniStudentsTab extends ConsumerStatefulWidget {
  const AlumniStudentsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AlumniStudentsTab> createState() => _AlumniStudentsTabState();
}

class _AlumniStudentsTabState extends ConsumerState<AlumniStudentsTab>
    with AutomaticKeepAliveClientMixin {
  List<StudentProfile> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadStudents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (_isInitialized && !_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final studentService = ref.read(studentServiceProvider);
      final students = await studentService.getAllStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    }
  }

  List<StudentProfile> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }

    final query = _searchQuery.toLowerCase();
    return _students.where((student) {
      final fullName = '${student.firstName} ${student.lastName}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  Future<void> _startChat(StudentProfile student) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final conversationId = await chatService.createConversationWithStudent(
        student.id,
      );

      if (conversationId != null && mounted) {
        // Navigate to chat screen with the correct path format and student name
        // Extract the tab parameter from the current route
        final uri = GoRouterState.of(context).uri;
        final pathSegments = uri.pathSegments;
        final tab = pathSegments.length > 1 ? pathSegments[1] : 'students';

        // Navigate to chat screen with the correct path format and student name
        GoRouter.of(context).go(
          '/alumni/$tab/chat/$conversationId?studentName=${Uri.encodeComponent(student.fullName)}',
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Try a different search term',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadStudents,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: ProfilePictureWidget(
                                        userId: student.id,
                                        name: student.fullName,
                                        profilePictureUrl:
                                            student.profilePictureUrl,
                                        userType: UserType.unknown,
                                        size: 60,
                                        isEditable: false,
                                      ),
                                    ),
                                    if (student.premium)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.verified,
                                            color: AppTheme.accentColor,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        student.email ?? 'No email',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  student.premium
                                                      ? AppTheme.accentColor
                                                          .withOpacity(0.1)
                                                      : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              student.premium
                                                  ? 'Premium'
                                                  : 'Basic',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    student.premium
                                                        ? AppTheme.accentColor
                                                        : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.person,
                                        color: AppTheme.primaryColor,
                                      ),
                                      onPressed: () {
                                        // Extract the tab parameter from the current route
                                        final uri =
                                            GoRouterState.of(context).uri;
                                        final pathSegments = uri.pathSegments;
                                        final tab =
                                            pathSegments.length > 1
                                                ? pathSegments[1]
                                                : 'students';

                                        // Navigate to student profile with the correct path format
                                        GoRouter.of(context).go(
                                          '/alumni/$tab/student_profile/${student.id}',
                                        );
                                      },
                                      tooltip: 'View Profile',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chat,
                                        color: AppTheme.accentColor,
                                      ),
                                      onPressed: () => _startChat(student),
                                      tooltip: 'Start Chat',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}
