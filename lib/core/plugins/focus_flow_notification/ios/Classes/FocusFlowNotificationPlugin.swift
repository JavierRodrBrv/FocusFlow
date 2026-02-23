import Flutter
import UIKit
import ActivityKit

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static var channel: FlutterMethodChannel?
  
  @available(iOS 16.1, *)
  private static var currentActivity: Activity<FocusFlowAttributes>? {
    return Activity<FocusFlowAttributes>.activities.first
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    channel = FlutterMethodChannel(name: "com.example.focus_flow/notification", binaryMessenger: messenger)
    let instance = FocusFlowNotificationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
    registrar.addApplicationDelegate(instance)
    
    UNUserNotificationCenter.current().delegate = instance
    
    // --- ESCUCHAR SEÑALES DE LOS BOTONES DEL WIDGET (SIN ABRIR APP) ---
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    
    let pauseObserver = UnsafeRawPointer(Unmanaged.passUnretained(instance).toOpaque())
    CFNotificationCenterAddObserver(center, pauseObserver, { (_, observer, _, _, _) in
        FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: "PAUSE_ACTION")
    }, "com.andaluzcode.focusflow.pause" as CFString, nil, .deliverImmediately)
    
    let playObserver = UnsafeRawPointer(Unmanaged.passUnretained(instance).toOpaque())
    CFNotificationCenterAddObserver(center, playObserver, { (_, observer, _, _, _) in
        FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: "PLAY_ACTION")
    }, "com.andaluzcode.focusflow.play" as CFString, nil, .deliverImmediately)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startLiveActivity", "updateLiveActivity":
      if #available(iOS 16.1, *), let args = call.arguments as? [String: Any] {
        manageActivity(args: args)
        result(nil)
      }
    case "endLiveActivity":
      if #available(iOS 16.1, *) {
        Activity<FocusFlowAttributes>.activities.forEach { $0.end(dismissalPolicy: .immediate) }
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.1, *)
  private func manageActivity(args: [String: Any]) {
      let targetEndTime = args["targetEndTime"] as? Int ?? 0
      let totalDuration = args["totalDuration"] as? Int ?? 0
      let status = args["status"] as? String ?? "focus"
      let isPaused = args["isPaused"] as? Bool ?? false
      let progress = args["progress"] as? Double ?? 0.0
      let remainingSeconds = args["remainingSeconds"] as? Int ?? 0
      
      let state = FocusFlowAttributes.ContentState(
          targetEndDate: Date(timeIntervalSince1970: TimeInterval(targetEndTime) / 1000),
          isPaused: isPaused,
          totalDuration: Double(totalDuration),
          progress: progress,
          status: status,
          remainingSeconds: remainingSeconds
      )
      
      if let activity = FocusFlowNotificationPlugin.currentActivity {
          Task { await activity.update(using: state) }
      } else {
          do {
              _ = try Activity<FocusFlowAttributes>.request(
                  attributes: FocusFlowAttributes(name: "Focus Timer"),
                  contentState: state,
                  pushType: nil
              )
          } catch { print(error) }
      }
  }
}
