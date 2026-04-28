import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gram_panchayat_api.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';

class GramPanchayatScreen extends StatefulWidget {
  const GramPanchayatScreen({super.key});

  @override
  State<GramPanchayatScreen> createState() => _GramPanchayatScreenState();
}

class _GramPanchayatScreenState extends State<GramPanchayatScreen> {
  bool _showEnteredSurveys = true;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _noOfVillagesController = TextEditingController();
  final _populationController = TextEditingController();
  final _mainCropController = TextEditingController();

  String? _networkFacility;
  String? _bankFacility;
  bool _isActive = true;
  bool _isSubmitting = false;
  bool _isLoadingList = false;

  final List<String> _networkOptions = ['2G', '3G', '4G', '5G', 'No Network'];
  final List<String> _bankOptions = ['Yes', 'No', 'ATM Only', 'BC Agent'];

  List<dynamic> _entered = [];

  final GramPanchayatApi _api = GramPanchayatApi();

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _noOfVillagesController.dispose();
    _populationController.dispose();
    _mainCropController.dispose();
    super.dispose();
  }

  Future<void> _fetchList() async {
    final officeId = AuthSession.instance.officeId;
    setState(() => _isLoadingList = true);
    try {
      final items = await _api.fetchPanchayats(officeId: officeId);
      if (mounted) setState(() => _entered = items);
    } catch (e) {
      debugPrint('Error loading panchayats: $e');
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _codeController.clear();
    _noOfVillagesController.clear();
    _populationController.clear();
    _mainCropController.clear();
    setState(() {
      _networkFacility = null;
      _bankFacility = null;
      _isActive = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final officeId = AuthSession.instance.officeId;
    if (officeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No office linked to this user')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'officeId': officeId,
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'isActive': _isActive,
      'noOfVillages': _noOfVillagesController.text.trim(),
      'totalPopulation': _populationController.text.trim(),
      'networkFacility': _networkFacility,
      'bankFacility': _bankFacility,
      'mainCrop': _mainCropController.text.trim(),
    };

    setState(() => _isSubmitting = true);
    try {
      await _api.create(payload);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Gram Panchayat saved'),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _resetForm();
      setState(() => _showEnteredSurveys = true);
      await _fetchList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showEnteredSurveys = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showEnteredSurveys ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _showEnteredSurveys ? [
                          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Already Entered',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _showEnteredSurveys ? AppTheme.primaryColor : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _resetForm();
                      setState(() => _showEnteredSurveys = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showEnteredSurveys ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_showEnteredSurveys ? [
                          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'New Survey',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_showEnteredSurveys ? AppTheme.primaryColor : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showEnteredSurveys ? _buildEnteredList() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnteredList() {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (_entered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No Gram Panchayats entered yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _resetForm();
                setState(() => _showEnteredSurveys = false);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add First Panchayat'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchList,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _entered.length,
        itemBuilder: (context, index) {
          final item = _entered[index] as Map;
          final isActive = item['active'] == true || item['isActive'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha:0.1),
                  child: const Icon(Icons.maps_home_work_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item['officeName']?.toString() ?? '-',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('ID: ${item['id'] ?? '-'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.green[800] : Colors.grey[700],
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Basic Information',
            icon: Icons.info_outline_rounded,
            color: AppTheme.primaryColor,
            children: [
              _buildFormField(
                label: 'Name *',
                hint: 'e.g. Agadi',
                controller: _nameController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Code *',
                hint: 'e.g. AGD',
                controller: _codeController,
                uppercase: true,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Number of Villages *',
                hint: 'e.g. 12',
                controller: _noOfVillagesController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Total Population *',
                hint: 'e.g. 25000',
                controller: _populationController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                value: _isActive,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Connectivity & Economy',
            icon: Icons.location_on_rounded,
            color: AppTheme.accentColor,
            children: [
              _buildDropdown(
                label: 'Network Facility *',
                hint: 'Select network type',
                items: _networkOptions,
                value: _networkFacility,
                onChanged: (v) => setState(() => _networkFacility = v),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Bank Facility *',
                hint: 'Select bank facility',
                items: _bankOptions,
                value: _bankFacility,
                onChanged: (v) => setState(() => _bankFacility = v),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Main Crop *',
                hint: 'e.g. Paddy',
                controller: _mainCropController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Save Panchayat'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enter Gram Panchayat details. Fields marked * are required.',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
    int maxLines = 1,
    bool uppercase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
          inputFormatters: uppercase
              ? [TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase()))]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select an option' : null,
        ),
      ],
    );
  }
}
