#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

// Rotate 2D helper for dynamic motion
mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    float ratio = uResolution.x / uResolution.y;
    
    // Slow down time for a smooth, deep immersive experience
    float t = uTime * 0.12;
    
    // Adjust coordinates
    vec2 p = uv * 2.0 - 1.0;
    p.x *= ratio;
    
    // Multi-layered plasma flow for infinite immersion
    vec2 p_flow = p;
    for(int i = 1; i < 7; i++) {
        float fi = float(i);
        p_flow = p_flow * rotate2D(t * 0.04 + fi * 0.2);
        p_flow.x += 0.35 / fi * sin(fi * 2.2 * p_flow.y + t + 0.6 * fi);
        p_flow.y += 0.35 / fi * sin(fi * 2.2 * p_flow.x + t + 0.9 * fi);
    }
    
    // New Color Palette requested:
    // #00E5FF (Cyan Accent)
    // #2979FF (Blue Accent)
    // #7C4DFF (Deep Purple Accent)
    // #D500F9 (Purple Accent)
    vec3 c1 = vec3(0.0, 0.898, 1.0);   // #00E5FF
    vec3 c2 = vec3(0.161, 0.475, 1.0); // #2979FF
    vec3 c3 = vec3(0.486, 0.302, 1.0); // #7C4DFF
    vec3 c4 = vec3(0.835, 0.0, 0.976); // #D500F9
    
    // Create organic mixing based on coordinates and time
    float m1 = 0.5 + 0.5 * sin(p_flow.x + t);
    float m2 = 0.5 + 0.5 * cos(p_flow.y - t * 0.8);
    float m3 = 0.5 + 0.5 * sin(length(p_flow) - t * 0.5);
    
    // Deep mixing strategy for infinite transitions
    vec3 mixA = mix(c1, c2, m1);
    vec3 mixB = mix(c3, c4, m2);
    vec3 finalColor = mix(mixA, mixB, m3);
    
    // Subtle background darkness to maintain contrast with UI
    // We mix with a very dark slate to keep the immersive feeling without being too bright
    vec3 darkBase = vec3(0.02, 0.04, 0.08); // Near black slate
    finalColor = mix(darkBase, finalColor, 0.35); // 35% color intensity for elegance
    
    // Premium rectangular vignette that matches the screen borders perfectly
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    vignette = clamp(pow(16.0 * vignette, 0.25), 0.0, 1.0); // Smooth falloff to all edges
    finalColor *= (0.6 + 0.4 * vignette);
    
    fragColor = vec4(finalColor, 1.0); 
}
