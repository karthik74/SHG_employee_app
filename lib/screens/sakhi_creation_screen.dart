import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'sakhi/sakhi_form_controller.dart';
import 'sakhi/widgets/sakhi_enrollment_form.dart';
import 'sakhi/widgets/sakhi_list_view.dart';
import 'sakhi/widgets/sakhi_otp_dialog.dart';

/// Top-level Sakhi screen with two tabs ("My Sakhis" and "Enroll New").
///
/// All persistent form state — including the `TextEditingController`s, the
/// Aadhaar polling [Timer], dropdown lookup data, and the mobile-OTP /
/// Aadhaar status flags — lives on a [SakhiFormController]. This widget owns
/// the [TabController], the [GlobalKey] for the form, and the side-effecting
/// methods that need a [BuildContext] (snackbars, dialogs, image picker, date
/// picker, URL launcher). Behaviour is preserved verbatim from the previous
/// monolithic implementation.
class SakhiCreationScreen extends StatefulWidget {
  const SakhiCreationScreen({super.key});

  @override
  State<SakhiCreationScreen> createState() => _SakhiCreationScreenState();
}

class _SakhiCreationScreenState extends State<SakhiCreationScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SakhiFormController _controller = SakhiFormController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.attachMobileListener();
    _controller.fetchSakhis();
    _controller.loadTemplateData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------- Helpers wrapping the picker / date dialogs ----------------

  Future<void> _capturePhoto(void Function(File) onImageSelected) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) onImageSelected(File(picked.path));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      String day = picked.day.toString().padLeft(2, '0');
      String month = picked.month.toString().padLeft(2, '0');
      String year = picked.year.toString();
      _controller.dobController.text = '$day-$month-$year';
    }
  }

  // ---------------- Mobile OTP flow ----------------

  Future<void> _verifyMobile() async {
    final number = _controller.mobileController.text.trim();
    if (number.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }

    _controller.isSendingSakhiOtp = true;

    try {
      await _controller.api.sendOtp(number);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
      _controller.isSendingSakhiOtp = false;
      return;
    }

    if (!mounted) return;
    _controller.isSendingSakhiOtp = false;

    final verified = await showSakhiOtpDialog(
      context: context,
      number: number,
      api: _controller.api,
    );

    if (!mounted) return;
    if (verified == true) {
      _controller.sakhiMobileVerified = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile verified successfully'), backgroundColor: Colors.green),
      );
    }
  }

  // ---------------- Aadhaar verification flow ----------------

  /// Launches the Aadhaar verification URL, falling back through three
  /// launcher modes (external app → platform default → in-app browser) before
  /// giving up. Returns `true` once any of them succeeds. Mirrors the original
  /// inline triple try/catch chain exactly.
  Future<bool> _launchAadharLink(Uri uri) async {
    bool launched = false;
    for (final mode in const [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      if (launched) break;
      try {
        launched = await launchUrl(uri, mode: mode);
      } catch (_) {
        launched = false;
      }
    }
    return launched;
  }

  Future<void> _verifyAadhar() async {
    final aadhar = _controller.aadharNoController.text.trim();
    if (aadhar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 12-digit Aadhaar number')),
      );
      return;
    }
    _controller.isAadharVerifying = true;
    try {
      final resp = await _controller.api.generateAadharLink(aadhar);
      if (!mounted) return;
      final status = resp['status']?.toString().toLowerCase();
      final result = resp['result'];
      final link = result is Map ? result['link']?.toString() : null;
      final refId = resp['reference_id']?.toString();
      final txnId = resp['transaction_id']?.toString();

      if (status == 'success' && link != null && link.isNotEmpty) {
        final launched = await _launchAadharLink(Uri.parse(link));
        if (!mounted) return;
        _controller.markAadharLinkSent(launched: launched, refId: refId, txnId: txnId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(launched
                ? 'Verify in browser. Auto-fetching details…'
                : 'Could not open link'),
            backgroundColor: launched ? Colors.green : Colors.red,
          ),
        );
        if (launched && refId != null && txnId != null) {
          _controller.startAadharAutoFetch(() => _fetchAadharDetails(silent: true));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message']?.toString() ?? 'Failed to generate link')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aadhaar verification failed: $e')),
      );
    } finally {
      if (mounted) _controller.isAadharVerifying = false;
    }
  }

  Future<void> _fetchAadharDetails({bool silent = false}) async {
    final refId = _controller.aadharReferenceId;
    final txnId = _controller.aadharTransactionId;
    if (refId == null || txnId == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generate verification link first')),
        );
      }
      return;
    }
    if (!silent) _controller.isFetchingAadhar = true;
    try {
      final resp = await _controller.api.downloadAadhar(referenceId: refId, transactionId: txnId);
      if (!mounted) return;
      final validated = resp['result'] is Map ? resp['result']['validated_data'] : null;
      final data = validated is Map ? validated['result'] : null;
      final innerStatus = data is Map ? data['status']?.toString().toUpperCase() : null;

      if (data is Map && innerStatus == 'SUCCESS') {
        _controller.applyAadharData(data);
        _controller.markAadharFetched();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar details fetched'), backgroundColor: Colors.green),
        );
      } else {
        if (!silent) {
          _controller.isFetchingAadhar = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp['message']?.toString() ?? 'Details not ready yet')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        _controller.isFetchingAadhar = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetch failed: $e')),
        );
      }
    }
  }

  // ---------------- Submission ----------------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controller.sakhiPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Sakhi Photo')));
      return;
    }

    _controller.isLoading = true;

    final payload = _controller.buildPayload();

    try {
      final respBody = await _controller.api.createSakhi(payload);
      if (!mounted) return;

      String resourceId = respBody['resourceId']?.toString()
          ?? respBody['sakhiId']?.toString()
          ?? '650';

      if (_controller.sakhiPhoto != null) {
        await _controller.api.uploadSakhiImage(resourceId, _controller.sakhiPhoto!);
      }
      if (_controller.aadharPhoto != null) {
        await _controller.api.uploadAadhar(resourceId, _controller.aadharPhoto!);
      }
      if (_controller.panPhoto != null) {
        await _controller.api.uploadPan(resourceId, _controller.panPhoto!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sakhi Created (ID: $resourceId) & documents uploaded!', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );

      _tabController.animateTo(0);
      _formKey.currentState!.reset();
      _controller.resetFormTokens();
      await _controller.fetchSakhis();
    } catch (e) {
      if (!mounted) return;
      final message = _controller.extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) _controller.isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Sakhi Directory'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Inter', fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Sakhis'),
            Tab(text: 'Enroll New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SakhiListView(
            controller: _controller,
            onEnrollTap: () => _tabController.animateTo(1),
          ),
          SakhiEnrollmentForm(
            controller: _controller,
            formKey: _formKey,
            onVerifyAadhar: _verifyAadhar,
            onFetchAadharNow: () => _fetchAadharDetails(silent: false),
            onPickSakhiPhoto: () => _capturePhoto(_controller.setSakhiPhoto),
            onPickAadharPhoto: () => _capturePhoto(_controller.setAadharPhoto),
            onPickPanPhoto: () => _capturePhoto(_controller.setPanPhoto),
            onSelectDate: _selectDate,
            onVerifyMobile: _verifyMobile,
            onSubmit: _submitForm,
          ),
        ],
      ),
    );
  }
}
