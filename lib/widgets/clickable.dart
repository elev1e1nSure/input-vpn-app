import 'package:flutter/material.dart';

/// Desktop-friendly wrapper that ensures a pointer cursor on hover.
///
/// Unlike raw [GestureDetector], this always shows
/// [SystemMouseCursors.click] when [onTap] is non-null.
class Clickable extends StatelessWidget {
  const Clickable({
    super.key,
    this.onTap,
    required this.child,
  });

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
    );
  }
}
