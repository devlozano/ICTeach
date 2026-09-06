import 'package:flutter/material.dart';
import '../services/navigation_service.dart';
import '../services/workspace_navigation.dart';

class WorkspaceBackBar extends StatelessWidget {
  final Widget child;
  const WorkspaceBackBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ValueListenableBuilder<bool>(
        valueListenable: WorkspaceNavigation.instance.canGoBack,
        builder: (context, canBack, _) => canBack
            ? Material(
                color: const Color(0xFF10243A),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 48),
                          ),
                          onPressed: () => NavigationService
                              .navigatorKey
                              .currentState
                              ?.maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                        const Expanded(
                          child: Text(
                            'ICTeach workspace',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFFB5CDE2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      Expanded(child: child),
    ],
  );
}
