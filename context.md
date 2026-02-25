# ROL: SENIOR FLUTTER ARCHITECT & TECH LEAD

ESTÁS EN MODO: [ANÁLISIS DE PROYECTO Y ASISTENCIA TÉCNICA]

1. Arquitectura General
   El proyecto sigue los principios de Clean Architecture, dividiendo el código en capas claras (Presentation,
   Domain, Data) por cada funcionalidad (features/focus_mode, features/premium, etc.) y utilizando un
   directorio core para utilidades compartidas y plugins.


- Inyección de Dependencias (DI): Se utiliza el paquete get_it junto con injectable para la resolución de
  dependencias. La configuración principal se genera en lib/app/injection.config.dart y se inicializa
  mediante la función configureDependencies() en lib/app/injection.dart.
- Estructura de Directorios:
    - lib/app/: Configuración global, inyección y servicio de background.
    - lib/core/: Componentes comunes, manejo de errores, servicios de audio/háptica y plugins nativos
      personalizados (focus_flow_notification).
    - lib/features/: Módulos principales del negocio organizados por funcionalidad.
    - lib/bootstrap.dart: Archivo de arranque para inicializar Hive, anuncios, permisos y el Background
      Service antes de lanzar la app.

  ---


2. Gestión de Estado
   El estado principal del temporizador y la aplicación es manejado a través del patrón BLoC usando
   flutter_bloc.


- FocusBloc (`lib/features/focus_mode/presentation/bloc/focus_bloc.dart`): Es el cerebro de la UI. Recibe
  eventos (StartTimer, PauseTimer, SaveCurrentMix, etc.) y emite FocusState.
- FocusSessionManager: El FocusBloc no ejecuta la cuenta regresiva directamente, sino que delega la lógica
  del dominio al FocusSessionManager. El BLoC escucha un Stream de estado de este manager para reaccionar
  a los ticks del reloj y los cambios de fase (Focus/Break).
- Flujo de Datos UI ↔ Background: La UI no mantiene el temporizador en memoria principal si la app se
  cierra. El estado real vive en un Isolate de Background. La UI se comunica con este isolate enviando
  comandos vía FlutterBackgroundService().invoke('sendEvent', ...) y recibe el estado actualizado
  escuchando el canal update.

  ---

3. Integraciones Nativas (iOS)
   La integración con el ecosistema iOS se centra en Live Activities y la Dynamic Island, ofreciendo soporte
   interactivo en iOS 17+.


- Live Activity (`FocusFlowLiveActivity.swift`): Define la interfaz de usuario para la pantalla de bloqueo
  y la Dynamic Island usando WidgetKit y ActivityKit. Recibe datos estáticos (como tiempos objetivo y
  estados) definidos en FocusFlowAttributes.
- Actualización desde Dart: Dart se comunica con iOS mediante un MethodChannel
  (com.example.focus_flow/notification). Se utilizan los métodos updateLiveActivity y endLiveActivity
  pasándole fechas absolutas (targetEndTime, startDate). La vista nativa interpola el progreso, evitando
  que Dart tenga que enviar un ping cada segundo.
- Interacciones (AppIntents): Para permitir botones de Pausa/Play en la Live Activity (iOS 17+), se usan
  AppIntents (PauseIntent, ResumeIntent, StopIntent). Como las Live Activities no pueden ejecutar código
  principal directamente, estos Intents emiten Darwin Notifications (CFNotificationCenterPostNotification
  con nombres como com.andaluzcode.focusflow.pause). El plugin nativo intercepta estas notificaciones en
  Swift/Objective-C y las reenvía al Isolate de Dart mediante el MethodChannel (onNotificationAction).
- Actualizaciones Optimistas (Crucial): Los AppIntents (Play/Pause) actualizan la UI nativa al instante recalculando matemáticamente el startDate y targetEndDate. Para que iOS no congele la Isla Dinámica, la actualización nativa en Swift SIEMPRE se hace usando ActivityContent(state: state, staleDate: nil) en iOS 16.2+.
  ---


4. Integraciones Nativas (Android)
   El comportamiento en segundo plano para Android se apoya en un servicio Foreground para mantener el
   temporizador vivo y mostrar notificaciones persistentes.


- FlutterBackgroundService (`lib/app/background_service.dart`): Al arrancar la app, se invoca
  initializeService(). Esto lanza la función onStart en un nuevo Isolate independiente de Dart.
- Isolate Independiente: En onStart(), la app vuelve a inicializar Hive y el árbol de dependencias (getIt)
  porque la memoria no se comparte con el Isolate de la UI.
- Notificaciones: El Isolate instancia su propio FocusBloc y reacciona al Stream de estados. Cada vez que
  hay un cambio relevante (o cada segundo en Android para suavidad), llama al método updateNotification
  del MethodChannel para actualizar el texto y título de la notificación Foreground del sistema operativo.
- Botones de la Notificación: Los botones en la notificación de Android se procesan de manera similar a
  iOS; el plugin envía una llamada a onNotificationAction ('PAUSE_ACTION', etc.) directamente al
  MethodCallHandler registrado en el Background Isolate, actualizando el FocusBloc subyacente.

  ---


5. Almacenamiento Local
   Se utiliza Hive como la base de datos persistente de clave-valor.


- Inicialización: Hive se inicializa mediante Hive.initFlutter() tanto en el Isolate de la UI
  (bootstrap.dart) como en el Isolate del Background (background_service.dart).
- Adaptadores: Se han registrado adaptadores de tipos personalizados (TypeAdapters):
    - 0: PremiumStatusAdapter (Modelos relacionados a suscripciones/compras).
    - 1: SoundMixModelAdapter (Modelos para las mezclas de ruido blanco/lluvia guardadas por el usuario).
- Cajas (Boxes): Se accede a cajas específicas a través de repositorios en la capa de datos para guardar
  configuración de usuario, historial de mezclas (savedMixes, lastActivatedMixId) y estado premium.

  ---


6. Reglas de Oro del Proyecto
   Estas son directrices estrictas basadas en el comportamiento actual del código que no deben romperse ni
   alterarse:


1. Flutter es la única fuente de la verdad para el temporizador: Ni iOS ni Android calculan el tiempo
   final por su cuenta para cambiar de fase. El Isolate de Background en Dart corre el BLoC y decide
   cuándo termina un Pomodoro, notificando al sistema nativo para que actualice su interfaz o finalice la
   actividad.
2. Doble Inicialización Obligatoria: Cualquier servicio base (GetIt, Hive, plugins globales) DEBE
   inicializarse dos veces: una en el main() / bootstrap() para la UI, y otra obligatoria dentro de la
   función onStart() del flutter_background_service.
3. Optimización de Live Activities en iOS: Dart NO debe enviar actualizaciones a la Live Activity de iOS
   cada segundo. Debe enviar una fecha de finalización (targetEndTime) usando el método updateLiveActivity
   y dejar que el sistema operativo la cuente regresivamente. Dart solo envía actualizaciones cuando el
   estado cambia drásticamente (Pausa, Resume, Skip o Finalización).
4. Isolate Communication vía Eventos: La UI de Flutter NUNCA modifica la base de datos de temporizadores
   directamente. Usa FlutterBackgroundService().invoke('sendEvent', {...}) para mandar acciones
   (startTimer, pauseTimer) al Isolate que corre en segundo plano.
5. Reproducción de Sonido Independiente: El manejo de volumen (lluvia, fuego, ruido marrón) se persiste
   como parte de los "Mixes" y su ciclo de vida va de la mano con el Pomodoro (se pausan automáticamente
   cuando termina el temporizador para no superponerse con las alarmas).
6. No bloquear el eco en Dart (Sincronización Absoluta): Aunque iOS haga actualizaciones optimistas, el servicio de Dart SIEMPRE debe responder forzando una actualización a iOS (_forceNextUpdate = true) cuando recibe una acción (PAUSE_ACTION, PLAY_ACTION). Esto garantiza que si Dart estaba suspendido en segundo plano, sobrescriba el estado de la Live Activity con su reloj interno al despertar, evitando desincronizaciones.
