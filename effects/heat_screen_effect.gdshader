shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float heat_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float strength = clamp(heat_intensity, 0.0, 1.0);
	float wave = sin(uv.y * 78.0 + TIME * 2.8) + 0.42 * sin(uv.y * 143.0 - TIME * 1.9);
	vec2 distortion = vec2(wave * 0.0018, sin(uv.x * 34.0 + TIME * 2.2) * 0.00045) * strength;
	vec4 scene = texture(screen_texture, clamp(uv + distortion, vec2(0.001), vec2(0.999)));

	vec2 centered = (uv - vec2(0.5)) * vec2(2.0, 2.0);
	float edge = smoothstep(0.78, 1.28, length(centered));
	float vignette = edge * (0.18 + 0.08 * sin(TIME * 2.0)) * strength;
	vec3 alert_red = vec3(0.62, 0.035, 0.025);
	COLOR = vec4(mix(scene.rgb, alert_red, vignette), scene.a);
}
