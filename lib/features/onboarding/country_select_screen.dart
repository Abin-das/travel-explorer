import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/scene_art.dart';
import '../../domain/entities/geography.dart';

/// First-run country picker, also reused from Settings / Home to switch country.
class CountrySelectScreen extends ConsumerStatefulWidget {
  const CountrySelectScreen({super.key, required this.onboarding});
  final bool onboarding;

  @override
  ConsumerState<CountrySelectScreen> createState() => _CountrySelectScreenState();
}

class _CountrySelectScreenState extends ConsumerState<CountrySelectScreen> {
  final _search = TextEditingController();
  late String _selected = ref.read(settingsProvider).countryId ?? 'in';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    await ref.read(settingsProvider.notifier).selectCountry(_selected);
    if (!mounted) return;
    if (widget.onboarding) {
      context.go(Routes.explore);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      body: AsyncView(
        value: catalog,
        onRetry: () => ref.invalidate(catalogDataProvider),
        builder: (cat) {
          final q = _search.text.trim().toLowerCase();
          final list = cat.countries.where((c) => q.isEmpty || c.name.toLowerCase().contains(q)).toList()
            ..sort((a, b) {
              final da = cat.hasCuratedData(a.id) ? 0 : 1, db = cat.hasCuratedData(b.id) ? 0 : 1;
              return da != db ? da - db : a.name.compareTo(b.name);
            });
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(onboarding: widget.onboarding)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.sm),
                sliver: SliverToBoxAdapter(
                  child: AppSearchField(
                    controller: _search,
                    hint: 'Search countries',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.travel_explore_rounded,
                    title: 'No matches',
                    message: 'Try a different country name.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 120),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                    itemBuilder: (_, i) => FadeSlideIn(
                      index: i,
                      child: _CountryTile(
                        country: list[i],
                        curated: cat.hasCuratedData(list[i].id),
                        regions: cat.regionsOf(list[i].id).length,
                        selected: list[i].id == _selected,
                        onTap: () => setState(() => _selected = list[i].id),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
        child: FilledButton.icon(
          onPressed: catalog.hasValue ? _confirm : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(widget.onboarding ? 'Start exploring' : 'Use this country'),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onboarding});
  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 260 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SceneArt(theme: SceneTheme.mountains, seed: 'welcome-2'),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, context.colors.surface],
                stops: const [0.45, 1],
              ),
            ),
          ),
          if (!onboarding) Positioned(top: top + 4, left: 4, child: const BackButton()),
          Positioned(
            left: AppSpace.gutter,
            right: AppSpace.gutter,
            bottom: AppSpace.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onboarding ? 'Where does your\njourney begin?' : 'Change country',
                  style: context.text.displaySmall,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Pick a country to explore. You can switch any time.',
                  style: context.text.bodyMedium?.copyWith(color: context.palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.curated,
    required this.regions,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool curated;
  final int regions;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryContainer : context.palette.card,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? context.colors.primary : context.palette.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
            child: Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(country.name, style: context.text.titleMedium),
                      Text(
                        curated
                            ? '$regions ${country.regionLabel.toLowerCase()}s · ${country.tagline}'
                            : 'No curated guide yet — add your own places',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: AppDurations.fast,
                  opacity: selected ? 1 : 0,
                  child: Icon(Icons.check_circle_rounded, color: context.colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
