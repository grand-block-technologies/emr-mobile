import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Keeps case numbers, phones, clocks, distances and coordinates left-to-right inside Arabic.
class Ltr extends StatelessWidget {
  const Ltr(this.child, {super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Text that is always LTR (numbers, codes) but sits naturally in an RTL row.
class LtrText extends StatelessWidget {
  const LtrText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(text, style: style, textDirection: TextDirection.ltr);
}

enum ButtonVariant { primary, secondary, ghost, danger }

/// 48-high button (Material minimum touch target). While [busy], keeps its width, shows a spinner and ignores taps.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = ButtonVariant.primary,
    this.busy = false,
    this.icon,
    this.expand = true,
    this.height = Space.minTarget,
    this.iconAfter = false,
  });

  /// Put the icon after the label (forward arrows).
  final bool iconAfter;

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool busy;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = switch (variant) {
      ButtonVariant.primary || ButtonVariant.danger => AppColors.onBrand,
      ButtonVariant.secondary => AppColors.ink,
      ButtonVariant.ghost => AppColors.brand,
    };
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: busy ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !iconAfter) ...[Icon(icon, size: 20), const SizedBox(width: Space.sm)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
              if (icon != null && iconAfter) ...[const SizedBox(width: Space.sm), Icon(icon, size: 20)],
            ],
          ),
        ),
        if (busy)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          ),
      ],
    );
    final onTap = busy ? () {} : onPressed;
    final size = Size(expand ? double.infinity : Space.minTarget, height);
    final button = switch (variant) {
      ButtonVariant.primary => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(minimumSize: size, disabledBackgroundColor: AppColors.brand),
          child: content,
        ),
      ButtonVariant.danger => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: AppColors.danger,
            disabledBackgroundColor: AppColors.danger,
          ).copyWith(overlayColor: const WidgetStatePropertyAll(Color(0xFF7D1812))),
          child: content,
        ),
      ButtonVariant.secondary => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(minimumSize: size), child: content),
      ButtonVariant.ghost => TextButton(onPressed: onTap, style: TextButton.styleFrom(minimumSize: size), child: content),
    };
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: busy ? '$label, ${'loading'.tr}' : null,
      child: Opacity(opacity: onPressed == null && !busy ? 0.6 : 1, child: button),
    );
  }
}

/// White card, 1 px line border, soft shadow, radius 12, padding 20.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.padding = const EdgeInsets.all(Space.cardPadding), this.onTap, this.stripe});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Priority stripe on the start edge (6 px).
  final Color? stripe;

  @override
  Widget build(BuildContext context) {
    Widget inner = Padding(padding: padding, child: child);
    if (stripe != null) {
      inner = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Container(width: 6, color: stripe), Expanded(child: inner)],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Space.cardRadius),
        border: Border.all(color: AppColors.line),
        boxShadow: cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Space.cardRadius),
        child: Material(
          type: MaterialType.transparency,
          child: onTap == null ? inner : Semantics(button: true, child: InkWell(onTap: onTap, child: inner)),
        ),
      ),
    );
  }
}

/// P1–P4 pill: code (LTR) + words, 28 high, 13 semibold.
class PriorityPill extends StatelessWidget {
  const PriorityPill(this.priority, {super.key, this.showWords = true});
  final Priority priority;
  final bool showWords;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: priority.text, fontSize: 13, fontWeight: FontWeight.w600, height: 1.2);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(color: priority.fill, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LtrText(priority.code, style: style),
          if (showWords) ...[
            const SizedBox(width: 6),
            Text('·', style: style),
            const SizedBox(width: 6),
            Text(priority.labelKey.tr, style: style),
          ],
        ],
      ),
    );
  }
}

/// Tinted status pill with an icon and the word: 28 high, icon 16, 13 medium.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.tone, super.key, this.icon});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: Motion.colour,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(color: tone.fill, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: tone.text), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tone.text, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
              ),
            ),
          ],
        ),
      );
}

/// Visible label above every field (placeholder is never the label), error message under it,
/// danger outline plus a 4 px danger ring at 15 % when invalid.
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.ltr = false,
    this.enabled = true,
    this.helper,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  /// Numbers, codes and usernames are typed left-to-right even in Arabic.
  final bool ltr;
  final bool enabled;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final invalid = errorText != null;
    const radius = BorderRadius.all(Radius.circular(Space.controlRadius));
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: Motion.colour,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: invalid ? [BoxShadow(color: AppColors.danger.withValues(alpha: 0.15), spreadRadius: 4)] : const [],
          ),
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            maxLength: maxLength,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            autofillHints: autofillHints,
            textDirection: ltr ? TextDirection.ltr : null,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
              counterText: '',
              enabledBorder: invalid ? border(AppColors.danger) : null,
              focusedBorder: invalid ? border(AppColors.danger, 2) : null,
            ),
          ),
        ),
        if (invalid)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          )
        else if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(helper!, style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          ),
      ],
    );
  }
}

/// Inline banner for a form-level error, with the support reference on unexpected errors.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key, this.reference});
  final String message;
  final String? reference;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(color: AppColors.dangerSurface, borderRadius: BorderRadius.circular(Space.controlRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.circleAlert, size: 20, color: AppColors.danger),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 14, fontWeight: FontWeight.w500)),
                    if (reference != null) ...[
                      const SizedBox(height: Space.xs),
                      LtrText('${'reference'.tr}: $reference', style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// One-line feedback at the bottom of the screen. No-op when there is no app yet
/// (before `runApp`, in unit tests): a toast must never break the caller.
void showToast(String message) {
  BuildContext? ctx;
  try {
    ctx = Get.context;
  } on FlutterError {
    return;
  }
  if (ctx == null) return;
  ScaffoldMessenger.maybeOf(ctx)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Bottom sheet with the design surface. `Get.bottomSheet` ignores the theme and is transparent,
/// so every sheet goes through here: white surface, 12 px top corners, ink scrim at 40 %,
/// above the bottom navigation, and lifted with the keyboard.
Future<T?> showAppSheet<T>(Widget child) {
  final ctx = Get.context;
  if (ctx == null) return Future.value();
  return showModalBottomSheet<T>(
    context: ctx,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Space.cardRadius))),
    builder: (_) => child,
  );
}
