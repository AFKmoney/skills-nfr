// NFR / SRN analytic materials — zero textures. Patterns from NeonForge SRN Engine.
// Evaluate in world space `p`. All functions are continuous: zoom in and the detail is recomputed.

// Analytic "SIREN without a network": nested sinusoids give organic micro-detail.
float siren(vec3 p) {
  return sin(p.x * 7.1 + sin(p.y * 5.3)) * sin(p.y * 6.7 + sin(p.z * 4.9)) * sin(p.z * 8.3 + sin(p.x * 3.7));
}

// Height field for bump/normals: low + high frequency layers.
float sirenH(vec3 p) {
  return siren(p * 1.35) * 0.65 + sin(p.x * 23.0) * sin(p.y * 19.0) * sin(p.z * 21.0) * 0.15;
}

// Normal perturbation from the field's gradient (finite differences).
vec3 sirenNormal(vec3 p, vec3 n, float strength) {
  float e = 0.09;
  float h0 = sirenH(p);
  vec3 g = vec3(sirenH(p + vec3(e, 0.0, 0.0)) - h0,
                sirenH(p + vec3(0.0, e, 0.0)) - h0,
                sirenH(p + vec3(0.0, 0.0, e)) - h0) / e;
  return normalize(n - strength * (g - dot(g, n) * n));
}

// ABS plastic (LEGO-like): clean base colour, faint mould micro-detail, mid roughness.
void plastic(vec3 p, vec3 baseColor, out vec3 albedo, out float rough, out float metal) {
  float micro = siren(p * 3.0) * 0.5 + 0.5;
  albedo = baseColor * (0.94 + 0.06 * micro);
  rough = 0.38 + 0.08 * micro;
  metal = 0.0;
}

// Stud distance field (cylinder on top of a brick cell), for raymarched bricks.
float sdStud(vec3 p, float r, float h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Stratified rock.
vec3 strata(vec3 p, vec3 a, vec3 b) {
  float s = 0.5 + 0.5 * sin(p.y * 1.3 + siren(p * 0.5) * 2.2);
  return mix(a, b, s);
}

// Emissive lava veins (add to emission).
vec3 lavaVeins(vec3 p) {
  float vein = smoothstep(0.72, 0.95, sin(p.y * 2.6 + siren(p * 0.8) * 3.0));
  return vec3(1.0, 0.32, 0.05) * vein * 2.4;
}
