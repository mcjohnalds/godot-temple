shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 10.0) = 1.0;

void fragment() {
	COLOR = texture(screen_texture, UV, strength);
}