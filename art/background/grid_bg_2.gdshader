shader_type canvas_item;
render_mode blend_mix;

uniform vec2 camera_offset;
uniform float camera_zoom = 1.0;
uniform float camera_rotation = 0.0;

vec2 get_position(vec2 uv, vec2 pixel_size) {
	vec2 screen_center_uv = uv - 0.5;
	vec2 pixel_pos = screen_center_uv / pixel_size;
	float c = cos(camera_rotation);
	float s = sin(camera_rotation);
	vec2 rotated_pos = vec2(pixel_pos.x * c - pixel_pos.y * s, pixel_pos.x * s + pixel_pos.y * c);
	vec2 base_screen_pos = rotated_pos / camera_zoom;
	return base_screen_pos;
}

void fragment() {
	vec2 world_pos = get_position(UV, SCREEN_PIXEL_SIZE) + camera_offset;

	float grid_spacing = 100.0;
	float line_width = 2.0;

	vec2 cell = mod(world_pos, grid_spacing);
	vec2 cell_inv = grid_spacing - cell;
	vec2 nearest = min(cell, cell_inv);

	float on_x_grid = step(nearest.y, line_width);
	float on_y_grid = step(nearest.x, line_width);
	float on_grid = max(on_x_grid, on_y_grid);

	float on_x_axis = step(abs(world_pos.y), line_width);
	float on_y_axis = step(abs(world_pos.x), line_width); 
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	if (on_grid > 0.0) {
		color = vec4(0.4, 0.4, 0.4, 0.8);
	}
	if (on_x_axis > 0.0) {
		color = vec4(1.0, 0.0, 0.0, 1.0);
	}
	if (on_y_axis > 0.0) {
		color = vec4(0.0, 1.0, 0.0, 1.0);
	}

	COLOR = color;
}