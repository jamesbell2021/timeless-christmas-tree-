shader_type canvas_item;
render_mode blend_add;
// Hearth fire: scrolling noise, domain-warped into licking tongues and
// shaped by a soft heat gradient. Drawn additively over the darkened room so
// it always reads as a light source.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float intensity = 0.85;
uniform float speed = 1.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float warp = texture(noise_tex, vec2(uv.x * 0.7 + 0.13, uv.y * 0.5 + t * 0.35)).r - 0.5;
	vec2 wuv = vec2(uv.x + warp * 0.18 * (1.0 - uv.y), uv.y);
	float n1 = texture(noise_tex, vec2(wuv.x * 1.1, wuv.y * 0.8 + t * 0.6)).r;
	float n2 = texture(noise_tex, vec2(wuv.x * 2.3 + 0.37, wuv.y * 1.5 + t * 1.1)).r;
	float n = n1 * 0.65 + n2 * 0.35;
	// Hotter at the bottom (UV.y = 1), narrower toward the top.
	float heat = pow(uv.y, 1.3);
	float cx = abs(wuv.x - 0.5) * 2.0;
	float body = 1.0 - smoothstep(0.25 + heat * 0.6, 1.05, cx);
	float f = heat * body * 1.45 + (n - 0.5) * 1.1 - (1.0 - uv.y) * 0.2;
	f = clamp(f, 0.0, 1.0);
	vec3 col = mix(vec3(0.5, 0.06, 0.0), vec3(1.0, 0.4, 0.05), smoothstep(0.1, 0.5, f));
	col = mix(col, vec3(1.0, 0.76, 0.4), smoothstep(0.55, 1.0, f));
	float a = smoothstep(0.04, 0.6, f) * intensity;
	COLOR = vec4(col * a, a);
}
