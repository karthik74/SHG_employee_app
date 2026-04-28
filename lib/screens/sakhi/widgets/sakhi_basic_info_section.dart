import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../sakhi_form_controller.dart';
import 'sakhi_form_fields.dart';

/// "Basic Information" group: profile photo, Sakhi name, the read-only Taluk
/// field, the Gram Panchayat dropdown, and the date-of-birth picker.
class SakhiBasicInfoSection extends StatelessWidget {
  const SakhiBasicInfoSection({
    super.key,
    required this.controller,
    required this.onPickSakhiPhoto,
    required this.onSelectDate,
  });

  final SakhiFormController controller;
  final VoidCallback onPickSakhiPhoto;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            const SakhiSectionHeader('Basic Information'),

            // Sakhi Photo Upload
            Center(
              child: GestureDetector(
                onTap: onPickSakhiPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2),
                        image: controller.sakhiPhoto != null
                            ? DecorationImage(image: FileImage(controller.sakhiPhoto!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: controller.sakhiPhoto == null
                          ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Upload Sakhi Photo', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
            const SizedBox(height: 24),

            SakhiTextField(label: 'Sakhi Name', controller: controller.sakhiNameController, icon: Icons.person),

            // Office (from logged-in user)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                enabled: false,
                controller: TextEditingController(text: controller.selectedOfficeName ?? 'Loading office…'),
                decoration: InputDecoration(
                  labelText: 'Taluk',
                  prefixIcon: Icon(Icons.store, color: Colors.grey[500], size: 20),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Gram Panchayat Dropdown
            SakhiDropdownField(
              label: 'Gram Panchayat',
              icon: Icons.location_city,
              value: controller.selectedGramPanchayatId,
              items: controller.gramPanchayats.map((gp) => DropdownMenuItem(
                value: gp['id'] as int,
                child: Text(gp['name']?.toString() ?? 'N/A'),
              )).toList(),
              onChanged: controller.setSelectedGramPanchayatId,
            ),

            GestureDetector(
              onTap: onSelectDate,
              child: AbsorbPointer(
                child: SakhiTextField(
                  label: 'Date of Birth (dd-MM-yyyy)',
                  controller: controller.dobController,
                  icon: Icons.calendar_month,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
