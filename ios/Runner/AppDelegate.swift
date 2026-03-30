import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.focus_flow/native",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if ("vibrate" == call.method) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let urlString = url.absoluteString
    if urlString.hasPrefix("focusflow://") {
        let action = urlString.replacingOccurrences(of: "focusflow://", with: "")
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.focus_flow/native",
                                                  binaryMessenger: controller.binaryMessenger)
        // Informar a Flutter del comando (pause/resume/stop)
        channel.invokeMethod("onNotificationAction", arguments: action)
        return true
    }
    return super.application(app, open: url, options: options)
  }
}
