#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

// Helper for more complex motion
mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution.xy;
    float ratio = uResolution.x / uResolution.y;
    
    // Slow down the base time for a more relaxing feel
    float t = uTime * 0.15;
    
    // Dynamic coordinates
    vec2 p = uv * 2.0 - 1.0;
    p.x *= ratio;
    
    // Layered noise-like motion (Plasma effect)
    // We increase iterations and add rotation for a more "infinite" and less repetitive feel
    for(int i = 1; i < 6; i++) {
        float fi = float(i);
        p = p * rotate2D(t * 0.05 + fi); // Slow rotation per layer
        p.x += 0.4 / fi * sin(fi * 2.5 * p.y + t + 0.5 * fi);
        p.y += 0.4 / fi * sin(fi * 2.5 * p.x + t + 0.8 * fi);
    }
    
    // Colors based on the app's palette
    vec3 color1 = vec3(0.05, 0.08, 0.15); // #0F172A (Base)
    vec3 color2 = vec3(0.35, 0.15, 0.65); // Deep Purple
    vec3 color3 = vec3(0.15, 0.45, 0.95); // Blue Accent
    vec3 color4 = vec3(0.08, 0.12, 0.25); // Mid-tone Slate
    
    // Complex color mixing
    float dist = length(p) * 0.5;
    float m1 = 0.5 + 0.5 * sin(p.x + t * 0.5);
    float m2 = 0.5 + 0.5 * cos(p.y - t * 0.3);
    
    vec3 baseMix = mix(color1, color4, m1);
    vec3 accentMix = mix(color2, color3, m2);
    
    // Final composite
    vec3 finalColor = mix(baseMix, accentMix, 0.4);
    
    // Add a subtle vignette to keep the center clear for the timer
    float vignette = smoothstep(1.5, 0.5, dist / ratio);
    finalColor *= (0.7 + 0.3 * vignette);
    
    fragColor = vec4(finalColor * 0.5, 1.0); 
}
