import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

import '../models/shg_group.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isMapView = false;

  final List<SHGGroup> _todaysGroups = [
    SHGGroup(
      name: 'Lakshmi SHG',
      village: 'Rampur Village',
      membersCount: 15,
      totalSavings: 45000,
      totalLoan: 120000,
      collectionDue: 8500,
      status: CollectionStatus.pending,
      time: '10:00 AM',
    ),
    SHGGroup(
      name: 'Saraswati SHG',
      village: 'Krishnapur Village',
      membersCount: 12,
      totalSavings: 38000,
      totalLoan: 95000,
      collectionDue: 6200,
      status: CollectionStatus.collected,
      time: '11:30 AM',
    ),
    SHGGroup(
      name: 'Durga Mahila SHG',
      village: 'Sundarpur Village',
      membersCount: 18,
      totalSavings: 62000,
      totalLoan: 180000,
      collectionDue: 12400,
      status: CollectionStatus.pending,
      time: '02:00 PM',
    ),
    SHGGroup(
      name: 'Shakti SHG',
      village: 'Nandpur Village',
      membersCount: 10,
      totalSavings: 28000,
      totalLoan: 75000,
      collectionDue: 5000,
      status: CollectionStatus.partial,
      time: '03:30 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSummaryCards()),
          SliverToBoxAdapter(child: _buildTodayHeader()),
          _isMapView ? _buildMapView() : _buildListView(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning 👋',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Rajesh Kumar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Text(
                              'RK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.primaryColor, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Rampur Block, Uttar Pradesh',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12),
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
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total SHG Groups',
                  value: '24',
                  subtitle: '4 for today',
                  icon: Icons.groups_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Loans',
                  value: '₹4.7L',
                  subtitle: '18 active loans',
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
                  title: 'Today\'s Collection',
                  value: '₹32,100',
                  subtitle: '2 of 4 collected',
                  icon: Icons.payments_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Savings',
                  value: '₹1.73L',
                  subtitle: 'All groups',
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

  Widget _buildTodayHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Today\'s Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _viewToggleButton(
                  icon: Icons.list_rounded,
                  isActive: !_isMapView,
                  onTap: () => setState(() => _isMapView = false),
                ),
                _viewToggleButton(
                  icon: Icons.map_rounded,
                  isActive: _isMapView,
                  onTap: () => setState(() => _isMapView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _todaysGroups.length) return null;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SHGGroupCard(group: _todaysGroups[index]),
          );
        },
        childCount: _todaysGroups.length,
      ),
    );
  }

  Widget _buildMapView() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Map placeholder - replace with google_maps_flutter
              Container(
                color: const Color(0xFFE8F0FE),
                child: CustomPaint(
                  size: const Size(double.infinity, 400),
                  painter: _MapPlaceholderPainter(),
                ),
              ),
              // Map pins
              ..._buildMapPins(context),
              // Map attribution
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Replace with Google Maps',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMapPins(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final pins = [
      {'x': 0.3, 'y': 0.3, 'label': 'Lakshmi SHG', 'pending': true},
      {'x': 0.6, 'y': 0.4, 'label': 'Saraswati SHG', 'pending': false},
      {'x': 0.45, 'y': 0.6, 'label': 'Durga Mahila', 'pending': true},
      {'x': 0.7, 'y': 0.65, 'label': 'Shakti SHG', 'pending': false},
    ];

    return pins.map((pin) {
          return Positioned(
            left: (pin['x'] as double) * width - 16,
            top: (pin['y'] as double) * 400 - 16,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (pin['pending'] as bool)
                        ? AppTheme.accentColor
                        : AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.groups, color: Colors.white, size: 16),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    pin['label'] as String,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
    }).toList();
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Roads
    paint.color = Colors.white;
    paint.strokeWidth = 6;
    paint.style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(
        Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height * 0.25), Offset(size.width * 0.7, size.height * 0.75), paint);

    // Fields/blocks
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFD4E6B5).withOpacity(0.6);
    canvas.drawRect(
        Rect.fromLTWH(20, 20, size.width * 0.35, size.height * 0.35), paint);

    paint.color = const Color(0xFFC8E6C9).withOpacity(0.5);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.1,
            size.width * 0.4, size.height * 0.3),
        paint);

    paint.color = const Color(0xFFBBDEFB).withOpacity(0.5);
    canvas.drawRect(
        Rect.fromLTWH(20, size.height * 0.6, size.width * 0.4,
            size.height * 0.35),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
