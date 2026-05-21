---
trigger: always_on
---

# 🌌 PROTOCOLO MAESTRO: ECOSISTEMA ANTIGRAVITY 2.3 (FLUTTER EDITION)

Este documento rige el comportamiento de todos los agentes dentro del workspace. Ninguna instrucción individual de agente puede violar estos principios fundamentales. Para el detalle operativo, consultar el `Protocolo_Gobernanza.md`.

## 1. MODO OPERATIVO: "PLANNING-FIRST"
- **Regla de Oro:** Prohibido realizar cambios estructurales o masivos sin un `Implementation Plan` previo, excepto tareas `TRIVIAL` autorizadas por el `MANAGER_AGENT`.
- **Flujo Obligatorio:**
  1. Análisis de Contexto.
  2. Clasificación de complejidad (`MANAGER_AGENT`).
  3. Generación de Plan de Implementación (Task Groups) si es `MEDIUM` o `COMPLEX`.
  4. Validación del Arquitecto (Usuario).
  5. Ejecución por fases mediante especialistas específicos usando Handoffs Atómicos.

## 1.1 ARTEFACTOS DE ESPECIFICACIÓN (KIRO-FLOW)
- Todo nuevo feature `COMPLEX` DEBE iniciar con la generación de:
  - `requirements.md`: Alcance y reglas de negocio.
  - `design.md`: Contratos de Clean Architecture y Diagramas.
  - `tasks.md`: Checklist técnico de implementación.
- Estos archivos residen en la carpeta `/docs/specs/` y sirven como la "Única Fuente de Verdad" (SSoT).

## 2. JERARQUÍA Y DELEGACIÓN (AMG)
- El **AMG (Governor)** es la única autoridad para orquestar. El AMG **NUNCA** escribe código de implementación.
- La ejecución recae exclusivamente en los especialistas mediante `@mentions`.
- Si una tarea requiere múltiples capas, el AMG debe modularizarla en **Task Groups**.
- **Regla de Oro del Handoff (Zero-History):** Toda delegación a un especialista debe realizarse mediante un **Paquete de Handoff Atómico** que contenga solo: Tarea concreta, Archivos afectados, Contexto técnico mínimo, Template a utilizar y Restricción activa. Queda prohibido enviar el historial completo de la conversación.

## 3. ESTÁNDARES TÉCNICOS INNEGOCIABLES (FLUTTER 2026)
- **Arquitectura:** Clean Architecture estricta (Separación total de Domain, Data y Presentation).
- **Gestión de Errores:** Uso obligatorio de la mónada `Either<Failure, T>`. Prohibido el uso de `throw` o `try-catch` en capas superiores a DataSources.
- **Inmutabilidad:** Todas las entidades y estados deben ser inmutables (`equatable` o `freezed`).
- **Rendimiento:** Widgets con constructores `const` y uso de `RepaintBoundary` en listas complejas.
- **Slivers Obligatorios:** Toda lista o grid debe implementarse con `SliverList`, `SliverGrid` y `CustomScrollView`.
- **Inyección:** Uso de `GetIt` + `Injectable`. Prohibida la instanciación manual de clases dependientes.
- **Modularidad Optimizada:** Las funciones y métodos deben ser atómicos. **Máximo de 30-40 líneas** por bloque de código para evitar boilerplate innecesario. Si excede, debe refactorizarse en métodos privados.

## 4. GOBERNANZA DE INTEGRACIONES EXTERNAS (SPOONACULAR API)
- **Seguridad de Credenciales:** NUNCA imprimir la API Key completa en la consola, logs o archivos `.txt`. Referenciar siempre mediante la variable de entorno `${SPOONACULAR_API_KEY}`.
- **Estrategia de Consulta:** Para búsquedas en bases de datos de recetas extensas, es OBLIGATORIO activar el **Planning Mode** para estructurar los Task Groups de filtrado antes de la ejecución.
- **Enriquecimiento de Datos:** Toda respuesta de receta hacia el usuario debe incluir un resumen nutricional generado específicamente por el modelo de contexto **Gemini 2.5 Flash**.

## 5. PROTOCOLO DE COMUNICACIÓN Y MEMORIA
- **Idioma:** 100% Español.
- **Trazabilidad:** Cada cambio significativo debe ser registrado por el `DOCS_AGENT`.
- **Knowledge Items (KIs):** Antes de cada tarea, consultar los KIs del workspace para evitar redundancias o errores previos.
- **Memoria Automática:** El sistema aprende de forma autónoma de los errores corregidos (ver `DOCS_AGENT`).
- **Changes Sidebar:** Al finalizar una tarea, el agente ejecutor debe realizar un `Walkthrough` técnico explicando qué cambió y por qué.

## 6. ANTIPATRONES PROHIBIDOS
- **Pureza de BLoC:** Prohibido incluir lógica de negocio, filtrado, validación o transformación en el BLoC. El BLoC solo debe emitir estados basados en la respuesta del **UseCase**. Toda la lógica reside en el Domain.
- No mezclar lógica de negocio en la capa de UI.
- No realizar peticiones HTTP fuera del `DATA_AGENT`.
- No hardcodear estilos; usar siempre el `PRESENTATION_AGENT`.
- No aceptar código con cobertura de test inferior al 85%.
- **Navegación:** Queda prohibido el uso de `Navigator.push`. Toda navegación debe gestionarse exclusivamente mediante `GoRouter` (centralizado en `app_router.dart`).

## 7. ZERO-HARDCODE POLICY (ESTRICTO)
- **Textos e i18n:** Prohibido el uso de Strings literales en la UI. Todo texto DEBE ser gestionado a través de `S.of(context)` usando el paquete `intl`.
- **Sistema de Color:** Prohibido el uso de `Colors.xyz` o `Color(0xFF...)` directamente en los widgets. Se debe usar exclusivamente el `AppTheme` o `AppColors` definido en `/lib/shared/`.
- **Estilos de Texto:** Prohibido definir `TextStyle` locales. Se deben consumir del `AppTextStyles` en el directorio `shared`.
- **Fondo de Aplicación:** Se prohíben fondos planos (Pure Black #000 o Pure White #FFF). Se deben implementar gradientes vibrantes o superficies con elevación sutil para un look moderno.

## 8. ARQUITECTURA DE UI Y ESTRUCTURA DE DIRECTORIOS (ADDENDUM)
- **Atomic Design:** Los widgets deben clasificarse estrictamente en `Atoms`, `Molecules` u `Organisms`. Los componentes de UI de una feature residen en `lib/features/[feature_name]/presentation/widgets/`.
- **Jerarquía de Directorios:** El directorio `/lib/shared/` es de nivel superior (misma jerarquía que `/features/` o `/core/`) y contiene el `AppTheme`, fuentes y constantes globales.
- **Sistema de Templates:** Cada screen de una feature DEBE tener un subdirectorio `templates/` (ej: `lib/features/recipe_search/presentation/screens/search/templates/`) que defina la estructura visual (layout) separada de la screen principal. Además, el directorio `/templates/` contiene los moldes maestros (`.template`) gestionados por el `PRESENTATION_AGENT`.
- **Enrutamiento:** Uso obligatorio de `go_router`. Las rutas deben estar centralizadas en `lib/app/router/` y no dispersas en la UI.

---
"Soberanía técnica para el Arquitecto, autonomía avanzada para la Orquesta."