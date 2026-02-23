// lib/core/utils/first_time_hint.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeHint {
  /// يمنع تكرار الـ Overlay في نفس اللحظة
  static final Set<String> _activeHints = <String>{};

  static Future<bool> _seen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Spotlight coach-mark (مرة واحدة):
  /// - تعتيم خفيف
  /// - فتحة حول العنصر
  /// - نبض (Pulse)
  /// - فقاعة شرح
  static Future<void> showRefreshHint({
    required BuildContext context,
    required GlobalKey targetKey,
    required String prefsKey,
    required String message,
    Duration autoDismiss = const Duration(seconds: 10),
  }) async {
    if (await _seen(prefsKey)) return;
    if (_activeHints.contains(prefsKey)) return;

    _activeHints.add(prefsKey);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) {
        _activeHints.remove(prefsKey);
        return;
      }

      final targetContext = targetKey.currentContext;
      if (targetContext == null) {
        _activeHints.remove(prefsKey);
        return;
      }

      final ro = targetContext.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) {
        _activeHints.remove(prefsKey);
        return;
      }

      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) {
        _activeHints.remove(prefsKey);
        return;
      }

      final targetPos = ro.localToGlobal(Offset.zero);
      final targetSize = ro.size;
      final targetRect = Rect.fromLTWH(
        targetPos.dx,
        targetPos.dy,
        targetSize.width,
        targetSize.height,
      );

      bool removed = false;
      late final OverlayEntry entry;

      Future<void> dismiss() async {
        if (removed) return;
        removed = true;

        try {
          entry.remove();
        } catch (_) {}

        await _markSeen(prefsKey);
        _activeHints.remove(prefsKey);
      }

      entry = OverlayEntry(
        builder: (_) {
          return _SpotlightHintOverlay(
            targetRect: targetRect,
            message: message,
            onDismiss: dismiss,
          );
        },
      );

      overlay.insert(entry);
      Future.delayed(autoDismiss, dismiss);
    } catch (_) {
      _activeHints.remove(prefsKey);
    }
  }
}

class _SpotlightHintOverlay extends StatefulWidget {
  const _SpotlightHintOverlay({
    required this.targetRect,
    required this.message,
    required this.onDismiss,
  });

  final Rect targetRect;
  final String message;
  final Future<void> Function() onDismiss;

  @override
  State<_SpotlightHintOverlay> createState() => _SpotlightHintOverlayState();
}

class _SpotlightHintOverlayState extends State<_SpotlightHintOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();

  late final AnimationController _appear =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
        ..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          final screenH = constraints.maxHeight;
          final screen = Size(screenW, screenH);

          final hole = _holeRect(widget.targetRect, screen);

          final bubbleW = screenW < 360 ? 255.0 : 295.0;

          final aboveY = hole.top - 80;
          final placeAbove = aboveY > 24;

          final bubbleTop = placeAbove ? aboveY : (hole.bottom + 14);
          final bubbleLeft = (hole.center.dx - bubbleW / 2)
              .clamp(12.0, screenW - bubbleW - 12.0)
              .toDouble();

          final arrowUp = !placeAbove;

          final fade = CurvedAnimation(parent: _appear, curve: Curves.easeOut);
          final scale = CurvedAnimation(parent: _appear, curve: Curves.easeOutBack);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onDismiss(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _SpotlightPainter(
                          target: hole,
                          t: _pulse.value,
                          overlayColor: Colors.black.withOpacity(0.42),
                          glowColor: Colors.white.withOpacity(0.90),
                          primary: cs.primary,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: bubbleTop,
                  left: bubbleLeft,
                  width: bubbleW,
                  child: FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(
                      scale: scale,
                      child: _HintBubble(
                        message: widget.message,
                        onClose: () => widget.onDismiss(),
                        arrowUp: arrowUp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Rect _holeRect(Rect target, Size screen) {
    final inflated = target.inflate(10);

    final left = inflated.left.clamp(6.0, screen.width - 6.0).toDouble();
    final top = inflated.top.clamp(6.0, screen.height - 6.0).toDouble();
    final right = inflated.right.clamp(6.0, screen.width - 6.0).toDouble();
    final bottom = inflated.bottom.clamp(6.0, screen.height - 6.0).toDouble();

    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.target,
    required this.t,
    required this.overlayColor,
    required this.glowColor,
    required this.primary,
  });

  final Rect target;
  final double t;
  final Color overlayColor;
  final Color glowColor;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    const baseRadius = 16.0;
    final rrect = RRect.fromRectAndRadius(target, const Radius.circular(baseRadius));

    // Overlay + Hole (even-odd)
    final path = Path()
      ..addRect(full)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = overlayColor);

    // Pulse ring
    final pulseGrow = 8.0 + 10.0 * t;
    final alpha = (0.55 - 0.55 * t).clamp(0.0, 0.55).toDouble();

    final pulseRect = target.inflate(pulseGrow);
    final pulseRRect = RRect.fromRectAndRadius(
      pulseRect,
      const Radius.circular(baseRadius + 8),
    );

    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = glowColor.withOpacity(alpha);

    canvas.drawRRect(pulseRRect, pulsePaint);

    // Inner ring
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = primary.withOpacity(0.95);

    canvas.drawRRect(rrect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.target != target ||
        oldDelegate.overlayColor != overlayColor;
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.message,
    required this.onClose,
    required this.arrowUp,
  });

  final String message;
  final VoidCallback onClose;
  final bool arrowUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrowUp)
          CustomPaint(
            size: const Size(18, 9),
            painter: _ArrowPainter(color: Colors.white, up: true),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.info_outline_rounded, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.25,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: cs.primary),
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (!arrowUp)
          CustomPaint(
            size: const Size(18, 9),
            painter: _ArrowPainter(color: Colors.white, up: false),
          ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool up;
  _ArrowPainter({required this.color, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();

    if (up) {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }

    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}
