import 'package:flutter/material.dart';

import '../sakhi_form_controller.dart';
import 'sakhi_form_fields.dart';

/// "Family & Occupation" group: spouse name, spouse mobile, the two
/// occupation dropdowns, and the monthly-income field.
class SakhiFamilySection extends StatelessWidget {
  const SakhiFamilySection({super.key, required this.controller});

  final SakhiFormController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 24),
            const SakhiSectionHeader('Family & Occupation'),
            SakhiTextField(label: 'Spouse Name', controller: controller.spouseNameController, icon: Icons.family_restroom),
            SakhiTextField(label: 'Spouse Mobile', controller: controller.spouseMobileController, icon: Icons.phone_android, isNumber: true, maxLength: 10),

            // Occupation Dropdown
            SakhiDropdownField(
              label: 'Sakhi Occupation',
              icon: Icons.work,
              value: controller.occupationId,
              items: controller.professions.map((p) => DropdownMenuItem(
                value: p['id'] as int,
                child: Text(p['name']?.toString() ?? 'N/A'),
              )).toList(),
              onChanged: controller.setOccupationId,
            ),

            // Spouse Occupation Dropdown
            SakhiDropdownField(
              label: 'Spouse Occupation',
              icon: Icons.work_outline,
              value: controller.spouseOccupationId,
              items: controller.professions.map((p) => DropdownMenuItem(
                value: p['id'] as int,
                child: Text(p['name']?.toString() ?? 'N/A'),
              )).toList(),
              onChanged: controller.setSpouseOccupationId,
            ),

            SakhiTextField(label: 'Monthly Income (₹)', controller: controller.monthlyIncomeController, icon: Icons.currency_rupee, isNumber: true),
          ],
        );
      },
    );
  }
}
