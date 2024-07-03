shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	COLOR = (texture(screen_texture, UV) +
			texture(screen_texture, UV * 0.99 + 0.5*0.01) +
			texture(screen_texture, UV * 0.98 + 0.5*0.02) +
			texture(screen_texture, UV * 0.97 + 0.5*0.03) +
			texture(screen_texture, UV * 0.96 + 0.5*0.04) +
			texture(screen_texture, UV * 0.95 + 0.5*0.05) +
			texture(screen_texture, UV * 0.94 + 0.5*0.06) +
			texture(screen_texture, UV * 0.93 + 0.5*0.07) +
			texture(screen_texture, UV * 0.92 + 0.5*0.08) +
			texture(screen_texture, UV * 0.91 + 0.5*0.09)) / 10.0;
}