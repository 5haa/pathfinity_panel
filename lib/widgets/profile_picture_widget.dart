import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/storage_service.dart';
import 'package:admin_panel/services/auth_service.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? profilePictureUrl;
  final String userId;
  final String name;
  final UserType userType;
  final bool isEditable;
  final double size;
  final Function(String?)? onPictureUpdated;

  const ProfilePictureWidget({
    Key? key,
    this.profilePictureUrl,
    required this.userId,
    required this.name,
    required this.userType,
    this.isEditable = true,
    this.size = 100.0,
    this.onPictureUpdated,
  }) : super(key: key);

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  bool _isUploading = false;
  final StorageService _storageService = StorageService();

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final File imageFile = File(image.path);
      final String? uploadedUrl = await _storageService.uploadProfilePicture(
        widget.userId,
        imageFile,
        widget.userType,
      );

      if (uploadedUrl != null && widget.onPictureUpdated != null) {
        widget.onPictureUpdated!(uploadedUrl);
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload profile picture'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                if (widget.profilePictureUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        _isUploading = true;
                      });

                      await _storageService.deleteProfilePicture(
                        widget.userId,
                        widget.userType,
                      );

                      if (widget.onPictureUpdated != null) {
                        widget.onPictureUpdated!(null);
                      }

                      setState(() {
                        _isUploading = false;
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? _showImageSourceSheet : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            if (_isUploading)
              Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: widget.size < 60 ? 2 : 4,
                ),
              )
            else if (widget.profilePictureUrl != null &&
                widget.profilePictureUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(widget.size / 2),
                child: Image.network(
                  widget.profilePictureUrl!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildInitialsAvatar(),
                ),
              )
            else
              _buildInitialsAvatar(),

            if (widget.isEditable)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: widget.size < 60 ? 12 : 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    String initials = '';

    if (widget.name.isNotEmpty) {
      final nameParts = widget.name.trim().split(' ');

      if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
        initials += nameParts.first[0].toUpperCase();

        if (nameParts.length > 1 && nameParts.last.isNotEmpty) {
          initials += nameParts.last[0].toUpperCase();
        }
      }
    }

    // Default to question mark if no initials could be extracted
    if (initials.isEmpty) {
      initials = '?';
    }

    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: _getAvatarColor(),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: widget.size * 0.35,
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    // Use different colors based on user type or generate a color from userId
    // to keep the same color for the same user
    switch (widget.userType) {
      case UserType.alumni:
        return AppTheme.primaryColor;
      case UserType.admin:
        return AppTheme.accentColor;
      case UserType.company:
        return Colors.teal;
      case UserType.contentCreator:
        return Colors.purple;
      case UserType.unknown:
      default:
        // Generate a color based on the user ID to ensure consistency
        if (widget.userId.isNotEmpty) {
          final int hashCode = widget.userId.hashCode;
          final List<Color> colors = [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            AppTheme.accentColor,
            Colors.purple,
            Colors.teal,
            Colors.indigo,
            Colors.orange,
          ];
          return colors[hashCode.abs() % colors.length];
        }
        return AppTheme.secondaryColor;
    }
  }
}
