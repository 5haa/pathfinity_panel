import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/chat_message_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/services/chat_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:async';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String studentName;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.studentName,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  late String _currentUserId;
  AlumniUser? _currentUserProfile;
  bool _showScrollButton = false;
  String? _studentProfilePictureUrl;
  StreamSubscription? _messagesSubscription;
  Timer? _markAsReadTimer;
  bool _markingAsRead = false;
  DateTime _lastMarkAsReadTime = DateTime(1970);
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadCurrentUserProfile();
    _loadStudentProfile();
    _subscribeToMessages();

    _scrollController.addListener(() {
      final showButton =
          _scrollController.hasClients &&
          _scrollController.position.pixels <
              _scrollController.position.maxScrollExtent - 500;
      if (showButton != _showScrollButton) {
        setState(() {
          _showScrollButton = showButton;
        });
      }
    });

    // Mark messages as read immediately when entering a chat
    _markMessagesAsReadNow();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _markAsReadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    _isAppActive = state == AppLifecycleState.resumed;

    // Mark messages as read when app comes to foreground
    if (_isAppActive) {
      _markMessagesAsReadNow();
    }
  }

  void _subscribeToMessages() {
    try {
      final messageStream = _chatService.listenToMessages(
        widget.conversationId,
      );
      _messagesSubscription = messageStream.listen(
        (messages) {
          if (mounted) {
            // Check if there are new unread messages
            final hasNewUnreadMessages = _hasUnreadMessages(messages);

            setState(() {
              _messages = messages;
            });

            // Only mark as read if there are unread messages and the app is active
            if (hasNewUnreadMessages && _isAppActive) {
              _debouncedMarkMessagesAsRead();
            }

            // Scroll to bottom if we were already at the bottom
            if (_scrollController.hasClients &&
                _scrollController.position.pixels >
                    _scrollController.position.maxScrollExtent - 200) {
              // Use a slight delay to let the UI render first
              Future.delayed(const Duration(milliseconds: 100), () {
                _scrollToBottom();
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Error in message subscription: $error');
        },
      );
    } catch (e) {
      debugPrint('Error subscribing to messages: $e');
    }
  }

  bool _hasUnreadMessages(List<ChatMessage> messages) {
    // Check if there are messages from the other user that are unread
    return messages.any((msg) => msg.senderId != _currentUserId && !msg.isRead);
  }

  void _debouncedMarkMessagesAsRead() {
    // Cancel any pending mark-as-read operation
    _markAsReadTimer?.cancel();

    // Don't schedule if we're already in the process of marking messages as read
    if (_markingAsRead) return;

    // Don't mark as read if we've done so recently (within the last 5 seconds)
    final now = DateTime.now();
    if (now.difference(_lastMarkAsReadTime).inSeconds < 5) return;

    // Schedule a mark-as-read operation with a delay to debounce multiple calls
    _markAsReadTimer = Timer(const Duration(milliseconds: 500), () {
      _markMessagesAsRead();
    });
  }

  // Call this when we want to mark messages as read immediately (e.g., when entering the chat)
  void _markMessagesAsReadNow() {
    if (_markingAsRead) return;
    _markMessagesAsRead();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;

          // Set student profile picture from messages if available
          if (messages.isNotEmpty) {
            final studentMessages =
                messages
                    .where((msg) => msg.senderId != _currentUserId)
                    .toList();
            if (studentMessages.isNotEmpty &&
                studentMessages.first.senderProfilePictureUrl != null) {
              _studentProfilePictureUrl =
                  studentMessages.first.senderProfilePictureUrl;
            }
          }
        });

        // Only mark as read if there are unread messages
        if (_hasUnreadMessages(messages)) {
          _markMessagesAsRead();
        }

        // Scroll to bottom after messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    // Prevent concurrent mark-as-read operations
    if (_markingAsRead) return;

    _markingAsRead = true;

    try {
      // Try to mark messages as read with retry logic
      bool success = false;
      int retries = 0;
      const maxRetries = 3;

      while (!success && retries < maxRetries) {
        try {
          final result = await _chatService.markMessagesAsRead(
            widget.conversationId,
          );
          success = result;

          if (success) {
            _lastMarkAsReadTime = DateTime.now();

            // Update local messages to show as read immediately
            setState(() {
              for (int i = 0; i < _messages.length; i++) {
                if (_messages[i].senderId != _currentUserId &&
                    !_messages[i].isRead) {
                  // Create a new instance with isRead set to true
                  _messages[i] = ChatMessage(
                    id: _messages[i].id,
                    conversationId: _messages[i].conversationId,
                    senderId: _messages[i].senderId,
                    content: _messages[i].content,
                    isRead: true,
                    createdAt: _messages[i].createdAt,
                    updatedAt: _messages[i].updatedAt,
                    senderProfile: _messages[i].senderProfile,
                  );
                }
              }
            });
          }
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            debugPrint(
              'Failed to mark messages as read after $maxRetries attempts: $e',
            );
            break;
          }
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 300 * retries));
        }
      }
    } catch (e) {
      debugPrint('Error in _markMessagesAsRead: $e');
    } finally {
      _markingAsRead = false;
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final userProfile = await ref.read(authServiceProvider).getUserProfile();
      if (userProfile is AlumniUser) {
        setState(() {
          _currentUserProfile = userProfile;
        });
      }
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    }
  }

  Future<void> _loadStudentProfile() async {
    try {
      final studentProfile = await _chatService
          .getStudentProfileFromConversation(widget.conversationId);

      if (mounted &&
          studentProfile != null &&
          studentProfile.profilePictureUrl != null) {
        setState(() {
          _studentProfilePictureUrl = studentProfile.profilePictureUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading student profile: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();

      final message = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        content: messageText,
      );

      if (message != null) {
        setState(() {
          _messages.add(message);
        });

        // Scroll to bottom after sending
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        title: Row(
          children: [
            _studentProfilePictureUrl != null
                ? ProfilePictureWidget(
                  userId: "student",
                  name: widget.studentName,
                  profilePictureUrl: _studentProfilePictureUrl,
                  userType: UserType.unknown,
                  size: 40,
                  isEditable: false,
                )
                : CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    widget.studentName.isNotEmpty
                        ? widget.studentName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Student",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () {
            // Extract the tab parameter from the current route
            final uri = GoRouterState.of(context).uri;
            final pathSegments = uri.pathSegments;
            final tab = pathSegments.length > 1 ? pathSegments[1] : 'chat';

            // Navigate back to the appropriate tab
            GoRouter.of(context).go('/alumni/$tab');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
            onPressed: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder:
                    (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                          ),
                          title: const Text("Delete Conversation"),
                          onTap: () {
                            Navigator.pop(context);
                            // Add delete functionality
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.block,
                            color: AppTheme.warningColor,
                          ),
                          title: const Text("Block Student"),
                          onTap: () {
                            Navigator.pop(context);
                            // Add block functionality
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text("View Profile"),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to student profile
                          },
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.grey[50]),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _messages.isEmpty
                          ? _buildEmptyChat()
                          : _buildChatMessages(),
                ),
                if (_showScrollButton)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppTheme.primaryColor,
                      onPressed: _scrollToBottom,
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start a conversation with ${widget.studentName}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textLightColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    // Group messages by date
    final Map<String, List<ChatMessage>> messagesByDate = {};

    for (final message in _messages) {
      final date = _formatDate(message.createdAt);
      if (!messagesByDate.containsKey(date)) {
        messagesByDate[date] = [];
      }
      messagesByDate[date]!.add(message);
    }

    // Sort dates
    final sortedDates =
        messagesByDate.keys.toList()
          ..sort((a, b) => _parseDate(a).compareTo(_parseDate(b)));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final messagesForDate = messagesByDate[date]!;

        return Column(
          children: [
            // Date separator
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Messages for this date
            ...messagesForDate.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              final isFromCurrentUser = message.senderId == _currentUserId;

              // Check if this is the first message or from a different sender than the previous
              final isFirstInGroup =
                  index == 0 ||
                  messagesForDate[index - 1].senderId != message.senderId;

              // Check if this is the last message or from a different sender than the next
              final isLastInGroup =
                  index == messagesForDate.length - 1 ||
                  messagesForDate[index + 1].senderId != message.senderId;

              return _buildMessageBubble(
                message,
                isFromCurrentUser,
                isFirstInGroup,
                isLastInGroup,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isFromCurrentUser,
    bool isFirstInGroup,
    bool isLastInGroup,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 8.0 : 2.0,
        bottom: isLastInGroup ? 8.0 : 2.0,
      ),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && isLastInGroup)
            ProfilePictureWidget(
              userId: message.senderId,
              name: widget.studentName,
              profilePictureUrl:
                  message.senderProfilePictureUrl ?? _studentProfilePictureUrl,
              userType: UserType.unknown,
              size: 28,
              isEditable: false,
            )
          else if (!isFromCurrentUser)
            const SizedBox(width: 28),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromCurrentUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    isFromCurrentUser || !isFirstInGroup ? 20 : 4,
                  ),
                  topRight: Radius.circular(
                    !isFromCurrentUser || !isFirstInGroup ? 20 : 4,
                  ),
                  bottomLeft: Radius.circular(
                    isFromCurrentUser ? 20 : (isLastInGroup ? 4 : 20),
                  ),
                  bottomRight: Radius.circular(
                    !isFromCurrentUser ? 20 : (isLastInGroup ? 4 : 20),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isFromCurrentUser ? Colors.white : AppTheme.textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color:
                              isFromCurrentUser
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        _buildReadStatus(message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (isFromCurrentUser && isLastInGroup)
            ProfilePictureWidget(
              userId: _currentUserId,
              name:
                  _currentUserProfile != null
                      ? '${_currentUserProfile!.firstName} ${_currentUserProfile!.lastName}'
                      : 'Me',
              profilePictureUrl: _currentUserProfile?.profilePictureUrl,
              userType: UserType.alumni,
              size: 28,
              isEditable: false,
            )
          else if (isFromCurrentUser)
            const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildReadStatus(ChatMessage message) {
    if (message.isRead) {
      // Double blue check for read messages - make it more obvious
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Icon(
              Icons.done_all,
              size: 16, // Slightly larger
              color: Colors.blue[200], // Light blue to make it stand out
            ),
          );
        },
      );
    } else {
      // Single check for unread/delivered messages
      return Icon(
        Icons.done,
        size: 14,
        color: Colors.white.withOpacity(0.6), // More transparent for unread
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: AppTheme.secondaryColor),
            onPressed: () {
              // Show attachment options
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Share Content',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAttachmentOption(
                                icon: Icons.photo,
                                color: Colors.purple,
                                label: 'Gallery',
                                onTap: () => Navigator.pop(context),
                              ),
                              _buildAttachmentOption(
                                icon: Icons.camera_alt,
                                color: Colors.red,
                                label: 'Camera',
                                onTap: () => Navigator.pop(context),
                              ),
                              _buildAttachmentOption(
                                icon: Icons.insert_drive_file,
                                color: Colors.blue,
                                label: 'Document',
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
              );
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: Transform.rotate(
                      angle: -math.pi / 4,
                      child: const Icon(
                        Icons.send,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onPressed: _isSending ? null : _sendMessage,
                    tooltip: 'Send Message',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  DateTime _parseDate(String formattedDate) {
    if (formattedDate == 'Today') {
      return DateTime.now();
    } else if (formattedDate == 'Yesterday') {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - 1);
    } else {
      // Parse date in format dd/mm/yyyy
      final parts = formattedDate.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
  }
}
