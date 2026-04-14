import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GramPanchayatScreen extends StatefulWidget {
  const GramPanchayatScreen({super.key});

  @override
  State<GramPanchayatScreen> createState() => _GramPanchayatScreenState();
}

class _GramPanchayatScreenState extends State<GramPanchayatScreen> {
  bool _showEnteredSurveys = true;
  final _formKey = GlobalKey<FormState>();
  
  final _numberOfVillagesController = TextEditingController();
  final _villageNamesController = TextEditingController();
  final _populationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _literacyRatioController = TextEditingController();
  final _mainCropController = TextEditingController();

  String? _networkFacility;
  String? _bankFacility;

  final List<String> _networkOptions = ['2G', '3G', '4G', '5G', 'No Network'];
  final List<String> _bankOptions = ['Bank Branch', 'ATM Only', 'BC Agent', 'Post Office', 'No Facility'];

  final List<Map<String, String>> _enteredSurveys = [
    {
      'id': 'GP-001',
      'villages': 'Rampur, Laxmipur',
      'population': '12500',
      'date': '10 Apr 2026',
      'status': 'Approved'
    },
    {
      'id': 'GP-002',
      'villages': 'Bhavanipur, Kamalpur, Sitapur',
      'population': '24100',
      'date': '12 Apr 2026',
      'status': 'Pending Sync'
    }
  ];

  @override
  void dispose() {
    _numberOfVillagesController.dispose();
    _villageNamesController.dispose();
    _populationController.dispose();
    _distanceController.dispose();
    _literacyRatioController.dispose();
    _mainCropController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
         _enteredSurveys.insert(0, {
            'id': 'GP-00${_enteredSurveys.length + 1}',
            'villages': _villageNamesController.text.trim(),
            'population': _populationController.text.trim(),
            'date': 'Today',
            'status': 'Pending Sync'
         });
         _showEnteredSurveys = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Gram Panchayat survey saved!'),
            ],
          ),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
      _formKey.currentState!.reset();
      _numberOfVillagesController.clear();
      _villageNamesController.clear();
      _populationController.clear();
      _distanceController.clear();
      _literacyRatioController.clear();
      _mainCropController.clear();
      setState(() {
        _networkFacility = null;
        _bankFacility = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Custom Segmented Toggle Control
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
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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
                    onTap: () => setState(() => _showEnteredSurveys = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showEnteredSurveys ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_showEnteredSurveys ? [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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
    if (_enteredSurveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No surveys entered yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showEnteredSurveys = false),
              icon: const Icon(Icons.add),
              label: const Text('Start First Survey'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _enteredSurveys.length,
      itemBuilder: (context, index) {
        final survey = _enteredSurveys[index];
        final bool isPending = survey['status'] == 'Pending Sync';
        
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
                child: const Icon(Icons.maps_home_work_rounded, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Villages: ${survey['villages']}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.tag, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text('${survey['id']} • Expected Pop: ${survey['population']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Surveyed: ${survey['date']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                  survey['status']!,
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
                label: 'Number of Villages *',
                hint: 'e.g. 5',
                controller: _numberOfVillagesController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Village Names *',
                hint: 'Enter village names separated by comma',
                controller: _villageNamesController,
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Total Population *',
                hint: 'e.g. 12500',
                controller: _populationController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Location & Connectivity',
            icon: Icons.location_on_rounded,
            color: AppTheme.accentColor,
            children: [
              _buildFormField(
                label: 'Distance from Panchayat HQ (km) *',
                hint: 'e.g. 12',
                controller: _distanceController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                suffix: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('km', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Demographics & Agriculture',
            icon: Icons.people_outline_rounded,
            color: AppTheme.secondaryColor,
            children: [
              _buildFormField(
                label: 'Literacy Ratio (%) *',
                hint: 'e.g. 68',
                controller: _literacyRatioController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n < 0 || n > 100) return 'Enter a valid percentage (0–100)';
                  return null;
                },
                suffix: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('%', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Main Crop *',
                hint: 'e.g. Wheat, Rice, Sugarcane',
                controller: _mainCropController,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Survey'),
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
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fill in the Gram Panchayat survey form. All fields marked * are required.',
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
