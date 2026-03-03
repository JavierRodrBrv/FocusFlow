# 📄 IMPLEMENTATION PLAN — Feature: Gamificación por Evitar Distracciones

> **Estado:** `EJEMPLO DE REFERENCIA` *(No ejecutar — sirve como guía de nivel de detalle)*
> **Fecha:** 2026-03-03
> **Solicitado por:** Usuario
> **Lead asignado:** FLUTTER_LEAD

---

## [IP-1] Infraestructura Nativa

| Componente            | Versión requerida |
|-----------------------|-------------------|
| Flutter SDK           | ≥ 3.22.x          |
| Dart SDK              | ≥ 3.4.x           |
| AGP                   | 8.3.x             |
| Gradle Wrapper        | 8.6               |
| Kotlin                | 1.9.x             |
| iOS Deployment Target | 14.0              |
| Xcode (mínimo)        | 15.x              |

**Nuevas dependencias (`pubspec.yaml`):**
```yaml
# Ninguna nueva — se aprovecha Hive y flutter_bloc ya existentes
```

**Acción UPGRADE_AGENT:** No requiere sync adicional. Verificar compilación base antes de iniciar.

---

## [IP-2] Scope

**Descripción funcional:**
> El usuario acumula puntos ("FocusCoins") por cada sesión de foco completada sin distracciones.
> Los puntos se muestran en la pantalla de Historial como un badge de racha y en un contador total.
> Si el usuario levanta el móvil durante la sesión, pierde una cantidad proporcional de puntos.

**Features afectadas:**
- `lib/features/gamification/` ← Nueva feature
- `lib/features/focus_mode/domain/usecases/focus_session_manager.dart` ← Añadir hook de penalización
- `lib/features/history/presentation/` ← Añadir badge de racha en la UI del historial

**Fuera de scope (explícito):**
- No se implementan rankings ni comparativas sociales en esta iteración.
- No se implementa monetización ni canje de puntos.
- No se sincronizan puntos con backend remoto (solo Hive local).

---

## [IP-3] Arquitectura

**Estructura de carpetas a crear:**
```
lib/features/gamification/
├── domain/
│   ├── entities/
│   │   └── focus_streak.dart          ← Entidad: racha actual, puntos totales
│   ├── repositories/
│   │   └── i_gamification_repository.dart
│   └── usecases/
│       ├── add_points_use_case.dart
│       ├── deduct_points_use_case.dart
│       └── get_streak_use_case.dart
├── data/
│   ├── models/
│   │   └── focus_streak_model.dart    ← HiveObject mapper
│   └── repositories/
│       └── gamification_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── gamification_bloc.dart
    │   ├── gamification_event.dart
    │   └── gamification_state.dart
    └── widgets/
        ├── streak_badge_widget.dart   ← Badge de racha para Historial
        └── focus_coins_counter.dart   ← Contador animado de puntos
```

**Diagrama de dependencias:**
```
FocusBloc (penalización) → GamificationBloc → AddPointsUseCase
                                             → DeductPointsUseCase
                                             → IGamificationRepository
                                                      ↑
                                        GamificationRepositoryImpl → Hive Box
```

**Archivos existentes que se modifican:**
- [ ] `injection.dart` — Registrar `IGamificationRepository` y UseCases
- [ ] `focus_session_manager.dart` — Emitir evento de penalización al EventBus al detectar distracción
- [ ] `history_page.dart` — Inyectar `StreakBadgeWidget` en la cabecera

---

## [IP-4] Interfaces Definidas

```dart
// Repository
abstract class IGamificationRepository {
  Future<FocusStreak> getStreak();
  Future<void> addPoints(int amount);
  Future<void> deductPoints(int amount);
  Future<void> resetStreak();
}

// UseCases
abstract class IAddPointsUseCase {
  Future<void> call(int sessionDurationSeconds);
}

abstract class IDeductPointsUseCase {
  Future<void> call(int penaltyCount);
}

abstract class IGetStreakUseCase {
  Future<FocusStreak> call();
}
```

---

## [IP-5] Inyección de Dependencias

**Estrategia:** `get_it` + `injectable`

```dart
@lazySingleton
class GamificationRepositoryImpl implements IGamificationRepository { ... }

@injectable
class AddPointsUseCase implements IAddPointsUseCase { ... }

@injectable
class DeductPointsUseCase implements IDeductPointsUseCase { ... }
```

> ⚠️ Ejecutar tras cualquier cambio en anotaciones:
> `dart run build_runner build --delete-conflicting-outputs`

---

## [IP-6] Seguridad

**Backend afectado:** Hive (local, sin backend remoto en esta iteración)

- **RLS / Security Rules:** No aplica (datos 100% locales).
- **Datos sensibles:** No aplica. Los puntos son datos de gamificación no sensibles.
- **Permisos nuevos:** Ninguno. El acelerómetro ya está declarado en `AndroidManifest.xml`.
- **Hive — Regla de Oro:** Aplicar patrón `_withBox` (abrir → operar → cerrar) igual que en `SessionHistoryRepositoryImpl` para evitar corrupción de caché entre Isolates.

---

## [IP-7] Performance & Cost

- **Isolates:** Las escrituras en Hive desde `FocusSessionManager` (Isolate secundario) se hacen via EventBus hacia el Isolate Principal, que ejecuta el repositorio. No se escribe Hive directamente desde el Isolate secundario.
- **Queries / Lecturas:** Solo lectura de un único objeto `FocusStreak` de Hive. Sin paginación necesaria (1 registro por usuario).
- **RepaintBoundary:** Añadir en `StreakBadgeWidget` y `FocusCoinsCounter` ya que son widgets animados que no deben invalidar el árbol de la página completa.
- **Impacto en Cold Start estimado:** Bajo (una lectura Hive adicional al arrancar).

---

## [IP-8] Testing Strategy

| Tipo de test  | Qué cubre                                             | Archivo                                          |
|---------------|-------------------------------------------------------|--------------------------------------------------|
| Unit (UseCase)| `AddPointsUseCase` y `DeductPointsUseCase` con mock   | `test/features/gamification/usecases_test.dart`  |
| Unit (Bloc)   | Estados del `GamificationBloc` ante eventos           | `test/features/gamification/bloc_test.dart`      |
| Widget        | Renderizado de `StreakBadgeWidget` con distintos puntos| `test/features/gamification/streak_badge_test.dart` |
| Integration   | Flujo completo: sesión sin distracción → puntos suman | `integration_test/gamification_flow_test.dart`   |

**Cobertura mínima objetivo:** 85%

**Mocks necesarios:**
```dart
@GenerateMocks([IGamificationRepository])
```

---

## ✅ Aprobación

- [ ] **AMG** valida Arquitectura + Coste + Performance
- [ ] **Usuario** aprueba Scope
- [ ] **UPGRADE_AGENT** confirma compilación base limpia antes de iniciar
