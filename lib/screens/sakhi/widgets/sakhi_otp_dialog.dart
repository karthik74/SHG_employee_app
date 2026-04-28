import 'package:flutter/material.dart';

import '../../../services/sakhi_api.dart';
import '../../../theme/app_theme.dart';

/// Modal that prompts the user for the 6-digit OTP just sent to [number] and
/// verifies it via [api]. Resolves to `true` when the OTP was accepted, to
/// `false` (or `null`) when the user dismissed the dialog. Behaviour is a
/// straight port of the inline `showDialog` block that previously lived in
/// `_verifyMobile`.
Future<bool?> showSakhiOtpDialog({
  required BuildContext context,
  required String number,
  required SakhiApi api,
}) {
  final otpController = TextEditingController();
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      bool verifying = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Verify Sakhi Mobile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OTP sent to $number', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: verifying
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      if (otp.isEmpty) return;
                      setDialogState(() => verifying = true);
                      try {
                        final ok = await api.verifyOtp(number, otp);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(dialogCtx, true);
                        } else {
                          setDialogState(() => verifying = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Invalid OTP')),
                          );
                        }
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setDialogState(() => verifying = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Verification failed: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: verifying
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify'),
            ),
          ],
        ),
      );
    },
  );
}
