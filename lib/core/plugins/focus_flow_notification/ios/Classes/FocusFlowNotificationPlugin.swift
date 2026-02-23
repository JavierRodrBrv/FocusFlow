import Flutter
import UIKit
import ActivityKit

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static var channel: FlutterMethodChannel?
  private static var lastStatus: String = ""
  
  // Hold the current activity
  @available(iOS 16.1, *)
  private static var currentActivity: Activity<FocusFlowAttributes>?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    channel = FlutterMethodChannel(name: "com.example.focus_flow/notification", binaryMessenger: messenger)
    let instance = FocusFlowNotificationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
    registrar.addApplicationDelegate(instance)
    
    UNUserNotificationCenter.current().delegate = instance
    instance.setupCategories()
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("[FocusFlowNotification] Permission error: \(error)")
        }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateNotification":
      if let args = call.arguments as? [String: Any],
         let time = args["time"] as? String,
         let status = args["status"] as? String {
        updateNotification(time: time, status: status)
        result(nil)
      }
      
    case "startLiveActivity":
      if #available(iOS 16.1, *),
         let args = call.arguments as? [String: Any] {
        startLiveActivity(args: args)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }

    case "updateLiveActivity":
      if #available(iOS 16.1, *),
         let args = call.arguments as? [String: Any] {
        updateLiveActivity(args: args)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }

    case "endLiveActivity":
      if #available(iOS 16.1, *) {
        endLiveActivity()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Live Activities (iOS 16.1+)

  @available(iOS 16.1, *)
  private func startLiveActivity(args: [String: Any]) {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
          print("[FocusFlowNotification] Live Activities are disabled")
          return
      }

      let targetEndTime = args["targetEndTime"] as? Int ?? 0
      let totalDuration = args["totalDuration"] as? Int ?? 0
      let status = args["status"] as? String ?? "focus"
      let isPaused = args["isPaused"] as? Bool ?? false
      let progress = args["progress"] as? Double ?? 0.0
      
      let attributes = FocusFlowAttributes(name: "Focus Timer")
      let state = FocusFlowAttributes.ContentState(
          targetEndDate: Date(timeIntervalSince1970: TimeInterval(targetEndTime) / 1000),
          isPaused: isPaused,
          pausedTime: Date(), // Current time if paused
          totalDuration: Double(totalDuration),
          progress: progress,
          status: status
      )
      
      do {
          let activity = try Activity<FocusFlowAttributes>.request(
              attributes: attributes,
              contentState: state,
              pushType: nil
          )
          FocusFlowNotificationPlugin.currentActivity = activity
          print("[FocusFlowNotification] Started Live Activity: \(activity.id)")
      } catch {
          print("[FocusFlowNotification] Error starting Live Activity: \(error.localizedDescription)")
      }
  }

  @available(iOS 16.1, *)
  private func updateLiveActivity(args: [String: Any]) {
      guard let activity = FocusFlowNotificationPlugin.currentActivity else { return }
      
      let targetEndTime = args["targetEndTime"] as? Int ?? 0
      let totalDuration = args["totalDuration"] as? Int ?? 0
      let status = args["status"] as? String ?? "focus"
      let isPaused = args["isPaused"] as? Bool ?? false
      let progress = args["progress"] as? Double ?? 0.0
      
      let state = FocusFlowAttributes.ContentState(
          targetEndDate: Date(timeIntervalSince1970: TimeInterval(targetEndTime) / 1000),
          isPaused: isPaused,
          pausedTime: Date(),
          totalDuration: Double(totalDuration),
          progress: progress,
          status: status
      )
      
      Task {
          await activity.update(using: state)
      }
  }

  @available(iOS 16.1, *)
  private func endLiveActivity() {
      guard let activity = FocusFlowNotificationPlugin.currentActivity else { return }
      
      Task {
          await activity.end(dismissalPolicy: .immediate)
          FocusFlowNotificationPlugin.currentActivity = nil
      }
  }

  // MARK: - Standard Notifications

  private func updateNotification(time: String, status: String) {
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    
    content.title = "FocusFlow"
    
    if status == "resting" || status == "paused_break" {
        content.body = "☕ Descanso • \(time)"
    } else if status == "finished" {
        content.body = "🎯 ¡SESIÓN COMPLETADA!"
        content.sound = UNNotificationSound.default
    } else if status == "initial" {
        content.body = "A la espera de comenzar..."
    } else {
        content.body = "⏱️ Focus: \(time)"
    }
    
    if status != "initial" && status != "finished" {
        content.categoryIdentifier = (status == "running" || status == "resting") ? "POMODORO_RUNNING" : "POMODORO_PAUSED"
    } else {
        content.categoryIdentifier = "POMODORO_NONE"
    }

    if #available(iOS 15.0, *) {
        if status == FocusFlowNotificationPlugin.lastStatus && status != "finished" {
            content.interruptionLevel = .passive
        } else {
            content.interruptionLevel = .timeSensitive
        }
    }
    
    FocusFlowNotificationPlugin.lastStatus = status

    let request = UNNotificationRequest(identifier: "pomodoro_timer", content: content, trigger: nil)
    center.add(request) { error in
        if let error = error {
            print("[FocusFlowNotification] Error: \(error)")
        }
    }
  }
  
  private func setupCategories() {
      let center = UNUserNotificationCenter.current()
      let playAction = UNNotificationAction(identifier: "PLAY_ACTION", title: "Reproducir", options: [])
      let pauseAction = UNNotificationAction(identifier: "PAUSE_ACTION", title: "Pausar", options: [])
      
      let runningCategory = UNNotificationCategory(identifier: "POMODORO_RUNNING", actions: [pauseAction], intentIdentifiers: [], options: [.customDismissAction])
      let pausedCategory = UNNotificationCategory(identifier: "POMODORO_PAUSED", actions: [playAction], intentIdentifiers: [], options: [.customDismissAction])
      let noneCategory = UNNotificationCategory(identifier: "POMODORO_NONE", actions: [], intentIdentifiers: [], options: [])
      
      center.setNotificationCategories([runningCategory, pausedCategory, noneCategory])
  }
  
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
      let action = response.actionIdentifier
      if action == "PLAY_ACTION" || action == "PAUSE_ACTION" {
          FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: action)
      }
      completionHandler()
  }

  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .badge, .sound])
  }
  
  // Handle application opening from URL (Deep Links)
  public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      let urlString = url.absoluteString
      if urlString.contains("focusflow://pause") {
          FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: "PAUSE_ACTION")
      } else if urlString.contains("focusflow://resume") {
          FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: "PLAY_ACTION")
      } else if urlString.contains("focusflow://stop") {
          FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: "STOP_ACTION")
      }
      return true
  }
}
