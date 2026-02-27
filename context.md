# FocusFlow - Contexto de Desarrollo

## Objetivo General
Desarrollar y escalar FocusFlow, una aplicación de productividad (Pomodoro) estricta, visualmente inmersiva (estética cyberpunk/dark) y resistente, que penaliza distracciones físicas levantando el móvil. 

## Arquitectura y Reglas Clave
- **Clean Architecture:** Estricta separación en capas (Presentation -> Domain -> Data).
- **Gestión de Estado (UI):** `flutter_bloc` con estados inmutables (`copyWith`, `Equatable`).
- **Inyección de Dependencias:** `get_it` e `injectable`. *Obligatorio ejecutar `dart run build_runner build --delete-conflicting-outputs` tras modificar dependencias o modelos de base de datos.*
- **Servicio en Segundo Plano:** El temporizador principal y la lógica estricta (acelerómetro, audio) viven en un **Isolate secundario** gestionado por `flutter_background_service`.
- **Persistencia y Sincronización (Hive):** Los datos (Ajustes, Historial) se guardan en Hive. **Regla de Oro para el Historial:** Para evitar bloqueos de archivo y corrupción de caché entre la UI y el Background Isolate, el repositorio (`SessionHistoryRepositoryImpl`) debe abrir la caja, realizar la operación (CRUD) y cerrarla inmediatamente en la misma transacción (ver método `_withBox`). Al borrar, siempre usar `box.compact()`.

## Archivos Clave y Flujos
- **`FocusSessionManager`** (`lib/features/focus_mode/domain/usecases/focus_session_manager.dart`): El "Single Source of Truth" del temporizador. Vive en el Isolate secundario. Gestiona los cambios de estado del sensor y los castigos.
- **`FocusBloc`** (`lib/features/focus_mode/presentation/bloc/focus_bloc.dart`): Actúa como puente en el Isolate Principal (UI). Recibe actualizaciones del manager vía Event Bus, maneja la lógica de cuándo registrar una sesión en el historial (agrupación de ciclos, regla de >10 segundos) y notifica a la UI.
- **`SessionHistoryRepositoryImpl`**: Maneja el guardado transaccional de sesiones.
- **`SettingsMenuBottomSheet`**: Modal deslizante de múltiples vistas (Main, Fondo, Feedback) con alturas mínimas fijas (`minHeight: 480`) para evitar problemas de layout con el teclado.

## Estado Actual y Bugs Solucionados Hoy
1. **Historial de Ciclos (Agrupación):** Las sesiones de Foco y Descanso continuas ahora comparten un `groupId`. Se guardan todas automáticamente si el primer bloque de foco dura más de 10 segundos o se completa.
2. **Sincronización de Base de Datos (Hive):** Solucionado el bug crítico donde las sesiones eliminadas reaparecían, o las nuevas sesiones no se mostraban hasta reiniciar la app. Se logró aislando las transacciones de lectura/escritura en Hive.
3. **Modo Focus (Hardcore) Restricciones de Inicio:** El modo estricto ahora requiere físicamente voltear el móvil para iniciar el contador y empezar a registrar penalizaciones. Si se pulsa Play antes, muestra un `SnackBar` rojo eléctrico.
4. **Modo Inmersivo (Zoom):** Minimiza la interfaz para máxima concentración. Integrado correctamente en el widget `Showcase` de tutorial.
5. **Modernización de UI:** Actualización masiva de `withOpacity` a `withValues(alpha: X)` según las nuevas directrices de Flutter.

## Próximos Pasos (Mañana)
- [ ] A espera de instrucción del usuario. (Posibles caminos: Mejorar las métricas/gráficas del historial, añadir gamificación por evitar distracciones, o refinar animaciones del Modo Zoom).
