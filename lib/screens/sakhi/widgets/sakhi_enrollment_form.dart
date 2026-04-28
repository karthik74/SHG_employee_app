import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../sakhi_form_controller.dart';
import 'sakhi_aadhaar_section.dart';
import 'sakhi_basic_info_section.dart';
import 'sakhi_contact_section.dart';
import 'sakhi_documents_section.dart';
import 'sakhi_family_section.dart';

/// "Enroll New" tab content. Composes the five form sections and the submit
/// button, owning only the [Form] key passed in by the screen.
class SakhiEnrollmentForm extends StatelessWidget {
  const SakhiEnrollmentForm({
    super.key,
    required this.controller,
    required this.formKey,
    required this.onVerifyAadhar,
    required this.onFetchAadharNow,
    required this.onPickSakhiPhoto,
    required this.onPickAadharPhoto,
    required this.onPickPanPhoto,
    required this.onSelectDate,
    required this.onVerifyMobile,
    required this.onSubmit,
  });

  final SakhiFormController controller;
  final GlobalKey<FormState> formKey;
  final VoidCallback onVerifyAadhar;
  final VoidCallback onFetchAadharNow;
  final VoidCallback onPickSakhiPhoto;
  final VoidCallback onPickAadharPhoto;
  final VoidCallback onPickPanPhoto;
  final VoidCallback onSelectDate;
  final VoidCallback onVerifyMobile;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Sakhi Enrollment',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text('Please fill in all details and upload documents carefully.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    SakhiAadhaarSection(
                      controller: controller,
                      onVerifyAadhar: onVerifyAadhar,
                      onFetchAadharNow: onFetchAadharNow,
                    ),
                    SakhiBasicInfoSection(
                      controller: controller,
                      onPickSakhiPhoto: onPickSakhiPhoto,
                      onSelectDate: onSelectDate,
                    ),
                    SakhiContactSection(
                      controller: controller,
                      onVerifyMobile: onVerifyMobile,
                    ),
                    SakhiDocumentsSection(
                      controller: controller,
                      onPickAadharPhoto: onPickAadharPhoto,
                      onPickPanPhoto: onPickPanPhoto,
                    ),
                    SakhiFamilySection(controller: controller),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isLoading ? null : onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: controller.isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('CREATE SAKHI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
