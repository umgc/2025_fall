import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HiddenSearchLauncher extends StatefulWidget {
  final Alignment alignment;
  final double thickness;
  final String searchPath;
  final bool showOnWebHover;
  final bool debugVisible;

  const HiddenSearchLauncher({
    super.key,
    this.alignment = Alignment.centerRight,
    this.thickness = 8,
    this.searchPath = '/search',
    this.showOnWebHover = true,
    this.debugVisible = false,
  });

  @override
  State<HiddenSearchLauncher> createState() => _HiddenSearchLauncherState();
}

class _HiddenSearchLauncherState extends State<HiddenSearchLauncher> {
  bool _hovering = false;

  void _openSearch() {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    context.go(widget.searchPath);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.thickness.clamp(6, 16);
    final baseOpacity = widget.debugVisible ? 0.25 : 0.04;
    final onHoverOpacity = 0.12;
    final showHover = kIsWeb && widget.showOnWebHover;

    return Align(
      alignment: widget.alignment,
      child: MouseRegion(
        onEnter: (_) {
          if (showHover) setState(() => _hovering = true);
        },
        onExit: (_) {
          if (showHover) setState(() => _hovering = false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _openSearch,
          onDoubleTap: _openSearch,
          onLongPress: _openSearch,
          child: Semantics(
            label: 'Quick search',
            button: true,
            enabled: true,
            child: Container(
              width: width.toDouble(),
              height: MediaQuery.of(context).size.height * 0.5,
              margin: const EdgeInsets.symmetric(vertical: 80),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(
                  _hovering ? onHoverOpacity : baseOpacity,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: widget.alignment.x > 0 ? const Radius.circular(6) : Radius.zero,
                  right: widget.alignment.x < 0 ? const Radius.circular(6) : Radius.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
