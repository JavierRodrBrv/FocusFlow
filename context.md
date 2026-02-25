# ROL: SENIOR FLUTTER ARCHITECT & TECH LEAD

ESTÁS EN MODO: [ANÁLISIS DE PROYECTO Y ASISTENCIA TÉCNICA]

## 1. Arquitectura General
El proyecto sigue los principios de **Clean Architecture**, dividiendo el código en capas claras (Presentation, Domain, Data) por cada funcionalidad (`features/focus_mode`, `features/premium`, etc.) y utilizando un directorio `core` para utilidades compartidas y plugins.

- **Inyección de Dependencias (DI):** Se utiliza `get_it` junto con `injectable`. La configuración principal se genera en `lib/app/injection.config.dart` y se inicializa mediante `configureDependencies()` en `lib/app/injection.dart`.
- **Estructura de Directorios:**
  - `lib/app/`: Configuración global, inyección y servicio de background (`flutter_background_service`).
  - `lib/core/`: Componentes comunes, manejo de errores, servicios de audio/háptica, notificaciones locales y plugins nativos personalizados (`focus_flow_notification`).
  - `lib/features/`: Módulos principales del negocio organizados por funcionalidad.
  - `lib/bootstrap.dart`: Archivo de arranque para inicializar Hive, anuncios, permisos, notificaciones locales y el Background Service antes de lanzar la app.

---

## 2. Gestión de Estado
El estado principal del temporizador y la aplicación es manejado a través del patrón **BLoC** usando `flutter_bloc`.

- **FocusBloc** (`lib/features/focus_mode/presentation/bloc/focus_bloc.dart`): Cerebro de la UI. Recibe eventos y emite `FocusState`.
- **FocusSessionManager**: El BLoC no ejecuta la cuenta regresiva directamente, delega la lógica del dominio a este manager. El BLoC escucha un Stream de estado de este manager para reaccionar a los ticks del reloj y los cambios de fase (Focus/Break/Penalty).
- **Flujo de Datos UI ↔ Background:** La UI no mantiene el temporizador en memoria principal si la app se cierra. El estado real vive en un **Isolate de Background**. La UI se comunica con este isolate enviando comandos vía `FlutterBackgroundService().invoke('sendEvent', ...)` y recibe el estado actualizado escuchando el canal `update`.

---

## 3. Integraciones Nativas (iOS & Android)
- **iOS (Live Activities):** Integración mediante WidgetKit y ActivityKit (`FocusFlowLiveActivity.swift`). Se actualiza enviando fechas absolutas (`targetEndTime`, `startDate`) desde Dart para que iOS interpole el progreso sin pings por segundo. Los botones nativos usan `AppIntents` que se comunican de vuelta a Dart.
- **Android (Foreground Service):** Se usa `flutter_background_service` para mantener vivo el temporizador en un Isolate independiente. El servicio actualiza una notificación persistente nativa personalizada. 
- **Notificaciones Locales (Dart):** Añadido `flutter_local_notifications` en `LocalNotificationService` para manejar avisos netamente informativos (Temporizador completado, advertencias de castigo en Hardcore mode, y recordatorios de 24 horas).

---

## 4. Almacenamiento Local
Se utiliza **Hive** como la base de datos persistente clave-valor.
- Requiere inicialización doble (`Hive.initFlutter()`): tanto en el Isolate de la UI (`bootstrap.dart`) como en el Isolate del Background (`background_service.dart`).
- Se usan `TypeAdapters` personalizados para guardar configuraciones de usuario, historiales de mezcla de sonidos y el estado premium.

---

## 5. Reglas de Oro del Proyecto (CRÍTICO)
1. **Flutter es la única fuente de la verdad para el temporizador:** El Isolate de Background en Dart corre el BLoC, decide cuándo termina un Pomodoro o cambia de fase, y notifica al sistema nativo para actualizar su UI.
2. **Doble Inicialización Obligatoria:** Servicios base (GetIt, Hive, LocalNotifications, plugins globales) DEBEN inicializarse dos veces: en el main/bootstrap para la UI, y dentro de `onStart()` de `flutter_background_service` para el background.
3. **Isolate Communication:** La UI NUNCA modifica el estado directamente. Usa `FlutterBackgroundService().invoke('sendEvent', {...})`.
4. **Optimización de Servicios de Background:**
   - **iOS:** Enviar actualizaciones de Live Activity solo en cambios drásticos de estado (Play/Pause/Skip), no cada segundo.
   - **Android:** Llamar a `setAsForegroundService()` o `setAsBackgroundService()` **únicamente** cuando hay transiciones reales entre inactividad y actividad, para evitar resetear el UI de la notificación nativa y perder el flag inamovible (`setOngoing`).
   - El estado "Castigo/Penalty" en Focus Mode en Android fuerza el envío del status `running` al plugin nativo para asegurar que la notificación no se oculte de la pantalla de bloqueo.
5. **Comportamiento de Pantalla de Bloqueo (Android):** La app ya NO usa `showWhenLocked` o `turnScreenOn` de forma agresiva. Se comporta como una app normal en background, confiando en su Foreground Notification.
6. **Sincronización AdMob:** Para evitar el error `The ad can not be shown when app is not in foreground` al mostrar Interstitials instantáneos tras un tap, usar `setImmersiveMode(true)` y envolver el `show()` en un pequeño `Future.delayed(100ms)`.

---

## 6. Registro de Cambios Recientes (Última Sesión)
- **Implementadas Notificaciones Locales (Dart-only):** Se añadió `LocalNotificationService` para avisos de fin de timer, recordatorio de 24h, y advertencias al voltear el móvil en modo Hardcore.
- **Arreglado Flujo de AdMob (Interstitial):** 
  - Manejo correcto del Spinner de carga en `SessionCompletionDialog`.
  - Agregado Test Device ID en `bootstrap.dart` para evitar "Error 3 (No Fill)" en desarrollo.
  - Corrección del crasheo por "App not in foreground" al mostrar el anuncio tras hacer tap rápido.
  - Se eliminó la restricción rígida de `canRequestAds` que bloqueaba la precarga del anuncio en background.
- **Correcciones UI/UX Android Nativo:**
  - Eliminado el agresivo "mostrar sobre pantalla de bloqueo" en el `AndroidManifest.xml` y `MainActivity.kt`.
  - La notificación nativa de Android ya no parpadea ni se pierde al voltear el dispositivo (entrar en penalty), gracias a la optimización de las llamadas al Foreground Service.
  - Eliminado el molesto texto por defecto "Iniciando..." del servicio en background.

## 7. Próximos Pasos (Siguiente Sesión)
*(Espacio reservado para definir la siguiente feature, bugfix o refactor de la próxima sesión)*.