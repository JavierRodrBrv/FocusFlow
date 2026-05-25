---
trigger: always_on
---

# 🎨 FOCUSFLOW DESIGN SYSTEM & STYLE RULES (FLUTTER EDITION)

Este documento contiene las reglas de diseño y tokens visuales específicos de la aplicación FocusFlow.
TODO nuevo componente, pantalla o funcionalidad DEBE regirse estrictamente por esta paleta y estilo.

## 1. PALETA DE COLORES (COLOR TOKENS)
Para mantener la coherencia del modo oscuro elegante de la aplicación, utiliza únicamente estos colores:

- **Background Principal (Deep Slate):** `Color(0xFF0F172A)` (Slate 900)
  - *Uso:* Scaffold `backgroundColor`, fondos de pantallas principales (Dashboard, FocusBody), y fondos de modales a pantalla completa.
  
- **Superficies y Tarjetas (Surface Slate):** `Color(0xFF1E293B)` (Slate 800)
  - *Uso:* Fondos de Dialogs, BottomSheets, Cards, contenedores internos, Focus Bottom Bar y menús expansibles.

- **Acentos Primarios (Blue):**
  - **Blue 500:** `Color(0xFF3B82F6)`
  - **Blue 400:** `Color(0xFF60A5FA)`
  - *Uso:* Gráficos (Animated Bar Chart), botones de acción principal, estados activos.

- **Acentos Secundarios / Highlights:** `Colors.orangeAccent`
  - *Uso:* Indicadores de racha (streaks), notificaciones destacadas o elementos de gamificación.

- **Estados de Feedback:**
  - **Error/Destructivo:** `Color(0xFFEF5350)`
  - **Info/Acción Alternativa:** `Color(0xFF2979FF)`

- **Textos e Iconos:**
  - **Texto Principal:** `Colors.white`
  - **Texto Secundario:** `Colors.white70` o blanco con opacidad reducida.

## 2. REGLAS DE UI Y COMPOSICIÓN

- **Border Radius:** 
  - Usar bordes redondeados suaves. Estándar para tarjetas y botones: `BorderRadius.circular(16.0)` a `BorderRadius.circular(30.0)` dependiendo del tamaño del contenedor. Modales grandes suelen llevar bordes redondeados solo en las esquinas superiores.
  
- **Sombras y Profundidad (Glass/Glow):**
  - La aplicación hace un fuerte uso de elevación mediante `BoxShadow` con opacidades sutiles y colores oscuros (`Colors.black26`) para destacar las superficies (ej. Slate 800 sobre Slate 900).
  - Efectos visuales de "glow" (resplandor) en botones interactivos.

- **Transiciones y Difuminación (Fading):**
  - Las listas y cuerpos desplazables (scroll) deben integrar efectos de difuminación (`ShaderMask` con `LinearGradient`) para que el contenido se desvanezca elegantemente antes de tocar los bordes o barras de navegación.

- **Consistencia Zero-Hardcode:**
  - Prohibido introducir colores ajenos a esta paleta (nada de `Colors.green`, o rojos estándar, a menos que sean los definidos arriba).
  - Todo nuevo componente debe usar estos valores. En el futuro, todos estos colores literales deberán migrarse a un `AppTheme` / `AppColors` centralizado, pero hasta que se complete esa migración, se deben usar obligatoriamente estos exactos códigos hexadecimales para preservar la estética.
