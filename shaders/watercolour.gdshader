shader_type canvas_item;
// "Watercolour illustration" post-process for the story chapters.
//
// - Wobbles edges with low-frequency noise (hand-painted outlines)
// - Darkens pigment where colour changes sharply (edge pooling)
// - Granulates darker washes and lets paper texture show through lights
// - Fades to a soft paper border instead of a hard frame

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D paper_tex : repeat_enable, filter_linear;
uniform float wobble = 2.2;
uniform float edge_dark = 0.55;
uniform float granulation = 0.22;
uniform float border = 0.045;
uniform vec3 paper_col = vec3(0.95, 0.91, 0.82);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 nuv = FRAGCOORD.xy / 512.0;
	vec2 w = (texture(noise_tex, nuv).rg - 0.5) * wobble * px * 4.0;
	vec2 suv = uv + w;
	vec3 c = texture(screen_tex, suv).rgb;
	// Soft bleed: blend with a small blur
	vec3 b = (texture(screen_tex, suv + vec2(px.x * 2.0, 0.0)).rgb + texture(screen_tex, suv - vec2(px.x * 2.0, 0.0)).rgb
		+ texture(screen_tex, suv + vec2(0.0, px.y * 2.0)).rgb + texture(screen_tex, suv - vec2(0.0, px.y * 2.0)).rgb) * 0.25;
	vec3 col = mix(c, b, 0.45);
	// Edge pooling
	vec3 gx = texture(screen_tex, suv + vec2(px.x * 1.5, 0.0)).rgb - texture(screen_tex, suv - vec2(px.x * 1.5, 0.0)).rgb;
	vec3 gy = texture(screen_tex, suv + vec2(0.0, px.y * 1.5)).rgb - texture(screen_tex, suv - vec2(0.0, px.y * 1.5)).rgb;
	float edge = clamp(length(gx) + length(gy), 0.0, 1.0);
	col *= 1.0 - edge * edge_dark * 0.6;
	// Granulation in the darker washes
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	float gr = texture(noise_tex, FRAGCOORD.xy / 96.0).b;
	col *= 1.0 - (gr - 0.5) * granulation * (1.0 - l);
	// Paper shows through: lift toward paper colour in the lights
	vec3 paper = texture(paper_tex, FRAGCOORD.xy / 512.0).rgb;
	col = mix(col, col * paper * 1.08, 0.55);
	col = mix(col, paper_col * paper * 1.05, smoothstep(0.8, 1.0, l) * 0.35);
	// Deckled paper border
	vec2 d = min(uv, 1.0 - uv);
	float edge_n = texture(noise_tex, FRAGCOORD.xy / 220.0).r * 0.03;
	float m = smoothstep(border * 0.2, border + edge_n, min(d.x * 1.0, d.y * 1.78));
	col = mix(paper_col * paper, col, m);
	COLOR = vec4(col, 1.0);
}
