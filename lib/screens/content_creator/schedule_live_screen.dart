import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class ScheduleLiveScreen extends ConsumerStatefulWidget {
  const ScheduleLiveScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScheduleLiveScreen> createState() => _ScheduleLiveScreenState();
}

class _ScheduleLiveScreenState extends ConsumerState<ScheduleLiveScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  String? _selectedCourseId;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  List<Map<String, dynamic>> _availableCourses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        _availableCourses = courses;
        _selectedCourseId = courses.isNotEmpty ? courses[0]['id'] : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      setState(() {
        _errorMessage = 'Failed to load courses: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _scheduledDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _scheduledTime = pickedTime;
      });
    }
  }

  Future<void> _scheduleSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
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

      // Combine date and time
      final scheduledDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );

      final liveSessionService = ref.read(liveSessionServiceProvider);
      final liveSession = await liveSessionService.scheduleLiveSession(
        creatorId: user.id,
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
        scheduledAt: scheduledDateTime,
      );

      if (liveSession != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live session scheduled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        GoRouter.of(context).pop();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to schedule live session';
        });
      }
    } catch (e) {
      debugPrint('Error scheduling live session: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(_scheduledDate);
    final formattedTime = _scheduledTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Live Session'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableCourses.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.warningColor,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You don\'t have any approved courses to create a live session for.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please create a course and wait for it to be approved before scheduling a live session.',
                        style: TextStyle(color: AppTheme.textLightColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Go Back',
                        onPressed: () => GoRouter.of(context).pop(),
                        type: ButtonType.secondary,
                      ),
                    ],
                  ),
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: AppTheme.errorColor.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Session Title',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter a title for your live session',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                const Text(
                                  'Course',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCourseId,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  isExpanded: true,
                                  items:
                                      _availableCourses
                                          .map(
                                            (course) =>
                                                DropdownMenuItem<String>(
                                                  value: course['id'],
                                                  child: Text(
                                                    course['title'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCourseId = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Schedule Date and Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectDate,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                                color: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  formattedDate,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectTime,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 18,
                                                color: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  formattedTime,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Schedule Live Session',
                            onPressed: _scheduleSession,
                            type: ButtonType.primary,
                            isLoading: _isLoading,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Cancel button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () => GoRouter.of(context).pop(),
                            type: ButtonType.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
