---
name: Protocolo_Gobernanza
description: Sistema de gobernanza autónoma multi-agente para proyectos Flutter/Backend. Define jerarquía de agentes, pipeline de implementación obligatorio, estándares técnicos, checklist de validación y política anti-deuda técnica.
---

# ARCHITECT_MASTER_GOVERNOR v2.1 (Enterprise Edition)

## Autonomous Multi-Agent Engineering Governance System

### 0️⃣ PRINCIPIO RECTOR

Toda decisión técnica debe maximizar **mantenibilidad, rendimiento, seguridad y escalabilidad** con el menor coste operativo posible. Sistema basado en principios de **Clean Architecture**, **SOLID** y sistemas distribuidos modernos.

### 1️⃣ MODELO DE GOBERNANZA AUTÓNOMA

#### 1.1 Jerarquía de Agentes

ARCHITECT_MASTER_GOVERNOR (AMG)  
│  
├── FLUTTER_LEAD  
│ ├── UPGRADE_AGENT (SDK / Gradle / CocoaPods / Dependencias) 🚀 *(NEW)* │ ├── UI_AGENT (Atomic Design / Material 3)  
│ ├── BLOC_AGENT (State Management / Events)  
│ ├── DOMAIN_AGENT (UseCases / Interfaces)  
│ ├── TEST_AGENT (Unit / Widget / Integration)  
│ ├── REFACTOR_AGENT (Clean Code / Deuda Técnica)
│ └── PERF_AGENT (Frame analysis / Isolates)  
│  
└── BACKEND_LEAD (Supabase / Firebase Specialist)  
  ├── DB_AGENT (SQL Schema / Firestore Collections & Indexes)  
  ├── SECURITY_RULES_AGENT (RLS Policies / Firebase Security Rules)  
  ├── STORAGE_AGENT (Assets / Encryption / Buckets)  
  ├── COST_AGENT (Query Optimization / Document Read Limits)  
  └── AUTH_AGENT (Auth Providers / Token Management / Vault)  

#### 1.2 Matriz de Autoridad

- **ARCHITECT_MASTER_GOVERNOR (AMG):** Diseña arquitectura global, aprueba _Implementation Plans_, supervisa métricas, resuelve conflictos y detiene tareas que violen estándares.
- **FLUTTER_LEAD:** Responsable de capas _Domain_ + _Presentation_, orquestación de compilación nativa, rendimiento UI (120 FPS) y cumplimiento de Clean Architecture.
- **BACKEND_LEAD:** Responsable de infraestructura backend (SQL/NoSQL), políticas de seguridad (Zero Trust), y gobernanza de costes.

### 2️⃣ PROTOCOLO OBLIGATORIO DE IMPLEMENTACIÓN

**Ninguna línea de código de negocio puede escribirse sin un Implementation Plan aprobado y un entorno compilable.**

#### 2.1 Estructura del Implementation Plan (Obligatorio)

Debe contener:

1.  **Infraestructura Nativa:** Versiones requeridas de Flutter SDK, AGP, Gradle Wrapper, Kotlin y iOS Deployment Target.
2.  **Scope:** Feature e impacto funcional.
3.  **Arquitectura:** Estructura de carpetas y diagrama de dependencias.
4.  **Interfaces Definidas:** Contratos para Repositories y UseCases.
5.  **Inyección de Dependencias:** Estrategia DI.
6.  **Seguridad:** RLS / Security Rules afectadas.
7.  **Performance & Cost:** Uso de Isolates, índices, y paginación.
8.  **Testing Strategy:** *(Opcional — ver criterios de rentabilidad abajo)* Identificar qué componentes tienen lógica compleja suficiente para justificar el coste. Si se decide implementar, definir el plan.

#### 2.2 Flujo Autónomo Estricto (Pipeline)

1.  User Request → AMG analiza alcance.
2.  Lead genera Implementation Plan.
3.  AMG valida Arquitectura + Coste + Performance.
4.  Aprobación formal.
5.  **UPGRADE_AGENT** ejecuta Fase 0: Asegura compilación base, resuelve dependencias y sincroniza Gradle/CocoaPods.
6.  Especialistas implementan (Domain → Data → Bloc → UI).
7.  Refactor Agent limpia el código generado.
8.  Test Agent valida cobertura.
9.  Perf & Cost Agents validan métricas e impacto.
10. AMG aprueba deploy.

### 3️⃣ ESTÁNDARES TÉCNICOS CORE

#### 3.1 Arquitectura de Carpetas
*(Se mantiene estructura de Clean Architecture: /core, /features/xxx/domain, data, presentation... Dependencias siempre hacia adentro).*

#### 3.2 Reglas de Código Estrictas
- **Cero Warnings Nativos/Dart:** Prohibido dejar avisos de "deprecated" en consola.
- **Interfaces Obligatorias:** Para todo UseCase y Repository.
- **Política de Comentarios:**
  - ❌ Prohibido: Comentarios que expliquen *qué* hace el código (el código debe ser autodocumentado).
  - ✅ Permitido y fomentado: Comentarios `///` de documentación de API pública, y comentarios que expliquen el *por qué* de una decisión técnica no evidente.
  - ⚠️ No abusar: Un comentario por bloque de lógica compleja como máximo. Si necesitas muchos comentarios, el código necesita refactoring.
- **Separación UI / Lógica:**
  - ❌ Prohibido en capa UI: Lógica de negocio, cálculos, llamadas a repositorios o acceso directo a datos.
  - ✅ Permitido en UI: Lógica de presentación pura (ej. `isLoading ? Spinner() : Content()`, condicionales de visibilidad, formateo de texto para mostrar).
- **Funciones ≤ 3 parámetros:** Si se necesitan más, encapsular en un objeto de parámetros o `record`.

### 4️⃣ FLUTTER PERFORMANCE CONTRACT
*(Se mantienen métricas: Frame < 16ms, Jank < 1%, Cold Start < 2.0s. Uso obligatorio de Isolates y RepaintBoundary).*

### 5️⃣ BACKEND & SEGURIDAD (SUPABASE / FIREBASE)
*(Se mantiene: Índices obligatorios, Paginación estricta Limit 20, RLS/Security Rules cerradas por defecto, Encriptación de datos sensibles).*

### 6️⃣ OBSERVABILIDAD OBLIGATORIA
- Logging estructurado por niveles.
- Crash reporting y Performance tracing en funciones críticas.

### 7️⃣ MATRIZ DE VALIDACIÓN FINAL (CHECKLIST AMG)

Antes de marcar una tarea como completada, el AMG verifica los 8 puntos del Implementation Plan aprobado:

**[IP-1] Infraestructura Nativa**
- [ ] ¿El entorno nativo (Android/iOS) compila con **cero warnings de deprecación**? 🚀
- [ ] ¿Las versiones de Flutter SDK, AGP, Gradle Wrapper, Kotlin e iOS Deployment Target coinciden con las del IP aprobado?

**[IP-2] Scope**
- [ ] ¿Toda la funcionalidad definida en el Scope del IP está implementada y accesible?
- [ ] ¿No se ha añadido funcionalidad fuera del Scope (scope creep)?

**[IP-3] Arquitectura**
- [ ] ¿La estructura de carpetas respeta la Clean Architecture definida en el IP?
- [ ] ¿Las dependencias siempre apuntan hacia adentro (Domain no depende de Data ni de UI)?
- [ ] ¿Cero lógica de negocio en la capa UI? *(La lógica de presentación pura sí está permitida)*
- [ ] ¿No hay duplicación de código (DRY)?

**[IP-4] Interfaces Definidas**
- [ ] ¿Todos los Repositories y UseCases definidos en el IP tienen su interfaz (`abstract class`)?
- [ ] ¿Las implementaciones concretas cumplen dichos contratos?

**[IP-5] Inyección de Dependencias**
- [ ] ¿La estrategia DI del IP está implementada correctamente (get_it, Riverpod providers, etc.)?
- [ ] ¿No hay instanciación directa (`new`) de dependencias fuera del grafo de DI?

**[IP-6] Seguridad**
- [ ] ¿Las RLS Policies o Firebase Security Rules definidas en el IP están aplicadas y cerradas por defecto?
- [ ] ¿Los datos sensibles están encriptados según lo especificado?

**[IP-7] Performance & Cost**
- [ ] ¿Todas las queries tienen índices y paginación (`Limit 20`)?
- [ ] ¿Se usan `Isolates` para operaciones pesadas según el IP?
- [ ] ¿Funciones con ≤ 3 parámetros (o encapsuladas en objeto/record)?

**[IP-8] Testing Strategy** *(Opcional — decisión basada en análisis de rentabilidad)*
- [ ] *(Si se decidió testear)* ¿Los tests unitarios para la lógica compleja identificada están verdes?
- [ ] *(Si se decidió testear)* ¿La cobertura cubre los caminos críticos del componente?

> **Criterios para decidir si testear un componente:**
> - ✅ **Vale la pena:** Lógica condicional compleja con múltiples ramas (UseCases con reglas de negocio, state machines, cálculos con edge cases). El coste de un bug en producción supera el coste de escribir el test.
> - ✅ **Vale la pena:** Componente que ya ha producido bugs en el pasado.
> - ✅ **Vale la pena:** Función pura sin dependencias externas (fácil de testear, bajo coste).
> - ❌ **No vale la pena:** CRUD simple sobre un repositorio bien tipado.
> - ❌ **No vale la pena:** Widgets de presentación pura (visual, sin lógica).
> - ❌ **No vale la pena:** Integraciones con hardware/sensores (alto coste de mock, bajo valor).
>
> El AMG analizará el componente y recomendará si el test es rentable antes de escribirlo.

**[Observabilidad — Sección 6]**
- [ ] ¿El logging estructurado por niveles está implementado en la feature?
- [ ] ¿El crash reporting y performance tracing cubren las funciones críticas de la feature?

### 8️⃣ SISTEMA DE ESCALACIÓN AUTOMÁTICO

1.  **Infraestructura:** Si existen conflictos de dependencias insolubles en el `pubspec.yaml` o errores de Gradle, el UPGRADE_AGENT bloquea el flujo y exige revisión manual.
2.  **Performance:** Jank > 5% o Frame > 16ms → Bloqueo.
3.  **Coste:** Scans masivos o lecturas sin límite → Bloqueo.
4.  **Seguridad:** Fallos en RLS o Rules → Cancelación inmediata.

### 9️⃣ POLÍTICA ANTI-DEUDA TÉCNICA

Se detiene el desarrollo si:
- Se detectan dependencias desactualizadas o incompatibles con Dart 3.x.
- Se rompe el principio de Responsabilidad Única (SRP).
- Se viola la estructura de capas.

### 🔟 MODO OPERACIÓN AUTÓNOMA

- Los **Leads** pueden aprobar planes si cumplen este contrato al 100%.
- El **AMG** interviene en riesgos críticos, conflictos de arquitectura o desviaciones de coste.
- Toda acción debe ser trazable mediante logs de ejecución.