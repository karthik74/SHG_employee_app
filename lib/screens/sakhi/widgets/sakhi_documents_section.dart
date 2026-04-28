import 'package:flutter/material.dart';

import '../sakhi_form_controller.dart';
import 'sakhi_form_fields.dart';

/// "Identification Documents" group: Aadhaar card image upload, PAN number
/// text input with format validation, and PAN card image upload.
class SakhiDocumentsSection extends StatelessWidget {
  const SakhiDocumentsSection({
    super.key,
    required this.controller,
    required this.onPickAadharPhoto,
    required this.onPickPanPhoto,
  });

  final SakhiFormController controller;
  final VoidCallback onPickAadharPhoto;
  final VoidCallback onPickPanPhoto;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 12),
            const SakhiSectionHeader('Identification Documents'),

            // Aadhar Card Image
            SakhiImageUploader(
              title: 'Upload Aadhar Card Image',
              file: controller.aadharPhoto,
              onPick: onPickAadharPhoto,
            ),
            const SizedBox(height: 16),

            // PAN Card Section
            SakhiTextField(
              label: 'PAN Number',
              controller: controller.panNoController,
              icon: Icons.credit_card,
              uppercase: true,
              maxLength: 10,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'This field is required';
                if (v.length != 10) return 'PAN must be 10 characters';
                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) return 'Invalid PAN format';
                return null;
              },
            ),
            SakhiImageUploader(
              title: 'Upload PAN Card Image',
              file: controller.panPhoto,
              onPick: onPickPanPhoto,
            ),
          ],
        );
      },
    );
  }
}
