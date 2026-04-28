import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../sakhi_form_controller.dart';
import 'sakhi_form_fields.dart';

/// Aadhaar number entry, "Verify" / "Re-send" trigger and the
/// pending / fetched status banners.
class SakhiAadhaarSection extends StatelessWidget {
  const SakhiAadhaarSection({
    super.key,
    required this.controller,
    required this.onVerifyAadhar,
    required this.onFetchAadharNow,
  });

  final SakhiFormController controller;
  final VoidCallback onVerifyAadhar;
  final VoidCallback onFetchAadharNow;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SakhiSectionHeader('Aadhaar Verification'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.aadharNoController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    onChanged: (_) => controller.onAadharNumberChanged(),
                    decoration: InputDecoration(
                      labelText: 'Aadhar Number',
                      counterText: '',
                      prefixIcon: Icon(Icons.badge, color: Colors.grey[500], size: 20),
                      suffixIcon: controller.aadharFetched
                          ? const Icon(Icons.verified, color: Colors.green)
                          : null,
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Required';
                      if (value.trim().length != 12) return 'Must be 12 digits';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isAadharVerifying ? null : onVerifyAadhar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.aadharLinkSent ? Colors.green : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: controller.isAadharVerifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(controller.aadharLinkSent ? 'Re-send' : 'Verify', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (controller.aadharLinkSent && !controller.aadharFetched) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: controller.isFetchingAadhar || controller.aadharPollTimer?.isActive == true
                          ? const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)
                          : const Icon(Icons.hourglass_top, size: 18, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Complete verification in the browser. Details will auto-fill once available.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.isFetchingAadhar ? null : onFetchAadharNow,
                      child: const Text('Fetch Now'),
                    ),
                  ],
                ),
              ),
            ],
            if (controller.aadharFetched) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aadhaar verified — details auto-filled below.',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
