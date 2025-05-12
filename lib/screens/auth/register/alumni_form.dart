import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class AlumniRegistrationForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController universityController;
  final TextEditingController graduationYearController;
  final TextEditingController experienceController;
  final DateTime? selectedDate;
  final Function() onSelectDate;

  const AlumniRegistrationForm({
    Key? key,
    required this.firstNameController,
    required this.lastNameController,
    required this.universityController,
    required this.graduationYearController,
    required this.experienceController,
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
              const Icon(Icons.school, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Alumni Information',
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

        // University
        CustomTextField(
          label: 'University',
          hint: 'Enter your university',
          controller: universityController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.account_balance_outlined),
        ),
        const SizedBox(height: 20),

        // Graduation Year
        CustomTextField(
          label: 'Graduation Year',
          hint: 'Year of graduation',
          controller: graduationYearController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final year = int.tryParse(value);
            if (year == null ||
                year < 1950 ||
                year > DateTime.now().year + 10) {
              return 'Enter a valid year';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        const SizedBox(height: 20),

        // Experience
        CustomTextField(
          label: 'Experience',
          hint: 'Briefly describe your professional experience',
          controller: experienceController,
          maxLines: 3,
          validator: (value) => null,
          prefixIcon: const Icon(Icons.work_outline),
        ),
      ],
    );
  }
}
