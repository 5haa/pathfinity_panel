import 'package:flutter/material.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class CompanyRegistrationForm extends StatelessWidget {
  final TextEditingController companyNameController;

  const CompanyRegistrationForm({Key? key, required this.companyNameController})
    : super(key: key);

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
              const Icon(Icons.business, color: AppTheme.accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Company Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Company name field
        CustomTextField(
          label: 'Company Name',
          hint: 'Enter your company name',
          controller: companyNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Company name is required';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.business_outlined),
        ),
      ],
    );
  }
}
