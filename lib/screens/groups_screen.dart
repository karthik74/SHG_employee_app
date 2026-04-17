import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/groups_api.dart';
import '../services/auth_session.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupsApi _groupsApi = GroupsApi();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _groups = [];

  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _groupsApi.fetchGroups(
        officeId: AuthSession.instance.officeId,
      );
      if (!mounted) return;
      setState(() {
        _groups = items.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load groups: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredGroups {
    return _groups.where((g) {
      final name = g['name']?.toString() ?? '';
      final accountNo = g['accountNo']?.toString() ?? '';
      final office = g['officeName']?.toString() ?? '';
      final statusValue = (g['status'] is Map)
          ? g['status']['value']?.toString() ?? ''
          : '';

      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          name.toLowerCase().contains(q) ||
          accountNo.toLowerCase().contains(q) ||
          office.toLowerCase().contains(q);

      final matchesFilter = _filterStatus == 'All' ||
          statusValue.toLowerCase() == _filterStatus.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _activeCount =>
      _groups.where((g) => g['active'] == true).length;

  String _formatDate(dynamic v) {
    if (v is List && v.length >= 3) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final m = (v[1] is int && v[1] >= 1 && v[1] <= 12) ? months[v[1] - 1] : v[1].toString();
      return '${v[2]} $m ${v[0]}';
    }
    return v?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchGroups,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildSummaryBar(),
                    _buildSearchAndFilter(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchGroups,
                        color: AppTheme.primaryColor,
                        child: _filteredGroups.isEmpty
                            ? ListView(children: [_buildEmptyState()])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: _filteredGroups.length,
                                itemBuilder: (context, index) {
                                  return _buildGroupCard(_filteredGroups[index]);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchGroups, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final office = AuthSession.instance.officeName ?? '—';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E6FFF), Color(0xFF0040CC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Office',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(office,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('${_groups.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const Text('Groups', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$_activeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by name, account, or office...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['All', 'Active', 'Pending', 'Closed'].map((filter) {
              final isSelected = _filterStatus == filter;
              return GestureDetector(
                onTap: () => setState(() => _filterStatus = filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final isActive = group['active'] == true;
    final name = group['name']?.toString() ?? 'Unnamed';
    final accountNo = group['accountNo']?.toString() ?? '—';
    final officeName = group['officeName']?.toString() ?? '—';
    final staffName = group['staffName']?.toString();
    final statusValue = (group['status'] is Map)
        ? group['status']['value']?.toString() ?? '—'
        : '—';
    final activationDate = _formatDate(group['activationDate']);

    return GestureDetector(
      onTap: () => _showGroupDetail(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: isActive ? AppTheme.primaryColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text('A/C: $accountNo',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          staffName != null && staffName.isNotEmpty
                              ? '$officeName • $staffName'
                              : officeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.secondaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusValue,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.secondaryColor : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(activationDate,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No groups found',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showGroupDetail(Map<String, dynamic> group) {
    final groupId = group['id'] is int
        ? group['id'] as int
        : int.tryParse(group['id']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: groupId != null
                    ? Future.wait([
                        _groupsApi.fetchGroupDetails(groupId),
                        _groupsApi.fetchGroupAccounts(groupId),
                      ])
                    : Future.value(<Map<String, dynamic>>[{}, {}]),
                builder: (ctx, snapshot) {
                  final loading = snapshot.connectionState == ConnectionState.waiting;
                  final details = (snapshot.data != null && snapshot.data!.isNotEmpty)
                      ? snapshot.data![0]
                      : <String, dynamic>{};
                  final accounts = (snapshot.data != null && snapshot.data!.length > 1)
                      ? snapshot.data![1]
                      : <String, dynamic>{};

                  final members = (details['clientMembers'] as List?) ?? const [];
                  final glim = (accounts['groupLoanIndividualMonitoringAccounts'] as List?) ?? const [];
                  final memberLoans = (accounts['memberLoanAccounts'] as List?) ?? const [];
                  final memberSavings = (accounts['memberSavingsAccounts'] as List?) ?? const [];

                  final summary = _computeSummary(members, memberLoans, glim);

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group['name']?.toString() ?? '—',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary)),
                            Text('A/C: ${group['accountNo']?.toString() ?? '—'} • ${group['officeName']?.toString() ?? '—'}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                        )
                      else if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('Failed to load: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 12)),
                        )
                      else ...[
                        _buildSummaryCards(summary),
                        const SizedBox(height: 24),
                        _overviewSectionHeader(Icons.groups_2_rounded, 'Client Members'),
                        _buildClientMembersTable(members),
                        const SizedBox(height: 24),
                        _overviewSectionHeader(Icons.grid_view_rounded, 'GSIM Account Overview'),
                        _buildGsimTable(memberSavings),
                        const SizedBox(height: 24),
                        _overviewSectionHeader(Icons.account_balance_wallet_rounded, 'GLIM Loans Account Overview'),
                        _buildGlimTable(glim),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
      },
    );
  }
  bool _isLoanClosed(dynamic a) {
    if (a is! Map) return false;
    final status = a['status'];
    if (status is Map) {
      if (status['closed'] == true) return true;
      if (status['closedObligationsMet'] == true) return true;
      if (status['closedWrittenOff'] == true) return true;
      if (status['closedRescheduled'] == true) return true;
    }
    return false;
  }

  Map<String, int> _computeSummary(
      List<dynamic> members, List<dynamic> memberLoans, List<dynamic> groupLoans) {
    int activeClients = 0;
    for (final m in members) {
      if (m is Map && (m['active'] == true || (m['status'] is Map && m['status']['active'] == true))) {
        activeClients++;
      }
    }
    int activeClientLoans = 0;
    int overdueClientLoans = 0;
    final borrowers = <dynamic>{};
    for (final l in memberLoans) {
      if (l is! Map) continue;
      final active = l['status'] is Map && l['status']['active'] == true;
      if (active) {
        activeClientLoans++;
        if (l['clientId'] != null) borrowers.add(l['clientId']);
      }
      if (l['inArrears'] == true) overdueClientLoans++;
    }
    int activeGroupLoans = 0;
    for (final l in groupLoans) {
      if (l is Map && l['status'] is Map && l['status']['active'] == true) {
        activeGroupLoans++;
      }
    }
    return {
      'activeClients': activeClients,
      'activeClientLoans': activeClientLoans,
      'activeClientBorrowers': borrowers.isEmpty ? activeClientLoans : borrowers.length,
      'overdueClientLoans': overdueClientLoans,
      'activeGroupLoans': activeGroupLoans,
    };
  }

  Widget _buildSummaryCards(Map<String, int> summary) {
    final cards = [
      {'icon': Icons.people_rounded, 'label': 'Active Clients', 'value': summary['activeClients'], 'color': const Color(0xFF8B5CF6)},
      {'icon': Icons.credit_card_rounded, 'label': 'Active Client Loans', 'value': summary['activeClientLoans'], 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.account_circle_rounded, 'label': 'Active Client Borrowers', 'value': summary['activeClientBorrowers'], 'color': const Color(0xFF10B981)},
      {'icon': Icons.warning_amber_rounded, 'label': 'Overdue Client Loans', 'value': summary['overdueClientLoans'], 'color': const Color(0xFFEF4444)},
      {'icon': Icons.account_balance_rounded, 'label': 'Active Group Loans', 'value': summary['activeGroupLoans'], 'color': const Color(0xFF06B6D4)},
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final c = cards[i];
          final color = c['color'] as Color;
          return Container(
            width: 170,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(c['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${c['value']}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text(c['label'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loanSectionHeader(
    String title, {
    IconData icon = Icons.credit_card_rounded,
    required int closedCount,
    required bool showingClosed,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
          ),
          if (closedCount > 0)
            ElevatedButton(
              onPressed: onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              child: Text(showingClosed ? 'View Active Accounts' : 'View Closed Accounts'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanAccountsTable(List<dynamic> loans, {required bool showingClosed}) {
    if (loans.isEmpty) {
      return _emptyTableNote(showingClosed ? 'No closed loan accounts.' : 'No active loan accounts.');
    }
    final flex = showingClosed
        ? [3, 3, 3, 3, 3, 2, 3]
        : [3, 3, 3, 3, 3, 2, 3];
    final headers = showingClosed
        ? const ['Account No.', 'Loan Account', 'Original Loan', 'Loan Balance', 'Amount Paid', 'Type', 'Closed Date']
        : const ['Account No.', 'Loan Account', 'Original Loan', 'Loan Balance', 'Amount Paid', 'Type', 'Actions'];

    return _overviewTableCard(
      children: [
        _tableHeaderRow(headers, flex),
        ...List.generate(loans.length, (i) {
          final a = loans[i] as Map<String, dynamic>;
          final statusMap = a['status'] is Map ? a['status'] as Map : const {};
          final active = statusMap['active'] == true;
          final inArrears = a['inArrears'] == true;
          final loanType = (a['loanType'] is Map) ? a['loanType']['value']?.toString() ?? '—' : '—';
          final closedDate = (a['timeline'] is Map) ? _formatDate(a['timeline']['closedOnDate']) : '—';
          return _tableBodyRow(
            [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: inArrears
                          ? const Color(0xFFEF4444)
                          : (active ? const Color(0xFF10B981) : Colors.grey),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a['accountNo']?.toString() ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ),
                ],
              ),
              Text(a['productName']?.toString() ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              Text(_num(a['originalLoan']).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              Text(_num(a['loanBalance']).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              Text(_num(a['amountPaid']).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
              Icon(
                loanType == 'Individual' ? Icons.person_rounded : Icons.group_rounded,
                size: 18,
                color: Colors.grey[600],
              ),
              showingClosed
                  ? Text(closedDate,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))
                  : _loanActionIcons(statusMap),
            ],
            flex,
            alt: i.isOdd,
          );
        }),
      ],
    );
  }

  Widget _loanActionIcons(Map statusMap) {
    final icons = <IconData>[];
    if (statusMap['active'] == true) icons.add(Icons.attach_money_rounded);
    if (statusMap['pendingApproval'] == true) icons.add(Icons.check_rounded);
    if (statusMap['waitingForDisbursal'] == true) icons.add(Icons.flag_rounded);
    if (statusMap['overpaid'] == true) icons.add(Icons.swap_horiz_rounded);
    if (icons.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary));
    }
    return Row(
      children: icons
          .map((i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(i, size: 18, color: AppTheme.primaryColor),
              ))
          .toList(),
    );
  }

  Widget _buildSavingsAccountsTable(List<dynamic> savings, {required bool showingClosed}) {
    if (savings.isEmpty) {
      return _emptyTableNote(showingClosed ? 'No closed savings accounts.' : 'No active savings accounts.');
    }
    final flex = showingClosed ? [3, 4, 4] : [3, 4, 3, 3, 3];
    final headers = showingClosed
        ? const ['Account No.', 'Saving Account', 'Closed Date']
        : const ['Account No.', 'Saving Account', 'Last Active', 'Balance', 'Actions'];

    return _overviewTableCard(
      children: [
        _tableHeaderRow(headers, flex),
        ...List.generate(savings.length, (i) {
          final a = savings[i] as Map<String, dynamic>;
          final statusMap = a['status'] is Map ? a['status'] as Map : const {};
          final active = statusMap['active'] == true;
          final lastActive = _formatDate(a['lastActiveTransactionDate']);
          final closedDate = (a['timeline'] is Map) ? _formatDate(a['timeline']['closedOnDate']) : '—';
          final accountCell = Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF10B981) : Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(a['accountNo']?.toString() ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
            ],
          );
          final productCell = Text(a['productName']?.toString() ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary));

          return _tableBodyRow(
            showingClosed
                ? [
                    accountCell,
                    productCell,
                    Text(closedDate, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                  ]
                : [
                    accountCell,
                    productCell,
                    Text(lastActive, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                    Text(_num(a['accountBalance']).toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    _savingsActionIcons(statusMap),
                  ],
            flex,
            alt: i.isOdd,
          );
        }),
      ],
    );
  }

  Widget _savingsActionIcons(Map statusMap) {
    final icons = <IconData>[];
    if (statusMap['active'] == true) {
      icons.addAll([Icons.arrow_upward_rounded, Icons.arrow_downward_rounded]);
    }
    if (statusMap['submittedAndPendingApproval'] == true) {
      icons.add(Icons.check_rounded);
    }
    if (icons.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary));
    }
    return Row(
      children: icons
          .map((i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(i, size: 18, color: AppTheme.primaryColor),
              ))
          .toList(),
    );
  }

  Widget _overviewSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _overviewTableCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _tableHeaderRow(List<String> labels, List<int> flex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(
                labels[i].toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableBodyRow(List<Widget> cells, List<int> flex, {bool alt = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: alt ? Colors.grey[50] : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(flex: flex[i], child: cells[i]),
        ],
      ),
    );
  }

  Widget _statusPill(String value, {bool active = true}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD1FAE5) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF047857) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildClientMembersTable(List<dynamic> members) {
    if (members.isEmpty) {
      return _emptyTableNote('No client members.');
    }
    final flex = [4, 3, 2, 2];
    return _overviewTableCard(
      children: [
        _tableHeaderRow(const ['Name', 'Account No.', 'Branch', 'JLG Loan Application'], flex),
        ...List.generate(members.length, (i) {
          final m = members[i] as Map<String, dynamic>;
          final name = m['displayName']?.toString()
              ?? '${m['firstname'] ?? ''} ${m['lastname'] ?? ''}'.trim();
          final accountNo = m['accountNo']?.toString() ?? '—';
          final branch = m['officeName']?.toString() ?? '—';
          final isActive = m['active'] == true || (m['status'] is Map && m['status']['active'] == true);
          return _tableBodyRow(
            [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF10B981) : Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name.isEmpty ? '—' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                ],
              ),
              Text(accountNo,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              Text(branch,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('JLG loan application for $name')),
                  );
                },
                child: const Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
              ),
            ],
            flex,
            alt: i.isOdd,
          );
        }),
      ],
    );
  }

  Widget _buildGsimTable(List<dynamic> savings) {
    if (savings.isEmpty) {
      return _emptyTableNote('No GSIM savings accounts.');
    }
    final flex = [2, 3, 4, 2, 2];
    return _overviewTableCard(
      children: [
        _tableHeaderRow(const ['GSIM ID', 'Account Number', 'Product', 'Balance', 'Status'], flex),
        ...List.generate(savings.length, (i) {
          final a = savings[i] as Map<String, dynamic>;
          final statusMap = a['status'] is Map ? a['status'] as Map : const {};
          final statusValue = statusMap['value']?.toString() ?? '—';
          final active = statusMap['active'] == true;
          return _tableBodyRow(
            [
              Text(a['id']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
              Text(a['accountNo']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              Text(a['productName']?.toString() ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              Text(_formatAmount(_num(a['accountBalance'])),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              _statusPill(statusValue, active: active),
            ],
            flex,
            alt: i.isOdd,
          );
        }),
      ],
    );
  }

  Widget _buildGlimTable(List<dynamic> loans) {
    if (loans.isEmpty) {
      return _emptyTableNote('No GLIM loan accounts.');
    }
    final flex = [2, 3, 4, 3, 2];
    return _overviewTableCard(
      children: [
        _tableHeaderRow(const ['GLIM ID', 'Account Number', 'Product', 'Original Loan', 'Status'], flex),
        ...List.generate(loans.length, (i) {
          final a = loans[i] as Map<String, dynamic>;
          final statusMap = a['status'] is Map ? a['status'] as Map : const {};
          final statusValue = statusMap['value']?.toString() ?? '—';
          final active = statusMap['active'] == true;
          return _tableBodyRow(
            [
              Text(a['id']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
              Text(a['accountNo']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              Text(a['productName']?.toString() ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              Text(_num(a['originalLoan']).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              _statusPill(statusValue, active: active),
            ],
            flex,
            alt: i.isOdd,
          );
        }),
      ],
    );
  }

  Widget _emptyTableNote(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(message,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

}
