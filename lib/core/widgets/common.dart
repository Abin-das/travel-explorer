import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.action, this.onAction, this.padding});

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xl, AppSpace.sm, AppSpace.md),
      // Baseline alignment lines the action's text up with the title's text,
      // whatever the button's padding or the subtitle below the title.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge, semanticsLabel: title),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: context.text.bodySmall)],
              ],
            ),
          ),
          // Not Flexible: a Flexible here would take half the row and leave the
          // button floating mid-way instead of at the trailing edge.
          if (action != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: TextButton(
                onPressed: onAction,
                child: Text(action!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpace.lg : AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 64 : 88,
              height: compact ? 64 : 88,
              decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: compact ? 30 : 40, color: context.colors.primary),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: context.palette.muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmering placeholder used for skeleton loading states.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 3 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [p.shimmerBase, p.shimmerHighlight, p.shimmerBase],
            ),
          ),
        );
      },
    );
  }
}

/// A generic skeleton for list screens.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.gutter),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.lg),
      itemBuilder: (_, _) => const Row(
        children: [
          Skeleton(width: 84, height: 84, radius: AppRadius.md),
          SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 18),
                SizedBox(height: AppSpace.sm),
                Skeleton(width: 140, height: 14),
                SizedBox(height: AppSpace.sm),
                Skeleton(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders an [AsyncValue] with consistent loading and error states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder, this.loading, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: '$error',
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      ),
      _ => loading ?? const SkeletonList(),
    };
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.hint});

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: context.palette.chip, borderRadius: AppRadius.smAll),
            child: Icon(icon, size: 20, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: context.text.titleSmall),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured label.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.icon, this.color, this.solid = false});

  final String label;
  final IconData? icon;
  final Color? color;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    final fg = solid ? Colors.white : c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? c : c.withValues(alpha: context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Honesty label shown wherever curated sample content appears.
class SampleDataNote extends StatelessWidget {
  const SampleDataNote({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: context.colors.secondary),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text ??
                  'Curated sample guide content. Timings, fees and conditions change — verify locally before you go.',
              style: context.text.bodySmall?.copyWith(color: context.colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and slides its child in; [index] staggers list items.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 18});

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 50;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * offset), child: child),
      ),
      child: child,
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, this.onChanged, this.size = 28});

  final int? value;
  final ValueChanged<int?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value == null ? 'No rating' : 'Rated $value out of 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(value == i ? null : i),
              child: Padding(
                padding: EdgeInsets.all(onChanged == null ? 0 : 3),
                child: Icon(
                  (value ?? 0) >= i ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: (value ?? 0) >= i ? AppColors.bucket : context.palette.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.value, required this.label, this.color, this.onTap});

  final IconData icon;
  final int value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    return Material(
      color: context.palette.card,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.13), borderRadius: AppRadius.smAll),
                child: Icon(icon, size: 18, color: c),
              ),
              const SizedBox(height: AppSpace.sm),
              AnimatedCount(value: value, style: context.text.headlineSmall),
              Text(label, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, this.style});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: AppDurations.slow,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(v.round().toString(), style: style),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.value, this.color, this.height = 8});
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: AppDurations.slow,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: context.palette.chip,
          color: color ?? context.colors.primary,
        ),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.icon, this.selected = false, required this.onTap});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.colors.onPrimary : context.colors.onSurface;
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: selected ? context.colors.primary : context.palette.card,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: selected ? context.colors.primary : context.palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? fg : context.colors.primary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A search field. With [onTap] set it acts as a button that opens search.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.hint = 'Search destinations, attractions, or food spots...',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        readOnly: onTap != null,
        onTap: onTap,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search_rounded, color: context.colors.primary),
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
          suffixIcon: controller == null
              ? null
              : ListenableBuilder(
                  listenable: controller!,
                  builder: (context, _) => controller!.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            controller!.clear();
                            onChanged?.call('');
                          },
                        ),
                ),
        ),
      ),
    );
  }
}

/// Rounded white card container used throughout.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft(Theme.of(context).brightness),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section title used inside detail pages.
class DetailHeading extends StatelessWidget {
  const DetailHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
    child: Text(text, style: context.text.titleLarge?.w(700)),
  );
}

class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key, this.icon = Icons.check_circle_rounded});
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: context.colors.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(i, style: context.text.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Grows a fixed layout height with the user's font-size setting, so rows of
/// cards and chips that contain text keep fitting. [textShare] is the part of
/// [base] that is text (the rest, e.g. an image, stays the same size).
double scaledHeight(BuildContext context, double base, {double textShare = 0.5}) {
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  if (scale <= 1) return base;
  return base + base * textShare * (scale - 1);
}

/// A grid whose rows size to their tallest child, so text never overflows a
/// cell (unlike `GridView` with a fixed aspect ratio). Column count adapts to
/// the available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 150,
    this.maxColumns = 4,
    this.spacing = AppSpace.md,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = ((c.maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final cells = <Widget>[];
          for (var j = 0; j < cols; j++) {
            if (j > 0) cells.add(SizedBox(width: spacing));
            cells.add(Expanded(child: i + j < children.length ? children[i + j] : const SizedBox.shrink()));
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
