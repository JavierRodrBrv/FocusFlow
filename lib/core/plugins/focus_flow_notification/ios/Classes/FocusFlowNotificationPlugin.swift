import Flutter
import UIKit
import ActivityKit
import CoreFoundation
import os
import AppIntents

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static var channels: [FlutterMethodChannel] = []
  private static let updateQueue = DispatchQueue(label: "com.focusflow.liveactivity.update")
  private let appGroup = "group.com.andaluzcode.focusFlow"

  @available(iOS 16.2, *)
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
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
      if #available(iOS 16.2, *) {
          self.manageActivity(args: nil)
      }
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
      if #available(iOS 16.2, *) {
          self.manageActivity(args: nil)
      }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startLiveActivity", "updateLiveActivity":
      if #available(iOS 16.2, *), let args = call.arguments as? [String: Any] {
        manageActivity(args: args)
        result(nil)
      }
    case "stageLiveActivity":
      if let args = call.arguments as? [String: Any] {
        stageStateInUserDefaults(args: args)
        result(nil)
      }
    case "endLiveActivity":
      if #available(iOS 16.2, *) {
        FocusFlowNotificationPlugin.updateQueue.async {
          Task {
            for activity in Activity<FocusFlowAttributes>.activities {
              await activity.end(nil, dismissalPolicy: .immediate)
            }
          }
        }
        result(nil)
      }
    case "syncWidgetState":
      if let defaults = UserDefaults(suiteName: appGroup) {
          defaults.synchronize()
          let dict: [String: Any] = [
              "isPaused": defaults.bool(forKey: "isPaused"),
              "remainingSeconds": defaults.integer(forKey: "remainingSeconds"),
              "isStopped": defaults.bool(forKey: "isStopped"),
              "targetEndTime": defaults.integer(forKey: "targetEndTime"),
              "status": defaults.string(forKey: "status") ?? "focus",
              "lastWidgetActionTime": defaults.double(forKey: "lastWidgetActionTime")
          ]
          result(dict)
      } else {
          result(["error": "App Group not configured"])
      }
    case "clearWidgetState":
      if let defaults = UserDefaults(suiteName: appGroup) {
          os_log("[FocusFlow] Clearing widget state flags.", log: .default, type: .info)
          defaults.set(false, forKey: "isStopped")
          defaults.set(0.0, forKey: "lastWidgetActionTime")
          defaults.synchronize()
          result(nil)
      } else {
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

  private func stageStateInUserDefaults(args: [String: Any]) {
      if let defaults = UserDefaults(suiteName: appGroup) {
          defaults.set(args["isPaused"] as? Bool ?? false, forKey: "isPaused")
          defaults.set(args["remainingSeconds"] as? Int ?? 0, forKey: "remainingSeconds")
          defaults.set(args["startDate"] as? Int ?? 0, forKey: "startDate")
          defaults.set(args["targetEndTime"] as? Int ?? 0, forKey: "targetEndTime")
          defaults.set(args["totalDuration"] as? Int ?? 0, forKey: "totalDuration")
          defaults.set(args["status"] as? String ?? "focus", forKey: "status")
          // No seteamos isStopped aqui para no sobreescribir una accion real del widget
          defaults.synchronize()
      }
  }

  @available(iOS 16.2, *)
  private func manageActivity(args: [String: Any]?) {
      var finalArgs: [String: Any] = [:]
      
      if let inputArgs = args {
          finalArgs = inputArgs
      } else if let defaults = UserDefaults(suiteName: appGroup) {
          finalArgs["startDate"] = defaults.integer(forKey: "startDate")
          finalArgs["targetEndTime"] = defaults.integer(forKey: "targetEndTime")
          finalArgs["totalDuration"] = defaults.integer(forKey: "totalDuration")
          finalArgs["status"] = defaults.string(forKey: "status") ?? "focus"
          finalArgs["isPaused"] = defaults.bool(forKey: "isPaused")
          finalArgs["remainingSeconds"] = defaults.integer(forKey: "remainingSeconds")
      }
      
      if finalArgs.isEmpty { return }
      
      let startDateMillis    = finalArgs["startDate"] as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
      let targetEndTimeMillis = finalArgs["targetEndTime"] as? Int ?? 0
      let status             = finalArgs["status"] as? String ?? "focus"
      let isPaused           = finalArgs["isPaused"] as? Bool ?? false
      let remainingSeconds   = finalArgs["remainingSeconds"] as? Int ?? 0
      
      let targetEndDate = Date(timeIntervalSince1970: TimeInterval(targetEndTimeMillis) / 1000)
      let state = FocusFlowAttributes.ContentState(
          isPaused: isPaused,
          status: status,
          remainingSeconds: remainingSeconds,
          timerStartDate: Date(timeIntervalSince1970: TimeInterval(startDateMillis) / 1000),
          timerEndDate: targetEndDate,
          pauseDate: isPaused ? Date() : nil
      )
      
      FocusFlowNotificationPlugin.updateQueue.async {
          let semaphore = DispatchSemaphore(value: 0)
          Task {
              defer { semaphore.signal() }
              let activities = Activity<FocusFlowAttributes>.activities
              
              if activities.isEmpty {
                  do {
                      _ = try Activity<FocusFlowAttributes>.request(
                          attributes: FocusFlowAttributes(name: "Focus Timer"),
                          content: ActivityContent(state: state, staleDate: nil),
                          pushType: nil
                      )
                  } catch {
                      os_log("[FocusFlow] Error: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
                  return
              }
              
              for activity in activities {
                  guard activity.activityState == .active else { continue }
                  let currentState = activity.content.state
                  
                  let isStatusChanged = currentState.status != state.status
                  let isPausedChanged = currentState.isPaused != state.isPaused
                  let isSameEndDate = abs(currentState.timerEndDate.timeIntervalSince(state.timerEndDate)) < 1.0
                  
                  let isRedundant = !isStatusChanged && !isPausedChanged && isSameEndDate
                  
                  if isRedundant {
                      os_log("[FocusFlow] Skipping redundant update.", log: .default, type: .info)
                      continue
                  }
                  
                  do {
                      os_log("[FocusFlow] Updating activity. Status: %{public}@", log: .default, type: .info, status)
                      try await activity.update(ActivityContent(state: state, staleDate: nil))
                  } catch {
                      os_log("[FocusFlow] Update error: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
              }
          }
          _ = semaphore.wait(timeout: .now() + 5.0)
      }
  }
}
