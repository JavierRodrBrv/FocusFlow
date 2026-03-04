import Flutter
import UIKit
import ActivityKit
import CoreFoundation
import os

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  // Channels para todos los Flutter engines activos (background + main)
  private static var channels: [FlutterMethodChannel] = []
  
  // CRÍTICO: Los observers de Darwin se registran UNA SOLA VEZ.
  // Cada llamada a register() con observer=nil en CFNotificationCenterRemoveObserver
  // no elimina nada (documentado por Apple: "If observer is nil, does nothing").
  // Sin este flag, cada apertura de app desde el DI añadía un observer duplicado,
  // causando que cada botón disparase N eventos simultáneos al TimerBloc.
  private static var darwinObserversRegistered = false

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
    // Las closures acceden a channels[] dinámicamente, por lo que siempre
    // usarán los canales más recientes aunque channels cambie después.
    guard !darwinObserversRegistered else { return }
    darwinObserversRegistered = true
    
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let pauseName = "com.andaluzcode.focusflow.pause" as CFString
    let playName  = "com.andaluzcode.focusflow.play"  as CFString
    let stopName  = "com.andaluzcode.focusflow.stop"  as CFString
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.channels.forEach {
        $0.invokeMethod("onNotificationAction", arguments: "PAUSE_ACTION")
      }
    }, pauseName, nil, .deliverImmediately)
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.channels.forEach {
        $0.invokeMethod("onNotificationAction", arguments: "PLAY_ACTION")
      }
    }, playName, nil, .deliverImmediately)
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.channels.forEach {
        $0.invokeMethod("onNotificationAction", arguments: "STOP_ACTION")
      }
    }, stopName, nil, .deliverImmediately)
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
      let startDateMillis    = args["startDate"]     as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
      let targetEndTimeMillis = args["targetEndTime"] as? Int ?? 0
      let totalDuration      = args["totalDuration"] as? Int ?? 0
      let status             = args["status"]        as? String ?? "focus"
      let isPaused           = args["isPaused"]      as? Bool ?? false
      let progress           = args["progress"]      as? Double ?? 0.0
      let remainingSeconds   = args["remainingSeconds"] as? Int ?? 0
      
      let targetEndDate = Date(timeIntervalSince1970: TimeInterval(targetEndTimeMillis) / 1000)
      // staleDate cubre toda la vida del timer para evitar que iOS lo marque stale
      // y deje de aceptar actualizaciones (el bug original de congelamiento).
      let staleDate = isPaused
          ? Date.distantFuture                        // pausa: sin caducidad
          : targetEndDate.addingTimeInterval(60)      // corriendo: fin + 60s

      let state = FocusFlowAttributes.ContentState(
          startDate: Date(timeIntervalSince1970: TimeInterval(startDateMillis) / 1000),
          targetEndDate: targetEndDate,
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
                  do {
                      if #available(iOS 16.2, *) {
                          let content = ActivityContent(state: state, staleDate: staleDate)
                          try await activity.update(content)
                      } else {
                          await activity.update(using: state)
                      }
                  } catch {
                      os_log("[FocusFlow] Error updating Live Activity: %@",
                             log: .default, type: .error, error.localizedDescription)
                  }
              }
          }
      } else {
          do {
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
          } catch {
              os_log("[FocusFlow] Error starting Live Activity: %@",
                     log: .default, type: .error, error.localizedDescription)
          }
      }
  }
}
