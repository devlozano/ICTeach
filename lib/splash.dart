import 'dart:async';

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.duration = const Duration(seconds: 2),
    required this.onFinished,
  });

  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;

  // White -> blue for LMS-style polish (fast, with easing).
  final Duration _colorAnimDuration = const Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _colorAnimDuration)
      ..forward();

    _timer = Timer(widget.duration, widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color splashBlue = Color(0xFF3F8EE8);
    const Color white = Colors.white;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // LMS-like animation: logo fades in and gently scales up while background transitions.
    final logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    final logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.9, curve: Curves.easeOutBack),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bg = Color.lerp(white, splashBlue, curved.value) ?? splashBlue;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Center(
              child: Opacity(
                opacity: logoOpacity.value,
                child: Transform.scale(
                  scale: logoScale.value,
                  child: Image.asset(
                    'assets/logo 2.png',
                    width: 220,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
