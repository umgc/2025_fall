import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class GlobalSearchShortcut extends StatelessWidget {
  final Widget child;
  final String searchPath;

  const GlobalSearchShortcut({
    super.key,
    required this.child,
    this.searchPath = '/search',
  });

  @override
  Widget build(BuildContext context) {
    final keySet = LogicalKeySet(
      defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.meta
          : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyK,
    );

    return Shortcuts(
      shortcuts: {keySet: const ActivateIntent()},
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              final ctx = _navigatorContextOf(context) ?? context;
              FocusScope.of(ctx).unfocus();
              ctx.go(searchPath);
              return null;
            },
          ),
        },
        child: Focus(autofocus: kIsWeb, child: child),
      ),
    );
  }

  static BuildContext? _navigatorContextOf(BuildContext context) {
    BuildContext? found;
    context.visitAncestorElements((e) {
      if (ModalRoute.of(e) != null) found = e;
      return found == null;
    });
    return found;
  }
}
