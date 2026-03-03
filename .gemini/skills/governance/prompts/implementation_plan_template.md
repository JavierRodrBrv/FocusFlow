# 📄 IMPLEMENTATION PLAN — [NOMBRE DE LA FEATURE]

> **Estado:** `BORRADOR` | `EN REVISIÓN` | `APROBADO`
> **Fecha:** YYYY-MM-DD
> **Solicitado por:** [Usuario / AMG]
> **Lead asignado:** [FLUTTER_LEAD / BACKEND_LEAD]

---

## [IP-1] Infraestructura Nativa

| Componente         | Versión requerida |
|--------------------|-------------------|
| Flutter SDK        |                   |
| Dart SDK           |                   |
| AGP                |                   |
| Gradle Wrapper     |                   |
| Kotlin             |                   |
| iOS Deployment Target |               |
| Xcode (mínimo)     |                   |

**Nuevas dependencias (`pubspec.yaml`):**
```yaml
# Ninguna / Listar aquí
```

**Acción UPGRADE_AGENT:** [Sí requiere sync Gradle/CocoaPods / No requiere]

---

## [IP-2] Scope

**Descripción funcional:**
> Qué hace exactamente esta feature desde el punto de vista del usuario.

**Features afectadas:**
- `lib/features/[feature_name]/`

**Fuera de scope (explícito):**
- Lista aquí lo que NO vamos a hacer en esta iteración para evitar scope creep.

---

## [IP-3] Arquitectura

**Estructura de carpetas a crear/modificar:**
```
lib/features/[feature_name]/
├── domain/
│   ├── entities/
│   ├── repositories/       ← Interfaces (abstract class)
│   └── usecases/
├── data/
│   ├── models/             ← Mappers desde/hacia la fuente de datos
│   └── repositories/       ← Implementaciones concretas
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

**Diagrama de dependencias:**
```
UI (Bloc events) → BLoC → UseCase → IRepository ← RepositoryImpl → DataSource
```

**Archivos existentes que se modifican:**
- [ ] `injection.dart` (registro DI)
- [ ] Otro: ___

---

## [IP-4] Interfaces Definidas

```dart
// Repository
abstract class I[Feature]Repository {
  // Listar métodos con tipos de retorno
}

// UseCases
abstract class I[UseCase]UseCase {
  // Listar call() con parámetros y tipo de retorno
}
```

---

## [IP-5] Inyección de Dependencias

**Estrategia:** `get_it` + `injectable`

```dart
// Registros nuevos en injection.dart / @injectable
@lazySingleton
class [Feature]RepositoryImpl implements I[Feature]Repository { ... }
```

> ⚠️ Recordar ejecutar: `dart run build_runner build --delete-conflicting-outputs`

---

## [IP-6] Seguridad

**Backend afectado:** `Hive` / `Firebase` / `Supabase` / Ninguno

- **RLS / Security Rules afectadas:** [Ninguna / Describir cambios]
- **Datos sensibles:** [Ninguno / Describir qué datos y cómo se encriptan]
- **Permisos de plataforma nuevos** (`AndroidManifest.xml` / `Info.plist`): [Ninguno / Listar]

---

## [IP-7] Performance & Cost

- **Isolates:** [No aplica / Describir qué operación va en Isolate secundario]
- **Queries / Lecturas de BD:** [Ninguna / Describir con índices y límite de paginación]
- **RepaintBoundary:** [No aplica / Describir dónde se añade]
- **Impacto en Cold Start estimado:** [Ninguno / Bajo / Medio]

---

## [IP-8] Testing Strategy

| Tipo de test       | Qué cubre                          | Archivo                          |
|--------------------|------------------------------------|----------------------------------|
| Unit (UseCase)     | Lógica de negocio del UseCase      | `test/features/.../usecase_test.dart` |
| Unit (Bloc)        | Estados y eventos del BLoC         | `test/features/.../bloc_test.dart`    |
| Widget             | Renderizado del componente crítico | `test/features/.../widget_test.dart`  |
| Integration        | Flujo completo E2E                 | `integration_test/...`           |

**Cobertura mínima objetivo:** 85%
**Mocks necesarios:** [Listar interfaces a mockear con Mockito/Mocktail]

---

## ✅ Aprobación

- [ ] **AMG** valida Arquitectura + Coste + Performance
- [ ] **Usuario** aprueba Scope
- [ ] **UPGRADE_AGENT** confirma entorno compilable antes de iniciar implementación
