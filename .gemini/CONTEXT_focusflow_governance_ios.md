# FocusFlow — Contexto de sesión de trabajo

> Generado el 2026-03-04. Para el agente que abra este proyecto: lee este archivo para tener contexto completo de las decisiones arquitectónicas tomadas.

---

## Estado del proyecto

### Checklist AMG — Todo resuelto ✅

| Punto | Estado |
|---|---|
| [IP-1] Infraestructura Nativa compila | ✅ |
| [IP-2] Scope sin creep | ✅ |
| [IP-3] Clean Architecture — `FocusView` sin lógica de negocio | ✅ |
| [IP-4] Interfaces en UseCases y Repos | ✅ |
| [IP-5] DI sin instanciación directa | ✅ |
| [IP-6] Seguridad | ✅ N/A |
| [IP-7] Hive patrón `_withBox` | ✅ |
| [IP-8] Tests | ✅ (14/14 pasando) |
| Logging (`print` → `debugPrint`) | ✅ |

---

## Cambios arquitectónicos realizados

### 1. Interfaces creadas
- `IProcessSessionUseCase` → `lib/features/focus_mode/domain/usecases/i_process_session_usecase.dart`
- `ISoundMixRepository` → renombrado en `lib/features/focus_mode/domain/repositories/sound_mix_repository.dart`
- `TimerBloc` ahora depende de `IProcessSessionUseCase` (inyectable/mockeable)

### 2. FocusCoordinatorService — Nuevo servicio
- Archivo: `lib/features/focus_mode/domain/services/focus_coordinator_service.dart`
- Motivo: extraer `_handleDeepLink` y `_checkConsent` de `FocusView` (violación IP-3)
- Registrado como `@lazySingleton` en `injection.dart`
- `FlutterBackgroundService` y `AdConsentManager` registrados como singletons externos en `injection.dart`

### 3. SoundMixRepositoryImpl
- Aplicado patrón `_withBox` para seguridad cross-isolate en todas las operaciones Hive
- `print()` → `debugPrint()`

### 4. Tests unitarios
- `test/features/focus_mode/domain/usecases/process_session_usecase_test.dart` — 9 tests
- `test/features/focus_mode/presentation/bloc/timer_bloc_test.dart` — 6 tests
- Dependencias: `mocktail`, `bloc_test` en `dev_dependencies`

---

## Arquitectura iOS — Live Activity / Dynamic Island

### Cómo funciona el sistema
```
ISOLATE PRINCIPAL (UI)              BACKGROUND ISOLATE
───────────────────────             ────────────────────
FocusView                           background_service.dart (onStart)
FocusCoordinatorService               TimerBloc
                                      AudioMixBloc
    ↕ FlutterBackgroundService ↕      SettingsBloc
    (invoke/on via JSON IPC)          FocusSessionManager
```

### Bugs de iOS Live Activity corregidos

**Bug 1 — `staleDate: nil` en Swift (causa raíz del congelamiento original)**
- Archivo: `lib/core/plugins/focus_flow_notification/ios/Classes/FocusFlowNotificationPlugin.swift`
- Con `nil`, iOS asignaba ~8 min de vida por defecto. Al expirar, la Live Activity congelaba y rechazaba todos los updates silenciosamente.
- Fix: `staleDate = targetEndDate + 60s` (o `Date.distantFuture` si está pausado)

**Bug 2 — Darwin observers duplicados (causa raíz del fallo tras ~5 interacciones)**
- `CFNotificationCenterRemoveObserver(center, nil, ...)` con `observer=nil` → **NO hace nada** (documentado por Apple)
- Sin el flag `darwinObserversRegistered`, cada apertura de app desde el DI añadía un nuevo observer
- Con 5 aperturas: 5 observers × N channels = decenas de `PauseTimer()` simultáneos → estado corrompido
- Fix: flag `darwinObserversRegistered = false` en `FocusFlowNotificationPlugin`

**Bug 3 — Bootstrap reiniciaba el background service en cada apertura**
- `bootstrap()` siempre llamaba `initializeService()` sin comprobar si ya estaba corriendo
- Al reiniciar: `TimerBloc` emitía `PomodoroStatus.initial` → `endLiveActivity` se disparaba → Live Activity muerta
- Fix en `bootstrap.dart`: `if (!isAlreadyRunning) { await initializeService(); }`

**Bug 4 — `targetEndDate` incorrecto cuando está pausado**
- Cuando pausado, se enviaba `targetEndDate = now + remainingTime` → SwiftUI continuaba contando aunque había terminado
- Fix: `isPaused ? Date.distantFuture : now + remainingTime`

**Bug 5 — `ui_heartbeat` no procesado**
- `FocusView` enviaba heartbeats cada 3s al background service pero no existía handler
- Fix en `background_service.dart`: `if (name == 'ui_heartbeat') { if (Platform.isIOS) forceNextUpdate = true; }`

---

## Archivos clave modificados

| Archivo | Cambio |
|---|---|
| `lib/app/bootstrap.dart` | Guard para no reiniciar background service si ya corre |
| `lib/app/background_service.dart` | Handlers `ui_heartbeat`/`ui_resumed`, iOS `targetEndDate` en pausa, Fix #1 revertido |
| `lib/app/injection.dart` | Pre-registro de `FlutterBackgroundService` y `AdConsentManager` |
| `lib/features/focus_mode/presentation/widgets/focus_view.dart` | Usa `FocusCoordinatorService`, eliminada lógica de negocio |
| `lib/features/focus_mode/domain/services/focus_coordinator_service.dart` | NUEVO — deep links y consent |
| `lib/features/focus_mode/domain/usecases/i_process_session_usecase.dart` | NUEVO — interfaz |
| `lib/features/focus_mode/domain/repositories/sound_mix_repository.dart` | Renombrado a `ISoundMixRepository` |
| `lib/features/focus_mode/data/repositories/sound_mix_repository_impl.dart` | `_withBox` pattern completo |
| `lib/core/plugins/focus_flow_notification/ios/Classes/FocusFlowNotificationPlugin.swift` | `staleDate`, `darwinObserversRegistered`, `os_log` |
| `.vscode/launch.json` | Configuraciones DEV/PRO con flavors |
| `.vscode/settings.json` | Copilot en español, Conventional Commits |

---

## Tests — Cómo ejecutarlos

```bash
# Todos los tests del proyecto
flutter test

# Solo los unitarios nuevos
flutter test test/features/focus_mode/

# Con output expandido
flutter test --reporter expanded
```

---

## Pendientes conocidos

- [ ] Verificar en dispositivo real que el fix de `darwinObserversRegistered` resuelve definitivamente el congelamiento del Dynamic Island
- [ ] Evaluar si los fixes de iOS aún no son suficientes → el siguiente paso sería usar AppGroups + UserDefaults para la comunicación botón→Flutter (más robusto que Darwin notifications)

---

## Referencia a conversación original

ID de conversación Windows: `746aa89e-1b89-4ce5-b73f-b08472f85052`
