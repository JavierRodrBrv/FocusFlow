import Flutter
import UIKit
import ActivityKit
import CoreFoundation

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  // Use an array to store multiple channels (Main + Background Isolates)
  private static var channels: [FlutterMethodChannel] = []
  
  @available(iOS 16.1, *)
  private static var currentActivity: Activity<FocusFlowAttributes>? {
    return Activity<FocusFlowAttributes>.activities.first
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: "com.example.focus_flow/notification", binaryMessenger: messenger)
    
    channels.append(channel)
    
    let instance = FocusFlowNotificationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
    
    UNUserNotificationCenter.current().delegate = instance
    
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    
    let pauseName = "com.andaluzcode.focusflow.pause" as CFString
    let playName = "com.andaluzcode.focusflow.play" as CFString
    let stopName = "com.andaluzcode.focusflow.stop" as CFString
    
    // Explicit casts to help type inference
    let observer: UnsafeRawPointer? = nil
    let object: UnsafeRawPointer? = nil
    
    // -----------------------------------------------------------
    // SOLUCIÓN: Usar closures literales en lugar de funciones static
    // -----------------------------------------------------------
    
    CFNotificationCenterRemoveObserver(center, observer, CFNotificationName(pauseName), object)
    CFNotificationCenterAddObserver(center, observer, { center, observer, name, object, userInfo in
        FocusFlowNotificationPlugin.channels.forEach { $0.invokeMethod("onNotificationAction", arguments: "PAUSE_ACTION") }
    }, pauseName, object, .deliverImmediately)
    
    CFNotificationCenterRemoveObserver(center, observer, CFNotificationName(playName), object)
    CFNotificationCenterAddObserver(center, observer, { center, observer, name, object, userInfo in
        FocusFlowNotificationPlugin.channels.forEach { $0.invokeMethod("onNotificationAction", arguments: "PLAY_ACTION") }
    }, playName, object, .deliverImmediately)
    
    CFNotificationCenterRemoveObserver(center, observer, CFNotificationName(stopName), object)
    CFNotificationCenterAddObserver(center, observer, { center, observer, name, object, userInfo in
        FocusFlowNotificationPlugin.channels.forEach { $0.invokeMethod("onNotificationAction", arguments: "STOP_ACTION") }
    }, stopName, object, .deliverImmediately)
  }

  // (Las funciones static onPause, onPlay y onStop han sido eliminadas)

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startLiveActivity", "updateLiveActivity":
      if #available(iOS 16.1, *), let args = call.arguments as? [String: Any] {
        manageActivity(args: args)
        result(nil)
      }
    case "endLiveActivity":
      if #available(iOS 16.1, *) {
        Task {
            for activity in Activity<FocusFlowAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        result(nil)
      }
    case "updateNotification":
      if let args = call.arguments as? [String: Any],
         let time = args["time"] as? String,
         let status = args["status"] as? String {
          showLocalNotification(time: time, status: status)
          result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showLocalNotification(time: String, status: String) {
      let content = UNMutableNotificationContent()
      content.title = "FocusFlow"
      content.body = status == "finished" ? "¡Sesión completada!" : "Tiempo restante: \(time)"
      content.sound = UNNotificationSound.default

      let request = UNNotificationRequest(identifier: "focus_flow_update", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
  }

  @available(iOS 16.1, *)
  private func manageActivity(args: [String: Any]) {
      let startDateMillis = args["startDate"] as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
      let targetEndTimeMillis = args["targetEndTime"] as? Int ?? 0
      let totalDuration = args["totalDuration"] as? Int ?? 0
      let status = args["status"] as? String ?? "focus"
      let isPaused = args["isPaused"] as? Bool ?? false
      let progress = args["progress"] as? Double ?? 0.0
      let remainingSeconds = args["remainingSeconds"] as? Int ?? 0
      
      let state = FocusFlowAttributes.ContentState(
          startDate: Date(timeIntervalSince1970: TimeInterval(startDateMillis) / 1000),
          targetEndDate: Date(timeIntervalSince1970: TimeInterval(targetEndTimeMillis) / 1000),
          isPaused: isPaused,
          totalDuration: Double(totalDuration),
          progress: progress,
          status: status,
          remainingSeconds: remainingSeconds
      )
      
      let activities = Activity<FocusFlowAttributes>.activities
      if !activities.isEmpty {
          Task {
              for activity in activities {
                  await activity.update(using: state)
              }
          }
      } else {
          do {
              _ = try Activity<FocusFlowAttributes>.request(
                  attributes: FocusFlowAttributes(name: "Focus Timer"),
                  contentState: state,
                  pushType: nil
              )
          } catch { print("[FocusFlow] Error: \(error)") }
      }
  }
}
