shader_type canvas_item;

uniform float fold_progress : hint_range(0.0, 1.0) = 0.0;
uniform float fold_direction : hint_range(-1.0, 1.0) = 1.0;

// Color base del pergamino (dorado viejo)
uniform vec4 page_color : source_color = vec4(0.84, 0.74, 0.50, 1.0);

// Genera ruido simple para simular textura de papel
float paper_noise(vec2 uv) {
	vec2 p = uv * 180.0;
	float n = fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
	vec2 p2 = uv * 90.0 + vec2(1.7, 9.2);
	float n2 = fract(sin(dot(p2, vec2(269.5, 183.3))) * 17251.4321);
	vec2 p3 = uv * 40.0 + vec2(5.3, 2.8);
	float n3 = fract(sin(dot(p3, vec2(419.2, 371.9))) * 29817.6234);
	return (n * 0.5 + n2 * 0.3 + n3 * 0.2);
}

void fragment() {
	vec2 uv = UV;

	// --- Textura de papel ---
	float noise = paper_noise(uv);
	// Variación sutil sobre el color base
	vec3 paper = page_color.rgb + (noise - 0.5) * 0.06;
	// Venas muy sutiles (fibras del papel)
	float fiber = fract(sin(uv.y * 320.0 + uv.x * 15.0) * 8742.3) * 0.018;
	paper -= fiber;
	paper = clamp(paper, 0.0, 1.0);

	// --- Sombra en la costura central del libro ---
	float spine = abs(uv.x - 0.5);
	float spine_shadow = mix(0.72, 1.0, smoothstep(0.0, 0.18, spine));
	paper *= spine_shadow;

	// --- Sombra en bordes (efecto de profundidad) ---
	float edge_x = min(uv.x, 1.0 - uv.x);
	float edge_y = min(uv.y, 1.0 - uv.y);
	float edge = min(edge_x, edge_y);
	float edge_shadow = mix(0.82, 1.0, smoothstep(0.0, 0.06, edge));
	paper *= edge_shadow;

	// --- Efecto de doblado ---
	float fold_x = (fold_direction > 0.0) ? (1.0 - fold_progress) : fold_progress;
	float dist = (fold_direction > 0.0) ? (uv.x - fold_x) : (fold_x - uv.x);

	if (dist > 0.0 && fold_progress > 0.01) {
		// Zona doblada: reverso de la página (más oscuro y desaturado)
		float bend = clamp(1.0 - dist * 3.0, 0.0, 1.0);
		vec3 back_color = mix(vec3(0.45, 0.38, 0.25), paper, bend * 0.3);
		float alpha = clamp(1.0 - dist * 2.0, 0.0, 1.0) * (1.0 - fold_progress * 0.6);
		COLOR = vec4(back_color, alpha);
	} else {
		// Sombra progresiva mientras se dobla
		float fold_shadow = 1.0 - fold_progress * clamp(1.0 - abs(dist) * 4.0, 0.0, 1.0) * 0.45;
		COLOR = vec4(paper * fold_shadow, page_color.a);
	}
}
