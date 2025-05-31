import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminInternshipsTab extends ConsumerStatefulWidget {
  const AdminInternshipsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminInternshipsTab> createState() =>
      _AdminInternshipsTabState();
}

class _AdminInternshipsTabState extends ConsumerState<AdminInternshipsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _internships = [];

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  Future<void> _loadInternships() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final internships = await adminService.getAllInternships();

      setState(() {
        _internships = internships;
      });
    } catch (e) {
      debugPrint('Error loading internships: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveInternship(String internshipId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveInternship(internshipId);

      if (success && mounted) {
        // Update the local state immediately to reflect the change
        setState(() {
          for (int i = 0; i < _internships.length; i++) {
            if (_internships[i]['id'] == internshipId) {
              _internships[i]['is_approved'] = true;
              _internships[i]['rejection_reason'] = null;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while approving internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRejectDialog(String internshipId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Internship'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter rejection reason',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final reason = reasonController.text;
                  Navigator.of(context).pop();
                  if (reason.trim().isNotEmpty) {
                    _rejectInternship(internshipId, reason);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rejection reason'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _rejectInternship(String internshipId, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.rejectInternship(internshipId, reason);

      if (success && mounted) {
        // Update the local state immediately to reflect the change
        setState(() {
          for (int i = 0; i < _internships.length; i++) {
            if (_internships[i]['id'] == internshipId) {
              _internships[i]['is_approved'] = false;
              _internships[i]['rejection_reason'] = reason;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while rejecting internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleInternshipActiveStatus(
    String internshipId,
    bool newActiveStatus,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.toggleInternshipActiveStatus(
        internshipId,
        newActiveStatus,
      );

      if (success && mounted) {
        // Update the local state immediately to reflect the change
        setState(() {
          for (int i = 0; i < _internships.length; i++) {
            if (_internships[i]['id'] == internshipId) {
              _internships[i]['is_active'] = newActiveStatus;
              break;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Internship ${newActiveStatus ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload from server to ensure data consistency
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${newActiveStatus ? 'activate' : 'deactivate'} internship',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating internship active status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while updating internship status'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _loadInternships,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Internship Opportunities (${_internships.length})',
                      style: AppTheme.subheadingStyle,
                    ),
                  ],
                ),
                const Divider(height: 32),
                if (_internships.isEmpty)
                  _buildEmptyState('internships')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _internships.length,
                    itemBuilder: (context, index) {
                      final internship = _internships[index];
                      return _buildInternshipCard(internship);
                    },
                  ),
              ],
            ),
          ),
        );
  }

  Widget _buildEmptyState(String contentType) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppTheme.textLightColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No $contentType found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Companies haven\'t posted any $contentType yet',
            style: TextStyle(fontSize: 14, color: AppTheme.textLightColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInternships,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> internship) {
    final bool isActive = internship['is_active'] ?? false;
    final bool? isApproved = internship['is_approved'];
    final bool isPaid = internship['is_paid'] ?? false;
    final companyData = internship['company'];
    final String companyName =
        companyData != null
            ? companyData['company_name'] ?? 'Unknown Company'
            : 'Unknown Company';
    final List<dynamic> skillsData = internship['skills'] ?? [];
    final List<String> skills = skillsData.map((s) => s.toString()).toList();
    final String city = internship['city'] ?? 'Remote';

    // Get badge text and color based on approval status
    String statusText;
    Color statusColor;

    if (isApproved == true) {
      statusText = 'Approved';
      statusColor = AppTheme.successColor;
    } else if (isApproved == false) {
      statusText = 'Rejected';
      statusColor = AppTheme.errorColor;
    } else {
      statusText = 'Pending Review';
      statusColor = AppTheme.warningColor;
    }

    return GestureDetector(
      onTap: () => _showInternshipDetails(internship),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      internship['title'] ?? 'Untitled Internship',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  _buildStatusBadge(
                    statusText,
                    statusColor,
                    isApproved == true
                        ? Icons.verified
                        : (isApproved == false ? Icons.cancel : Icons.pending),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    internship['description'] ?? 'No description provided',
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Info Row (wrap in SingleChildScrollView to prevent overflow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoChip(Icons.business, 'Company: $companyName'),
                        _buildInfoChip(Icons.location_on, 'Location: $city'),
                        _buildInfoChip(
                          Icons.timelapse,
                          'Duration: ${internship['duration'] ?? 'Not specified'}',
                        ),
                        _buildInfoChip(
                          Icons.attach_money,
                          isPaid ? 'Paid' : 'Unpaid',
                          backgroundColor:
                              isPaid
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          textColor: isPaid ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  // Action buttons for pending internships
                  if (isApproved != true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: 'Approve',
                            onPressed:
                                () => _approveInternship(internship['id']),
                            type: ButtonType.success,
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          CustomButton(
                            text: 'Reject',
                            onPressed:
                                () => _showRejectDialog(internship['id']),
                            type: ButtonType.danger,
                            height: 40,
                          ),
                        ],
                      ),
                    ),

                  // Action button for approved internships
                  if (isApproved == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: isActive ? 'Set Inactive' : 'Set Active',
                            onPressed:
                                () => _toggleInternshipActiveStatus(
                                  internship['id'],
                                  !isActive,
                                ),
                            type:
                                isActive
                                    ? ButtonType.warning
                                    : ButtonType.success,
                            icon:
                                isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                            height: 40,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppTheme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showInternshipDetails(Map<String, dynamic> internship) {
    final bool? isApproved = internship['is_approved'];
    final bool isPaid = internship['is_paid'] ?? false;
    final bool isActive = internship['is_active'] ?? false;
    final String rejectionReason =
        internship['rejection_reason'] ?? 'No reason provided';
    final companyData = internship['company'];
    final String companyName =
        companyData != null
            ? companyData['company_name'] ?? 'Unknown Company'
            : 'Unknown Company';
    final String companyEmail =
        companyData != null ? companyData['email'] ?? 'No email' : 'No email';
    final List<dynamic> skillsData = internship['skills'] ?? [];
    final List<String> skills = skillsData.map((s) => s.toString()).toList();
    final String city = internship['city'] ?? 'Remote';
    final String duration = internship['duration'] ?? 'Not specified';
    final DateTime createdAt = DateTime.parse(internship['created_at']);
    final DateTime updatedAt = DateTime.parse(internship['updated_at']);

    // Get badge text and color based on approval status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isApproved == true) {
      statusText = 'Approved';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else if (isApproved == false) {
      statusText = 'Rejected';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel;
    } else {
      statusText = 'Pending Review';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.pending;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  internship['title'] ?? 'Untitled Internship',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                // Wrap the Row in SingleChildScrollView for horizontal overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusBadge(statusText, statusColor, statusIcon),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        isPaid ? 'Paid' : 'Unpaid',
                        isPaid ? Colors.green : Colors.orange,
                        Icons.attach_money,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(
                        isActive ? 'Active' : 'Inactive',
                        isActive ? AppTheme.accentColor : Colors.grey,
                        Icons.circle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  // Company information
                  const Text(
                    'Company Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.business, 'Company', companyName),
                  _buildDetailRow(Icons.email, 'Email', companyEmail),
                  _buildDetailRow(Icons.location_on, 'Location', city),

                  const SizedBox(height: 16),

                  // Internship details
                  const Text(
                    'Internship Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.description,
                    'Description',
                    internship['description'] ?? 'No description provided',
                  ),
                  _buildDetailRow(Icons.timelapse, 'Duration', duration),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Payment',
                    isPaid ? 'Paid internship' : 'Unpaid internship',
                  ),

                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Required Skills:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          skills
                              .map(
                                (skill) => Chip(
                                  label: Text(
                                    skill,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  side: const BorderSide(
                                    color: AppTheme.primaryLightColor,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Status information
                  const Text(
                    'Status Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Add status details here
                  _buildDetailRow(statusIcon, 'Status', statusText),

                  // Add more status details here
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Created',
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  ),
                  _buildDetailRow(
                    Icons.update,
                    'Updated',
                    '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}',
                  ),

                  // For rejected internships, show rejection reason
                  if (isApproved == false)
                    _buildDetailRow(
                      Icons.comment,
                      'Rejection Reason',
                      rejectionReason,
                    ),

                  // Add active status toggle for approved internships
                  if (isApproved == true) ...[
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.visibility,
                      'Visibility',
                      isActive
                          ? 'This internship is visible to students'
                          : 'This internship is hidden from students',
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: CustomButton(
                        text: isActive ? 'Set Inactive' : 'Set Active',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _toggleInternshipActiveStatus(
                            internship['id'],
                            !isActive,
                          );
                        },
                        type:
                            isActive ? ButtonType.warning : ButtonType.success,
                        icon:
                            isActive ? Icons.visibility_off : Icons.visibility,
                        height: 45,
                        width: 200,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (isApproved != true) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(80, 36),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _approveInternship(internship['id']);
                      },
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(80, 36),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showRejectDialog(internship['id']);
                      },
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ] else
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textLightColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textColor,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
