import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'basics.dart';

/// Rounded-square icon holder (radius 12). Brand-soft by default; pass a [tone] to match a status.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 44, this.tone, this.iconSize = 20});
  final IconData icon;
  final double size;
  final double iconSize;
  final Tone? tone;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tone?.fill ?? AppColors.brandSoft,
          borderRadius: BorderRadius.circular(Space.cardRadius),
        ),
        child: Icon(icon, size: iconSize, color: tone?.text ?? AppColors.brand),
      );
}

/// App mark for the sign-in screens: the app's icon in a brand circle plus its name.
class BrandMark extends StatelessWidget {
  const BrandMark({required this.icon, required this.name, super.key});
  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.onBrand, size: 24),
          ),
          const SizedBox(width: Space.md),
          Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
        ],
      );
}

/// Section title (17 semibold) with an optional trailing action, spaced for the 4-unit grid.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(subtitle!, style: t.bodyMedium!.copyWith(color: AppColors.inkMuted, fontSize: 14)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Chevron that points "forward" in the reading direction.
class ForwardChevron extends StatelessWidget {
  const ForwardChevron({super.key, this.color = AppColors.inkSubtle});
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
        Directionality.of(context) == TextDirection.rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        size: 20,
        color: color,
      );
}

/// One tappable row: icon tile, title, subtitle, trailing widget or chevron. At least 64 high.
class ListRow extends StatelessWidget {
  const ListRow({
    required this.title,
    super.key,
    this.icon,
    this.tone,
    this.subtitle,
    this.detail,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  /// A widget under the title (e.g. a status chip) that may be wider than a trailing slot allows.
  final Widget? detail;

  final IconData? icon;
  final Tone? tone;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
        child: Row(
          children: [
            if (icon != null) ...[IconTile(icon!, tone: tone, size: 40), const SizedBox(width: Space.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: t.bodyLarge!.copyWith(fontWeight: FontWeight.w500, color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: t.bodySmall),
                  ],
                  if (detail != null) ...[const SizedBox(height: Space.sm), detail!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: Space.sm), trailing!],
            if (onTap != null && showChevron) ...[const SizedBox(width: Space.xs), const ForwardChevron()],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Semantics(button: true, child: InkWell(onTap: onTap, child: content));
  }
}

/// A card holding [ListRow]s separated by hairlines (grouped settings style).
class RowGroup extends StatelessWidget {
  const RowGroup({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(indent: Space.lg, endIndent: Space.lg),
              children[i],
            ],
          ],
        ),
      );
}

/// Icon + text line inside a card ("near the big mosque", "Riyadh hospital").
class InfoRow extends StatelessWidget {
  const InfoRow({required this.icon, required this.text, super.key, this.label});
  final IconData icon;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, size: 32, iconSize: 16, tone: Tone.neutral),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) Text(label!, style: t.labelMedium!.copyWith(color: AppColors.inkMuted)),
              Text(text, style: t.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky action area at the bottom of a screen (thumb reach), above the gesture bar.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(Space.screen, Space.md, Space.screen, Space.md), child: child),
        ),
      );
}

enum TimelineStepState { done, current, upcoming }

/// Vertical timeline: a dot per step joined by a line; done steps in brand, the current one ringed.
class StepTimeline extends StatelessWidget {
  const StepTimeline({required this.steps, required this.current, super.key});
  final List<String> steps;

  /// Index of the current step; -1 when unknown.
  final int current;

  TimelineStepState _state(int i) => i < current ? TimelineStepState.done : (i == current ? TimelineStepState.current : TimelineStepState.upcoming);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _Dot(_state(i)),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: i < current ? AppColors.brand : AppColors.line,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < steps.length - 1 ? Space.lg : 0),
                    child: Text(
                      steps[i],
                      style: t.bodyLarge!.copyWith(
                        height: 1.3,
                        color: _state(i) == TimelineStepState.upcoming ? AppColors.inkMuted : AppColors.ink,
                        fontWeight: _state(i) == TimelineStepState.current ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.state);
  final TimelineStepState state;

  @override
  Widget build(BuildContext context) => switch (state) {
        TimelineStepState.done => Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
            child: const Icon(LucideIcons.check, size: 12, color: AppColors.onBrand),
          ),
        TimelineStepState.current => Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand, width: 6),
            ),
          ),
        TimelineStepState.upcoming => Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.lineSoft, width: 2)),
          ),
      };
}

/// Initials in a brand-soft circle (profile header).
class AvatarInitials extends StatelessWidget {
  const AvatarInitials(this.name, {super.key, this.size = 56});
  final String name;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    // Arabic letters join, so two initials read as a word: use one letter for Arabic names.
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(parts.first)) return parts.first.characters.first;
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.brandSoft, shape: BoxShape.circle),
        child: Text(_initials, style: TextStyle(color: AppColors.brandActive, fontSize: size * 0.36, fontWeight: FontWeight.w600)),
      );
}
