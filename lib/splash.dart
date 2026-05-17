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

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color splashBlue = Color(0xFF3F8EE8);

    return Scaffold(
      backgroundColor: splashBlue,
      body: SafeArea(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              // Approximates the logo from your screenshot.
              // If you have a real SVG/PNG logo later, we can swap this Text for an Image.
              'iCT',
              style:
                  Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 96,
                    letterSpacing: -2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
