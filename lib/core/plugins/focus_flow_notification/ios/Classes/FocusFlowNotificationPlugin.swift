import Flutter
import UIKit
import ActivityKit
import CoreFoundation
import os

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  // Channels para todos los Flutter engines activos (background + main)
  private static var channels: [FlutterMethodChannel] = []
  
  // --- Serializar updates para evitar race conditions ---
  private static let updateQueue = DispatchQueue(label: "com.focusflow.liveactivity.update")

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
    // Darwin Observers eliminados: los Intents del Widget Extension
    // actualizan la actividad directamente sin despertar Flutter.
  }

  // --- CICLO DE VIDA: sincroniza estado al volver a primer plano ---
  public func applicationWillEnterForeground(_ application: UIApplication) {
      os_log("[FocusFlow] applicationWillEnterForeground", log: .default, type: .info)
      // Al volver de background, leemos el estado más reciente de App Groups
      // por si el Widget actuó mientras la app estaba cerrada.
      if #available(iOS 16.1, *) {
          self.manageActivity(args: nil)
      }
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
      os_log("[FocusFlow] applicationDidEnterBackground - Final stage", log: .default, type: .info)
      if #available(iOS 16.1, *) {
          self.manageActivity(args: nil)
      }
  }

  public static func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    os_log("[FocusFlow] Engine detached. Channels: %d", log: .default, type: .info, channels.count)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startLiveActivity", "updateLiveActivity":
      if #available(iOS 16.1, *), let args = call.arguments as? [String: Any] {
        manageActivity(args: args)
        result(nil)
      }
    case "stageLiveActivity":
      if let args = call.arguments as? [String: Any] {
        stageStateInUserDefaults(args: args)
        result(nil)
      }
    case "endLiveActivity":
      if #available(iOS 16.1, *) {
        FocusFlowNotificationPlugin.updateQueue.async {
          Task {
            for activity in Activity<FocusFlowAttributes>.activities {
              await activity.end(dismissalPolicy: .immediate)
            }
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
    case "syncWidgetState":
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.synchronize()
          let dict: [String: Any] = [
              "isPaused": defaults.bool(forKey: "isPaused"),
              "remainingSeconds": defaults.integer(forKey: "remainingSeconds"),
              "isStopped": defaults.bool(forKey: "isStopped"),
              "lastWidgetActionTime": defaults.double(forKey: "lastWidgetActionTime")
          ]
          result(dict)
      } else {
          result(["error": "App Group not configured"])
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
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.set(args["isPaused"] as? Bool ?? false, forKey: "isPaused")
          defaults.set(args["remainingSeconds"] as? Int ?? 0, forKey: "remainingSeconds")
          defaults.set(args["startDate"] as? Int ?? 0, forKey: "startDate")
          defaults.set(args["targetEndTime"] as? Int ?? 0, forKey: "targetEndTime")
          defaults.set(args["totalDuration"] as? Int ?? 0, forKey: "totalDuration")
          defaults.set(args["status"] as? String ?? "focus", forKey: "status")
          defaults.set(false, forKey: "isStopped")
          defaults.synchronize()
      }
  }

  @available(iOS 16.1, *)
  private func manageActivity(args: [String: Any]?) {
      var finalArgs: [String: Any] = [:]
      
      if let inputArgs = args {
          finalArgs = inputArgs
      } else if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
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
      let staleDate: Date = isPaused ? Date.distantFuture : targetEndDate.addingTimeInterval(60)

      let state = FocusFlowAttributes.ContentState(
          isPaused: isPaused,
          status: status,
          remainingSeconds: remainingSeconds,
          timerStartDate: Date(timeIntervalSince1970: TimeInterval(startDateMillis) / 1000),
          timerEndDate: targetEndDate,
          pauseDate: isPaused ? Date() : nil
      )
      
      // Sincronizar App Groups
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.set(isPaused, forKey: "isPaused")
          defaults.set(remainingSeconds, forKey: "remainingSeconds")
          defaults.set(false, forKey: "isStopped")
          defaults.synchronize()
      }
      
      FocusFlowNotificationPlugin.updateQueue.async {
          let semaphore = DispatchSemaphore(value: 0)
          Task {
              defer { semaphore.signal() }
              
              let activities = Activity<FocusFlowAttributes>.activities
              
              if activities.isEmpty {
                  // Sin actividad activa → crear nueva
                  do {
                      os_log("[FocusFlow] Requesting NEW activity.", log: .default, type: .info)
                      if #available(iOS 16.2, *) {
                          _ = try Activity<FocusFlowAttributes>.request(
                              attributes: FocusFlowAttributes(name: "Focus Timer"),
                              content: ActivityContent(state: state, staleDate: staleDate),
                              pushType: nil
                          )
                      } else {
                          _ = try Activity<FocusFlowAttributes>.request(
                              attributes: FocusFlowAttributes(name: "Focus Timer"),
                              contentState: state,
                              pushType: nil
                          )
                      }
                  } catch {
                      os_log("[FocusFlow] Error creating activity: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
                  return
              }
              
              // Actividad existente → UPDATE simple (sin rebirth)
              // El rebirth consume 2x budget y no es necesario para pause/resume.
              for activity in activities {
                  guard activity.activityState == .active else { continue }
                  
                  let currentState: FocusFlowAttributes.ContentState
                  if #available(iOS 16.2, *) {
                      currentState = activity.content.state
                  } else {
                      currentState = activity.contentState
                  }
                  
                  let isSameEndDate = abs(currentState.timerEndDate.timeIntervalSince(state.timerEndDate)) < 2.0
                  let isSameRemaining = abs(currentState.remainingSeconds - state.remainingSeconds) <= 1
                  let isPausedChanged = currentState.isPaused != state.isPaused
                  let isRedundant = !isPausedChanged && (state.isPaused ? isSameRemaining : isSameEndDate)
                  
                  if isRedundant {
                      os_log("[FocusFlow] Skipping redundant update.", log: .default, type: .info)
                      continue
                  }
                  
                  do {
                      os_log("[FocusFlow] Updating activity. isPaused: %d", log: .default, type: .info, isPaused ? 1 : 0)
                      if #available(iOS 16.2, *) {
                          try await activity.update(ActivityContent(state: state, staleDate: staleDate))
                      } else {
                          await activity.update(using: state)
                      }
                  } catch {
                      os_log("[FocusFlow] Update error: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
              }
          }
          _ = semaphore.wait(timeout: .now() + 5.0)
      }
  }
}
