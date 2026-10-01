shader_type spatial;

// C17 — piso de chapas de ferro manchado de óleo (ART-PROMPTS-TIER1: "oil-stained floor").
// Coordenadas de mundo (sem UV): chapas com juntas, leve variação por chapa e manchas de
// óleo por ruído suave. As faces laterais do volume usam só a cor base.

uniform vec3 plate_color : source_color = vec3(0.118, 0.13, 0.145);
uniform vec3 plate_color_alt : source_color = vec3(0.145, 0.14, 0.13);
uniform vec3 seam_color : source_color = vec3(0.05, 0.052, 0.055);
uniform vec3 oil_color : source_color = vec3(0.045, 0.04, 0.035);
uniform float plate_size = 1.5;
uniform float seam_width = 0.02;
uniform float oil_amount = 0.55;
uniform float metallic_value = 0.55;
uniform float roughness_value = 0.78;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (abs(world_normal.y) < 0.7) {
		ALBEDO = plate_color * 0.8;
		ROUGHNESS = roughness_value;
		METALLIC = metallic_value;
	} else {
		vec2 p = world_pos.xz;
		vec2 cell = p / plate_size;
		vec2 id = floor(cell);
		vec2 f = fract(cell);
		vec2 edge = min(f, 1.0 - f) * plate_size;
		float seam = 1.0 - step(seam_width, min(edge.x, edge.y));
		vec3 plate = mix(plate_color, plate_color_alt, hash(id));
		float stain = value_noise(p * 0.45) * 0.65 + value_noise(p * 1.7) * 0.35;
		stain = smoothstep(1.0 - oil_amount, 1.0, stain);
		vec3 color = mix(plate, oil_color, stain * 0.8);
		ALBEDO = mix(color, seam_color, seam);
		// Óleo é mais liso: brilha de leve sob a luz.
		ROUGHNESS = mix(roughness_value, 0.35, stain);
		METALLIC = metallic_value;
	}
}
