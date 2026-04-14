import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'gram_panchayat_screen.dart';
import 'village_screen.dart';

class SurveyHubScreen extends StatefulWidget {
  const SurveyHubScreen({super.key});

  @override
  State<SurveyHubScreen> createState() => _SurveyHubScreenState();
}

class _SurveyHubScreenState extends State<SurveyHubScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: const Text('Survey Management'),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          centerTitle: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Inter', fontSize: 14),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Gram Panchayat'),
              Tab(text: 'Village Level'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // First tab Content
            GramPanchayatScreen(),
            // Second tab Content
            VillageScreen(),
          ],
        ),
      ),
    );
  }
}
