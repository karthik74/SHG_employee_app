import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../sakhi_form_controller.dart';

/// "My Sakhis" tab content. Displays a loading spinner, an empty-state CTA,
/// or the list of Sakhis exposed by [SakhiFormController].
class SakhiListView extends StatelessWidget {
  const SakhiListView({
    super.key,
    required this.controller,
    required this.onEnrollTap,
  });

  final SakhiFormController controller;
  final VoidCallback onEnrollTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoadingSakhis) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        final sakhis = controller.sakhis;
        if (sakhis.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No Sakhis Enrolled yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onEnrollTap,
                  icon: const Icon(Icons.add),
                  label: const Text('Enroll Your First Sakhi'),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchSakhis,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sakhis.length,
            itemBuilder: (context, index) {
              final sakhi = sakhis[index];
              final bool isPending = sakhi['status'] == 'Pending' || sakhi['status'] == 'Pending Sync';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                        color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
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
      },
    );
  }
}
