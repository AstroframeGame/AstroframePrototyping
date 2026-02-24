shader_type canvas_item;

uniform sampler2D grid_texture : repeat_enable, filter_nearest;
uniform sampler2D color_gradient : repeat_disable, filter_linear;
uniform vec2 camera_offset;
uniform float camera_zoom = 1.0;
uniform float camera_rotation = 0.0;
uniform float noise_frequency = 0.002;
uniform float star_density = 0.998;
uniform float star_scale = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v) {
	const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
	vec2 i  = floor(v + dot(v, C.yy));
	vec2 x0 = v - i + dot(i, C.xx);
	vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	m = m*m;
	m = m*m;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
	vec3 g;
	g.x  = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

void fragment() {
	vec2 screen_center_uv = UV - 0.5;
	vec2 pixel_pos = screen_center_uv / SCREEN_PIXEL_SIZE;
	float c = cos(camera_rotation);
	float s = sin(camera_rotation);
	vec2 rotated_pos = vec2(pixel_pos.x * c - pixel_pos.y * s, pixel_pos.x * s + pixel_pos.y * c);
	vec2 world_pos = (rotated_pos / camera_zoom) + camera_offset;
	
	float noise_val = snoise(world_pos * noise_frequency);
	float normalized_noise = noise_val * 0.5 + 0.5;
	
	vec4 gradient_color = texture(color_gradient, vec2(normalized_noise, 0.0));
	
	float star1 = step(star_density, hash(floor(world_pos * star_scale)));
	float star2 = step(star_density + 0.005, hash(floor(world_pos * star_scale * 2.0)));
	float stars = clamp(star1 + star2, 0.0, 1.0);
	
	COLOR = gradient_color + vec4(vec3(stars), 0.0);
}