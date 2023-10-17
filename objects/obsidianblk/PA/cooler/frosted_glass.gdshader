shader_type spatial;
render_mode cull_disabled;
/*
Original Shader obtained from...
https://godotshaders.com/shader/frosted-glass/
*/

uniform float distortion_size = 0.4;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D glass;

void fragment() {
	vec2 d = texture(glass, UV).xy - vec2(0.5);
	vec3 gcolor = texture(screen_texture, SCREEN_UV + d * distortion_size).rgb;
	ALBEDO = gcolor * tint.rgb;
}