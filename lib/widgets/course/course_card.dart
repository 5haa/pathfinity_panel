import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final Function(String) onEditTap;
  final Function(String) onDeleteTap;
  final Function(String, String) onVideosTap;
  final Function(String, String) onGoLiveTap;

  const CourseCard({
    Key? key,
    required this.course,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onVideosTap,
    required this.onGoLiveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String id = course['id'] as String;
    final String title = course['title'] as String;
    final String description =
        course['description'] as String? ?? 'No description';
    final int videosCount =
        course['videos_count'] != null ? (course['videos_count'] as int) : 0;
    final int studentsCount =
        course['students_count'] != null
            ? (course['students_count'] as int)
            : 0;
    final String status = course['status'] as String;
    final DateTime createdAt = course['created_at'] as DateTime;
    final String thumbnailUrl = course['thumbnail_url'] as String? ?? '';

    // Updated category name extraction to handle different data structures
    String categoryName = 'Uncategorized';
    if (course['course_categories'] != null &&
        course['course_categories'] is Map<String, dynamic>) {
      categoryName = course['course_categories']['name'] ?? 'Uncategorized';
    } else if (course['category'] != null &&
        course['category'] is Map<String, dynamic>) {
      categoryName = course['category']['name'] ?? 'Uncategorized';
    }

    final String membershipType = course['membership_type'] as String? ?? 'PRO';
    final String difficulty = course['difficulty'] as String? ?? 'medium';

    // Determine status color
    Color statusColor;
    switch (status) {
      case 'Published':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Format difficulty for display
    String formattedDifficulty = difficulty;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        formattedDifficulty = 'Easy';
        break;
      case 'medium':
        formattedDifficulty = 'Medium';
        break;
      case 'hard':
        formattedDifficulty = 'Hard';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course thumbnail and status
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image:
                      thumbnailUrl.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                  color: thumbnailUrl.isEmpty ? Colors.grey.shade200 : null,
                ),
                child:
                    thumbnailUrl.isEmpty
                        ? Center(
                          child: Icon(
                            Icons.photo,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        )
                        : null,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Course metadata - videos, students, creation date
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInfoChip(
                        Icons.video_library,
                        '$videosCount videos',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.people, '$studentsCount students'),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Created ${_formatDate(createdAt)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Course additional details - category, membership, difficulty
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCourseTag(
                      'Category: $categoryName',
                      Colors.blue.shade100,
                      Colors.blue.shade800,
                    ),
                    _buildCourseTag(
                      membershipType == MembershipType.free
                          ? 'Free'
                          : 'Pro Membership',
                      membershipType == MembershipType.free
                          ? Colors.green.shade100
                          : Colors.purple.shade100,
                      membershipType == MembershipType.free
                          ? Colors.green.shade800
                          : Colors.purple.shade800,
                    ),
                    _buildCourseTag(
                      formattedDifficulty,
                      _getDifficultyColor(difficulty).withOpacity(0.2),
                      _getDifficultyColor(difficulty),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.video_library,
                  label: 'Videos',
                  onTap: () => onVideosTap(id, title),
                ),
                _buildActionButton(
                  icon: Icons.live_tv,
                  label: 'Go Live',
                  onTap: () => onGoLiveTap(id, title),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () => onEditTap(id),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onTap: () => onDeleteTap(id),
                  color: AppTheme.errorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCourseTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
