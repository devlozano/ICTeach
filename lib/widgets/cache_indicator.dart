import 'package:flutter/material.dart';

class CacheIndicator extends StatelessWidget {
  final bool isFromCache;
  final Widget child;

  const CacheIndicator({
    super.key,
    required this.isFromCache,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFromCache) return child;

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storage,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Cached',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
