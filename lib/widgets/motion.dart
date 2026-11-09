import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One set of timings for every animation in the app. Everything is short so
/// the interface feels quick: feedback in ~140ms, content in ~220ms.
abstract class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
  static const Curve curve = Curves.easeOutCubic;

  /// True when the device asks for reduced motion.
  static bool off(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Page transition: a quick fade with a short rise, used for every route.
class FastPageTransitionsBuilder extends PageTransitionsBuilder {
  const FastPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.off(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// [MaterialPageRoute] with shorter durations than the 300ms default.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required super.builder, super.settings, super.fullscreenDialog});

  @override
  Duration get transitionDuration => Motion.base;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);
}

/// Fades a widget in and lifts it a few pixels when it first appears.
/// Siblings pass an [index] to enter one after another (capped, so long lists
/// never wait more than ~240ms).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;

  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 8});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.base);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.curve);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed || _timer != null) return;
    if (Motion.off(context)) {
      _c.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 30 * math.min(widget.index, 8));
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
      ),
    );
  }
}

/// Cross-fades between children with a short rise. Give each child a key that
/// changes when the content should switch (a tab, a section, a client).
class FadeSwitch extends StatelessWidget {
  final Widget child;
  const FadeSwitch({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Motion.off(context)) return child;
    return AnimatedSwitcher(
      duration: Motion.base,
      reverseDuration: Motion.fast,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.012), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Text whose leading number counts up to its value, keeping everything around
/// it: "81.5 kg", "−0.5 kg", "28 yrs", "12". Non-numeric text is shown as is.
class CountUpText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const CountUpText(this.text, {super.key, this.style, this.maxLines, this.overflow});

  static final _number = RegExp(r'^([^0-9]*?)(\d+(?:\.\d+)?)(.*)$', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final m = _number.firstMatch(text);
    if (m == null || Motion.off(context)) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final prefix = m.group(1)!;
    final raw = m.group(2)!;
    final suffix = m.group(3)!;
    final target = double.parse(raw);
    final decimals = raw.contains('.') ? raw.split('.').last.length : 0;
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 600),
      curve: Motion.curve,
      builder: (context, v, _) => Text(
        '$prefix${v.toStringAsFixed(decimals)}$suffix',
        style: (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// Raises a card slightly and deepens its shadow while the pointer is over it.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double radius;
  const HoverLift({super.key, required this.child, this.radius = 12});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (Motion.off(context)) return widget.child;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.07 : 0),
              blurRadius: _hover ? 18 : 0,
              offset: Offset(0, _hover ? 6 : 0),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
