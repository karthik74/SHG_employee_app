import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sakhi_api.dart';
import '../services/api_client.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';

class SakhiCreationScreen extends StatefulWidget {
  const SakhiCreationScreen({super.key});

  @override
  State<SakhiCreationScreen> createState() => _SakhiCreationScreenState();
}

class _SakhiCreationScreenState extends State<SakhiCreationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // My Sakhis State
  bool _isLoadingSakhis = false;
  List<Map<String, String>> _sakhis = [];

  // Enrollment Form State
  final _formKey = GlobalKey<FormState>();

  final _sakhiNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadharNoController = TextEditingController();
  final _panNoController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _spouseMobileController = TextEditingController();

  int? _selectedOfficeId;
  String? _selectedOfficeName;
  int? _selectedGramPanchayatId;
  int? _occupationId;
  int? _spouseOccupationId;

  List<dynamic> _gramPanchayats = [];
  List<dynamic> _professions = [];

  bool _isLoading = false;

  bool _isAadharVerifying = false;
  bool _aadharLinkSent = false;
  bool _isFetchingAadhar = false;
  bool _aadharFetched = false;
  String? _aadharReferenceId;
  String? _aadharTransactionId;
  Timer? _aadharPollTimer;
  int _aadharPollAttempts = 0;

  bool _sakhiMobileVerified = false;
  bool _isSendingSakhiOtp = false;

  // Image files
  File? _sakhiPhoto;
  File? _aadharPhoto;
  File? _panPhoto;

  final ImagePicker _picker = ImagePicker();
  final SakhiApi _sakhiApi = SakhiApi();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSakhis();
    _loadTemplateData();
    _mobileController.addListener(() {
      if (_sakhiMobileVerified) setState(() => _sakhiMobileVerified = false);
    });
  }

  Future<void> _verifyMobile() async {
    final number = _mobileController.text.trim();
    if (number.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isSendingSakhiOtp = true);

    try {
      await _sakhiApi.sendOtp(number);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
      setState(() => _isSendingSakhiOtp = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isSendingSakhiOtp = false);

    final otpController = TextEditingController();
    final verified = await showDialog<bool>(
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
                          final ok = await _sakhiApi.verifyOtp(number, otp);
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

    if (!mounted) return;
    if (verified == true) {
      setState(() => _sakhiMobileVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile verified successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildMobileVerifyField({
    required String label,
    required TextEditingController controller,
    required bool verified,
    required bool sending,
    required VoidCallback onVerify,
  }) {
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

  @override
  void dispose() {
    _aadharPollTimer?.cancel();
    _tabController.dispose();
    _sakhiNameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _aadharNoController.dispose();
    _panNoController.dispose();
    _spouseNameController.dispose();
    _addressController.dispose();
    _monthlyIncomeController.dispose();
    _spouseMobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchSakhis() async {
    setState(() => _isLoadingSakhis = true);
    try {
      final items = await _sakhiApi.fetchSakhis(
        officeId: AuthSession.instance.officeId,
      );
      setState(() {
        _sakhis = items.map<Map<String, String>>((item) {
          final statusEnum = item['statusEnum'];
          String status = 'Active';
          if (statusEnum == 100) status = 'Pending';
          if (statusEnum == 200) status = 'Active';
          
          return {
            'id': item['resourceId']?.toString() ?? item['id']?.toString() ?? 'N/A',
            'code': item['sakhiCode']?.toString() ?? '-',
            'name': item['sakhiName']?.toString() ?? 'Unknown',
            'mobile': item['mobileNumber']?.toString() ?? 'N/A',
            'branch': item['officeName']?.toString() ?? item['branchName']?.toString() ?? 'Main Branch',
            'status': status,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading sakhis: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSakhis = false);
    }
  }

  Future<void> _loadTemplateData() async {
    final userOfficeId = AuthSession.instance.officeId;
    final userOfficeName = AuthSession.instance.officeName;
    if (mounted && userOfficeId != null) {
      setState(() {
        _selectedOfficeId = userOfficeId;
        _selectedOfficeName = userOfficeName;
      });
    }

    try {
      if (userOfficeId != null) {
        final office = await _sakhiApi.fetchOfficeById(userOfficeId);
        if (mounted && office.isNotEmpty) {
          setState(() {
            _selectedOfficeId = (office['id'] is int) ? office['id'] as int : userOfficeId;
            _selectedOfficeName = office['name']?.toString() ?? userOfficeName;
          });
        }

        final panchayats = await _sakhiApi.fetchGramPanchayats(userOfficeId);
        if (mounted) {
          setState(() {
            _gramPanchayats = panchayats;
            if (panchayats.isNotEmpty) {
              _selectedGramPanchayatId = panchayats[0]['id'] is int ? panchayats[0]['id'] as int : null;
            }
          });
        }
      }

      final template = await _sakhiApi.fetchSakhiTemplate();
      if (mounted) {
        setState(() {
          _professions = template['professionOptions'] ?? [];
          if (_professions.isNotEmpty) {
            _occupationId = _professions[0]['id'];
            _spouseOccupationId = _professions[0]['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading template data: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        String day = picked.day.toString().padLeft(2, '0');
        String month = picked.month.toString().padLeft(2, '0');
        String year = picked.year.toString();
        _dobController.text = "$day-$month-$year";
      });
    }
  }

  Future<void> _showImageSourceDialog(Function(File) onImageSelected) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
              title: const Text('Take a photo from Camera'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) onImageSelected(File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) onImageSelected(File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyAadhar() async {
    final aadhar = _aadharNoController.text.trim();
    if (aadhar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 12-digit Aadhaar number')),
      );
      return;
    }
    setState(() => _isAadharVerifying = true);
    try {
      final resp = await _sakhiApi.generateAadharLink(aadhar);
      if (!mounted) return;
      final status = resp['status']?.toString().toLowerCase();
      final result = resp['result'];
      final link = result is Map ? result['link']?.toString() : null;
      final refId = resp['reference_id']?.toString();
      final txnId = resp['transaction_id']?.toString();

      if (status == 'success' && link != null && link.isNotEmpty) {
        final uri = Uri.parse(link);
        bool launched = false;
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          launched = false;
        }
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (_) {
            launched = false;
          }
        }
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          } catch (_) {
            launched = false;
          }
        }
        if (!mounted) return;
        setState(() {
          _aadharLinkSent = launched;
          _aadharReferenceId = refId;
          _aadharTransactionId = txnId;
          _aadharFetched = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(launched
                ? 'Verify in browser. Auto-fetching details…'
                : 'Could not open link'),
            backgroundColor: launched ? Colors.green : Colors.red,
          ),
        );
        if (launched && refId != null && txnId != null) {
          _startAadharAutoFetch();
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
      if (mounted) setState(() => _isAadharVerifying = false);
    }
  }

  void _startAadharAutoFetch() {
    _aadharPollTimer?.cancel();
    _aadharPollAttempts = 0;
    _aadharPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _aadharFetched) {
        timer.cancel();
        return;
      }
      _aadharPollAttempts++;
      if (_aadharPollAttempts > 36) {
        timer.cancel();
        return;
      }
      await _fetchAadharDetails(silent: true);
    });
  }

  Future<void> _fetchAadharDetails({bool silent = false}) async {
    final refId = _aadharReferenceId;
    final txnId = _aadharTransactionId;
    if (refId == null || txnId == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generate verification link first')),
        );
      }
      return;
    }
    if (!silent) setState(() => _isFetchingAadhar = true);
    try {
      final resp = await _sakhiApi.downloadAadhar(referenceId: refId, transactionId: txnId);
      if (!mounted) return;
      final validated = resp['result'] is Map ? resp['result']['validated_data'] : null;
      final data = validated is Map ? validated['result'] : null;
      final innerStatus = data is Map ? data['status']?.toString().toUpperCase() : null;

      if (data is Map && innerStatus == 'SUCCESS') {
        _applyAadharData(data);
        _aadharPollTimer?.cancel();
        setState(() {
          _aadharFetched = true;
          _isFetchingAadhar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar details fetched'), backgroundColor: Colors.green),
        );
      } else {
        if (!silent) {
          setState(() => _isFetchingAadhar = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp['message']?.toString() ?? 'Details not ready yet')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isFetchingAadhar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetch failed: $e')),
        );
      }
    }
  }

  void _applyAadharData(Map data) {
    final name = data['name']?.toString();
    final dob = data['dob']?.toString();
    final address = data['address']?.toString();
    setState(() {
      if (name != null && name.isNotEmpty) _sakhiNameController.text = name;
      if (dob != null && dob.isNotEmpty) _dobController.text = dob;
      if (address != null && address.isNotEmpty) _addressController.text = address;
    });
  }

  String _extractErrorMessage(Object e) {
    if (e is ApiException) {
      final body = e.body;
      if (body != null && body.isNotEmpty) {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            final errors = decoded['errors'];
            if (errors is List && errors.isNotEmpty) {
              final first = errors.first;
              if (first is Map) {
                final msg = first['defaultUserMessage']?.toString()
                    ?? first['developerMessage']?.toString();
                if (msg != null && msg.isNotEmpty) return msg;
              }
            }
            final top = decoded['defaultUserMessage']?.toString()
                ?? decoded['developerMessage']?.toString();
            if (top != null && top.isNotEmpty) return top;
          }
        } catch (_) {}
      }
      return e.message;
    }
    return e.toString();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sakhiPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Sakhi Photo')));
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      "officeId": _selectedOfficeId,
      "gramPanchayatId": _selectedGramPanchayatId,
      "sakhiName": _sakhiNameController.text.trim(),
      "dob": _dobController.text.trim(),
      "mobileNumber": _mobileController.text.trim(),
      "aadharNo": _aadharNoController.text.trim(),
      "panNo": _panNoController.text.trim(),
      "spouseName": _spouseNameController.text.trim(),
      "spouseOccupation": _spouseOccupationId,
      "occupation": _occupationId,
      "address": _addressController.text.trim(),
      "monthlyIncome": _monthlyIncomeController.text.trim(),
      "spouseMobile": _spouseMobileController.text.trim(),
      "dateFormat": "dd-MM-yyyy",
      "locale": "en",
    };

    try {
      final respBody = await _sakhiApi.createSakhi(payload);
      if (!mounted) return;

      String resourceId = respBody['resourceId']?.toString()
          ?? respBody['sakhiId']?.toString()
          ?? '650';

      if (_sakhiPhoto != null) {
        await _sakhiApi.uploadSakhiImage(resourceId, _sakhiPhoto!);
      }
      if (_aadharPhoto != null) {
        await _sakhiApi.uploadAadhar(resourceId, _aadharPhoto!);
      }
      if (_panPhoto != null) {
        await _sakhiApi.uploadPan(resourceId, _panPhoto!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sakhi Created (ID: $resourceId) & documents uploaded!', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );

      setState(() {
        _tabController.animateTo(0);
        _resetFormTokens();
      });
      await _fetchSakhis();
    } catch (e) {
      if (!mounted) return;
      final message = _extractErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFormTokens() {
    _formKey.currentState!.reset();
    _sakhiMobileVerified = false;
    _sakhiNameController.clear();
    _dobController.clear();
    _mobileController.clear();
    _aadharNoController.clear();
    _panNoController.clear();
    _spouseNameController.clear();
    _addressController.clear();
    _monthlyIncomeController.clear();
    _spouseMobileController.clear();
    _sakhiPhoto = null;
    _aadharPhoto = null;
    _panPhoto = null;
    _aadharLinkSent = false;
    _aadharFetched = false;
    _aadharReferenceId = null;
    _aadharTransactionId = null;
    _aadharPollTimer?.cancel();
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
          _buildSakhiList(),
          _buildEnrollmentForm(),
        ],
      ),
    );
  }

  Widget _buildSakhiList() {
    if (_isLoadingSakhis) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_sakhis.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No Sakhis Enrolled yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add),
              label: const Text('Enroll Your First Sakhi'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSakhis,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sakhis.length,
        itemBuilder: (context, index) {
          final sakhi = _sakhis[index];
          final bool isPending = sakhi['status'] == 'Pending' || sakhi['status'] == 'Pending Sync';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    sakhi['name']![0].toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sakhi['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(sakhi['code'] ?? '-', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(sakhi['mobile']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sakhi['status']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPending ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnrollmentForm() {
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAadharVerificationSection(),
                    _buildHeader('Basic Information'),
                    
                    // Sakhi Photo Upload
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog((file) => setState(() => _sakhiPhoto = file)),
                        child: Stack(
                          children: [
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                                image: _sakhiPhoto != null ? DecorationImage(image: FileImage(_sakhiPhoto!), fit: BoxFit.cover) : null,
                              ),
                              child: _sakhiPhoto == null 
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

                    _buildTextField(label: 'Sakhi Name', controller: _sakhiNameController, icon: Icons.person),
                    
                    // Office (from logged-in user)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        enabled: false,
                        controller: TextEditingController(text: _selectedOfficeName ?? 'Loading office…'),
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
                    _buildDropdownField(
                      label: 'Gram Panchayat',
                      icon: Icons.location_city,
                      value: _selectedGramPanchayatId,
                      items: _gramPanchayats.map((gp) => DropdownMenuItem(
                        value: gp['id'] as int,
                        child: Text(gp['name']?.toString() ?? 'N/A'),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedGramPanchayatId = val),
                    ),

                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(label: 'Date of Birth (dd-MM-yyyy)', controller: _dobController, icon: Icons.calendar_month),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    _buildHeader('Contact Details'),
                    _buildMobileVerifyField(
                      label: 'Mobile Number',
                      controller: _mobileController,
                      verified: _sakhiMobileVerified,
                      sending: _isSendingSakhiOtp,
                      onVerify: _verifyMobile,
                    ),
                    _buildTextField(label: 'Address', controller: _addressController, icon: Icons.location_on),
                    
                    const SizedBox(height: 12),
                    _buildHeader('Identification Documents'),
                    
                    // Aadhar Card Image
                    _buildImageUploader(
                      title: 'Upload Aadhar Card Image',
                      file: _aadharPhoto,
                      onPick: () => _showImageSourceDialog((f) => setState(() => _aadharPhoto = f))
                    ),
                    const SizedBox(height: 16),

                    // PAN Card Section
                    _buildTextField(
                      label: 'PAN Number',
                      controller: _panNoController,
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
                    _buildImageUploader(
                      title: 'Upload PAN Card Image', 
                      file: _panPhoto, 
                      onPick: () => _showImageSourceDialog((f) => setState(() => _panPhoto = f))
                    ),
                    const SizedBox(height: 24),
                    _buildHeader('Family & Occupation'),
                    _buildTextField(label: 'Spouse Name', controller: _spouseNameController, icon: Icons.family_restroom),
                    _buildTextField(label: 'Spouse Mobile', controller: _spouseMobileController, icon: Icons.phone_android, isNumber: true, maxLength: 10),
                    
                    // Occupation Dropdown
                    _buildDropdownField(
                      label: 'Sakhi Occupation',
                      icon: Icons.work,
                      value: _occupationId,
                      items: _professions.map((p) => DropdownMenuItem(
                        value: p['id'] as int,
                        child: Text(p['name']?.toString() ?? 'N/A'),
                      )).toList(),
                      onChanged: (val) => setState(() => _occupationId = val),
                    ),

                    // Spouse Occupation Dropdown
                    _buildDropdownField(
                      label: 'Spouse Occupation',
                      icon: Icons.work_outline,
                      value: _spouseOccupationId,
                      items: _professions.map((p) => DropdownMenuItem(
                        value: p['id'] as int,
                        child: Text(p['name']?.toString() ?? 'N/A'),
                      )).toList(),
                      onChanged: (val) => setState(() => _spouseOccupationId = val),
                    ),

                    _buildTextField(label: 'Monthly Income (₹)', controller: _monthlyIncomeController, icon: Icons.currency_rupee, isNumber: true),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('CREATE SAKHI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
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

  Widget _buildAadharVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Aadhaar Verification'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _aadharNoController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                onChanged: (_) {
                  if (_aadharLinkSent || _aadharFetched) {
                    setState(() {
                      _aadharLinkSent = false;
                      _aadharFetched = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  counterText: '',
                  prefixIcon: Icon(Icons.badge, color: Colors.grey[500], size: 20),
                  suffixIcon: _aadharFetched
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
                onPressed: _isAadharVerifying ? null : _verifyAadhar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _aadharLinkSent ? Colors.green : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: _isAadharVerifying
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_aadharLinkSent ? 'Re-send' : 'Verify', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (_aadharLinkSent && !_aadharFetched) ...[
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
                  child: _isFetchingAadhar || _aadharPollTimer?.isActive == true
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
                  onPressed: _isFetchingAadhar ? null : () => _fetchAadharDetails(silent: false),
                  child: const Text('Fetch Now'),
                ),
              ],
            ),
          ),
        ],
        if (_aadharFetched) ...[
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
  }

  Widget _buildHeader(String title) {
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
  
  Widget _buildImageUploader({required String title, required File? file, required VoidCallback onPick}) {
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
                file != null ? 'Image Attached (${(file.lengthSync() / 1024).toStringAsFixed(0)} KB)' : title,
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
                child: Image.file(file, width: 40, height: 40, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
    bool uppercase = false,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
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
          counterText: "",
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required dynamic value,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<int>(
        value: value,
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
