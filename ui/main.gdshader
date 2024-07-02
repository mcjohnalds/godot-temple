shader_type canvas_item;

uniform sampler2D albedo_texture;

void fragment(){
	float aspect_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec4 albedo_tex = texture(
		albedo_texture, SCREEN_UV.xy * vec2(1.0, aspect_ratio)
	);
	COLOR = vec4(albedo_tex.rgb, COLOR.a);
}
