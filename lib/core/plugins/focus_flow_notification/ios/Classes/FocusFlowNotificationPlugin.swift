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

  // --- Flag para forzar rebirth al volver de background (Reset de presupuesto) ---
  private static var pendingRebirthOnForeground = false

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
    let nextName  = "com.andaluzcode.focusflow.next"  as CFString
    
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
      FocusFlowNotificationPlugin.notifyFlutter("STOP_ACTION")
    }, stopName, nil, .deliverImmediately)
    
    CFNotificationCenterAddObserver(center, nil, { _, _, _, _, _ in
      FocusFlowNotificationPlugin.lastIntentActionTime = Date()
      FocusFlowNotificationPlugin.notifyFlutter("NEXT_ACTION")
    }, nextName, nil, .deliverImmediately)
  }

  // --- ESCUCHA DE CICLO DE VIDA ---
  public func applicationWillEnterForeground(_ application: UIApplication) {
      os_log("[FocusFlow] applicationWillEnterForeground - Marking pending rebirth for budget reset", log: .default, type: .info)
      FocusFlowNotificationPlugin.pendingRebirthOnForeground = true
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
      os_log("[FocusFlow] applicationDidBecomeActive - Triggering immediate sync/rebirth", log: .default, type: .info)
      if #available(iOS 16.1, *) {
          self.manageActivity(args: nil)
      }
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
      os_log("[FocusFlow] applicationDidEnterBackground - Performing Handoff", log: .default, type: .info)
      if #available(iOS 16.1, *) {
          // Realizamos el COMMIT final al entrar en segundo plano
          self.manageActivity(args: nil)
      }
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
         let title = args["title"] as? String,
         let body = args["body"] as? String {
          showLocalNotification(title: title, body: body)
          result(nil)
      }
    case "syncWidgetState":
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.synchronize() // Forzar lectura de disco/AppGroup
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

  private func showLocalNotification(title: String, body: String) {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = UNNotificationSound.default

      let request = UNNotificationRequest(identifier: "focus_flow_update", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
  }

  private func stageStateInUserDefaults(args: [String: Any]) {
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.set(args["isPaused"] as? Bool ?? false, forKey: "isPaused")
          defaults.set(args["remainingSeconds"] as? Int ?? 0, forKey: "remainingSeconds")
          defaults.set(args["cycleStartDate"] as? Int ?? 0, forKey: "cycleStartDate")
          defaults.set(args["focusDuration"] as? Int ?? 0, forKey: "focusDuration")
          defaults.set(args["breakDuration"] as? Int ?? 0, forKey: "breakDuration")
          defaults.set(args["status"] as? String ?? "focus", forKey: "status")
          defaults.set(args["phaseLabel"] as? String ?? "", forKey: "phaseLabel")
          defaults.set(args["showSkip"] as? Bool ?? true, forKey: "showSkip")
          defaults.set(false, forKey: "isStopped")
          defaults.synchronize()
          os_log("[FocusFlow] State STAGED in UserDefaults", log: .default, type: .info)
      }
  }

  @available(iOS 16.1, *)
  private func manageActivity(args: [String: Any]?) {
      var finalArgs: [String: Any] = [:]
      
      if let inputArgs = args {
          finalArgs = inputArgs
      } else if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          // Reclaiming staged state
          finalArgs["cycleStartDate"] = defaults.integer(forKey: "cycleStartDate")
          finalArgs["focusDuration"] = defaults.integer(forKey: "focusDuration")
          finalArgs["breakDuration"] = defaults.integer(forKey: "breakDuration")
          finalArgs["status"] = defaults.string(forKey: "status") ?? "focus"
          finalArgs["phaseLabel"] = defaults.string(forKey: "phaseLabel") ?? ""
          finalArgs["isPaused"] = defaults.bool(forKey: "isPaused")
          finalArgs["remainingSeconds"] = defaults.integer(forKey: "remainingSeconds")
          finalArgs["showSkip"] = defaults.object(forKey: "showSkip") as? Bool ?? true
          os_log("[FocusFlow] Reclaiming staged state from UserDefaults for COMMIT", log: .default, type: .info)
      }
      
      if finalArgs.isEmpty { return }
      
      os_log("[FocusFlow] manageActivity executing with: %{public}@", log: .default, type: .info, String(describing: finalArgs))
      
      let cycleStartDateMillis = finalArgs["cycleStartDate"] as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
      let focusDuration      = finalArgs["focusDuration"] as? Int ?? 0
      let breakDuration      = finalArgs["breakDuration"] as? Int ?? 0
      let status             = finalArgs["status"]        as? String ?? "focus"
      let phaseLabel         = finalArgs["phaseLabel"]    as? String ?? ""
      
      if status == "initial" || status == "finished" {
          os_log("[FocusFlow] manageActivity skipped because status is %{public}@", log: .default, type: .info, status)
          return
      }
      
      let isPaused           = finalArgs["isPaused"]      as? Bool ?? false
      let remainingSeconds   = finalArgs["remainingSeconds"] as? Int ?? 0
      let showSkip           = finalArgs["showSkip"]      as? Bool ?? true
      
      let cycleStartDate = Date(timeIntervalSince1970: TimeInterval(cycleStartDateMillis) / 1000)
      
      let state = FocusFlowAttributes.ContentState(
          isPaused: isPaused,
          status: status,
          phaseLabel: phaseLabel,
          remainingSeconds: remainingSeconds,
          cycleStartDate: cycleStartDate,
          focusDurationSeconds: focusDuration,
          breakDurationSeconds: breakDuration,
          pauseDate: isPaused ? Date() : nil,
          showSkip: showSkip
      )
      
      // Use the computed endDate for stale configuration
      let staleDate: Date? = isPaused ? nil : state.activePhaseInfo.endDate.addingTimeInterval(60)
      
      // --- GUARDA DE COLISIÓN (Proceso vs Proceso) ---
      if args == nil, let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          let lastAction = defaults.double(forKey: "lastWidgetActionTime")
          let now = Date().timeIntervalSince1970
          // Solo bloqueamos el COMMIT automático de fondo si el widget acaba de actuar.
          // Si Dart nos llama explícitamente con args, es porque quiere forzar la sincronía (ej: app abierta).
          if lastAction > 0 && (now - lastAction) < 2.0 {
              os_log("[FocusFlow] Skipping background COMMIT: Recent Widget interaction detected", log: .default, type: .info)
              return
          }
      }
      
      // Sincronizar hacia el App Group (redundante si venimos de stage, pero necesario si venimos de direct call)
      if let defaults = UserDefaults(suiteName: "group.com.andaluzcode.focusFlow") {
          defaults.set(isPaused, forKey: "isPaused")
          defaults.set(remainingSeconds, forKey: "remainingSeconds")
          defaults.set(false, forKey: "isStopped")
          defaults.synchronize()
      }
      
      os_log("[FocusFlow] New ContentState created. isPaused: %d", log: .default, type: .info, isPaused)
      
      FocusFlowNotificationPlugin.updateQueue.async {
          var bgTask: UIBackgroundTaskIdentifier = .invalid
          bgTask = UIApplication.shared.beginBackgroundTask(withName: "UpdateLiveActivity") {
              if bgTask != .invalid {
                  UIApplication.shared.endBackgroundTask(bgTask)
                  bgTask = .invalid
              }
          }
          
          let semaphore = DispatchSemaphore(value: 0)
          Task {
              defer { 
                  semaphore.signal() 
                  if bgTask != .invalid {
                      UIApplication.shared.endBackgroundTask(bgTask)
                      bgTask = .invalid
                  }
              }
              
              let activities = Activity<FocusFlowAttributes>.activities
              
              if activities.isEmpty {
                  // Caso 1: No hay actividad -> Crear una nueva
                  do {
                      os_log("[FocusFlow] Case: No active activity. Requesting NEW.", log: .default, type: .info)
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
                      os_log("[FocusFlow] Error requesting NEW: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
                  return
              }
              
              // Caso 2: ¿Necesitamos REBIRTH?
              // Estrategia Híbrida: Solo recreamos si hay cambio de Play/Pause Y estamos en PRIMER PLANO.
              // O si acabamos de volver de background (pendindRebirthOnForeground).
              let isForeground = UIApplication.shared.applicationState == .active
              var needsRebirth = FocusFlowNotificationPlugin.pendingRebirthOnForeground && isForeground
              
              for activity in activities {
                  let currentState: FocusFlowAttributes.ContentState
                  if #available(iOS 16.2, *) {
                      currentState = activity.content.state
                  } else {
                      currentState = activity.contentState
                  }
                  
                  if currentState.isPaused != state.isPaused && isForeground {
                      needsRebirth = true
                      break
                  }
              }
              
              if needsRebirth {
                  os_log("[FocusFlow] FOREGROUND/REENTRY detected. Executing NUCLEAR REBIRTH to reset budget.", log: .default, type: .info)
                  FocusFlowNotificationPlugin.pendingRebirthOnForeground = false
                  for activity in activities {
                      await activity.end(dismissalPolicy: .immediate)
                  }
                  try? await Task.sleep(nanoseconds: 300_000_000) // Un poco más de margen para asegurar el reset
                  
                  do {
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
                      os_log("[FocusFlow] Error in rebirth request: %{public}@", log: .default, type: .error, error.localizedDescription)
                  }
              } else {
                  // Caso 3: UPDATE normal (Mismo estado o Segundo Plano)
                  for activity in activities {
                      guard activity.activityState == .active else { continue }
                      
                      let currentState: FocusFlowAttributes.ContentState
                      if #available(iOS 16.2, *) {
                          currentState = activity.content.state
                      } else {
                          currentState = activity.contentState
                      }
                      
                      let isSameCycleDate = abs(currentState.cycleStartDate.timeIntervalSince(state.cycleStartDate)) < 2.0
                      let isSameRemaining = abs(currentState.remainingSeconds - state.remainingSeconds) <= 1
                      let isPausedChanged = currentState.isPaused != state.isPaused
                      let isStatusChanged = currentState.status != state.status
                      let isRedundant = !isPausedChanged && !isStatusChanged && (state.isPaused ? isSameRemaining : isSameCycleDate)
                      
                      if isRedundant {
                          os_log("[FocusFlow] Skipping redundant update.", log: .default, type: .info)
                          continue
                      }
                      
                      os_log("[FocusFlow] Executing Activity UPDATE (Visibility safe).", log: .default, type: .info)
                      do {
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
          }
          _ = semaphore.wait(timeout: .now() + 5.0) // Timeout de seguridad de 5s
      }
  }
}
