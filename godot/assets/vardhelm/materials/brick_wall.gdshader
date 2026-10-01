shader_type spatial;

// C17 — tijolo com fuligem (ART-PROMPTS-TIER1: "sooty canvas bricks"). Coordenadas de
// mundo projetadas pela face (sem UV): funciona em caixas de qualquer tamanho do
// LevelBuilder. Fiadas desencontradas, argamassa escura, variação por tijolo e fuligem
// que aumenta com a altura.

uniform vec3 brick_color : source_color = vec3(0.29, 0.20, 0.157);
uniform vec3 brick_color_alt : source_color = vec3(0.23, 0.165, 0.13);
uniform vec3 mortar_color : source_color = vec3(0.12, 0.11, 0.10);
uniform vec3 soot_color : source_color = vec3(0.07, 0.068, 0.066);
uniform vec2 brick_size = vec2(0.56, 0.24);
uniform float mortar_width = 0.025;
uniform float soot_start = 1.4;
uniform float soot_height = 3.4;
uniform float roughness_value = 0.95;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	// Face vertical: a coordenada horizontal é a que corre ao longo da parede.
	vec2 p = n.x > n.z ? world_pos.zy : world_pos.xy;
	if (n.y > 0.7) {
		p = world_pos.xz;
	}
	vec2 cell = p / brick_size;
	float row = floor(cell.y);
	cell.x += mod(row, 2.0) * 0.5;
	vec2 id = floor(cell);
	vec2 f = fract(cell);
	vec2 edge = min(f, 1.0 - f) * brick_size;
	float mortar = 1.0 - step(mortar_width, min(edge.x, edge.y));
	float variation = hash(id);
	vec3 brick = mix(brick_color, brick_color_alt, variation) * (0.85 + 0.3 * hash(id + 7.3));
	vec3 color = mix(brick, mortar_color, mortar);
	float soot = smoothstep(soot_start, soot_start + soot_height, world_pos.y);
	soot = clamp(soot * (0.75 + 0.5 * hash(id * 0.37)), 0.0, 1.0);
	ALBEDO = mix(color, soot_color, soot * 0.85);
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
}
