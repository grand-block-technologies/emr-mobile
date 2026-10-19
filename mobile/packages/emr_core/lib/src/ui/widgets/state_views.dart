import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_error.dart';
import '../../i18n/locale_service.dart';
import '../theme/app_colors.dart';
import 'basics.dart';

/// Grey block with a soft shine. The shine stops when the system asks for reduced motion.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 6});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _c.value * 3, 0),
              end: Alignment(-0.5 + _c.value * 3, 0),
              colors: const [AppColors.skeleton, Color(0xFFEDF1F2), AppColors.skeleton],
            ),
          ),
        ),
      );
}

/// Content-shaped placeholder; screen readers hear "Loading".
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.cards = 2});
  final int cards;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'loading'.tr,
        liveRegion: true,
        child: ExcludeSemantics(
          child: ListView.separated(
            padding: const EdgeInsets.all(Space.screen),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards,
            separatorBuilder: (_, _) => const SizedBox(height: Space.betweenCards),
            itemBuilder: (_, _) => const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 20, width: 140),
                  SizedBox(height: Space.inCard),
                  SkeletonBox(),
                  SizedBox(height: Space.sm),
                  SkeletonBox(width: 220),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Empty-state mark: 24 icon inside a 48 circle of surface-strong.
class _Mark extends StatelessWidget {
  const _Mark(this.icon, {this.color = AppColors.inkMuted});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(color: AppColors.surfaceStrong, shape: BoxShape.circle),
        child: Icon(icon, size: 24, color: color),
      );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
}

/// A short title, one sentence, and the single next action when there is one.
class EmptyView extends StatelessWidget {
  const EmptyView({required this.title, super.key, this.body, this.icon = LucideIcons.inbox, this.actionLabel, this.onAction});
  final String title;
  final String? body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Centered(
      children: [
        _Mark(icon),
        const SizedBox(height: Space.lg),
        Text(title, style: t.titleMedium, textAlign: TextAlign.center),
        if (body != null) ...[
          const SizedBox(height: Space.sm),
          Text(body!, style: t.bodyLarge!.copyWith(color: AppColors.inkMuted), textAlign: TextAlign.center),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: Space.xxl),
          AppButton(label: actionLabel!, onPressed: onAction, expand: false),
        ],
      ],
    );
  }
}

/// The server message, a reference when one was returned for an unexpected error, and Retry.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, super.key, this.onRetry});
  final ApiError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Centered(
      children: [
        _Mark(error.isNetwork ? LucideIcons.wifiOff : LucideIcons.circleAlert, color: AppColors.danger),
        const SizedBox(height: Space.lg),
        Semantics(
          liveRegion: true,
          child: Text(error.message(currentLang()), style: t.titleMedium, textAlign: TextAlign.center),
        ),
        if (error.reference != null && error.isUnexpected) ...[
          const SizedBox(height: Space.sm),
          LtrText('${'reference'.tr}: ${error.reference}', style: t.bodySmall),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: Space.xxl),
          AppButton(label: 'retry'.tr, onPressed: onRetry, variant: ButtonVariant.secondary, expand: false, icon: LucideIcons.rotateCw),
        ],
      ],
    );
  }
}

/// A plain statement, with no data behind it.
class NoAccessView extends StatelessWidget {
  const NoAccessView({super.key});

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: LucideIcons.lock,
        title: 'no_access_title'.tr,
        body: 'no_access_body'.tr,
      );
}
