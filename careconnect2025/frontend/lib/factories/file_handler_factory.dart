import '../abstracts/file_handler.dart';

class FileHandlerFactory {
  /// This factory to load the correct file loader depending on the platform.
  static FileHandler create() {
    // Conditional imports handle platform selection
    return _createPlatformHandler();
  }
}

// This will be implemented by the platform-specific files
FileHandler _createPlatformHandler() {
  // This function will be replaced by the conditional import
  throw UnsupportedError('Platform not supported');
}
