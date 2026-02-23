import Flutter
import UIKit
import UserNotifications

public class FocusFlowNotificationPlugin: NSObject, FlutterPlugin {
  private static var channel: FlutterMethodChannel?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    channel = FlutterMethodChannel(name: "com.example.focus_flow/notification", binaryMessenger: messenger)
    let instance = FocusFlowNotificationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel!)
    registrar.addApplicationDelegate(instance)
    
    // Request permission once at registration
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
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
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be [String: Any]", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func updateNotification(time: String, status: String) {
    let center = UNUserNotificationCenter.current()
    
    // Configurar categorías y acciones si es necesario
    setupCategories()

    let content = UNMutableNotificationContent()
    content.title = "FocusFlow"
    
    // Adaptación del texto según el estado (misma lógica que Android)
    if status == "resting" || status == "paused_break" {
        content.body = "Descanso • \(time)"
    } else if status == "finished" {
        content.body = "¡Sesión completada!"
    } else if status == "initial" {
        content.body = "A la espera de comenzar..."
    } else {
        content.body = time
    }
    
    // El "status" nos dice qué botón mostrar
    if status != "initial" && status != "finished" {
        content.categoryIdentifier = (status == "running" || status == "resting") ? "POMODORO_RUNNING" : "POMODORO_PAUSED"
    } else {
        content.categoryIdentifier = "POMODORO_NONE"
    }

    let request = UNNotificationRequest(identifier: "pomodoro_timer", content: content, trigger: nil)
    center.add(request) { error in
        if let error = error {
            print("[FocusFlowNotification] Error posting notification: \(error)")
        }
    }
  }
  
  private func setupCategories() {
      let center = UNUserNotificationCenter.current()
      
      // Acciones en segundo plano (sin .foreground para que no abra la app al pausar/reproducir)
      let playAction = UNNotificationAction(identifier: "PLAY_ACTION", title: "Reproducir", options: [])
      let pauseAction = UNNotificationAction(identifier: "PAUSE_ACTION", title: "Pausar", options: [])
      
      let runningCategory = UNNotificationCategory(identifier: "POMODORO_RUNNING", actions: [pauseAction], intentIdentifiers: [], options: [])
      let pausedCategory = UNNotificationCategory(identifier: "POMODORO_PAUSED", actions: [playAction], intentIdentifiers: [], options: [])
      let noneCategory = UNNotificationCategory(identifier: "POMODORO_NONE", actions: [], intentIdentifiers: [], options: [])
      
      center.setNotificationCategories([runningCategory, pausedCategory, noneCategory])
  }
  
  // Handle notification actions (User clicked Pause or Play)
  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
      if response.notification.request.identifier == "pomodoro_timer" {
          let action = response.actionIdentifier
          if action == "PLAY_ACTION" || action == "PAUSE_ACTION" {
              FocusFlowNotificationPlugin.channel?.invokeMethod("onNotificationAction", arguments: action)
          }
      }
      completionHandler()
  }
}
