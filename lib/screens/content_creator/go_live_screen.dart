import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

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

  // For scheduling
  bool _isScheduling = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  @override
  void initState() {
    super.initState();
    _loadApprovedCourses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle preselected course after approved courses are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading && widget.preselectedCourseId != null) {
        // Check if the preselected course is in the approved courses list
        final isCourseApproved = _approvedCourses.any(
          (course) => course['id'] == widget.preselectedCourseId,
        );

        if (isCourseApproved) {
          setState(() {
            _selectedCourseId = widget.preselectedCourseId;

            // Set default session title if course title is provided
            if (widget.preselectedCourseTitle != null) {
              _titleController.text = 'Live: ${widget.preselectedCourseTitle}';
            }
          });
        } else if (widget.preselectedCourseId != null && mounted) {
          // Show a message if trying to go live with a non-approved course
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can only go live with approved and active courses.',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
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
        _approvedCourses = [];
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

    // Double-check that the selected course is in the approved courses list
    final isCourseApproved = _approvedCourses.any(
      (course) => course['id'] == _selectedCourseId,
    );

    if (!isCourseApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only go live with approved and active courses.',
          ),
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

      if (_isScheduling) {
        // Schedule the live session for later
        final scheduledDateTime = DateTime(
          _scheduledDate.year,
          _scheduledDate.month,
          _scheduledDate.day,
          _scheduledTime.hour,
          _scheduledTime.minute,
        );

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
          // Navigate back to live sessions screen
          GoRouter.of(
            context,
          ).pushReplacement('/content-creator/live-sessions');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to schedule live session'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Start live session immediately
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
      }
    } catch (e) {
      debugPrint('Error with live session: $e');
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

  void _navigateToLiveSessions() {
    GoRouter.of(context).push('/content-creator/live-sessions');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(_scheduledDate);
    final formattedTime = _scheduledTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isScheduling ? 'Schedule Live Session' : 'Go Live'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Add button to navigate to Live Sessions
          TextButton.icon(
            onPressed: _navigateToLiveSessions,
            icon: const Icon(Icons.playlist_play, color: Colors.white),
            label: const Text(
              'My Live Sessions',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode selection
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: SwitchListTile(
                                title: Text(
                                  _isScheduling
                                      ? 'Schedule for Later'
                                      : 'Start Immediately',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _isScheduling
                                      ? 'This session will be scheduled for a future time'
                                      : 'This session will start immediately after you click "Start Live Session"',
                                ),
                                value: _isScheduling,
                                onChanged: (value) {
                                  setState(() {
                                    _isScheduling = value;
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            _isScheduling
                                ? 'Schedule a Live Session'
                                : 'Start a Live Session',
                            style: AppTheme.headingStyle,
                          ),
                          const SizedBox(height: 16),

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
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'You don\'t have any approved courses. Please create a course and wait for approval before going live.',
                                  style: TextStyle(
                                    color: AppTheme.warningColor,
                                    fontStyle: FontStyle.italic,
                                  ),
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
                              isExpanded: true, // Prevents overflow
                            ),

                          const SizedBox(height: 20),

                          // Session title
                          const Text(
                            'Session Title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
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

                          // Schedule date & time (only shown when scheduling)
                          if (_isScheduling) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Schedule Date and Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                              overflow: TextOverflow.ellipsis,
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
                                        borderRadius: BorderRadius.circular(8),
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
                                              overflow: TextOverflow.ellipsis,
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

                          const SizedBox(height: 32),

                          // Action button
                          Center(
                            child: SizedBox(
                              width: 240,
                              child: CustomButton(
                                text:
                                    _isScheduling
                                        ? 'Schedule Live Session'
                                        : 'Start Live Session',
                                onPressed:
                                    _approvedCourses.isEmpty
                                        ? () {} // Empty function when disabled
                                        : () => _startLiveSession(),
                                isLoading: _isLoading,
                                type: ButtonType.primary,
                                icon:
                                    _isScheduling
                                        ? Icons.calendar_today
                                        : Icons.live_tv,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // View live sessions button
                          Center(
                            child: TextButton.icon(
                              onPressed: _navigateToLiveSessions,
                              icon: const Icon(Icons.list),
                              label: const Text('View My Live Sessions'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
