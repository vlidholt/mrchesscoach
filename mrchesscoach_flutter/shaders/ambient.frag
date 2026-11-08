#version 460 core

// The room the game is played in: a dark lacquered surface lit by a single
// warm lamp, with slow volumetric light shafts and a soft vignette.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
// Where the lamp hangs, in 0..1 of the canvas.
uniform vec2 uLight;
// 0..1: how strongly the shafts glow (pulses on big moments).
uniform float uIntensity;
// Tint of the light, e.g. gold, or red after a blunder.
uniform vec3 uTint;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  vec2 l = vec2(uLight.x * aspect, uLight.y);
  vec2 d = p - l;
  float dist = length(d);
  float ang = atan(d.y, d.x);
  float t = uTime;

  // Integer angular frequencies keep the shafts seamless around the lamp.
  float r = 0.5 + 0.5 * sin(7.0 * ang + 1.7 * sin(3.0 * ang + t * 0.21) + t * 0.13);
  r *= 0.55 + 0.45 * sin(11.0 * ang - t * 0.17 + 1.3 * sin(2.0 * ang - t * 0.11));
  r += 0.35 * pow(0.5 + 0.5 * sin(19.0 * ang + t * 0.29), 6.0);
  r = pow(clamp(r, 0.0, 1.5), 2.2);
  float shafts = r * smoothstep(1.5, 0.08, dist) * smoothstep(0.0, 0.22, dist);
  // Shafts mostly fall downwards, away from the lamp.
  shafts *= smoothstep(-0.4, 0.6, d.y / max(dist, 0.001));

  float glow = exp(-dist * dist * 2.4);
  float core = exp(-dist * dist * 14.0);

  vec3 base = vec3(0.043, 0.039, 0.035);
  vec3 warm = mix(vec3(0.17, 0.14, 0.10), uTint * 0.22, 0.35);
  vec3 col = base;
  col += warm * glow * 1.15;
  col += uTint * core * 0.05;
  col += uTint * shafts * (0.07 + 0.10 * uIntensity);

  // Vignette.
  float v = smoothstep(1.2, 0.3, length((uv - 0.5) * vec2(1.15, 1.0)) * 1.35);
  col *= mix(0.5, 1.0, v);

  // Static film grain.
  col += (hash(floor(frag)) - 0.5) * 0.022;

  fragColor = vec4(col, 1.0);
}
