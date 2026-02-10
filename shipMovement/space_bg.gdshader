shader_type canvas_item;

uniform sampler2D grid_texture : repeat_enable, filter_nearest;
uniform vec2 camera_offset;
uniform float camera_zoom = 1.0;
uniform vec2 texture_scale = vec2(0.01, 0.01);

void fragment() {
	vec2 world_pos = (UV / SCREEN_PIXEL_SIZE) / camera_zoom + camera_offset;
	COLOR = texture(grid_texture, world_pos * texture_scale);
}