import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class ContentCreatorRegistrationForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final DateTime? selectedDate;
  final Function() onSelectDate;

  const ContentCreatorRegistrationForm({
    Key? key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.bioController,
    required this.selectedDate,
    required this.onSelectDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              const Icon(
                Icons.video_library,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Content Creator Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Name fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                label: 'First Name',
                hint: 'Enter your first name',
                controller: firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: 'Last Name',
                hint: 'Enter your last name',
                controller: lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Birthdate
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelectDate,
          child: AbsorbPointer(
            child: CustomTextField(
              label: 'Birthdate',
              controller: TextEditingController(
                text:
                    selectedDate == null
                        ? ''
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
              hint: 'Select your birthdate',
              readOnly: true,
              validator: (value) => null,
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Phone
        CustomTextField(
          label: 'Phone',
          hint: 'Enter your phone number',
          controller: phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: 20),

        // Bio
        CustomTextField(
          label: 'Bio',
          hint: 'Tell us about yourself and your content',
          controller: bioController,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bio is required';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.description_outlined),
        ),
      ],
    );
  }
}
