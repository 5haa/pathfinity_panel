import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/models/student_profile_model.dart';
import 'package:admin_panel/services/student_service.dart';
import 'package:admin_panel/config/theme.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});

final studentsProvider = FutureProvider<List<StudentProfile>>((ref) async {
  final studentService = ref.watch(studentServiceProvider);
  return await studentService.getAllStudents();
});

final skillsProvider = FutureProvider<List<String>>((ref) async {
  final studentService = ref.watch(studentServiceProvider);
  return await studentService.getAllSkills();
});

final selectedSkillsProvider = StateProvider<List<String>>((ref) => []);

final filteredStudentsProvider = FutureProvider<List<StudentProfile>>((
  ref,
) async {
  final selectedSkills = ref.watch(selectedSkillsProvider);
  final studentService = ref.watch(studentServiceProvider);

  if (selectedSkills.isEmpty) {
    return await studentService.getAllStudents();
  } else {
    return await studentService.filterStudentsBySkills(selectedSkills);
  }
});

class CompanyStudentsTab extends ConsumerStatefulWidget {
  const CompanyStudentsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyStudentsTab> createState() => _CompanyStudentsTabState();
}

class _CompanyStudentsTabState extends ConsumerState<CompanyStudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);
    final selectedSkills = ref.watch(selectedSkillsProvider);
    final filteredStudentsAsync = ref.watch(filteredStudentsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Profiles',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // Skills filter section
            Text(
              'Filter by Skills',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Skills chips
            skillsAsync.when(
              data: (skills) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skills.map((skill) {
                        final isSelected = selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            final currentSkills = List<String>.from(
                              selectedSkills,
                            );
                            if (selected) {
                              currentSkills.add(skill);
                            } else {
                              currentSkills.remove(skill);
                            }
                            ref.read(selectedSkillsProvider.notifier).state =
                                currentSkills;
                          },
                        );
                      }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error loading skills: $err'),
            ),

            if (selectedSkills.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
                onPressed: () {
                  ref.read(selectedSkillsProvider.notifier).state = [];
                },
              ),
            ],

            const SizedBox(height: 16),

            // Students list
            Expanded(
              child: filteredStudentsAsync.when(
                data: (students) {
                  // Apply local search filter if search query exists
                  final filteredStudents =
                      _searchQuery.isEmpty
                          ? students
                          : students
                              .where(
                                (student) => student.fullName
                                    .toLowerCase()
                                    .contains(_searchQuery),
                              )
                              .toList();

                  if (filteredStudents.isEmpty) {
                    return const Center(
                      child: Text('No students found matching your criteria'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return StudentCard(student: student);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) =>
                        Center(child: Text('Error loading students: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final StudentProfile student;

  const StudentCard({Key? key, required this.student}) : super(key: key);

  Future<void> _launchEmail() async {
    if (student.email == null || student.email!.isEmpty) return;

    final Uri emailUri = Uri(scheme: 'mailto', path: student.email);

    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Could not launch email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile picture or placeholder
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      student.profilePictureUrl != null
                          ? NetworkImage(student.profilePictureUrl!)
                          : null,
                  child:
                      student.profilePictureUrl == null
                          ? Text(
                            student.fullName.isNotEmpty
                                ? student.fullName.substring(0, 1)
                                : '?',
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                // Student details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (student.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          student.email!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                // Email button
                if (student.email != null && student.email!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.email, color: AppTheme.primaryColor),
                    onPressed: _launchEmail,
                    tooltip: 'Send email',
                  ),
              ],
            ),
            if (student.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Skills:'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    student.skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.all(4),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
