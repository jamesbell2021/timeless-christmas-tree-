shader_type canvas_item;
// "Oil on canvas" post-process for the parlour.
//
// 1. A 4-sector Kuwahara filter flattens fine detail into brush-like patches
//    while keeping edges crisp — the classic painterly look.
// 2. Canvas weave and a little grain give the surface a physical tooth.
// 3. A warm chromolithograph grade and vignette pull it toward the
//    Edwardian Christmas-card palette.
//
// quality: 0 = grade only (cheap), 1 = Kuwahara radius 2, 2 = radius 3.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D weave_tex : repeat_enable, filter_linear;
uniform int quality = 2;
uniform float vignette = 0.55;
uniform float grain = 0.035;
uniform float warmth = 0.06;
uniform float saturation = 1.08;

vec3 kuwahara(vec2 uv, vec2 px, int r) {
	vec3 m[4];
	vec3 s[4];
	for (int k = 0; k < 4; k++) { m[k] = vec3(0.0); s[k] = vec3(0.0); }
	float n = float((r + 1) * (r + 1));
	for (int j = 0; j <= 3; j++) {
		if (j > r) break;
		for (int i = 0; i <= 3; i++) {
			if (i > r) break;
			vec3 c0 = texture(screen_tex, uv + vec2(-float(i), -float(j)) * px).rgb;
			vec3 c1 = texture(screen_tex, uv + vec2( float(i), -float(j)) * px).rgb;
			vec3 c2 = texture(screen_tex, uv + vec2( float(i),  float(j)) * px).rgb;
			vec3 c3 = texture(screen_tex, uv + vec2(-float(i),  float(j)) * px).rgb;
			m[0] += c0; s[0] += c0 * c0;
			m[1] += c1; s[1] += c1 * c1;
			m[2] += c2; s[2] += c2 * c2;
			m[3] += c3; s[3] += c3 * c3;
		}
	}
	float best = 1e9;
	vec3 result = vec3(0.0);
	for (int k = 0; k < 4; k++) {
		vec3 mean = m[k] / n;
		vec3 var3 = abs(s[k] / n - mean * mean);
		float v = var3.r + var3.g + var3.b;
		if (v < best) { best = v; result = mean; }
	}
	return result;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 col;
	if (quality >= 2) {
		col = kuwahara(uv, px, 3);
	} else if (quality == 1) {
		col = kuwahara(uv, px, 2);
	} else {
		col = texture(screen_tex, uv).rgb;
	}
	// Canvas tooth
	float weave = texture(weave_tex, FRAGCOORD.xy / 128.0).r;
	col *= 1.0 + (weave - 0.5) * 0.09;
	// Grade: gentle saturation, warm highlights, slightly cool shadows
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col += vec3(warmth, warmth * 0.45, -warmth * 0.4) * smoothstep(0.25, 0.9, l);
	col += vec3(-0.01, 0.0, 0.025) * (1.0 - smoothstep(0.0, 0.3, l));
	// Lifted, inky blacks like a printed card
	col = col * 0.96 + vec3(0.018, 0.012, 0.01);
	// Vignette
	vec2 d = uv - vec2(0.5);
	d.x *= 1.2;
	float vig = smoothstep(0.85, 0.25, length(d));
	col *= mix(1.0 - vignette, 1.0, vig);
	// Grain
	float g = fract(sin(dot(FRAGCOORD.xy + fract(TIME) * 61.0, vec2(12.9898, 78.233))) * 43758.5453);
	col += (g - 0.5) * grain;
	COLOR = vec4(col, 1.0);
}
