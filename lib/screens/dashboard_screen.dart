import 'package:flutter/material.dart';
import '../services/dashboard_api.dart';
import '../services/staff_api.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApi _api = DashboardApi();
  final StaffApi _staffApi = StaffApi();

  bool _isLoading = false;
  String? _error;
  Map<String, num> _stats = {};
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    final staffId = AuthSession.instance.staffId;
    if (staffId == null) return;
    try {
      final staff = await _staffApi.fetchStaff(staffId);
      if (!mounted) return;
      final name = staff['displayName']?.toString();
      if (name != null && name.isNotEmpty) {
        setState(() => _displayName = name);
      }
    } catch (e) {
      debugPrint('Error loading staff: $e');
    }
  }

  Future<void> _fetchStats() async {
    final officeId = AuthSession.instance.officeId;
    if (officeId == null) {
      setState(() => _error = 'No office linked to this user');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchShgDashboard(officeId: officeId);
      if (!mounted) return;
      setState(() => _stats = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num value) {
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _fetchStats,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildSummary()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final displayName = _displayName ?? AuthSession.instance.username ?? 'User';
    final officeName = AuthSession.instance.officeName ?? 'Office';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E6FFF), Color(0xFF0040CC)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back 👋',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          officeName,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _fetchStats,
          icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final groupCount = (_stats['unique_group_count'] ?? 0).toInt();
    final loan = _stats['total_loan_principal'] ?? 0;
    final collected = _stats['total_collected'] ?? 0;
    final deposits = _stats['total_deposits'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total SHG Groups',
                  value: '$groupCount',
                  subtitle: 'Active groups',
                  icon: Icons.groups_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Loans',
                  value: _formatCurrency(loan),
                  subtitle: 'Disbursed principal',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Collected',
                  value: _formatCurrency(collected),
                  subtitle: 'Loan repayments',
                  icon: Icons.payments_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Deposits',
                  value: _formatCurrency(deposits),
                  subtitle: 'Savings',
                  icon: Icons.savings_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
