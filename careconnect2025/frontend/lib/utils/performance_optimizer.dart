import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for the CareConnect app
class PerformanceOptimizer {
  static bool _isInitialized = false;
  static final Map<String, DateTime> _lastExecution = {};
  static final Map<String, int> _executionCount = {};

  /// Initialize performance optimizations
  static void initialize() {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      debugPrint('🚀 Initializing Performance Optimizer...');
    }

    // Enable performance overlays in debug mode
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Enable performance overlay for debugging
        // This helps identify performance bottlenecks
      });
    }

    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('✅ Performance Optimizer initialized');
    }
  }

  /// Debounce function calls to prevent excessive executions
  static void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    final now = DateTime.now();
    final lastExecution = _lastExecution[key];
    
    if (lastExecution == null || 
        now.difference(lastExecution) > delay) {
      _lastExecution[key] = now;
      callback();
    }
  }

  /// Throttle function calls to limit execution frequency
  static void throttle(
    String key,
    VoidCallback callback, {
    Duration interval = const Duration(milliseconds: 1000),
  }) {
    final now = DateTime.now();
    final lastExecution = _lastExecution[key];
    
    if (lastExecution == null || 
        now.difference(lastExecution) > interval) {
      _lastExecution[key] = now;
      _executionCount[key] = (_executionCount[key] ?? 0) + 1;
      callback();
    }
  }

  /// Measure execution time of a function
  static T measureExecution<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    final result = operation();
    stopwatch.stop();
    
    if (kDebugMode) {
      debugPrint('⏱️ $operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
    
    return result;
  }

  /// Async version of measureExecution
  static Future<T> measureExecutionAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();
    
    if (kDebugMode) {
      debugPrint('⏱️ $operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
    
    return result;
  }

  /// Optimize image loading with caching
  static Widget optimizedImage({
    required String imageUrl,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('🖼️ Image load error: $error');
        }
        return errorWidget;
      },
      // Enable caching
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  /// Create a lazy-loaded list view
  static Widget createLazyListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Add a small delay for very large lists to prevent UI blocking
        if (index % 50 == 0 && index > 0) {
          return FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 1)),
            builder: (context, snapshot) {
              return itemBuilder(context, index);
            },
          );
        }
        return itemBuilder(context, index);
      },
    );
  }

  /// Optimize widget rebuilds with automatic memoization
  static Widget memoized({
    required String key,
    required Widget Function() builder,
  }) {
    return _MemoizedWidget(
      key: ValueKey(key),
      builder: builder,
    );
  }

  /// Clear performance cache
  static void clearCache() {
    _lastExecution.clear();
    _executionCount.clear();
    
    if (kDebugMode) {
      debugPrint('🧹 Performance cache cleared');
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getStats() {
    return {
      'executionCount': Map.from(_executionCount),
      'lastExecutions': _lastExecution.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'isInitialized': _isInitialized,
    };
  }
}

/// Internal widget for memoization
class _MemoizedWidget extends StatefulWidget {
  final Widget Function() builder;

  const _MemoizedWidget({
    super.key,
    required this.builder,
  });

  @override
  State<_MemoizedWidget> createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<_MemoizedWidget> {
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    _cachedWidget ??= widget.builder();
    return _cachedWidget!;
  }
}

/// Performance monitoring mixin for widgets
mixin PerformanceMonitoring<T extends StatefulWidget> on State<T> {
  String get performanceKey => '${T.toString()}_${hashCode}';
  
  @override
  void initState() {
    super.initState();
    PerformanceOptimizer.throttle(
      '${performanceKey}_init',
      () {
        if (kDebugMode) {
          debugPrint('🎯 ${T.toString()} initialized');
        }
      },
    );
  }

  @override
  void dispose() {
    PerformanceOptimizer.throttle(
      '${performanceKey}_dispose',
      () {
        if (kDebugMode) {
          debugPrint('🗑️ ${T.toString()} disposed');
        }
      },
    );
    super.dispose();
  }

  void measureBuild(String operationName, VoidCallback operation) {
    PerformanceOptimizer.measureExecution(
      '${performanceKey}_$operationName',
      operation,
    );
  }
}
