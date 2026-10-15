import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/insights.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: notices.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'You\'re all caught up',
              message: 'Trip reminders and best-season tips for your bucket list will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpace.gutter),
              itemCount: notices.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) {
                final n = notices[i];
                return FadeSlideIn(
                  index: i,
                  child: SurfaceCard(
                    onTap: n.route == null ? null : () => context.push(n.route!),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: context.colors.primaryContainer,
                          child: Icon(n.icon, color: context.colors.primary),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: context.text.titleSmall),
                              const SizedBox(height: 2),
                              Text(n.body, style: context.text.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
