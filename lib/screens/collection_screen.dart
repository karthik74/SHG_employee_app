import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedGroup;
  String _collectionType = 'Both'; // Default to Both

  final List<String> _groups = [
    'Lakshmi SHG',
    'Saraswati SHG',
    'Durga Mahila SHG',
    'Shakti SHG',
    'Prerna SHG',
  ];

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Sunita Devi',
      'id': 'MBR001',
      'savingsDue': 500.0,
      'emiDue': 1200.0,
      'paid': false,
      'controller': TextEditingController(),
    },
    {
      'name': 'Geeta Kumari',
      'id': 'MBR002',
      'savingsDue': 500.0,
      'emiDue': 1500.0,
      'paid': true,
      'controller': TextEditingController(text: '2000'),
    },
    {
      'name': 'Meena Sharma',
      'id': 'MBR003',
      'savingsDue': 500.0,
      'emiDue': 1000.0,
      'paid': false,
      'controller': TextEditingController(),
    },
    {
      'name': 'Radha Yadav',
      'id': 'MBR004',
      'savingsDue': 500.0,
      'emiDue': 1800.0,
      'paid': false,
      'controller': TextEditingController(),
    },
    {
      'name': 'Anita Singh',
      'id': 'MBR005',
      'savingsDue': 500.0,
      'emiDue': 2000.0,
      'paid': true,
      'controller': TextEditingController(text: '2500'),
    },
  ];

  final _groupAmountController = TextEditingController();
  double _totalCollected = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _computeTotal();
  }

  void _computeTotal() {
    double total = 0;
    for (final m in _members) {
      final val = double.tryParse(
              (m['controller'] as TextEditingController).text) ??
          0;
      total += val;
    }
    setState(() => _totalCollected = total);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupAmountController.dispose();
    for (final m in _members) {
      (m['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Collection'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Customer Wise'),
            Tab(text: 'Group Wise'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildGroupSelector(),
          _buildTypeSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerWise(),
                _buildGroupWise(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded,
              size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGroup,
                hint: const Text('Select Group',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
                isExpanded: true,
                items: _groups
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGroup = v),
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: ['Savings', 'Loan EMI', 'Both'].map((type) {
          final isSelected = _collectionType == type;
          return GestureDetector(
            onTap: () {
              setState(() => _collectionType = type);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerWise() {
    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.secondaryColor, Color(0xFF00A87E)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Collected',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              Text(
                '₹${_totalCollected.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return _buildMemberRow(member, index);
            },
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member, int index) {
    final isPaid = member['paid'] as bool;

    // Calculate expected due based on dynamic collection type toggle
    double expectedDue = 0;
    if (_collectionType == 'Savings') expectedDue = member['savingsDue'];
    else if (_collectionType == 'Loan EMI') expectedDue = member['emiDue'];
    else expectedDue = member['savingsDue'] + member['emiDue'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPaid
            ? Border.all(color: AppTheme.secondaryColor.withValues(alpha:0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isPaid
                    ? AppTheme.secondaryColor.withValues(alpha:0.1)
                    : AppTheme.primaryColor.withValues(alpha:0.1),
                child: Text(
                  member['name'].toString()[0],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isPaid
                        ? AppTheme.secondaryColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      member['id'],
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 12, color: AppTheme.secondaryColor),
                      SizedBox(width: 4),
                      Text('Paid',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dueChip('Savings Due',
                    '₹${member['savingsDue'].toStringAsFixed(0)}', _collectionType == 'Savings' || _collectionType == 'Both'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dueChip(
                    'EMI Due', '₹${member['emiDue'].toStringAsFixed(0)}', _collectionType == 'Loan EMI' || _collectionType == 'Both'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Collected:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: member['controller'] as TextEditingController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _computeTotal(),
                    enabled: !isPaid,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1.5),
                      ),
                      filled: true,
                      fillColor: isPaid
                          ? Colors.grey[100]
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isPaid) const SizedBox(width: 8),
              if (!isPaid)
                OutlinedButton(
                  onPressed: () {
                    (member['controller'] as TextEditingController).text = expectedDue.toStringAsFixed(0);
                    _computeTotal();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text('Full', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dueChip(String label, String value, bool isRelevant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRelevant ? AppTheme.primaryColor.withValues(alpha:0.05) : AppTheme.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isRelevant ? Border.all(color: AppTheme.primaryColor.withValues(alpha:0.2)) : Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: isRelevant ? AppTheme.primaryColor : AppTheme.textSecondary, fontWeight: isRelevant ? FontWeight.w600 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isRelevant ? AppTheme.primaryColor : AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildGroupWise() {
    double totalSavings = _members.fold(0, (sum, m) => sum + m['savingsDue']);
    double totalEmi = _members.fold(0, (sum, m) => sum + m['emiDue']);

    double totalExpectedDue = 0;
    if (_collectionType == 'Savings') totalExpectedDue = totalSavings;
    else if (_collectionType == 'Loan EMI') totalExpectedDue = totalEmi;
    else totalExpectedDue = totalSavings + totalEmi;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Group Collection',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Enter the total amount collected from the group',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              _buildGroupInfoRow('Group', _selectedGroup ?? 'Not selected'),
              _buildGroupInfoRow('Members', '${_members.length}'),
              _buildGroupInfoRow('Total Savings Due', '₹${totalSavings.toStringAsFixed(0)}'),
              _buildGroupInfoRow('Total EMI Due', '₹${totalEmi.toStringAsFixed(0)}'),
              const Divider(),
              _buildGroupInfoRow('Expected $_collectionType', '₹${totalExpectedDue.toStringAsFixed(0)}', isBold: true),
              const SizedBox(height: 16),
              const Text('Amount Collected',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _groupAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[300]),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                         _groupAmountController.text = totalExpectedDue.toStringAsFixed(0);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Full Amount'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Group collection saved!'),
                            backgroundColor: AppTheme.secondaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isBold ? AppTheme.primaryColor : AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Collected',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text(
                  '₹${_totalCollected.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      const Text('Collection submitted successfully!'),
                  backgroundColor: AppTheme.secondaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
