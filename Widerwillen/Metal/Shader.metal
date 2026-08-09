//
//  Shader.metal
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 staticArenaBackground(
    float2 position,
    float2 size,
    float time,
    float glowIntensity,
    float accentRed,
    float accentGreen,
    float accentBlue
) {
    float2 uv = position / max(size, float2(1.0));
    float pulse = 0.92 + 0.08 * sin(time * 0.55);
    float3 accent = float3(accentRed, accentGreen, accentBlue);
    float3 secondaryAccent = mix(accent, float3(0.02, 0.72, 1.0), 0.35);

    float topFade = smoothstep(0.0, 1.0, 1.0 - uv.y);
    float centerGlow = 1.0 - smoothstep(0.0, 0.82, distance(uv, float2(0.5, 0.48)));
    float sideGlow = 1.0 - smoothstep(0.0, 0.72, distance(uv, float2(0.5, 0.18)));

    float3 color = mix(float3(0.002, 0.006, 0.018), accent * 0.08, topFade);
    color += accent * centerGlow * 0.14 * glowIntensity * pulse;
    color += secondaryAccent * sideGlow * 0.08 * glowIntensity * pulse;
    color = mix(color, float3(0.001, 0.003, 0.010), smoothstep(0.72, 1.0, uv.y) * 0.55);

    return half4(half3(color), 1.0);
}

[[ stitchable ]] half4 riverFloor(
    float2 position,
    float2 size,
    float time,
    float animationSpeed,
    float glowIntensity,
    float gridIntensity,
    float scanlineIntensity,
    float accentRed,
    float accentGreen,
    float accentBlue
) {
    float2 uv = position / max(size, float2(1.0));
    float t = time * animationSpeed;
    float3 accent = float3(accentRed, accentGreen, accentBlue);
    float3 secondaryAccent = mix(accent, float3(0.02, 0.72, 1.0), 0.38);
    float3 panelAccent = max(accent * 0.16, float3(0.003, 0.008, 0.018));
    float floorMask = smoothstep(0.0, 0.08, uv.y);
    float depth = smoothstep(0.0, 1.0, uv.y);
    float2 centered = float2((uv.x - 0.5) * 5.0, uv.y * 4.2);
    float isoX = centered.x + centered.y * 0.72;
    float isoY = centered.y * 1.12 - centered.x * 0.72 - t * 0.28;
    float2 gridPosition = float2(isoX, isoY);

    float2 grid = abs(fract(gridPosition - 0.5) - 0.5) / fwidth(gridPosition);
    float gridLine = 1.0 - saturate(min(grid.x, grid.y));
    float tileCenter = 1.0 - smoothstep(0.18, 0.48, max(abs(fract(gridPosition.x) - 0.5), abs(fract(gridPosition.y) - 0.5)));
    float pulse = 0.5 + 0.5 * sin(t * 4.0 + length(gridPosition) * 1.8);

    float dataFlow = (gridPosition.x + gridPosition.y) * 1.35 - t * 2.2;
    float broadWave = pow(0.5 + 0.5 * sin(dataFlow), 5.0);
    float thinWave = pow(0.5 + 0.5 * sin(dataFlow * 2.35 + 1.3), 12.0);
    float scanWave = 1.0 - smoothstep(0.020, 0.085, abs(fract((uv.y + uv.x * 0.18) * 8.0 - t * 0.45) - 0.5));
    float circuitPulse = smoothstep(0.82, 1.0, sin(length(gridPosition) * 3.4 - t * 4.2) * 0.5 + 0.5);
    float columnSignal = step(0.92, fract(sin(floor((gridPosition.x + t * 0.6) * 8.0) * 91.731) * 437.21));
    columnSignal *= 1.0 - smoothstep(0.04, 0.18, abs(fract(gridPosition.y * 0.5 - t) - 0.5));

    float3 farPanel = mix(float3(0.004, 0.010, 0.030), panelAccent, 0.75);
    float3 nearPanel = mix(float3(0.010, 0.045, 0.095), accent * 0.28, 0.62);
    float3 gridColor = mix(secondaryAccent, accent, pulse);
    float3 dataColor = mix(accent * 0.85, secondaryAccent + float3(0.12, 0.18, 0.22), uv.x);

    float3 color = mix(farPanel, nearPanel, depth);
    color += accent * tileCenter * 0.07 * glowIntensity;
    color += gridColor * gridLine * floorMask * 0.78 * gridIntensity;
    color += dataColor * broadWave * floorMask * 0.22 * glowIntensity;
    color += (accent + float3(0.25, 0.18, 0.22)) * thinWave * floorMask * 0.16 * glowIntensity;
    color += accent * scanWave * floorMask * 0.24 * scanlineIntensity;
    color += dataColor * circuitPulse * floorMask * 0.10 * glowIntensity;
    color += secondaryAccent * columnSignal * floorMask * 0.32 * glowIntensity;
    color = mix(color, float3(0.004, 0.008, 0.020), smoothstep(0.0, 0.16, uv.y) * 0.08);

    return half4(half3(color), 1.0);
}
