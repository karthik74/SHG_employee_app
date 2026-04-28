import 'package:flutter/material.dart';

import '../sakhi_form_controller.dart';
import 'sakhi_form_fields.dart';

/// "Contact Details" group: mobile-with-OTP and address.
class SakhiContactSection extends StatelessWidget {
  const SakhiContactSection({
    super.key,
    required this.controller,
    required this.onVerifyMobile,
  });

  final SakhiFormController controller;
  final VoidCallback onVerifyMobile;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 12),
            const SakhiSectionHeader('Contact Details'),
            SakhiMobileVerifyField(
              label: 'Mobile Number',
              controller: controller.mobileController,
              verified: controller.sakhiMobileVerified,
              sending: controller.isSendingSakhiOtp,
              onVerify: onVerifyMobile,
            ),
            SakhiTextField(label: 'Address', controller: controller.addressController, icon: Icons.location_on),
          ],
        );
      },
    );
  }
}
