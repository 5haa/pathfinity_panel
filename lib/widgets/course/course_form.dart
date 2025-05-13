import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/course_model.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/custom_button.dart';

class CourseForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? selectedCategoryId;
  final String selectedMembershipType;
  final String selectedDifficulty;
  final File? thumbnailFile;
  final String? currentThumbnailUrl;
  final List<CourseCategory> categories;
  final bool isUploading;
  final bool isLoading;
  final bool isEditing;
  final Function(String?) onCategoryChanged;
  final Function(String) onMembershipTypeChanged;
  final Function(String) onDifficultyChanged;
  final Function() onSelectThumbnail;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const CourseForm({
    Key? key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    this.selectedCategoryId,
    required this.selectedMembershipType,
    required this.selectedDifficulty,
    this.thumbnailFile,
    this.currentThumbnailUrl,
    required this.categories,
    this.isUploading = false,
    this.isLoading = false,
    this.isEditing = false,
    required this.onCategoryChanged,
    required this.onMembershipTypeChanged,
    required this.onDifficultyChanged,
    required this.onSelectThumbnail,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<CourseForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'Edit Course' : 'Create New Course',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Thumbnail selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Course Thumbnail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.onSelectThumbnail,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      image:
                          widget.thumbnailFile != null
                              ? DecorationImage(
                                image: FileImage(widget.thumbnailFile!),
                                fit: BoxFit.cover,
                              )
                              : (widget.currentThumbnailUrl != null &&
                                      widget.currentThumbnailUrl!.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(
                                      widget.currentThumbnailUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : null),
                    ),
                    child:
                        (widget.thumbnailFile == null &&
                                (widget.currentThumbnailUrl == null ||
                                    widget.currentThumbnailUrl!.isEmpty))
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Add Course Thumbnail',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '16:9 ratio recommended (landscape)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                            : Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      onPressed: widget.onSelectThumbnail,
                                      tooltip: 'Change thumbnail',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          CustomTextField(
            label: 'Course Title',
            controller: widget.titleController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course title';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          CustomTextField(
            label: 'Course Description',
            controller: widget.descriptionController,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a course description';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Category dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a category'),
                    value: widget.selectedCategoryId,
                    items:
                        widget.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      widget.onCategoryChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Membership type toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Membership Required',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Free option
                        GestureDetector(
                          onTap: () {
                            widget.onMembershipTypeChanged(MembershipType.free);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.selectedMembershipType ==
                                          MembershipType.free
                                      ? Colors.green
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_open,
                                  size: 16,
                                  color:
                                      widget.selectedMembershipType ==
                                              MembershipType.free
                                          ? Colors.white
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Free',
                                  style: TextStyle(
                                    color:
                                        widget.selectedMembershipType ==
                                                MembershipType.free
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Pro option
                        GestureDetector(
                          onTap: () {
                            widget.onMembershipTypeChanged(MembershipType.pro);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  widget.selectedMembershipType ==
                                          MembershipType.pro
                                      ? Colors.purple
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color:
                                      widget.selectedMembershipType ==
                                              MembershipType.pro
                                          ? Colors.white
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pro',
                                  style: TextStyle(
                                    color:
                                        widget.selectedMembershipType ==
                                                MembershipType.pro
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Difficulty level dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Difficulty Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: widget.selectedDifficulty,
                    items: [
                      DropdownMenuItem(
                        value: DifficultyLevel.easy,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Easy'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: DifficultyLevel.medium,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Medium'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: DifficultyLevel.hard,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Hard'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onDifficultyChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Upload progress indicator
          if (widget.isUploading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Uploading...',
                style: TextStyle(color: AppTheme.textLightColor),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.isEditing) ...[
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed:
                      widget.isUploading
                          ? null
                          : () {
                            widget.onSubmit();
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ] else ...[
                CustomButton(
                  text: 'Cancel',
                  onPressed: widget.onCancel,
                  type: ButtonType.secondary,
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'Create Course',
                  onPressed: widget.isUploading ? () {} : widget.onSubmit,
                  isLoading: widget.isLoading && !widget.isUploading,
                  type: ButtonType.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
