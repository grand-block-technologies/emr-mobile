import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Pocket-safe confirmation: drag the thumb to the end. Follows the reading direction
/// (left-to-right in English, right-to-left in Arabic). Screen readers get a plain button.
class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({required this.label, required this.onConfirmed, super.key, this.enabled = true, this.height = 64});

  final String label;
  final VoidCallback onConfirmed;
  final bool enabled;
  final double height;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _drag = 0;
  bool _done = false;

  static const _threshold = 0.85;

  void _end(double max) {
    if (_drag / max >= _threshold && widget.enabled && !_done) {
      setState(() {
        _drag = max;
        _done = true;
      });
      HapticFeedback.mediumImpact();
      widget.onConfirmed();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  void didUpdateWidget(covariant SwipeToConfirm old) {
    super.didUpdateWidget(old);
    if (old.label != widget.label) {
      _done = false;
      _drag = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      onTap: widget.enabled && !_done ? widget.onConfirmed : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final thumb = widget.height - 8;
          final max = (c.maxWidth - thumb - 8).clamp(1.0, double.infinity);
          final progress = (_drag / max).clamp(0.0, 1.0);
          return Opacity(
            opacity: widget.enabled ? 1 : 0.6,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(widget.height / 2)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1 - progress,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: thumb + 12),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.onBrand, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _drag == 0 && !reduceMotion ? Motion.colour : Duration.zero,
                    left: rtl ? null : 4 + _drag,
                    right: rtl ? 4 + _drag : null,
                    top: 4,
                    child: GestureDetector(
                      key: const Key('swipe_thumb'),
                      onHorizontalDragUpdate: widget.enabled && !_done
                          ? (d) => setState(() => _drag = (_drag + (rtl ? -d.delta.dx : d.delta.dx)).clamp(0.0, max))
                          : null,
                      onHorizontalDragEnd: widget.enabled && !_done ? (_) => _end(max) : null,
                      child: Container(
                        width: thumb,
                        height: thumb,
                        decoration: const BoxDecoration(color: AppColors.onBrand, shape: BoxShape.circle),
                        child: Icon(
                          _done ? LucideIcons.check : (rtl ? LucideIcons.chevronsLeft : LucideIcons.chevronsRight),
                          color: AppColors.brand,
                          size: 24,
                        ),
                      ),
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
