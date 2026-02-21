shader_type canvas_item;

uniform sampler2D grid_texture : repeat_enable, filter_nearest;
uniform vec2 camera_offset;
uniform float camera_zoom = 1.0;
uniform float camera_rotation = 0.0;
uniform vec2 texture_scale = vec2(1.0, 1.0);

void fragment() {
	vec2 screen_center_uv = UV - 0.5;
	vec2 pixel_pos = screen_center_uv / SCREEN_PIXEL_SIZE;
	
	float c = cos(camera_rotation);
	float s = sin(camera_rotation);
	
	vec2 rotated_pos = vec2(
		pixel_pos.x * c - pixel_pos.y * s,
		pixel_pos.x * s + pixel_pos.y * c
	);
	
	vec2 world_pos = (rotated_pos / camera_zoom) + camera_offset;
	COLOR = texture(grid_texture, world_pos * texture_scale);
}