import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// Section heading used inside the enrollment form. Mirrors the original
/// `_buildHeader` helper one-for-one.
class SakhiSectionHeader extends StatelessWidget {
  const SakhiSectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          const Divider(),
        ],
      ),
    );
  }
}

/// Standard text input row used throughout the enrollment form. Mirrors the
/// original `_buildTextField` helper.
class SakhiTextField extends StatelessWidget {
  const SakhiTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.isNumber = false,
    this.uppercase = false,
    this.maxLength,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isNumber;
  final bool uppercase;
  final int? maxLength;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
        inputFormatters: uppercase
            ? [TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()))]
            : null,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator ?? (value) {
          if (value == null || value.trim().isEmpty) return 'This field is required';
          return null;
        },
      ),
    );
  }
}

/// Dropdown row used throughout the enrollment form. Mirrors the original
/// `_buildDropdownField` helper, with the deprecated `value:` parameter
/// migrated to `initialValue:`.
class SakhiDropdownField extends StatelessWidget {
  const SakhiDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<int>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null ? 'Please select an option' : null,
      ),
    );
  }
}

/// Image-attachment row used for Aadhaar / PAN uploads. Mirrors the original
/// `_buildImageUploader` helper.
class SakhiImageUploader extends StatelessWidget {
  const SakhiImageUploader({
    super.key,
    required this.title,
    required this.file,
    required this.onPick,
  });

  final String title;
  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(file != null ? Icons.check_circle : Icons.upload_file,
                 color: file != null ? Colors.green : AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? 'Image Attached (${(file!.lengthSync() / 1024).toStringAsFixed(0)} KB)' : title,
                style: TextStyle(
                  fontSize: 14,
                  color: file != null ? Colors.green[700] : AppTheme.textSecondary,
                  fontWeight: file != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(file!, width: 40, height: 40, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mobile-number row with an inline OTP-verify button. Mirrors the original
/// `_buildMobileVerifyField` helper.
class SakhiMobileVerifyField extends StatelessWidget {
  const SakhiMobileVerifyField({
    super.key,
    required this.label,
    required this.controller,
    required this.verified,
    required this.sending,
    required this.onVerify,
  });

  final String label;
  final TextEditingController controller;
  final bool verified;
  final bool sending;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: label,
                counterText: '',
                prefixIcon: Icon(Icons.phone_android, color: Colors.grey[500], size: 20),
                suffixIcon: verified
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
                if (value.trim().length != 10) return 'Must be 10 digits';
                if (!verified) return 'Please verify via OTP';
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: verified || sending ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: verified ? Colors.green : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(verified ? 'Verified' : 'Verify', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
