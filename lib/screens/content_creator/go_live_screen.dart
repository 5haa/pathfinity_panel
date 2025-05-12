import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class GoLiveScreen extends ConsumerStatefulWidget {
  final String? preselectedCourseId;
  final String? preselectedCourseTitle;

  const GoLiveScreen({
    Key? key,
    this.preselectedCourseId,
    this.preselectedCourseTitle,
  }) : super(key: key);

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _approvedCourses = [];
  String? _selectedCourseId;
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadApprovedCourses();

    // Set preselected course if provided
    if (widget.preselectedCourseId != null) {
      _selectedCourseId = widget.preselectedCourseId;

      // Set default session title if course title is provided
      if (widget.preselectedCourseTitle != null) {
        _titleController.text = 'Live: ${widget.preselectedCourseTitle}';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovedCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final liveSessionService = ref.read(liveSessionServiceProvider);
      final courses = await liveSessionService.getApprovedCoursesForCreator(
        user.id,
      );

      setState(() {
        _approvedCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading approved courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startLiveSession() async {
    if (!_formKey.currentState!.validate() || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final liveSessionService = ref.read(liveSessionServiceProvider);
      final liveSession = await liveSessionService.createLiveSession(
        creatorId: user.id,
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
      );

      if (liveSession != null && mounted) {
        // Navigate to the broadcasting screen
        GoRouter.of(context).push(
          '/content-creator/broadcast/${liveSession.id}',
          extra: {'liveSession': liveSession},
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create live session'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error starting live session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Live'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start a Live Session',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 24),

                      // Course selection
                      const Text(
                        'Select Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_approvedCourses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'You don\'t have any approved courses. Please create a course and wait for approval before going live.',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          hint: const Text('Select a course'),
                          value: _selectedCourseId,
                          items:
                              _approvedCourses.map((course) {
                                return DropdownMenuItem<String>(
                                  value: course['id'],
                                  child: Text(course['title']),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCourseId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a course';
                            }
                            return null;
                          },
                        ),

                      const SizedBox(height: 24),

                      // Session title
                      CustomTextField(
                        label: 'Session Title',
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a session title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Start button
                      Center(
                        child: CustomButton(
                          text: 'Start Live Session',
                          onPressed:
                              _approvedCourses.isEmpty
                                  ? () {} // Empty function when disabled
                                  : () => _startLiveSession(),
                          isLoading: _isLoading,
                          type: ButtonType.primary,
                          icon: Icons.live_tv,
                          width: 240,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
