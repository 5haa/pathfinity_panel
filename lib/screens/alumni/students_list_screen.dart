import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/student_profile_model.dart';
import 'package:admin_panel/services/student_service.dart';
import 'package:admin_panel/services/chat_service.dart';

final studentServiceProvider = Provider<StudentService>(
  (ref) => StudentService(),
);
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  List<StudentProfile> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final studentService = ref.read(studentServiceProvider);
      final students = await studentService.getAllStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
      setState(() {
        _isLoading = false;
      });
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
        GoRouter.of(context).push(
          '/alumni/chat',
          extra: {
            'conversationId': conversationId,
            'studentName': student.fullName,
          },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredStudents.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              student.firstName.isNotEmpty &&
                                      student.lastName.isNotEmpty
                                  ? student.firstName[0] + student.lastName[0]
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(student.fullName),
                          subtitle: Text(student.email ?? 'No email'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.person),
                                onPressed: () {
                                  GoRouter.of(context).push(
                                    '/alumni/student_profile',
                                    extra: {'id': student.id},
                                  );
                                },
                                tooltip: 'View Profile',
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: () => _startChat(student),
                                tooltip: 'Start Chat',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
