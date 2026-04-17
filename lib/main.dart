import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/env_config.dart';
import 'screens/dashboard_screen.dart';
import 'screens/survey_hub_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/sakhi_creation_screen.dart';
import 'services/auth_session.dart';

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (EnvConfig.isDevMode) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await AuthSession.instance.init();

  runApp(const EmployeeApp());
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavaJyothi Employee App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthSession.instance.isLoggedIn
          ? const MainNavigation()
          : const LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SakhiCreationScreen(),
    SurveyHubScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.person_add_alt_1_outlined,
      activeIcon: Icons.person_add_alt_1_rounded,
      label: 'Sakhi',
    ),
    NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Survey',
    ),
    NavigationItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Groups',
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onItemTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onItemTap,
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavBarItem(
                      item: items[i],
                      selected: currentIndex == i,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedColor = AppTheme.primaryColor;
    final unselectedColor = Colors.grey.shade500;
    final color = selected ? selectedColor : unselectedColor;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        splashColor: selectedColor.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 44 : 32,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? selectedColor.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: _NavIcon(
                  icon: selected ? item.activeIcon : item.icon,
                  badge: item.badge,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.badge, required this.color});

  final IconData icon;
  final int badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: color, size: 22);
    if (badge <= 0) return iconWidget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              badge > 99 ? '99+' : '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

