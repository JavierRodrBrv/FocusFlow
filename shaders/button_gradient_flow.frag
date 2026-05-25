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
    float t = uTime * 0.15;
    
    // Adjust coordinates
    vec2 p = uv * 2.0 - 1.0;
    p.x *= ratio;
    
    // Multi-layered plasma flow
    vec2 p_flow = p;
    for(int i = 1; i < 7; i++) {
        float fi = float(i);
        p_flow = p_flow * rotate2D(t * 0.04 + fi * 0.2);
        p_flow.x += 0.35 / fi * sin(fi * 2.2 * p_flow.y + t + 0.6 * fi);
        p_flow.y += 0.35 / fi * sin(fi * 2.2 * p_flow.x + t + 0.9 * fi);
    }
    
    // Deep & Rich Color Palette: Cyan, Blue, Deep Purple, and Pink (Darker for white text contrast)
    vec3 c1 = vec3(0.0, 0.592, 0.655);   // Darker Cyan (#0097A7)
    vec3 c2 = vec3(0.082, 0.396, 0.753); // Deep Blue (#1565C0)
    vec3 c3 = vec3(0.368, 0.208, 0.694); // Deep Purple (#5E35B1)
    vec3 c4 = vec3(0.761, 0.094, 0.357); // Deep Pink (#C2185B)
    
    // Create organic mixing based on coordinates and time
    float m1 = 0.5 + 0.5 * sin(p_flow.x + t);
    float m2 = 0.5 + 0.5 * cos(p_flow.y - t * 0.8);
    float m3 = 0.5 + 0.5 * sin(length(p_flow) - t * 0.5);
    
    // Mixing strategy for infinite transitions
    vec3 mixA = mix(c1, c2, m1);
    vec3 mixB = mix(c3, c4, m2);
    vec3 finalColor = mix(mixA, mixB, m3);
    
    // Scale down brightness slightly to ensure absolute readability with white text
    finalColor *= 0.75;
    
    fragColor = vec4(finalColor, 1.0); 
}
