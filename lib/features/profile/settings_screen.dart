import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final country = ref.watch(catalogProvider).value?.country(s.countryId);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.xxxl),
        children: [
          const _Group('General'),
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('Default country'),
            subtitle: Text('${country?.flag ?? ''} ${country?.name ?? ''}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.countries),
          ),
          const _Group('Theme'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('System'),
                ),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => n.setThemeMode(v.first),
            ),
          ),
          const _Group('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.luggage_rounded),
            title: const Text('Trip reminders'),
            subtitle: const Text('Show upcoming trips (within 14 days) in the notification centre'),
            value: s.tripReminders,
            onChanged: n.setTripReminders,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_rounded),
            title: const Text('Best-season tips'),
            subtitle: const Text('Tell me when a bucket-list destination is in its best season'),
            value: s.seasonTips,
            onChanged: n.setSeasonTips,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SampleDataNote(
              text:
                  'Notifications are generated on-device and shown inside the app. '
                  'Push notifications need a backend messaging service and are not set up yet.',
            ),
          ),
          const _Group('Privacy'),
          SwitchListTile(
            secondary: const Icon(Icons.bar_chart_rounded),
            title: const Text('Show statistics on profile'),
            value: s.showStatsOnProfile,
            onChanged: n.setShowStats,
          ),
          const ListTile(
            leading: Icon(Icons.lock_rounded),
            title: Text('Your data stays on this device'),
            subtitle: Text(
              'Visits, notes, photos and added places are stored locally. Nothing is uploaded — '
              'there is no account or cloud sync in this version.',
            ),
          ),
          const _Group('Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            title: const Text('Clear local data', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('Deletes visits, memories, photos, bucket list, trips and added places'),
            onTap: () async {
              final ok = await confirmAction(
                context,
                title: 'Clear all travel data?',
                message: 'This permanently deletes everything you have saved on this device. This cannot be undone.',
                confirmLabel: 'Delete everything',
                destructive: true,
              );
              if (!ok) return;
              await clearUserData(ref);
              if (context.mounted) showSnack(context, 'All local travel data cleared');
            },
          ),
          const _Group('About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Travel Explorer'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Travel Explorer',
              applicationVersion: '1.0.0',
              applicationIcon: Icon(Icons.explore_rounded, color: context.colors.primary, size: 40),
              children: const [
                Text(
                  'Discover, explore and track your adventures.\n\n'
                  'Destination content is a curated sample guide for demonstration. Opening hours, fees and '
                  'prices are not verified — always check locally. Seasonal information is general guidance, not a '
                  'weather forecast.\n\n'
                  'Map data © OpenStreetMap contributors. Fonts: Plus Jakarta Sans and Fraunces (SIL Open Font License).',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
    child: Text(text.toUpperCase(), style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
  );
}
