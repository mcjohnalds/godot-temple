shader_type canvas_item;

uniform sampler2D albedo_texture;
uniform float blend_amount : hint_range(0.0, 1.0) = 0.5;


vec4 blend_soft_light(vec4 base, vec4 blend) {
	return mix(
			sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend),
			2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
			step(base, vec4(0.5))
	);
}

void fragment() {
	float aspect_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec4 albedo_tex = texture(
		albedo_texture, SCREEN_UV.xy * vec2(1.0, aspect_ratio)
	);
	COLOR = vec4(albedo_tex.rgb, COLOR.a);
}
