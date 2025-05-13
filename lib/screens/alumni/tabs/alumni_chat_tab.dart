import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/services/alumni_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/chat_service.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'dart:async';

final alumniServiceProvider = Provider<AlumniService>((ref) => AlumniService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// Use an AsyncNotifier to properly handle async loading state and caching
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Map<String, dynamic>>>(
      () => ConversationsNotifier(),
    );

class ConversationsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  Timer? _refreshTimer;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Set up a ref listener to handle cleanup when this provider is disposed
    ref.onDispose(() {
      _stopRefreshTimer();
    });
    return [];
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> loadConversations(String userId) async {
    // Stop any existing refresh timer
    _stopRefreshTimer();

    state = const AsyncValue.loading();

    try {
      // Get initial conversations data
      final chatService = ref.read(chatServiceProvider);
      final conversations = await chatService.getConversations(userId);

      // Set initial state
      state = AsyncValue.data(conversations);

      // Start a polling refresh timer to simulate real-time updates
      // Use a 5-second interval for polling updates
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _refreshConversations(userId);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _refreshConversations(String userId) async {
    // Don't refresh if we're in an error or loading state
    if (state is AsyncLoading) return;

    try {
      final chatService = ref.read(chatServiceProvider);
      final conversations = await chatService.getConversations(userId);

      // Only update if we have data and it's different from current
      state = AsyncValue.data(conversations);
    } catch (e) {
      // Don't update state on error during background refresh
      debugPrint('Error refreshing conversations: $e');
    }
  }
}

class AlumniChatTab extends ConsumerStatefulWidget {
  const AlumniChatTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AlumniChatTab> createState() => _AlumniChatTabState();
}

class _AlumniChatTabState extends ConsumerState<AlumniChatTab>
    with AutomaticKeepAliveClientMixin {
  AlumniUser? _alumniUser;
  bool _isLoading = true;
  String _searchQuery = '';
  late TextEditingController _searchController;
  bool _isInitialized = false;
  bool _isSearching = false;
  bool _isLoadingConversations = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Delay loading to improve performance
    Future.microtask(() => _loadAlumniProfile());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlumniProfile() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
      _isLoadingConversations = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is AlumniUser) {
        setState(() {
          _alumniUser = userProfile;
          _isLoading = false;
          _isInitialized = true;
        });

        // Load conversations using the AsyncNotifier
        if (_alumniUser != null) {
          // Show loading state while conversations load
          await ref
              .read(conversationsProvider.notifier)
              .loadConversations(_alumniUser!.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading alumni profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConversations = false;
        });
      }
    }
  }

  Future<void> _loadConversations() async {
    if (_alumniUser == null) return;

    setState(() {
      _isLoadingConversations = true;
    });

    try {
      // Use the AsyncNotifier to reload conversations
      await ref
          .read(conversationsProvider.notifier)
          .loadConversations(_alumniUser!.id);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConversations = false;
        });
      }
    }
  }

  void _openChat(String conversationId) {
    if (conversationId.isEmpty) {
      debugPrint("Error: Empty conversation ID");
      return;
    }

    // Get the student name from the conversation
    final conversationsAsync = ref.read(conversationsProvider);

    String studentName = '';
    conversationsAsync.whenData((conversations) {
      if (conversations.isNotEmpty) {
        try {
          final conversation = conversations.firstWhere(
            (conv) => conv['id'] == conversationId,
            orElse: () => {'student_first_name': '', 'student_last_name': ''},
          );

          final firstName = conversation['student_first_name'] ?? '';
          final lastName = conversation['student_last_name'] ?? '';
          studentName = '$firstName $lastName'.trim();

          if (studentName.isEmpty) {
            studentName = 'Student';
          }
        } catch (e) {
          debugPrint('Error finding conversation: $e');
          studentName = 'Student';
        }
      } else {
        studentName = 'Student';
      }
    });

    // Fallback if studentName is still empty
    if (studentName.isEmpty) {
      studentName = 'Student';
    }

    // Extract the tab parameter from the current route
    final uri = GoRouterState.of(context).uri;
    final pathSegments = uri.pathSegments;
    final tab = pathSegments.length > 1 ? pathSegments[1] : 'chat';

    // Navigate to chat screen with the correct path format and student name
    GoRouter.of(context).go(
      '/alumni/$tab/chat/$conversationId?studentName=${Uri.encodeComponent(studentName)}',
    );
  }

  List<Map<String, dynamic>> _getFilteredConversations() {
    // Access conversations through the AsyncValue
    final conversationsAsync = ref.watch(conversationsProvider);

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty || _searchQuery.isEmpty) return conversations;

        return conversations.where((conversation) {
          // Check if required fields exist to avoid null issues
          if (conversation['student_first_name'] == null) return false;

          final String studentName =
              '${conversation['student_first_name']} ${conversation['student_last_name'] ?? ''}'
                  .toLowerCase();
          final String searchLower = _searchQuery.toLowerCase();
          return studentName.contains(searchLower);
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoading && !_isInitialized)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_alumniUser == null)
            const Expanded(
              child: Center(child: Text('Error loading alumni profile')),
            )
          else if (!_alumniUser!.isApproved)
            _buildPendingApproval()
          else
            Expanded(child: _buildConversationsTab()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isSearching
                  ? Container()
                  : const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
              Row(
                children: [
                  if (!_isSearching && _alumniUser != null)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        _loadConversations();
                      },
                      tooltip: 'Refresh conversations',
                    ),
                  if (!_isSearching)
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
          if (_isSearching)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search conversations',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      autofocus: true,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppTheme.secondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                    child: Text(
                      'Search conversations',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingApproval() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is pending approval by an administrator. Chat features will be available once your account is approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLightColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  GoRouter.of(context).go('/alumni/profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsTab() {
    final filteredConversations = _getFilteredConversations();
    final conversationsAsync = ref.watch(conversationsProvider);

    // If we're in initial loading state, show a centered loading indicator
    if (_isLoadingConversations && conversationsAsync.value?.isEmpty == true) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show appropriate UI based on the async state
    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading conversations',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadConversations,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
      data: (conversations) {
        // If we have no conversations but are still loading, show loading indicator
        if (conversations.isEmpty && _isLoadingConversations) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredConversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _searchQuery.isEmpty
                      ? 'No conversations yet'
                      : 'No conversations found matching "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'Start chatting with students to view your conversations here'
                      : 'Try a different search term',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textLightColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isEmpty) const SizedBox(height: 32),
                if (_searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      GoRouter.of(context).go('/alumni/students');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Find Students to Chat With'),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadConversations,
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredConversations.length,
                itemBuilder: (context, index) {
                  try {
                    final conversation = filteredConversations[index];
                    if (conversation['id'] == null) {
                      // Skip invalid conversations
                      return const SizedBox.shrink();
                    }

                    final hasUnread = (conversation['unread_count'] ?? 0) > 0;

                    // Handle potential parsing issues with lastMessageTime
                    DateTime? lastMessageTime;
                    try {
                      lastMessageTime =
                          conversation['last_message_time'] != null
                              ? DateTime.parse(
                                conversation['last_message_time'],
                              )
                              : null;
                    } catch (e) {
                      debugPrint('Error parsing last_message_time: $e');
                      lastMessageTime = null;
                    }

                    return _buildConversationItem(
                      conversation,
                      hasUnread,
                      lastMessageTime,
                    );
                  } catch (e) {
                    debugPrint('Error rendering conversation: $e');
                    return const SizedBox.shrink(); // Skip problematic conversations
                  }
                },
              ),
              // Show overlay loading indicator when refreshing
              if (_isLoadingConversations && filteredConversations.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConversationItem(
    Map<String, dynamic> conversation,
    bool hasUnread,
    DateTime? lastMessageTime,
  ) {
    // Make sure we have valid data for this conversation
    final String studentName =
        '${conversation['student_first_name'] ?? ''} ${conversation['student_last_name'] ?? ''}'
            .trim();
    final String studentId = conversation['student_id'] ?? '';
    final String profilePictureUrl =
        conversation['student_profile_picture_url'] ?? '';

    return Dismissible(
      key: Key(conversation['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        // Implement delete functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chat deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Implement undo
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () => _openChat(conversation['id']),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color:
                hasUnread
                    ? AppTheme.primaryColor.withOpacity(0.04)
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: ProfilePictureWidget(
                          userId: studentId,
                          name: studentName,
                          profilePictureUrl: profilePictureUrl,
                          userType: UserType.unknown,
                          size: 60,
                          isEditable: false,
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              studentName.isEmpty
                                  ? 'Unknown Student'
                                  : studentName,
                              style: TextStyle(
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                fontSize: 16,
                                color: AppTheme.textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (lastMessageTime != null)
                            Text(
                              _formatMessageTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    hasUnread
                                        ? AppTheme.accentColor
                                        : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child:
                                conversation['last_message'] != null
                                    ? Text(
                                      conversation['last_message'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight:
                                            hasUnread
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                        color:
                                            hasUnread
                                                ? AppTheme.textColor
                                                : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    )
                                    : Text(
                                      'No messages yet',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${conversation['unread_count'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      // Format as time for today
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      // Show day of week for within a week
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    } else {
      // Show date for older messages
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year.toString().substring(2)}';
    }
  }
}
