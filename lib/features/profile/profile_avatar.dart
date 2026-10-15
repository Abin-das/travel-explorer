import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/media.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.radius = 24});
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final initial = p.displayName.trim().isEmpty ? 'E' : p.displayName.trim().characters.first.toUpperCase();
    return Semantics(
      label: 'Profile picture',
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.primaryContainer,
          border: Border.all(color: context.colors.primary.withValues(alpha: 0.3), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: p.avatarPath != null
            ? LocalPhoto(path: p.avatarPath!, cacheWidth: (radius * 6).round())
            : Center(
                child: Text(
                  initial,
                  style: context.text.titleLarge?.copyWith(color: context.colors.primary, fontSize: radius * 0.8),
                ),
              ),
      ),
    );
  }
}
