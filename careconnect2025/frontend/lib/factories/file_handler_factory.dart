import '../abstracts/file_handler.dart';
import '../utils/file_handler_native.dart'
if (dart.library.html) '../../utils/file_handler_web.dart';

class FileHandlerFactory {
  /// This factory to load the correct file loader depending on the platform.
  static FileHandler create() {
    // Conditional imports handle platform selection
    return _createPlatformHandler();
  }
}

// This will be implemented by the platform-specific files
FileHandler _createPlatformHandler() {
  return NativeFileHandler(); // Default fallback
}
