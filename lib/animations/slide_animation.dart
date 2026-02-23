import 'package:flutter/material.dart';

class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  /// منين يبدأ السلايد (افتراضي: نزول خفيف لتحت)
  final Offset beginOffset;
  final Offset endOffset;

  const SlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.10),
    this.endOffset = Offset.zero,
  });

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);
    _position = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _play();
  }

  Future<void> _play() async {
    if (widget.delay != Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (!mounted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}
