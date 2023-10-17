shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec2 ground_area = vec2(0,0);
uniform vec2 ground_offset = vec2(0,0);
uniform sampler2D base_texture: source_color,filter_nearest,repeat_enable;
uniform sampler2D normal_texture: hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D overlay_texture : source_color,filter_nearest,repeat_enable;
uniform sampler2D mask_texture: source_color,filter_nearest,repeat_enable;


void fragment() {
	vec4 base_color = texture(base_texture, UV);
	
	vec3 world_vert = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec2 mask_uv = (world_vert.xz - ground_offset) / ground_area;
	vec4 mask_color = texture(mask_texture, mask_uv);
	
	vec4 over_color = texture(overlay_texture, mask_uv);
	
	vec4 out_color = mix(base_color, over_color, mask_color);
	ALBEDO = out_color.rgb;
	NORMAL = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = 1.0;
}
