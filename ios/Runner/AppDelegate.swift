import Flutter
import UIKit
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Diagnostic logging for crash investigation
    os_log("🔍 AppDelegate.didFinishLaunching: START", log: .default, type: .info)

    do {
      os_log("🔍 Registering plugins...", log: .default, type: .info)
      GeneratedPluginRegistrant.register(with: self)
      os_log("✅ Plugins registered successfully", log: .default, type: .info)

      os_log("🔍 Calling super.application...", log: .default, type: .info)
      let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
      os_log("✅ AppDelegate.didFinishLaunching: COMPLETE (result: %{public}@)", log: .default, type: .info, result ? "true" : "false")

      return result
    } catch {
      os_log("❌ CRASH in AppDelegate.didFinishLaunching: %{public}@", log: .default, type: .error, error.localizedDescription)
      fatalError("AppDelegate initialization failed: \(error)")
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    os_log("✅ App became active", log: .default, type: .info)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    os_log("⚠️ App will resign active", log: .default, type: .info)
  }
}
