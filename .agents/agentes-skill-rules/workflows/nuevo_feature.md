---
description: "Orquesta el ciclo Kiro-Flow para nuevas funcionalidades: genera automáticamente requerimientos EARS, diseño de arquitectura Clean y desglose de tareas técnicas antes de la implementación."
---

# Workflow: Inicialización de Feature (Kiro-Flow 2.0)

## 📋 Descripción
Automatiza la fase de especificación y diseño para nuevas funcionalidades de Flutter, garantizando la creación de la "Única Fuente de Verdad" (SSoT) en `/docs/specs/` antes de la implementación física.

## 🛠️ Activación
Se activa mediante el comando: `/new-feature [nombre_del_feature]` o mediante solicitud directa al **AMG**.

## 🔄 Pasos del Workflow

### 1. Fase de Requerimientos (@DOCS_AGENT)
- **Acción**: Entrevistar al Arquitecto (usuario) sobre el alcance.
- **Entregable**: Crear `docs/specs/requirements.md`.
- **Formato**: Notación EARS (Easy Approach to Requirements Syntax).
- **Check**: Debe incluir Criterios de Aceptación (AC) claros.

### 2. Diseño de Arquitectura (@CORE_AGENT)
- **Acción**: Definir el contrato de negocio y el modelo de fallos.
- **Entregable**: Crear `docs/specs/design.md`.
- **Contenido Obligatorio**:
  - Definición de `Entities` inmutables.
  - Contratos de `Repositories` (interfaces).
  - Modelado de `Failures` específicos para esta feature.
  - Diagrama Mermaid de flujo de datos.

### 3. Orquestación de Tareas (@MANAGER_AGENT)
- **Acción**: Desglosar el diseño técnico en pasos atómicos.
- **Entregable**: Crear `docs/specs/tasks.md`.
- **Estructura**: Dividir por capas (Domain -> Data -> Presentation -> Test).
- **Gobernanza**: Generar el `Implementation Plan` en el Manager para aprobación del Arquitecto.

### 4. Punto de Control (Gatekeeper)
- **Acción**: El **FLUTTER_LEAD** revisa la coherencia entre los tres documentos.
- **Veredicto**: Emite `READY FOR IMPLEMENTATION` o solicita correcciones.

## ⚖️ Reglas de Oro del Workflow
1. **SSoT**: Los archivos en `/docs/specs/` son inmutables durante la ejecución de tareas; cualquier cambio de alcance requiere actualizar la spec primero.
2. **No Implementation**: Prohibido crear archivos en `/lib` o `/test` hasta que este workflow finalice con el veredicto del Lead.