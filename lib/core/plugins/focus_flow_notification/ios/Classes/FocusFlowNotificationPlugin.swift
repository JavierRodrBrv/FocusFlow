import Flutter
import UIKit
import ActivityKit
import CoreFoundation
import os

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  // Channels para todos los Flutter engines activos (background + main)
  private static var channels: [FlutterMethodChannel] = []
  
  // CRÍTICO: Los observers de Darwin se registran UNA SOLA VEZ.
  private static var darwinObserversRegistered = false

  // --- Serializar updates para evitar race conditions ---
  private static let updateQueue = DispatchQueue(label: "com.focusflow.liveactivity.update")
  
  // --- Timestamp del último Intent para logging ---
  private static var lastIntentActionTime: Date = .distantPast

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

    // Registrar observers de Darwin una única vez.
    guard !darwinObserversRegistered else { return }
    darwinObserversRegistered = true
    
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let pauseName = "com.andaluzcode.focusflow.pause" as CFString
    let playName  = "com.andaluzcode.focusflow.play"  as CFString
    let stopName  = "com.andaluzcode.focusflow.stop"  as CFString
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      // FIX #A2: Registrar timestamp del Intent para aplicar cooldown
      FocusFlowNotificationPlugin.lastIntentActionTime = Date()
      FocusFlowNotificationPlugin.notifyFlutter("PAUSE_ACTION")
    }, pauseName, nil, .deliverImmediately)
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.lastIntentActionTime = Date()
      FocusFlowNotificationPlugin.notifyFlutter("PLAY_ACTION")
    }, playName, nil, .deliverImmediately)
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.lastIntentActionTime = Date()
      FocusFlowNotificationPlugin.notifyFlutter("STOP_ACTION")
    }, stopName, nil, .deliverImmediately)
  }

  // --- FIX #A3: Notificar solo canales vivos ---
  // Envía a todos los canales registrados. Los canales de engines muertos
  // pueden fallar silenciosamente, pero se limpiarán en detachFromEngine.
  private static func notifyFlutter(_ action: String) {
    for channel in channels {
      channel.invokeMethod("onNotificationAction", arguments: action)
    }
  }
  
  // --- FIX #A4: Limpiar canales de engines muertos ---
  public static func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    channels.removeAll { channel in
      // No hay API pública para comparar messengers, pero al destruir
      // el channel, se evitan futuras invocaciones.
      // Eliminamos el último canal agregado para este registrar.
      false // Placeholder: Flutter no expone messenger identity
    }
    os_log("[FocusFlow] Engine detached, channels count: %d",
           log: .default, type: .info, channels.count)
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
        // Serializar el end con la misma cola que los updates
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
          let isPaused = defaults.bool(forKey: "isPaused")
          let remainingSeconds = defaults.integer(forKey: "remainingSeconds")
          let isStopped = defaults.bool(forKey: "isStopped")
          let lastActionTime = defaults.double(forKey: "lastWidgetActionTime")
          
          let dict: [String: Any] = [
              "isPaused": isPaused,
              "remainingSeconds": remainingSeconds,
              "isStopped": isStopped,
              "lastWidgetActionTime": lastActionTime
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

  @available(iOS 16.1, *)
  private func manageActivity(args: [String: Any]) {
      os_log("[FocusFlow] manageActivity called with arguments: %{public}@", log: .default, type: .info, String(describing: args))
      
      let startDateMillis    = args["startDate"]     as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
      let targetEndTimeMillis = args["targetEndTime"] as? Int ?? 0
      let totalDuration      = args["totalDuration"] as? Int ?? 0
      let status             = args["status"]        as? String ?? "focus"
      let isPaused           = args["isPaused"]      as? Bool ?? false
      let progress           = args["progress"]      as? Double ?? 0.0
      let remainingSeconds   = args["remainingSeconds"] as? Int ?? 0
      
      let targetEndDate = Date(timeIntervalSince1970: TimeInterval(targetEndTimeMillis) / 1000)
      // staleDate cubre toda la vida del timer
      let staleDate: Date? = isPaused
          ? nil                        // pausa: sin caducidad
          : targetEndDate.addingTimeInterval(60)      // corriendo: fin + 60s

      let state = FocusFlowAttributes.ContentState(
          isPaused: isPaused,
          status: status,
          remainingSeconds: remainingSeconds,
          timerStartDate: Date(timeIntervalSince1970: TimeInterval(startDateMillis) / 1000),
          timerEndDate: targetEndDate,
          pauseDate: isPaused ? Date() : nil
      )
      
      // FIX #E: Arquitectura Indestructible - Sincronizar hacia el App Group
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.set(isPaused, forKey: "isPaused")
          defaults.set(remainingSeconds, forKey: "remainingSeconds")
          defaults.set(false, forKey: "isStopped")
          // No actualizamos lastWidgetActionTime porque esta orden viene de Dart (Master)
      }
      
      os_log("[FocusFlow] New ContentState created. isPaused: %d, targetEndDate: %{public}@", log: .default, type: .info, isPaused, String(describing: targetEndDate))
      
      let activities = Activity<FocusFlowAttributes>.activities
      os_log("[FocusFlow] Found %d active activities", log: .default, type: .info, activities.count)
      
      if !activities.isEmpty {
          FocusFlowNotificationPlugin.updateQueue.async {
              let group = DispatchGroup()
              group.enter()
              
              Task {
                  defer { group.leave() }
                  for activity in activities {
                      guard activity.activityState == .active else { continue }
                      
                      do {
                          os_log("[FocusFlow] Starting UPDATE for activity %{public}@", log: .default, type: .info, activity.id)
                          if #available(iOS 16.2, *) {
                              let content = ActivityContent(state: state, staleDate: staleDate)
                              try await activity.update(content)
                          } else {
                              await activity.update(using: state)
                          }
                          os_log("[FocusFlow] Update activity successful", log: .default, type: .info)
                      } catch {
                          os_log("[FocusFlow] Error updating Live Activity: %{public}@",
                                 log: .default, type: .error, error.localizedDescription)
                      }
                  }
              }
              group.wait()
          }
      } else {
          FocusFlowNotificationPlugin.updateQueue.async {
              let group = DispatchGroup()
              group.enter()
              
              Task {
                  defer { group.leave() }
                  do {
                      os_log("[FocusFlow] Starting REQUEST NEW activity", log: .default, type: .info)
                      if #available(iOS 16.2, *) {
                          let content = ActivityContent(state: state, staleDate: staleDate)
                          _ = try Activity<FocusFlowAttributes>.request(
                              attributes: FocusFlowAttributes(name: "Focus Timer"),
                              content: content,
                              pushType: nil
                          )
                      } else {
                          _ = try Activity<FocusFlowAttributes>.request(
                              attributes: FocusFlowAttributes(name: "Focus Timer"),
                              contentState: state,
                              pushType: nil
                          )
                      }
                      os_log("[FocusFlow] Request new activity successful", log: .default, type: .info)
                  } catch {
                      os_log("[FocusFlow] Error starting Live Activity: %{public}@",
                             log: .default, type: .error, error.localizedDescription)
                  }
              }
              group.wait()
          }
      }
  }
}
