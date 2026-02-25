# 🧠 FocusFlow

FocusFlow es una aplicación avanzada de temporizador Pomodoro construida con Flutter. A diferencia de los temporizadores convencionales, FocusFlow se integra profundamente con los sistemas nativos de iOS y Android para ofrecer una experiencia ininterrumpida, incluso cuando la aplicación está cerrada o el dispositivo está bloqueado.

## ✨ Características Principales

* **Sincronización Nativa Absoluta:** El temporizador sigue corriendo con precisión milimétrica en segundo plano gracias a un Isolate de Dart dedicado (`flutter_background_service`).
* **🍎 Soporte Premium para iOS (ActivityKit):**
    * Integración total con la **Dynamic Island** para ver el progreso de un vistazo.
    * **Live Activities** en la pantalla de bloqueo con controles interactivos (Play/Pause/Stop) nativos (iOS 17+), con actualizaciones optimistas sin abrir la app.
* **🤖 Soporte Nivel Sistema para Android:**
    * Uso de Foreground Services para mantener el sistema operativo informado y evitar que el temporizador sea destruido por el ahorro de batería.
    * Notificaciones enriquecidas e interactivas.
* **🎧 Mezclador de Sonidos Integrado:** Reproduce y guarda mezclas de ruido blanco, lluvia o fuego, gestionando el volumen de forma independiente.
* **Modo Hardcore (Penalty):** Sistema de castigos por distracciones (ej. voltear el móvil), apoyado por notificaciones locales nativas.

## 🛠 Arquitectura y Tecnologías

El proyecto sigue los principios de **Clean Architecture** y una gestión de estado predecible.

* **Framework:** Flutter (Dart)
* **Gestión de Estado:** BLoC (`flutter_bloc`)
* **Base de Datos Local:** Hive (con TypeAdapters personalizados)
* **Inyección de Dependencias:** GetIt + Injectable
* **Nativo iOS:** Swift, WidgetKit, ActivityKit, AppIntents (sin bloqueos de hilo principal).
* **Nativo Android:** Kotlin, Foreground Services, Notificaciones Locales.

## 🚀 Cómo ejecutar el proyecto

### Prerrequisitos
* Flutter SDK instalado (versión 3.38.6 o superior).
* Para probar las Live Activities de iOS, se recomienda encarecidamente un dispositivo físico con iOS 16.2+ (o el simulador de Xcode 15+).

### Instalación
1. Clona el repositorio:
   ```bash
   git clone [https://github.com/tu-usuario/focusflow.git](https://github.com/tu-usuario/focusflow.git)