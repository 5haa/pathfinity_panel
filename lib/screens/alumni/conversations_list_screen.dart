import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/chat_conversation_model.dart';
import 'package:admin_panel/services/chat_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await _chatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start a chat with a student to begin',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        GoRouter.of(context).go('/alumni/students');
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('View Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshConversations,
                child: ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final otherParticipant = conversation.getOtherParticipant(
                      currentUserId,
                    );
                    final lastMessage = conversation.lastMessage;

                    return ListTile(
                      leading: ProfilePictureWidget(
                        userId: otherParticipant?.userId ?? '',
                        name: otherParticipant?.displayName ?? 'Unknown',
                        profilePictureUrl: otherParticipant?.profilePictureUrl,
                        userType:
                            otherParticipant?.userType == 'student'
                                ? UserType.alumni
                                : UserType.alumni,
                        size: 48,
                        isEditable: false,
                      ),
                      title: Text(
                        otherParticipant?.displayName ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          lastMessage != null
                              ? Text(
                                lastMessage.content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                              : const Text(
                                'No messages yet',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(conversation.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (lastMessage != null &&
                              !lastMessage.isRead &&
                              lastMessage.senderId != currentUserId)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        GoRouter.of(context).push(
                          '/alumni/chat',
                          extra: {
                            'conversationId': conversation.id,
                            'studentName':
                                otherParticipant?.displayName ?? 'Student',
                          },
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      // Format as time if today
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      // Format as date if older
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
