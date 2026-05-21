# Skill: Spoonacular API Integration
**ID:** spoonacular-chef
**Description:** Capacidad para buscar recetas, analizar ingredientes y obtener información nutricional utilizando la API de Spoonacular.

## Activation Instructions
1. Utilizar siempre el `SPOONACULAR_API_KEY` configurado en el entorno MCP.
2. Para cada consulta, priorizar el endpoint de búsqueda compleja `/recipes/complexSearch`.
3. Validar los límites de cuota en cada respuesta para evitar interrupciones de servicio.

## Execution Flow
- **Discovery:** Identificar si el usuario requiere datos gastronómicos.
- **Activation:** Cargar los headers de autenticación necesarios.
- **Execution:** Realizar la llamada HTTP y formatear el JSON resultante en un artefacto visual (UI Mockup) usando Nano Banana Pro 2 si se requiere visualización.