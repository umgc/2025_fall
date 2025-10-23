import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // TODO: Add OcrHandler back when needed
    // let controller = window?.rootViewController as! FlutterViewController
    // OcrHandler.register(with: controller.binaryMessenger)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
